#' @keywords internal
PET_adjust <- function(bs, b0, b1, sebs) bs - b0 - b1 * sebs

#' @keywords internal
PEESE_adjust <- function(bs, b0, b1, sebs) bs - b0 - b1 * sebs^2

#' @keywords internal
compute_AR_CI_optimized <- function(model, adjust_fun, bs, sebs, invNs, g, type_choice, weights = NULL) {
  # Beta estimates and robust SEs
  beta0 <- model$coefficients[1]
  beta0se <- sqrt(clubSandwich::vcovCR(model, cluster = g, type = type_choice)[1, 1])
  beta1 <- model$coefficients[2]
  beta1se <- sqrt(clubSandwich::vcovCR(model, cluster = g, type = type_choice)[2, 2])

  M <- length(bs)

  if (!is.null(weights)) {
    if (length(weights) != M) {
      stop("weights must have the same length as the data used in the AR test.")
    }
    if (any(!is.finite(weights) | weights <= 0)) {
      stop("weights supplied to the AR test must be positive and finite.")
    }
    weight_ratio <- max(weights) / min(weights)
    if (is.finite(weight_ratio) && weight_ratio > 1000) {
      warning(
        "Adjusted weights vary substantially (ratio > 1000); Anderson-Rubin CI may be unstable."
      )
    }
    sqrt_weights <- sqrt(weights)
  } else {
    sqrt_weights <- rep(1, M)
  }

  # Transform key variables using the weight scaling
  bs_t <- bs * sqrt_weights
  sebs_t <- sebs * sqrt_weights
  invNs_t <- invNs * sqrt_weights
  ones_vec <- sqrt_weights

  # For extremely large datasets, disable AR computation to avoid memory issues
  if (M > 5000) {
    warning("Dataset too large for AR computation (", M, " observations). AR CI disabled.")
    return(list(b0_CI = "NA", b1_CI = "NA"))
  }

  # For very large datasets, use much smaller grids to avoid memory issues
  if (M > 1000) {
    max_grid_size <- min(30, max(15, round(500 / sqrt(M))))
    base_resolution <- max_grid_size
  } else {
    base_resolution <- min(50, max(20, round(sqrt(M))))
  }

  # Pre-compute matrices (reused across all grid points)
  Z <- cbind(ones_vec, invNs_t)
  ZtZ_inv <- solve(t(Z) %*% Z)
  PZ <- Z %*% ZtZ_inv %*% t(Z)
  MZ <- diag(M) - PZ

  # Pre-compute sebs powers for adjustment functions
  sebs_sq <- sebs_t^2

  # Helper for constructing AR statistic over a grid
  compute_AR_stats_chunked <- function(b0_vals, b1_vals) {
    n_b0 <- length(b0_vals)
    n_b1 <- length(b1_vals)

    max_chunk_size <- if (M > 2000) 500 else 1000
    chunk_size <- min(max_chunk_size, n_b0 * n_b1)
    n_chunks <- ceiling((n_b0 * n_b1) / chunk_size)

    all_stats <- numeric(n_b0 * n_b1)

    for (chunk in seq_len(n_chunks)) {
      start_idx <- (chunk - 1) * chunk_size + 1
      end_idx <- min(chunk * chunk_size, n_b0 * n_b1)
      chunk_indices <- start_idx:end_idx
      chunk_size_actual <- length(chunk_indices)

      b0_chunk <- rep(b0_vals, each = n_b1)[chunk_indices]
      b1_chunk <- rep(b1_vals, times = n_b0)[chunk_indices]

      bs_mat <- matrix(rep(bs_t, times = chunk_size_actual), nrow = M, ncol = chunk_size_actual)
      se_mat <- if (identical(adjust_fun, PET_adjust)) {
        matrix(rep(sebs_t, times = chunk_size_actual), nrow = M, ncol = chunk_size_actual)
      } else {
        matrix(rep(sebs_sq, times = chunk_size_actual), nrow = M, ncol = chunk_size_actual)
      }
      b0_mat <- matrix(rep(b0_chunk, each = M), nrow = M, ncol = chunk_size_actual)
      b1_mat <- matrix(rep(b1_chunk, each = M), nrow = M, ncol = chunk_size_actual)

      bs_star_mat <- bs_mat - b0_mat - b1_mat * se_mat

      PZ_bs_star <- PZ %*% bs_star_mat
      MZ_bs_star <- MZ %*% bs_star_mat

      num <- colSums(bs_star_mat * PZ_bs_star)
      denom <- colSums(bs_star_mat * MZ_bs_star)
      denom[abs(denom) < 1e-10] <- 1e-10

      stats <- (M - 2) * num / denom
      all_stats[chunk_indices] <- stats

      if (chunk %% 5 == 0) {
        gc()
      }
    }

    matrix(all_stats, nrow = n_b0, ncol = n_b1)
  }

  # Construct grids adaptively, starting from ±5 SE and expanding if necessary
  crit_value <- 5.99
  grid_multiplier <- 5
  max_multiplier <- 40
  accepted <- FALSE
  AR_accept <- NULL
  b0_grid <- NULL
  b1_grid <- NULL

  while (!accepted && grid_multiplier <= max_multiplier) {
    range0 <- if (is.finite(beta0se) && beta0se > 0) grid_multiplier * beta0se else grid_multiplier * max(1, abs(beta0))
    range1 <- if (is.finite(beta1se) && beta1se > 0) grid_multiplier * beta1se else grid_multiplier * max(1, abs(beta1))

    l0 <- beta0 - range0
    u0 <- beta0 + range0
    l1 <- beta1 - range1
    u1 <- beta1 + range1

    span0 <- max(u0 - l0, .Machine$double.eps)
    span1 <- max(u1 - l1, .Machine$double.eps)

    pr0 <- min(max(base_resolution, round(base_resolution * 5 / span0)), 150)
    pr1 <- min(max(base_resolution, round(base_resolution * 5 / span1)), 150)

    b0_grid <- seq(l0, u0, length.out = pr0)
    b1_grid <- seq(l1, u1, length.out = pr1)

    AR_stats <- compute_AR_stats_chunked(b0_grid, b1_grid)
    AR_accept <- AR_stats < crit_value

    accepted <- any(AR_accept)
    if (!accepted) {
      grid_multiplier <- grid_multiplier * 1.5
    }
  }

  if (!accepted) {
    warning("AR search grid failed to locate an acceptance region; returning unbounded interval.")
    return(list(b0_CI = c(-Inf, Inf), b1_CI = c(-Inf, Inf)))
  }

  b0_accept_idx <- which(rowSums(AR_accept) > 0)
  b1_accept_idx <- which(colSums(AR_accept) > 0)

  detect_disjoint <- function(indices) {
    if (length(indices) <= 1) {
      return(FALSE)
    }
    any(diff(indices) > 1)
  }

  disjoint_b0 <- detect_disjoint(b0_accept_idx)
  disjoint_b1 <- detect_disjoint(b1_accept_idx)

  if (disjoint_b0 || disjoint_b1) {
    warning("AR acceptance region is disjoint; returning conservative interval spanning all segments.")
  }

  b0_CI <- c(min(b0_grid[b0_accept_idx]), max(b0_grid[b0_accept_idx]))
  b1_CI <- c(min(b1_grid[b1_accept_idx]), max(b1_grid[b1_accept_idx]))

  # Warn if AR CI is implausibly narrow relative to the CR2 interval
  if (is.finite(beta1se) && beta1se > 0) {
    cr2_width <- 2 * qnorm(0.975) * beta1se
    ar_width <- diff(b1_CI)
    if (is.finite(ar_width) && ar_width > 0 && ar_width < 0.1 * cr2_width) {
      warning("AR slope CI width is less than 10% of the CR2 interval; investigate instrument strength.")
    }
  }

  list(
    b0_CI = round(b0_CI, 3),
    b1_CI = round(b1_CI, 3)
  )
}
