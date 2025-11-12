#!/usr/bin/env Rscript

# Build Package Documentation
# Generates roxygen documentation and builds pkgdown site

cat("===============================================================\n")
cat("  MAIVE Package - Documentation Builder\n")
cat("===============================================================\n\n")

# Check if required packages are installed
required_pkgs <- c("devtools", "pkgdown")
missing_pkgs <- required_pkgs[!sapply(required_pkgs, requireNamespace, quietly = TRUE)]

if (length(missing_pkgs) > 0) {
  cat("[!] Missing required packages:", paste(missing_pkgs, collapse = ", "), "\n")
  cat("Installing missing packages...\n\n")
  install.packages(missing_pkgs)
}

# Step 1: Update roxygen documentation
cat("[*] Step 1/3: Generating roxygen documentation...\n")
devtools::document()
cat("[OK] Roxygen documentation updated\n\n")

# Step 2: Build pkgdown site
cat("[*] Step 2/3: Building pkgdown website...\n")
pkgdown::build_site()
cat("[OK] Pkgdown site built in docs/\n\n")

# Step 3: Preview site (optional)
cat("===============================================================\n")
cat("  Documentation Build Complete\n")
cat("===============================================================\n\n")

response <- readline("Preview site in browser? (y/n): ")
if (tolower(substr(response, 1, 1)) == "y") {
  cat("\n[*] Opening preview...\n")
  pkgdown::preview_site()
} else {
  cat("\nTo preview later, run: pkgdown::preview_site()\n")
  cat("Or open: docs/index.html\n\n")
}
