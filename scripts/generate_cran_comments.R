#!/usr/bin/env Rscript

# Generate cran-comments.md for CRAN submission
# Usage: Rscript generate_cran_comments.R --new-version "0.1.3" --check-status "success"

option_list <- list(
  optparse::make_option(c("--new-version"),
    type = "character", default = "Unknown",
    help = "New version tag [default = %default]"
  ),
  optparse::make_option(c("--manual-file"),
    type = "character", default = NULL,
    help = "Path to manual cran-comments.md notes [default = %default]"
  ),
  optparse::make_option(c("--check-status"),
    type = "character", default = "Unknown",
    help = "Status of R CMD check (success/failure) [default = %default]"
  )
)

opt_parser <- optparse::OptionParser(option_list = option_list)
opts <- optparse::parse_args(opt_parser)

write_test_environments <- function() {
  lines <- c(
    "## Test environments",
    "",
    "* GitHub Actions (ubuntu-latest): R-release, R-devel, R-oldrel-1",
    "* GitHub Actions (windows-latest): R-release",
    "* GitHub Actions (macos-latest): R-release",
    ""
  )

  return(lines)
}

write_cmd_check_results <- function(status) {
  status_line <- if (status == "success") {
    "0 errors <U+2714> | 0 warnings <U+2714> | 0 notes <U+2714>"
  } else {
    "Errors or warnings found in R CMD check. See logs for details."
  }

  lines <- c(
    "## R CMD check results",
    "",
    status_line,
    ""
  )

  return(lines)
}

write_downstream_dependencies <- function() {
  lines <- c(
    "## Downstream dependencies",
    "",
    "There are currently no downstream dependencies for this package.",
    ""
  )

  return(lines)
}

write_notes_to_cran_reviewers <- function(new_version, manual_file = NULL) {
  manual_notes <- character()

  if (!is.null(manual_file) && nzchar(manual_file) && file.exists(manual_file)) {
    manual_notes <- readLines(manual_file, warn = FALSE)
    manual_notes <- c(manual_notes, "")
  }

  lines <- c(
    "## Notes to CRAN reviewers",
    "",
    sprintf("This is the initial submission of MAIVE v%s to CRAN.", new_version),
    "",
    "The package implements instrumental variable approaches to limit bias caused",
    "by spurious precision in meta-analysis of observational research.",
    "",
    manual_notes
  )

  return(lines)
}

test_envs <- write_test_environments()
check_results <- write_cmd_check_results(opts$`check-status`)
downstream <- write_downstream_dependencies()
cran_notes <- write_notes_to_cran_reviewers(opts$`new-version`, opts$`manual-file`)

full_lines <- c(test_envs, check_results, downstream, cran_notes)

writeLines(full_lines, "cran-comments.md")

cli::cli_inform("cran-comments.md generated successfully at {.path {getwd()}}.")
