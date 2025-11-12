#!/usr/bin/env Rscript

# CRAN Submission Script
# Interactive script to guide through CRAN submission

cat("═══════════════════════════════════════════════════════════════\n")
cat("  MAIVE Package - CRAN Submission\n")
cat("═══════════════════════════════════════════════════════════════\n\n")

# Check if required packages are installed
required_pkgs <- c("devtools", "usethis")
missing_pkgs <- required_pkgs[!sapply(required_pkgs, requireNamespace, quietly = TRUE)]

if (length(missing_pkgs) > 0) {
  cat("❌ Missing required packages:", paste(missing_pkgs, collapse = ", "), "\n")
  cat("Installing missing packages...\n\n")
  install.packages(missing_pkgs)
}

# Pre-submission checklist
cat("📋 Pre-submission Checklist\n")
cat("───────────────────────────────────────────────────────────────\n\n")

checklist <- c(
  "Updated NEWS.md with version changes",
  "Updated DESCRIPTION version number",
  "Ran scripts/check-cran.R successfully",
  "All GitHub Actions checks passing",
  "Reviewed and updated cran-comments.md",
  "Ready to monitor email for CRAN correspondence"
)

for (item in checklist) {
  response <- readline(sprintf("✓ %s? (y/n): ", item))
  if (tolower(substr(response, 1, 1)) != "y") {
    cat("\n❌ Please complete checklist item before proceeding:\n")
    cat("  ", item, "\n\n")
    quit(status = 1)
  }
}

cat("\n✅ All checklist items confirmed\n\n")

# Final confirmation
cat("═══════════════════════════════════════════════════════════════\n")
cat("  READY TO SUBMIT\n")
cat("═══════════════════════════════════════════════════════════════\n\n")

response <- readline("Type 'SUBMIT' to proceed with CRAN submission: ")

if (toupper(response) != "SUBMIT") {
  cat("\n❌ Submission cancelled\n\n")
  quit(status = 1)
}

cat("\n🚀 Submitting to CRAN...\n\n")

# Check on Windows one more time (optional)
cat("Performing final Windows check via winbuilder...\n")
tryCatch({
  devtools::check_win_devel()
  devtools::check_win_release()
  cat("✅ Windows check submitted (check email for results)\n\n")
}, error = function(e) {
  cat("⚠️  Windows check failed:", conditionMessage(e), "\n")
  cat("Continue anyway? (y/n): ")
  if (tolower(substr(readline(), 1, 1)) != "y") {
    quit(status = 1)
  }
})

# Submit to CRAN
cat("\n📤 Submitting package to CRAN...\n")
tryCatch({
  devtools::submit_cran()
  
  cat("\n═══════════════════════════════════════════════════════════════\n")
  cat("  ✅ SUBMISSION SUCCESSFUL\n")
  cat("═══════════════════════════════════════════════════════════════\n\n")
  cat("Important next steps:\n\n")
  cat("1. Check your email for CRAN confirmation request\n")
  cat("2. Click the confirmation link in the email\n")
  cat("3. Monitor email for CRAN reviewer feedback\n")
  cat("4. Respond to any CRAN feedback within 2 weeks\n\n")
  cat("📧 The package maintainer will receive all CRAN correspondence\n")
  cat("   at the email specified in DESCRIPTION\n\n")
  
}, error = function(e) {
  cat("\n❌ Submission failed:", conditionMessage(e), "\n\n")
  quit(status = 1)
})

