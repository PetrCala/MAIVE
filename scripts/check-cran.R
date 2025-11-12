#!/usr/bin/env Rscript

# CRAN Pre-Submission Check Script
# Run this locally before submitting to CRAN

cat("<U+2550><U+2550><U+2550><U+2550><U+2550><U+2550><U+2550><U+2550><U+2550><U+2550><U+2550><U+2550><U+2550><U+2550><U+2550><U+2550><U+2550><U+2550><U+2550><U+2550><U+2550><U+2550><U+2550><U+2550><U+2550><U+2550><U+2550><U+2550><U+2550><U+2550><U+2550><U+2550><U+2550><U+2550><U+2550><U+2550><U+2550><U+2550><U+2550><U+2550><U+2550><U+2550><U+2550><U+2550><U+2550><U+2550><U+2550><U+2550><U+2550><U+2550><U+2550><U+2550><U+2550><U+2550><U+2550><U+2550><U+2550><U+2550><U+2550><U+2550><U+2550><U+2550><U+2550>\n")
cat("  MAIVE Package - Local CRAN Check\n")
cat("<U+2550><U+2550><U+2550><U+2550><U+2550><U+2550><U+2550><U+2550><U+2550><U+2550><U+2550><U+2550><U+2550><U+2550><U+2550><U+2550><U+2550><U+2550><U+2550><U+2550><U+2550><U+2550><U+2550><U+2550><U+2550><U+2550><U+2550><U+2550><U+2550><U+2550><U+2550><U+2550><U+2550><U+2550><U+2550><U+2550><U+2550><U+2550><U+2550><U+2550><U+2550><U+2550><U+2550><U+2550><U+2550><U+2550><U+2550><U+2550><U+2550><U+2550><U+2550><U+2550><U+2550><U+2550><U+2550><U+2550><U+2550><U+2550><U+2550><U+2550><U+2550><U+2550><U+2550>\n\n")

# Check if required packages are installed
required_pkgs <- c("devtools", "rcmdcheck", "rhub")
missing_pkgs <- required_pkgs[!sapply(required_pkgs, requireNamespace, quietly = TRUE)]

if (length(missing_pkgs) > 0) {
  cat("<U+274C> Missing required packages:", paste(missing_pkgs, collapse = ", "), "\n")
  cat("Installing missing packages...\n\n")
  install.packages(missing_pkgs)
}

# Step 1: Update documentation
cat("<U+0001F4DD> Step 1/5: Updating documentation...\n")
devtools::document()
cat("<U+2705> Documentation updated\n\n")

# Step 2: Run local checks
cat("<U+0001F50D> Step 2/5: Running R CMD check (this may take several minutes)...\n")
check_results <- devtools::check(
  document = FALSE,
  remote = TRUE,
  manual = TRUE,
  cran = TRUE
)
cat("<U+2705> Local check completed\n\n")

# Step 3: Check on Windows (via rhub)
cat("<U+0001FA9F> Step 3/5: Checking on Windows via R-hub...\n")
cat("(This will submit to R-hub and email you results)\n")
tryCatch(
  {
    rhub::rhub_check(platforms = "windows")
    cat("<U+2705> Windows check submitted to R-hub\n\n")
  },
  error = function(e) {
    cat("<U+26A0><U+FE0F>  R-hub check failed (may require setup):", conditionMessage(e), "\n\n")
  }
)

# Step 4: Check on additional platforms
cat("<U+0001F30D> Step 4/5: Checking on additional platforms via R-hub...\n")
tryCatch(
  {
    rhub::rhub_check(platforms = c("linux", "macos"))
    cat("<U+2705> Platform checks submitted to R-hub\n\n")
  },
  error = function(e) {
    cat("<U+26A0><U+FE0F>  R-hub check failed:", conditionMessage(e), "\n\n")
  }
)

# Step 5: Summary
cat("<U+2550><U+2550><U+2550><U+2550><U+2550><U+2550><U+2550><U+2550><U+2550><U+2550><U+2550><U+2550><U+2550><U+2550><U+2550><U+2550><U+2550><U+2550><U+2550><U+2550><U+2550><U+2550><U+2550><U+2550><U+2550><U+2550><U+2550><U+2550><U+2550><U+2550><U+2550><U+2550><U+2550><U+2550><U+2550><U+2550><U+2550><U+2550><U+2550><U+2550><U+2550><U+2550><U+2550><U+2550><U+2550><U+2550><U+2550><U+2550><U+2550><U+2550><U+2550><U+2550><U+2550><U+2550><U+2550><U+2550><U+2550><U+2550><U+2550><U+2550><U+2550><U+2550><U+2550>\n")
cat("  Check Summary\n")
cat("<U+2550><U+2550><U+2550><U+2550><U+2550><U+2550><U+2550><U+2550><U+2550><U+2550><U+2550><U+2550><U+2550><U+2550><U+2550><U+2550><U+2550><U+2550><U+2550><U+2550><U+2550><U+2550><U+2550><U+2550><U+2550><U+2550><U+2550><U+2550><U+2550><U+2550><U+2550><U+2550><U+2550><U+2550><U+2550><U+2550><U+2550><U+2550><U+2550><U+2550><U+2550><U+2550><U+2550><U+2550><U+2550><U+2550><U+2550><U+2550><U+2550><U+2550><U+2550><U+2550><U+2550><U+2550><U+2550><U+2550><U+2550><U+2550><U+2550><U+2550><U+2550><U+2550><U+2550>\n\n")

if (length(check_results$errors) > 0) {
  cat("<U+274C> ERRORS found:", length(check_results$errors), "\n")
  print(check_results$errors)
}

if (length(check_results$warnings) > 0) {
  cat("<U+26A0><U+FE0F>  WARNINGS found:", length(check_results$warnings), "\n")
  print(check_results$warnings)
}

if (length(check_results$notes) > 0) {
  cat("<U+0001F4DD> NOTES found:", length(check_results$notes), "\n")
  print(check_results$notes)
}

if (length(check_results$errors) == 0 && length(check_results$warnings) == 0) {
  cat("\n<U+2705> Package passed all checks!\n\n")
  cat("Next steps:\n")
  cat("1. Review R-hub results (check your email)\n")
  cat("2. Update cran-comments.md with check results\n")
  cat("3. Run scripts/submit-cran.R to submit to CRAN\n\n")
} else {
  cat("\n<U+274C> Please fix errors and warnings before submitting to CRAN\n\n")
}
