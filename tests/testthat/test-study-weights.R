test_that("Study weights give each study equal total weight", {
  dat <- data.frame(
    bs = c(0.4, 0.5, 0.45, 0.55, 0.47, 0.52),
    sebs = c(0.2, 0.19, 0.21, 0.18, 0.22, 0.2),
    Ns = c(80, 85, 90, 95, 88, 92),
    study_id = c("A", "A", "B", "B", "B", "C")
  )

  opts <- MAIVE:::normalize_maive_options(dat, method = 1, weight = 3, instrument = 1, studylevel = 2, SE = 0, AR = 0, first_stage = 0)
  prepared <- MAIVE:::maive_prepare_data(opts$dat, opts$studylevel)
  instrumentation <- MAIVE:::maive_compute_variance_instrumentation(
    prepared$sebs,
    prepared$Ns,
    prepared$g,
    opts$type_choice,
    opts$instrument,
    opts$first_stage_type
  )

  w <- MAIVE:::maive_compute_weights(opts$weight, prepared$sebs, instrumentation$sebs2fit1, prepared$studyid)

  # w divides each row of the design, so the least-squares weight is 1 / w^2
  # (#29). An estimate from a study with k estimates must get weight 1 / k.
  ls_weight <- 1 / w^2
  expect_equal(ls_weight, c(rep(1 / 2, 2), rep(1 / 3, 3), 1))

  totals <- tapply(ls_weight, prepared$studyid, sum)
  expect_true(all(abs(totals - 1) < 1e-12))
})

study_weights_issue_data <- function() {
  # Reproduction from #29: three studies with 1, 3 and 8 estimates.
  set.seed(29)
  dat <- data.frame(
    bs = 0,
    sebs = runif(12, 0.05, 0.3),
    Ns = round(runif(12, 50, 500)),
    study_id = rep(1:3, times = c(1, 3, 8))
  )
  dat$bs <- c(0.1, 0.5, 1)[dat$study_id] + dat$sebs + rnorm(12, 0, 0.02)
  dat
}

test_that("Study-weighted PET matches lm with weights 1 / k (#29)", {
  dat <- study_weights_issue_data()
  k <- ave(dat$bs, dat$study_id, FUN = length)

  fit <- maive(
    dat,
    method = 1, weight = 3, instrument = 0, studylevel = 2, SE = 1, AR = 0,
    study_id = "study_id"
  )

  expected <- unname(coef(lm(bs ~ sebs, data = dat, weights = 1 / k))[1])
  # Before the fix the package matched weights = k^2 (0.9518 against 0.1116).
  expect_equal(fit$beta, expected, tolerance = 1e-10)
  expect_equal(fit$weights, sqrt(k))
})

test_that("Study-weighted PEESE matches lm with weights 1 / k (#29)", {
  dat <- study_weights_issue_data()
  k <- ave(dat$bs, dat$study_id, FUN = length)

  fit <- maive(
    dat,
    method = 2, weight = 3, instrument = 0, studylevel = 2, SE = 1, AR = 0,
    study_id = "study_id"
  )

  expected <- unname(coef(lm(bs ~ I(sebs^2), data = dat, weights = 1 / k))[1])
  expect_equal(fit$beta, expected, tolerance = 1e-10)
})
