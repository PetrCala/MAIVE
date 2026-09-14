# Anderson-Rubin intervals use the second stage's own weights, and the subset
# AR scales its intercept like every other variable (#32).

simulate_ar_weights_data <- function(seed, n = 80) {
  set.seed(seed)
  Ns <- round(exp(runif(n, 3, 7)))
  sebs <- exp(rnorm(n, 0, 0.4)) / sqrt(Ns)
  bs <- 0.2 + 0.8 * sebs + rnorm(n, 0, sebs)
  study_id <- rep(seq_len(25), times = rep(c(1, 2, 3, 6, 4), 5))
  data.frame(bs = bs, sebs = sebs, Ns = Ns, study_id = study_id)
}

# Run fn(...) and record the weights every AR routine receives.
capture_ar_weights <- function(fn, ...) {
  seen <- list()
  original <- MAIVE:::compute_AR_CI_optimized
  testthat::local_mocked_bindings(
    compute_AR_CI_optimized = function(..., weights = NULL, method = "joint") {
      seen[[method]] <<- weights
      original(..., weights = weights, method = method)
    },
    .package = "MAIVE"
  )
  result <- suppressWarnings(fn(...))
  list(result = result, weights = seen)
}

test_that("AR intervals receive 1 / w^2 of the final second-stage weights", {
  dat <- simulate_ar_weights_data(32)
  cases <- list(
    list(fn = maive, weight = 3),
    list(fn = waive, weight = 0),
    list(fn = waive, weight = 2),
    list(fn = waive, weight = 3)
  )

  for (case in cases) {
    for (fs in c(0, 1)) {
      run <- capture_ar_weights(
        case$fn,
        dat = dat, method = 1, weight = case$weight, instrument = 1,
        studylevel = 2, SE = 0, AR = 1, first_stage = fs
      )
      expected <- unname(1 / run$result$weights^2)
      expect_equal(unname(run$weights$joint), expected)
      expect_equal(unname(run$weights$slope_only), expected)
    }
  }
})

test_that("maive AR weights are unchanged for no weights and adjusted weights", {
  dat <- simulate_ar_weights_data(34)

  for (fs in c(0, 1)) {
    unweighted <- capture_ar_weights(
      maive,
      dat = dat, method = 1, weight = 0, instrument = 1,
      studylevel = 2, SE = 0, AR = 1, first_stage = fs
    )
    expect_equal(unname(unweighted$weights$joint), rep(1, nrow(dat)))

    adjusted <- capture_ar_weights(
      maive,
      dat = dat, method = 1, weight = 2, instrument = 1,
      studylevel = 2, SE = 0, AR = 1, first_stage = fs
    )
    expect_equal(unname(adjusted$weights$joint), unname(1 / adjusted$result$SE_instrumented^2))
  }
})

test_that("AR stays off for standard weights", {
  dat <- simulate_ar_weights_data(32)
  res <- suppressWarnings(maive(
    dat,
    method = 1, weight = 1, instrument = 1, studylevel = 2,
    SE = 0, AR = 1, first_stage = 1
  ))
  expect_identical(res$AR_CI, "NA")
  expect_identical(res$egger_ar_ci, "NA")
})

test_that("unweighted AR intervals match MAIVE 0.4.1", {
  # Reference values computed with MAIVE 0.4.1 on the same data.
  dat <- simulate_ar_weights_data(32)
  reference <- list(
    "0" = list(ar = c(0.140356327519286, 0.229207087381809), egger = c(0.292179197158888, 1.66194999580354)),
    "1" = list(ar = c(0.153089431912652, 0.241954899040947), egger = c(0.269337227759855, 1.26759594430672))
  )

  for (fs in c(0, 1)) {
    res <- suppressWarnings(maive(
      dat,
      method = 1, weight = 0, instrument = 1, studylevel = 2,
      SE = 0, AR = 1, first_stage = fs
    ))
    ref <- reference[[as.character(fs)]]
    expect_equal(res$AR_CI, ref$ar, tolerance = 1e-10)
    expect_equal(unname(res$egger_ar_ci), ref$egger, tolerance = 1e-10)
  }
})

test_that("subset AR with no weights matches the unscaled-intercept regression", {
  dat <- simulate_ar_weights_data(33)
  invNs <- 1 / dat$Ns
  model <- lm(bs ~ sebs, data = dat)
  g <- dat$study_id

  result <- suppressWarnings(MAIVE:::compute_AR_CI_slope_only(
    model = model,
    adjust_fun = MAIVE:::PET_adjust,
    bs = dat$bs,
    sebs = dat$sebs,
    invNs = invNs,
    g = g,
    type_choice = "CR0"
  ))

  # Every grid point inside the interval is accepted by lm(r ~ 1 + z).
  crit <- qchisq(0.95, df = 1)
  stat_at <- function(b1) {
    r <- dat$bs - b1 * dat$sebs
    z <- invNs
    fit <- lm(r ~ z)
    vc <- clubSandwich::vcovCR(fit, cluster = g, type = "CR0")
    unname(coef(fit)["z"]^2 / vc["z", "z"])
  }
  expect_true(all(is.finite(result$b1_CI)))
  expect_lt(stat_at(result$b1_CI[1]), crit)
  expect_lt(stat_at(result$b1_CI[2]), crit)
})

test_that("weighted Egger AR interval is finite and covers the weighted Egger estimate", {
  for (seed in 32:34) {
    dat <- simulate_ar_weights_data(seed)
    for (fs in c(0, 1)) {
      res <- suppressWarnings(maive(
        dat,
        method = 1, weight = 2, instrument = 1, studylevel = 0,
        SE = 0, AR = 1, first_stage = fs
      ))
      ci <- res$egger_ar_ci
      expect_true(is.numeric(ci))
      expect_true(all(is.finite(ci)))
      expect_lte(ci[["lower"]], res$egger_coef)
      expect_gte(ci[["upper"]], res$egger_coef)
    }
  }
})

test_that("subset AR scales the intercept when x * sqrt(w) is constant", {
  # With PET, instrumented SEs and weights 1 / sebs^2, the scaled regressor is
  # constant. An unscaled intercept then absorbs every candidate slope, so the
  # interval came back as the whole search grid or NA.
  set.seed(32)
  n <- 80
  Ns <- round(exp(runif(n, 3, 7)))
  sebs <- exp(rnorm(n, 0, 0.4)) / sqrt(Ns)
  bs <- 0.2 + 0.8 * sebs + rnorm(n, 0, sebs)
  weights <- 1 / sebs^2
  model <- lm(I(bs / sebs) ~ 0 + I(1 / sebs) + I(sebs / sebs))
  beta1 <- unname(coef(model)[2])
  beta1se <- sqrt(clubSandwich::vcovCR(model, cluster = seq_len(n), type = "CR0")[2, 2])

  result <- suppressWarnings(MAIVE:::compute_AR_CI_slope_only(
    model = model,
    adjust_fun = MAIVE:::PET_adjust,
    bs = bs,
    sebs = sebs,
    invNs = 1 / Ns,
    g = seq_len(n),
    type_choice = "CR0",
    weights = weights
  ))

  expect_true(all(is.finite(result$b1_CI)))
  expect_lt(diff(result$b1_CI), 20 * beta1se)
  expect_lte(result$b1_CI[1], beta1)
  expect_gte(result$b1_CI[2], beta1)
})
