test_that("AR CI is available with MAIVE-adjusted weights", {
  dat <- data.frame(
    bs = c(0.2, 0.25, 0.22, 0.3, 0.27),
    sebs = c(0.1, 0.12, 0.11, 0.13, 0.12),
    Ns = c(100, 120, 110, 130, 115)
  )

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

  expect_true(is.numeric(result$AR_CI))
  expect_equal(length(result$AR_CI), 2L)
  expect_true(all(is.finite(result$AR_CI)))
})

test_that("standard weights continue to disable AR CI", {
  dat <- data.frame(
    bs = c(0.2, 0.25, 0.22, 0.3),
    sebs = c(0.1, 0.12, 0.11, 0.13),
    Ns = c(100, 120, 110, 130)
  )

  result <- suppressWarnings(maive(
    dat = dat,
    method = 1,
    weight = 1,
    instrument = 1,
    studylevel = 0,
    SE = 0,
    AR = 1,
    first_stage = 0
  ))

  expect_identical(result$AR_CI, "NA")
})

test_that("weighted AR computation handles weight diagnostics", {
  bs <- c(0.4, 0.5, 0.55, 0.48)
  sebs <- c(0.2, 0.18, 0.22, 0.19)
  invNs <- 1 / c(80, 90, 85, 88)
  model <- lm(bs ~ invNs)

  base <- MAIVE:::compute_AR_CI_optimized(
    model = model,
    adjust_fun = MAIVE:::PET_adjust,
    bs = bs,
    sebs = sebs,
    invNs = invNs,
    g = seq_along(bs),
    type_choice = "CR0"
  )

  identical_weights <- MAIVE:::compute_AR_CI_optimized(
    model = model,
    adjust_fun = MAIVE:::PET_adjust,
    bs = bs,
    sebs = sebs,
    invNs = invNs,
    g = seq_along(bs),
    type_choice = "CR0",
    weights = rep(1, length(bs))
  )

  expect_equal(base, identical_weights)

  expect_warning(
    MAIVE:::compute_AR_CI_optimized(
      model = model,
      adjust_fun = MAIVE:::PET_adjust,
      bs = bs,
      sebs = sebs,
      invNs = invNs,
      g = seq_along(bs),
      type_choice = "CR0",
      weights = c(1e-6, 1, 5, 10)
    ),
    "Adjusted weights vary substantially"
  )
})
