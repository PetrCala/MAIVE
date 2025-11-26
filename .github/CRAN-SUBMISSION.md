# CRAN Submission Guide

## Quick Reference

**Release to CRAN in one command:**

```bash
# Ensure working directory is clean, then:
make version-patch   # Bug fixes (0.0.X)
make version-minor   # New features (0.X.0)  
make version-major   # Breaking changes (X.0.0)
```

This automatically: bumps version → commits → creates tag → pushes → triggers CRAN submission workflow.

---

This guide provides comprehensive instructions for submitting and maintaining this package on CRAN. It is intended for package maintainers and contains both initial submission and update procedures.

## Table of Contents

- [Quick Reference](#quick-reference)
- [Prerequisites](#prerequisites)
- [Pre-Submission Checklist](#pre-submission-checklist)
- [Submission Methods](#submission-methods)
- [After Submission](#after-submission)
- [Responding to CRAN Feedback](#responding-to-cran-feedback)
- [Updating Your Package on CRAN](#updating-your-package-on-cran)
- [Helper Scripts](#helper-scripts)
- [GitHub Actions Workflows](#github-actions-workflows)
- [Troubleshooting](#troubleshooting)
- [Resources](#resources)

## Prerequisites

Before attempting CRAN submission, ensure you have:

- R and RStudio installed and up to date
- Required packages: `devtools`, `usethis`, `rcmdcheck`, `rhub`
- Package passes `R CMD check` with 0 errors, 0 warnings, 0 notes
- All tests passing
- Documentation complete and up to date
- GitHub repository access with Actions enabled

## Pre-Submission Checklist

Before each CRAN submission (initial or update), verify:

### Code Quality

- [ ] `R CMD check --as-cran` passes with 0 errors, 0 warnings, 0 notes
- [ ] All tests pass: `devtools::test()`
- [ ] Package builds successfully: `devtools::build()`
- [ ] No non-ASCII characters unless properly declared
- [ ] All examples run successfully (or are marked with `\dontrun{}`)

### Documentation

- [ ] All exported functions have complete documentation
- [ ] `DESCRIPTION` file is accurate and properly formatted
- [ ] `NEWS.md` is updated with version changes
- [ ] `cran-comments.md` is current with check results
- [ ] README is up to date
- [ ] Vignettes build successfully

### Version Management

- [ ] Version number follows semantic versioning (X.Y.Z)
- [ ] Version number is incremented appropriately:
  - Patch (0.0.X): Bug fixes only
  - Minor (0.X.0): New features, backward compatible
  - Major (X.0.0): Breaking changes
- [ ] Version in `DESCRIPTION` matches `NEWS.md` entry

### Legal and Licensing

- [ ] LICENSE file is present and properly formatted
- [ ] All authors and contributors are credited
- [ ] Copyright holders are correctly listed

### GitHub

- [ ] All GitHub Actions checks pass (see badges in README)
- [ ] Latest changes are pushed to GitHub
- [ ] Version is tagged in git (optional but recommended)

## Submission Methods

### Method 1: Makefile (Recommended)

The simplest way to release. Requires a clean working directory.

```bash
# 1. Ensure all changes are committed
git status  # Should show "nothing to commit"

# 2. Run the appropriate version bump
make version-patch   # 0.1.4 -> 0.1.5 (bug fixes)
make version-minor   # 0.1.4 -> 0.2.0 (new features)
make version-major   # 0.1.4 -> 1.0.0 (breaking changes)
```

This single command:

1. Validates clean working directory
2. Bumps version in `DESCRIPTION`
3. Commits with message `chore: bump version to X.Y.Z`
4. Creates git tag `vX.Y.Z`
5. Pushes commit and tag to GitHub
6. Triggers the CRAN submission workflow

Monitor progress at: <https://github.com/meta-analysis-es/maive/actions>

### Method 2: Manual Workflow Trigger

For running checks without releasing:

1. Go to **Actions** → **"Submit to CRAN"**
2. Click **"Run workflow"**
3. Type `CONFIRM` and optionally check "Skip CRAN submission"
4. Review results in workflow artifacts

### Method 3: Local Submission

For complete manual control:

```bash
# Run checks
make cran-check

# Submit manually
Rscript -e 'devtools::submit_cran()'
```

## After Submission

### Timeline and Process

#### 1. Confirmation Email (within minutes)

- **Action Required**: CRAN sends a confirmation link
- **Critical**: You MUST click the link within 2 hours
- **Important**: If not confirmed, submission is automatically cancelled

#### 2. Automated Checks (within hours to 1 day)

- CRAN runs automated checks across multiple platforms
- Results are emailed to the maintainer
- Common platforms: Windows, macOS, Linux with multiple R versions
- All automated checks must pass before human review

#### 3. Human Review (1-2 weeks typical)

- A CRAN team member manually reviews the package
- They may request changes or clarifications
- **Response time**: You have 2 weeks to respond
- **Important**: Late responses may result in rejection

#### 4. Publication (if approved)

- Package appears on CRAN
- Available via `install.packages("PACKAGE_NAME")`
- Updates to CRAN mirror sites may take 24-48 hours

### Monitoring

- Check the email address listed in `DESCRIPTION` regularly
- CRAN correspondence is time-sensitive
- Keep records of all CRAN communications

## Responding to CRAN Feedback

### General Principles

1. **Be Prompt**: Respond within 1 week if possible, 2 weeks maximum
2. **Be Polite**: CRAN reviewers are volunteers
3. **Be Thorough**: Address every point raised
4. **Be Clear**: Explain what you changed and why

### Common First-Time Issues

CRAN reviewers frequently request changes for:

#### Description Field

- Must be in title case
- No package name repetition
- Must describe what the package does, not just repeat the title
- Should be a paragraph, not bullet points
- References should be in the form: Author (Year) <DOI or URL>

#### Examples

- Must not write to the user's home directory
- Should not require internet connection (or use `\donttest{}`)
- Must run in < 5 seconds (or use `\donttest{}`)
- Should demonstrate main functionality

#### Documentation

- All exported functions must have `\value` sections
- References must be complete and correctly formatted
- Links must be working

#### License

- Must be a standard CRAN license or have LICENSE file
- Copyright holders must be clearly stated

#### Technical

- No calls to `library()` or `require()` in package code
- Use `Imports` in DESCRIPTION and `::` notation instead
- No modifications to user's options or par() without restoration

### Resubmission Process

1. Make all requested changes
2. Update `cran-comments.md` with:
   - Summary of changes made
   - Responses to each point raised
   - Any explanations needed
3. Update version number (typically increment patch version)
4. Update `NEWS.md` with changes
5. Run full check suite again
6. Resubmit using same method as initial submission

## Updating Your Package on CRAN

### When to Update

- **Bug fixes**: As soon as critical bugs are identified
- **New features**: When substantial improvements are ready
- **CRAN requests**: Immediately when CRAN requests updates (e.g., for policy changes)
- **Dependency changes**: When dependencies are updated or deprecated

### Frequency

- Avoid too frequent updates (give users time to adapt)
- Minimum recommended interval: 1-2 months (except critical bugs)
- Maximum recommended interval: 1 year (show active maintenance)

### Update Workflow

#### 1. Version Bump

```r
source("scripts/update-version.R")
# Follow prompts to select version increment type
```

#### 2. Document Changes

Update `NEWS.md` with:

- Version number and date
- All user-facing changes
- Bug fixes
- New features
- Deprecated functions
- Breaking changes (if any)

#### 3. Update Documentation

```r
# Update roxygen documentation
devtools::document()

# Rebuild pkgdown site
source("scripts/build-docs.R")
```

#### 4. Run Checks

```r
source("scripts/check-cran.R")
```

#### 5. Commit and Tag

```bash
git add .
git commit -m "Release vX.Y.Z"
git tag vX.Y.Z
git push origin main --tags
```

#### 6. Submit Update

Follow the same submission process as initial submission.

#### 7. Update Documentation After Acceptance

Once published on CRAN:

```r
# Update README badges if needed
# Update website
pkgdown::build_site()
```

## Helper Scripts

The package includes several helper scripts in the `scripts/` directory:

### check-cran.R

Comprehensive CRAN readiness checker.

**What it does:**

- Updates roxygen documentation
- Runs `R CMD check --as-cran`
- Submits to R-hub for multi-platform checks
- Summarizes results

**Usage:**

```r
source("scripts/check-cran.R")
```

**When to use:**

- Before every CRAN submission
- After making significant changes
- When troubleshooting check failures

### submit-cran.R

Interactive CRAN submission wizard.

**What it does:**

- Walks through pre-submission checklist
- Runs final Windows builder checks
- Submits to CRAN
- Provides post-submission instructions

**Usage:**

```r
source("scripts/submit-cran.R")
```

**When to use:**

- For final CRAN submission
- When you want guided submission process

### build-docs.R

Documentation builder and previewer.

**What it does:**

- Updates roxygen documentation
- Builds pkgdown website
- Optionally opens preview in browser

**Usage:**

```r
source("scripts/build-docs.R")
```

**When to use:**

- After changing documentation
- Before releasing new version
- When updating website

### update-version.R

Version management utility.

**What it does:**

- Interactive version bumping (patch/minor/major)
- Updates DESCRIPTION
- Updates NEWS.md template
- Provides git tagging instructions

**Usage:**

```r
source("scripts/update-version.R")
```

**When to use:**

- At the start of each release cycle
- When preparing for CRAN submission

## GitHub Actions Workflows

### R-CMD-check.yaml

**Purpose**: Continuous integration testing across platforms

**Triggers**:

- Every push to main
- Every pull request

**What it does**:

- Runs `R CMD check` on multiple platforms:
  - Windows (R-release)
  - macOS (R-release)
  - Linux (R-release, R-devel, R-oldrel)
- Uploads check results
- Updates status badge

**How to monitor**:

- Check README badge
- View Actions tab on GitHub
- Receive email notifications on failures

### pkgdown.yaml

**Purpose**: Automated documentation website

**Triggers**:

- Push to main branch
- Pull requests (for testing)
- Releases

**What it does**:

- Builds pkgdown website
- Deploys to GitHub Pages
- Updates documentation site

**Setup required**:

1. Enable GitHub Pages in repository settings
2. Set source to `gh-pages` branch
3. Website will be at: `https://USERNAME.github.io/REPO/`

### test-coverage.yaml

**Purpose**: Track test coverage

**Triggers**:

- Every push to main
- Every pull request

**What it does**:

- Runs test suite with coverage tracking
- Uploads results to Codecov (if configured)
- Updates coverage badge

**Optional setup**:

- Add `CODECOV_TOKEN` to GitHub secrets
- Badge will show in README

### submit-cran.yaml

**Purpose**: Pre-submission validation

**Triggers**:

- Manual (workflow_dispatch)
- Requires typing "CONFIRM"

**What it does**:

- Runs comprehensive CRAN checks
- Submits to R-hub
- Provides submission guidance
- Does NOT automatically submit to CRAN (manual step required)

**Safety features**:

- Requires explicit confirmation
- Multiple check layers
- Human review before final submission

## Troubleshooting

### Package Checks

#### "Package has NOTES"

**Issue**: `R CMD check` returns notes

**Solutions**:

- Some notes are acceptable (e.g., "New submission")
- Read each note carefully
- Common acceptable notes:
  - "New submission" (first submission)
  - "Possibly mis-spelled words" (if they're correct technical terms)
- Must address:
  - Unused dependencies
  - Large package size without justification
  - Unquoted URLs in DESCRIPTION

**Check**: Run `devtools::check()` to see specific notes

#### "Examples fail"

**Issue**: Examples in documentation don't run

**Solutions**:

- Wrap long-running examples in `\donttest{}`
- Wrap examples requiring user input in `\dontrun{}`
- Ensure all example data is available
- Check for missing library calls (use `::` notation instead)
- Test examples: `devtools::run_examples()`

#### "Tests fail in R CMD check but pass locally"

**Issue**: Tests work locally but fail during check

**Common causes and solutions**:

- Internet dependency: Mock external calls or skip when offline
- File writing: Use `tempdir()` instead of user directories
- Random numbers: Set seed for reproducibility
- Platform differences: Use `skip_on_cran()` for platform-specific tests
- Parallel processing: May cause timing issues, consider sequential for CRAN

**Check**:

```r
devtools::check(cran = TRUE)  # Mimics CRAN checks locally
```

### Platform-Specific Issues

#### "R-hub checks fail"

**Issue**: Package fails on R-hub but passes locally

**Solutions**:

- R-hub is stricter than local checks
- Common issues:
  - Missing system dependencies
  - Path separators (use `file.path()`)
  - Character encoding issues
  - Platform-specific function calls
- Check R-hub output carefully for specific errors
- Test on specific platform:

  ```r
  rhub::rhub_check(platform = "windows-x86_64-devel")
  ```

#### "Windows check fails"

**Issue**: Package fails on Windows but works on Unix

**Common issues**:

- Path separators: Use `file.path()` not paste with "/"
- Line endings: Git should handle automatically
- Case sensitivity: Windows is case-insensitive
- File locking: Windows locks files more aggressively

**Solution**:

```r
devtools::check_win_devel()  # Test on Windows
```

### Documentation Issues

#### "Rd files have issues"

**Issue**: Documentation formatting is incorrect

**Solutions**:

- Use roxygen2, don't edit .Rd files directly
- Check for unescaped special characters: `%`, `\`, `#`
- Ensure all cross-references exist
- Validate: `devtools::check_man()`

#### "Vignette fails to build"

**Issue**: Vignettes don't build during check

**Solutions**:

- Ensure all vignette dependencies in Suggests
- Use `eval=FALSE` for code that needs special setup
- Don't require internet connection
- Keep vignettes small and fast
- Test: `devtools::build_vignettes()`

### GitHub Actions Issues

#### "Workflow fails"

**Issue**: GitHub Actions workflow doesn't complete

**Common causes**:

- Network timeouts: Add retries or increase timeout
- Missing dependencies: Add to DESCRIPTION or workflow
- R version compatibility: Test against matrix of R versions
- Secrets missing: Check repository secrets settings

**Debug**:

- View workflow logs in Actions tab
- Check step-by-step output
- Reproduce locally if possible

#### "Badge shows 'failing'"

**Issue**: README badge shows red

**Solutions**:

- Click badge to see workflow run
- Check which platform failed
- Review error messages
- Fix issue and push again

## Resources

### Official CRAN Documentation

- **CRAN Repository Policy**: <https://cran.r-project.org/web/packages/policies.html>
  - Required reading before submission
  - Updated regularly, check for changes

- **Writing R Extensions**: <https://cran.r-project.org/doc/manuals/r-release/WRE.html>
  - Comprehensive guide to R package development
  - Technical details on package structure

### Books and Guides

- **R Packages** (Hadley Wickham & Jennifer Bryan): <https://r-pkgs.org/>
  - Modern R package development practices
  - Excellent for beginners and experts

- **rOpenSci Packaging Guide**: <https://devguide.ropensci.org/>
  - Best practices for R packages
  - Additional quality standards

### Tools

- **R-hub Builder**: <https://builder.r-hub.io/>
  - Test on multiple platforms before CRAN submission
  - Free service for R package developers

- **GitHub Actions for R**: <https://github.com/r-lib/actions>
  - Pre-built workflows for R packages
  - Examples and documentation

### Getting Help

#### For Package-Specific Issues

- **GitHub Issues**: Repository Issues tab
  - Bug reports
  - Feature requests
  - General questions

- **Maintainer Email**: Listed in DESCRIPTION file
  - Direct contact for specific concerns

#### For CRAN Submission Help

- **R-package-devel mailing list**: <https://stat.ethz.ch/mailman/listinfo/r-package-devel>
  - Community support for package development
  - Search archives before posting

- **CRAN Team**: <CRAN@R-project.org>
  - Only for submission-related questions
  - Response may take several days
  - Be respectful of volunteer time

#### Community Resources

- **Stack Overflow**: Tag questions with [r] and [cran]
- **RStudio Community**: <https://community.rstudio.com/>
- **R4DS Slack**: <https://www.rfordatasci.com/>

## Best Practices Summary

### General Principles

1. **Test Early and Often**: Don't wait until submission to run checks
2. **Version Control**: Use git tags for releases
3. **Documentation**: Keep all docs up to date
4. **Communication**: Be responsive to CRAN and users
5. **Quality**: Maintain high code and documentation standards

### Before Every Submission

1. Run full check suite
2. Update all documentation
3. Increment version appropriately
4. Update NEWS.md
5. Review cran-comments.md
6. Test on multiple platforms
7. Commit and tag

### During CRAN Review

1. Monitor email regularly
2. Respond promptly to requests
3. Be polite and professional
4. Document all changes made
5. Test thoroughly before resubmission

### After Acceptance

1. Announce release (if appropriate)
2. Update website
3. Monitor for bug reports
4. Plan next version
5. Maintain regular updates

---

## Final Notes

**Remember**: The CRAN team are volunteers who maintain one of the most important infrastructure pieces of the R ecosystem. They process thousands of packages and updates annually. Being patient, polite, and thorough in your submissions makes their job easier and increases the likelihood of smooth acceptance.

**Questions?** Refer to this guide, search documentation, and ask the community before contacting CRAN directly. Most questions have been answered before.

**Good luck with your CRAN submission!** 🚀

---

*This guide is maintained as part of the package repository. Updates and corrections are welcome via pull requests.*
