# EK must handle bias on either side of zero: the kink location uses the
# absolute PET-PEESE intercept, so EK on -bs is minus EK on bs (#31).

ek_sign_data <- function() {
  set.seed(31)
  n <- 90
  Ns <- round(runif(n, 30, 800))
  sebs <- 2 / sqrt(Ns) * exp(rnorm(n, 0, 0.2))
  bs <- 0.4 + 1.5 * sebs + rnorm(n, 0, sebs)
  data.frame(bs = bs, sebs = sebs, Ns = Ns, study_id = rep(1:30, each = 3))
}

ek_sign_configs <- list(
  list(weight = 0, instrument = 0, studylevel = 0, SE = 0),
  list(weight = 0, instrument = 1, studylevel = 0, SE = 0),
  list(weight = 2, instrument = 1, studylevel = 2, SE = 1),
  list(weight = 1, instrument = 1, studylevel = 3, SE = 2)
)

run_ek <- function(fun, data, cfg, first_stage) {
  args <- c(list(dat = data, method = 4, AR = 0, first_stage = first_stage), cfg)
  suppressWarnings(do.call(fun, args))
}

expect_ek_mirrored <- function(pos, neg) {
  expect_equal(pos$ek_structure, "kink")
  expect_equal(neg$ek_structure, "kink")
  expect_equal(neg$beta, -pos$beta, tolerance = 1e-8)
  expect_equal(neg$SE, pos$SE, tolerance = 1e-8)
  expect_equal(neg$beta_standard, -pos$beta_standard, tolerance = 1e-8)
  expect_equal(neg$SE_standard, pos$SE_standard, tolerance = 1e-8)
  expect_equal(neg$Hausman, pos$Hausman, tolerance = 1e-8)
  expect_equal(neg$slope_coef$kink_location, pos$slope_coef$kink_location, tolerance = 1e-8)
  expect_equal(neg$slope_coef$kink_effect, -pos$slope_coef$kink_effect, tolerance = 1e-8)
}

test_that("maive EK on -bs equals minus EK on bs", {
  dat <- ek_sign_data()
  dat_neg <- transform(dat, bs = -bs)

  for (cfg in ek_sign_configs) {
    for (first_stage in c(0, 1)) {
      pos <- run_ek(maive, dat, cfg, first_stage)
      neg <- run_ek(maive, dat_neg, cfg, first_stage)
      expect_ek_mirrored(pos, neg)
    }
  }
})

test_that("waive EK on -bs equals minus EK on bs", {
  dat <- ek_sign_data()
  dat_neg <- transform(dat, bs = -bs)
  cfg <- list(weight = 0, instrument = 1, studylevel = 2, SE = 1)

  pos <- run_ek(waive, dat, cfg, first_stage = 1)
  neg <- run_ek(waive, dat_neg, cfg, first_stage = 1)
  expect_ek_mirrored(pos, neg)
})

test_that("maive_fit_ek gives the same kink location for a negative intercept", {
  dat <- ek_sign_data()
  fit_ek <- function(bs) {
    design <- MAIVE:::maive_build_design_matrices(
      bs, dat$sebs, rep(1, nrow(dat)), dat$sebs, dat$sebs^2, NULL, 0L
    )
    fits <- MAIVE:::maive_fit_models(design)
    selection <- MAIVE:::maive_select_petpeese(fits, design, alpha_s = 0.05)
    sighats <- MAIVE:::maive_compute_sigma_h(fits, design$w, design$sebs)
    MAIVE:::maive_fit_ek(selection, design, sighats, 4L)
  }

  pos <- fit_ek(dat$bs)
  neg <- fit_ek(-dat$bs)

  expect_gt(pos$a0, 0)
  expect_equal(neg$a0, pos$a0)
  expect_equal(neg$a00, pos$a00)
  expect_equal(neg$structure, "kink")
  expect_equal(unname(coef(neg$ekreg)), -unname(coef(pos$ekreg)))
  expect_equal(unname(coef(neg$ekreg0)), -unname(coef(pos$ekreg0)))
})

test_that("EK results for a positive intercept are unchanged from 0.4.1", {
  dat <- ek_sign_data()
  # beta, SE, beta_standard, SE_standard, kink_location, kink_effect as
  # returned by MAIVE 0.4.1 with first_stage = 1
  expected <- list(
    c(0.5481342332, 0.0140649802, 0.5402879400, 0.0117714131, 0.1290810992, 1.7174233315),
    c(0.5482664100, 0.0147386558, 0.5402879400, 0.0117714131, 0.1285594556, 1.7251831837),
    c(0.5558526750, 0.0117505964, 0.5402879400, 0.0111541693, 0.1287449875, 1.1543338678),
    c(0.5371007283, 0.0097243682, 0.5276605591, 0.0092379794, 0.1176780263, 1.3283632498)
  )

  for (i in seq_along(ek_sign_configs)) {
    res <- run_ek(maive, dat, ek_sign_configs[[i]], first_stage = 1)
    expect_equal(res$ek_structure, "kink")
    got <- c(
      res$beta, res$SE, res$beta_standard, res$SE_standard,
      res$slope_coef$kink_location, res$slope_coef$kink_effect
    )
    expect_equal(got, expected[[i]], tolerance = 1e-7)
  }
})

test_that("euro EK with study dummies kinks on the negative conventional intercept", {
  euro <- read.csv(test_path("fixtures", "euro.csv"), stringsAsFactors = FALSE)
  euro_neg <- transform(euro, bs = -bs)
  # beta_standard and SE_standard at studylevel 1 and 3. They equal minus the
  # EK estimate (and the same SE) that MAIVE 0.4.1 returns on -bs, where the
  # intercept is positive and the old signed rule already kinked.
  expected <- list(
    "1" = c(-0.119156197910, 0.258962775480),
    "3" = c(-0.119156197910, 0.258642662525)
  )

  for (studylevel in c(1, 3)) {
    args <- list(
      method = 4, weight = 0, instrument = 1, studylevel = studylevel, SE = 2, AR = 0, first_stage = 0
    )
    pos <- suppressWarnings(do.call(maive, c(list(dat = euro), args)))
    neg <- suppressWarnings(do.call(maive, c(list(dat = euro_neg), args)))

    expect_equal(
      c(pos$beta_standard, pos$SE_standard),
      expected[[as.character(studylevel)]],
      tolerance = 1e-8
    )
    expect_equal(neg$beta, -pos$beta, tolerance = 1e-8)
    expect_equal(neg$beta_standard, -pos$beta_standard, tolerance = 1e-8)
    expect_equal(neg$SE_standard, pos$SE_standard, tolerance = 1e-8)
  }
})
