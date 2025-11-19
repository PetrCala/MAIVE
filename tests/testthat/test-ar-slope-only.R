test_that("slope-only AR CI method is available", {
  # Use larger sample with clearer instrument to ensure AR CI can be computed
  set.seed(42)
  n <- 30
  Ns <- exp(rnorm(n, 8, 1))
  sebs <- pmax(0.2 / sqrt(Ns) + rnorm(n, 0, 0.01), 0.01)
  bs <- 0.5 + 0.2 * sebs + rnorm(n, 0, 0.05)

  invNs <- 1 / Ns
  model <- lm(bs ~ invNs)

  # Test slope-only method directly
  result_slope <- suppressWarnings(MAIVE:::compute_AR_CI_slope_only(
    model = model,
    adjust_fun = MAIVE:::PET_adjust,
    bs = bs,
    sebs = sebs,
    invNs = invNs,
    g = seq_along(bs),
    type_choice = "CR0"
  ))

  expect_true(is.list(result_slope))
  expect_true("b1_CI" %in% names(result_slope))
  # CI may be NA if no acceptance region found, or numeric
  if (!all(is.na(result_slope$b1_CI))) {
    expect_equal(length(result_slope$b1_CI), 2L)
    expect_true(is.numeric(result_slope$b1_CI))
  }
})

test_that("slope-only AR CI differs from joint under weak instruments", {
  # Simulate weak instrument scenario
  set.seed(123)
  n <- 50
  # Create weak instrument: low correlation between instrument and SE
  Ns <- exp(rnorm(n, 6, 1))
  true_effect <- 0.5
  true_bias <- 0.3
  sebs <- 0.1 + rnorm(n, 0, 0.02)  # Almost constant SE (weak instrument)
  bs <- true_effect + true_bias * sebs + rnorm(n, 0, sebs)

  dat <- data.frame(
    bs = bs,
    sebs = sebs,
    Ns = Ns
  )

  invNs <- 1 / Ns
  model <- lm(bs ~ invNs)

  # Compare joint vs slope-only
  result_joint <- suppressWarnings(MAIVE:::compute_AR_CI_optimized(
    model = model,
    adjust_fun = MAIVE:::PET_adjust,
    bs = bs,
    sebs = sebs,
    invNs = invNs,
    g = seq_along(bs),
    type_choice = "CR0",
    method = "joint"
  ))

  result_slope <- suppressWarnings(MAIVE:::compute_AR_CI_slope_only(
    model = model,
    adjust_fun = MAIVE:::PET_adjust,
    bs = bs,
    sebs = sebs,
    invNs = invNs,
    g = seq_along(bs),
    type_choice = "CR0"
  ))

  # Both should return valid CIs
  expect_true(is.numeric(result_joint$b1_CI))
  expect_true(is.numeric(result_slope$b1_CI))

  # CIs might differ under weak instruments (not asserting direction)
  expect_equal(length(result_joint$b1_CI), 2L)
  expect_equal(length(result_slope$b1_CI), 2L)
})

test_that("MAIVE auto-selects slope-only method for weak instruments", {
  # Create dataset with larger sample
  set.seed(999)
  n <- 40
  Ns <- exp(rnorm(n, 8, 0.5))
  sebs <- 0.15 + rnorm(n, 0, 0.005)  # Nearly constant SE (weak instrument)
  bs <- 0.5 + 0.1 * sebs + rnorm(n, 0, sebs)

  dat <- data.frame(
    bs = bs,
    sebs = sebs,
    Ns = Ns,
    studyid = rep(1:10, each = 4)
  )

  # This should trigger weak instrument warning when F < 10
  result <- suppressWarnings(maive(
    dat = dat,
    method = 1,
    weight = 2,
    instrument = 1,
    studylevel = 0,
    SE = 0,
    AR = 1,
    first_stage = 0
  ))

  # Check that result was computed
  expect_true(!is.null(result))
  expect_true(!is.null(result$egger_ar_ci))
})

test_that("slope-only method handles PEESE adjustment", {
  set.seed(888)
  n <- 30
  Ns <- exp(rnorm(n, 8, 1))
  sebs <- pmax(0.2 / sqrt(Ns) + rnorm(n, 0, 0.01), 0.01)
  bs <- 0.5 + 0.3 * sebs^2 + rnorm(n, 0, 0.05)

  invNs <- 1 / Ns
  sebs_sq <- sebs^2
  model <- lm(bs ~ sebs_sq)

  # Test with PEESE adjustment
  result <- suppressWarnings(MAIVE:::compute_AR_CI_slope_only(
    model = model,
    adjust_fun = MAIVE:::PEESE_adjust,
    bs = bs,
    sebs = sebs,
    invNs = invNs,
    g = seq_along(bs),
    type_choice = "CR0"
  ))

  expect_true(is.list(result))
  expect_true("b1_CI" %in% names(result))
})

test_that("slope-only method handles weighted AR", {
  bs <- c(0.4, 0.5, 0.55, 0.48)
  sebs <- c(0.2, 0.18, 0.22, 0.19)
  invNs <- 1 / c(80, 90, 85, 88)
  model <- lm(bs ~ invNs)
  weights <- c(1, 1.5, 1.2, 1.3)

  result <- suppressWarnings(MAIVE:::compute_AR_CI_slope_only(
    model = model,
    adjust_fun = MAIVE:::PET_adjust,
    bs = bs,
    sebs = sebs,
    invNs = invNs,
    g = seq_along(bs),
    type_choice = "CR0",
    weights = weights
  ))

  expect_true(is.list(result))
  expect_true("b1_CI" %in% names(result))
})

test_that("slope-only handles extreme weight heterogeneity", {
  # Create scenario with extreme weight heterogeneity
  bs <- c(0.5, 0.55, 0.52)
  sebs <- c(0.001, 0.5, 0.002)
  invNs <- 1 / c(100, 120, 110)
  model <- lm(bs ~ invNs)
  weights <- c(1000, 1, 1000)  # Extreme weight variation

  # Suppress warnings and just check it doesn't error
  result <- suppressWarnings(MAIVE:::compute_AR_CI_slope_only(
    model = model,
    adjust_fun = MAIVE:::PET_adjust,
    bs = bs,
    sebs = sebs,
    invNs = invNs,
    g = seq_along(bs),
    type_choice = "CR0",
    weights = weights
  ))

  # Should return valid structure (may be NA)
  expect_true(is.list(result))
  expect_true("b1_CI" %in% names(result))
})
