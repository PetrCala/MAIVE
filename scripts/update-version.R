#!/usr/bin/env Rscript

# Version Update Helper
# Utility to bump version number and update NEWS.md

cat("===============================================================\n")
cat("  MAIVE Package - Version Updater\n")
cat("===============================================================\n\n")

# Read current DESCRIPTION
desc_path <- "DESCRIPTION"
if (!file.exists(desc_path)) {
  cat("[ERROR] DESCRIPTION file not found. Are you in the package root?\n")
  quit(status = 1)
}

desc_lines <- readLines(desc_path)
version_line <- grep("^Version:", desc_lines, value = TRUE)
current_version <- trimws(sub("^Version:\\s*", "", version_line))

cat("Current version:", current_version, "\n\n")

# Parse version
version_parts <- as.integer(strsplit(current_version, "\\.")[[1]])
if (length(version_parts) < 3) {
  version_parts <- c(version_parts, rep(0, 3 - length(version_parts)))
}

# Version bump options
cat("Version bump options:\n")
cat("1. Patch (", paste(c(version_parts[1:2], version_parts[3] + 1), collapse = "."), ")\n", sep = "")
cat("2. Minor (", paste(c(version_parts[1], version_parts[2] + 1, 0), collapse = "."), ")\n", sep = "")
cat("3. Major (", paste(c(version_parts[1] + 1, 0, 0), collapse = "."), ")\n", sep = "")
cat("4. Custom\n")
cat("5. Cancel\n\n")

choice <- readline("Select version bump (1-5): ")

new_version <- switch(choice,
  "1" = paste(c(version_parts[1:2], version_parts[3] + 1), collapse = "."),
  "2" = paste(c(version_parts[1], version_parts[2] + 1, 0), collapse = "."),
  "3" = paste(c(version_parts[1] + 1, 0, 0), collapse = "."),
  "4" = {
    custom <- readline("Enter new version (e.g., 1.0.0): ")
    custom
  },
  {
    cat("[!] Cancelled\n")
    quit(status = 0)
  }
)

cat("\n[*] Updating version from", current_version, "to", new_version, "\n\n")

# Update DESCRIPTION
desc_lines <- sub(
  paste0("^Version:\\s*", current_version),
  paste0("Version: ", new_version),
  desc_lines
)
writeLines(desc_lines, desc_path)
cat("[OK] Updated DESCRIPTION\n")

# Update NEWS.md
news_path <- "NEWS.md"
if (file.exists(news_path)) {
  cat("\n[*] Update NEWS.md\n")
  cat("Enter changes for this version (empty line to finish):\n")

  changes <- character()
  repeat {
    line <- readline()
    if (line == "") break
    changes <- c(changes, paste0("* ", line))
  }

  if (length(changes) > 0) {
    news_content <- readLines(news_path)
    new_entry <- c(
      paste0("# MAIVE ", new_version),
      "",
      changes,
      "",
      news_content
    )
    writeLines(new_entry, news_path)
    cat("[OK] Updated NEWS.md\n")
  }
}

# Update cran-comments.md
cran_comments_path <- "cran-comments.md"
if (file.exists(cran_comments_path)) {
  cat("\n[*] Remember to update cran-comments.md before submission\n")
}

cat("\n===============================================================\n")
cat("  Version Update Complete\n")
cat("===============================================================\n\n")
cat("Next steps:\n")
cat("1. Review changes in DESCRIPTION and NEWS.md\n")
cat("2. Commit version bump: git commit -am 'Bump version to", new_version, "'\n")
cat("3. Tag release: git tag v", new_version, "\n")
cat("4. Run checks: Rscript scripts/check-cran.R\n\n")
