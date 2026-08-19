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
    "0 errors | 0 warnings | 0 notes"
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

cran_mirror_url <- function() {
  fallback <- "https://cloud.r-project.org"
  repos <- getOption("repos")

  if (is.null(repos) || !"CRAN" %in% names(repos)) {
    return(fallback)
  }

  mirror <- repos[["CRAN"]]

  # CI points repos at an RSPM snapshot, which lags CRAN. Always ask CRAN
  # itself what is published, otherwise the comparison can be stale.
  if (is.na(mirror) || mirror == "@CRAN@" || grepl("packagemanager", mirror, fixed = TRUE)) {
    return(fallback)
  }

  return(mirror)
}

#' Look up the version of a package currently published on CRAN.
#' Returns NA_character_ when the package is genuinely not on CRAN yet, and
#' NULL when the lookup itself failed (offline runner, mirror hiccup). The two
#' cases warrant different wording, so they are reported separately.
cran_published_version <- function(package = "MAIVE") {
  tryCatch(
    {
      available <- available.packages(repos = cran_mirror_url())
      if (package %in% rownames(available)) {
        available[package, "Version"]
      } else {
        NA_character_
      }
    },
    error = function(e) NULL,
    warning = function(w) NULL
  )
}

write_submission_sentence <- function(new_version) {
  published <- cran_published_version()

  # Lookup failed. Claiming either "initial" or "update" could be wrong, so
  # state only what is certain.
  if (is.null(published)) {
    return(sprintf("This is a submission of MAIVE v%s to CRAN.", new_version))
  }

  if (is.na(published)) {
    return(sprintf("This is the initial submission of MAIVE v%s to CRAN.", new_version))
  }

  return(sprintf(
    "This is an update of MAIVE from v%s (the version currently on CRAN) to v%s.",
    published, new_version
  ))
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
    write_submission_sentence(new_version),
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
