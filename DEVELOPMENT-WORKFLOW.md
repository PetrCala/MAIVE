# Development Workflow Guide

This guide explains the complete development and release workflow for
the MAIVE package, including when to use Make commands vs. direct script
calls.

## Quick Reference

### Use Make For (Automated Tasks)

``` bash
make test              # Run tests
make check             # Run R CMD check
make document          # Update documentation
make version-patch     # Auto-bump version
make release-prep      # Full release preparation
```

### Run Scripts Directly For (Interactive Tasks)

``` bash
Rscript scripts/update-version.R    # Interactive version selection
Rscript scripts/submit-cran.R       # Interactive CRAN submission
Rscript scripts/check-cran.R        # Interactive check process
Rscript scripts/build-docs.R        # Interactive doc build
```

## Why This Distinction?

**Make** is designed for automation and non-interactive workflows. It:

- Chains commands together efficiently
- Works great in CI/CD pipelines
- Can’t properly handle interactive prompts (stdin/stdout issues)

**Direct R scripts** are better for interactive workflows because they:

- Properly handle user input via
  [`readline()`](https://rdrr.io/r/base/readline.html)
- Provide guided, step-by-step processes
- Give immediate feedback and allow course correction

## Complete Development Workflows

### Daily Development

``` bash
# 1. Make changes to R code
vim R/maivefunction.r

# 2. Update documentation
make document

# 3. Run tests
make test

# 4. Quick check
make quick-check

# 5. Commit when passing
git commit -am "Add feature X"
```

### Documentation Updates

``` bash
# Edit documentation
vim R/maivefunction.r  # Edit roxygen comments

# Update everything
make update-docs

# Or build interactively with preview
Rscript scripts/build-docs.R
```

### Bug Fix Release (Patch)

``` bash
# 1. Fix the bug
vim R/maivefunction.r

# 2. Update version automatically
make version-patch     # 0.0.4 -> 0.0.5

# 3. Update NEWS.md
vim NEWS.md
# Add: # MAIVE 0.0.5
#      * Fixed bug in X

# 4. Commit
git add .
git commit -m "Fix bug in X, bump to 0.0.5"
git tag v0.0.5

# 5. Run checks
make release-prep

# 6. Submit to CRAN
Rscript scripts/submit-cran.R
```

### Feature Release (Minor)

``` bash
# 1. Develop feature
vim R/new-feature.r

# 2. Interactive version update (for NEWS.md prompt)
Rscript scripts/update-version.R
# Choose option 2 (minor)
# Enter changes interactively

# Or quick automated bump
make version-minor     # 0.0.4 -> 0.1.0

# 3. Full preparation
make release-prep

# 4. Interactive submission
Rscript scripts/submit-cran.R
```

### Major Release

``` bash
# 1. Ensure breaking changes are documented
vim NEWS.md

# 2. Update version
make version-major     # 0.0.4 -> 1.0.0

# Or use interactive
Rscript scripts/update-version.R

# 3. Comprehensive testing
make release-prep

# 4. Submit
Rscript scripts/submit-cran.R
```

## Version Management

### Automated (Via Make)

Best for quick, non-interactive bumps:

``` bash
# Current: 0.0.4

make version-patch    # -> 0.0.5 (bug fixes)
make version-minor    # -> 0.1.0 (new features)
make version-major    # -> 1.0.0 (breaking changes)
```

These commands:

- ✅ Update DESCRIPTION automatically
- ✅ Print clear next steps
- ✅ Fast and scriptable
- ❌ Don’t prompt for NEWS.md
- ❌ Don’t provide interactive guidance

### Interactive (Direct Script)

Best for guided, thoughtful releases:

``` bash
Rscript scripts/update-version.R
```

This script:

- ✅ Shows current version
- ✅ Offers clear choices
- ✅ Prompts for NEWS.md updates
- ✅ Provides step-by-step guidance
- ✅ Handles custom versions
- ❌ Slightly slower
- ❌ Not suitable for CI/CD

**Recommendation**: Use interactive for important releases, automated
for quick fixes.

## CRAN Submission Workflow

### Pre-Submission Checklist

``` bash
# 1. Ensure version is updated
make check-version    # Shows current version

# 2. Run comprehensive checks
make release-prep     # This runs:
                      # - clean
                      # - document
                      # - test
                      # - cran-check

# 3. Review output
# All checks should pass with 0 errors, 0 warnings, 0 notes
```

### Submission

**Always use the interactive script**:

``` bash
Rscript scripts/submit-cran.R
```

This walks you through:

1.  Pre-submission checklist
2.  Windows builder checks
3.  Actual CRAN submission
4.  Post-submission instructions

**Do NOT automate CRAN submission** - it requires human review and email
confirmation.

## Testing Strategies

### Quick Iteration

``` bash
make quick-check      # Fast check (skip vignettes)
```

Use during active development for fast feedback.

### Standard Check

``` bash
make check            # Full R CMD check
```

Use before commits to ensure nothing is broken.

### CRAN-Ready Check

``` bash
make cran-check       # Comprehensive check
# Or interactive:
Rscript scripts/check-cran.R
```

Use before CRAN submission. The interactive version provides more
detailed feedback.

### Full Release Check

``` bash
make release-prep     # Everything
```

Use before creating releases.

## Documentation Workflow

### Quick Update

``` bash
make document         # Update roxygen docs only
```

### Full Update

``` bash
make update-docs      # Update docs + rebuild site
```

### Interactive Build

``` bash
Rscript scripts/build-docs.R
```

This offers to preview the site in your browser.

## Git Workflow

### Feature Branch

``` bash
# Create branch
git checkout -b feature/new-analysis

# Develop
vim R/new-feature.r
make document test

# Check before merge
make check

# Merge
git checkout main
git merge feature/new-analysis
```

### Release Branch

``` bash
# Create release branch
git checkout -b release/v0.1.0

# Prepare release
make version-minor
vim NEWS.md
make release-prep

# Merge and tag
git checkout main
git merge release/v0.1.0
git tag v0.1.0
git push --tags
```

## CI/CD Integration

The Makefile commands work perfectly in CI/CD:

### GitHub Actions Example

``` yaml
- name: Check package
  run: make check

- name: Build documentation
  run: make site
```

### Local Pre-Commit Hook

``` bash
#!/bin/bash
# .git/hooks/pre-commit
make quick-check || exit 1
```

## Troubleshooting

### “Interactive prompt doesn’t work”

**Problem**: Running `make update-version` doesn’t show prompts.

**Solution**: Use direct script call instead:

``` bash
Rscript scripts/update-version.R
```

### “Make command hangs”

**Problem**: Script is waiting for input but Make doesn’t show it.

**Solution**: Interactive scripts should always be called directly, not
through Make.

### “Need automation for CI/CD”

**Problem**: Can’t use interactive scripts in automated pipelines.

**Solution**: Use Make commands for automation:

``` bash
make version-patch    # Automated version bump
make release-prep     # Automated checks
```

## Best Practices Summary

### ✅ DO

- Use Make for automated, repeatable tasks
- Use direct scripts for interactive workflows
- Run `make release-prep` before every release
- Call `Rscript scripts/submit-cran.R` for submissions
- Keep version numbers semantic (X.Y.Z)
- Update NEWS.md with every version bump
- Tag releases in git

### ❌ DON’T

- Don’t call interactive scripts through Make
- Don’t automate CRAN submission without review
- Don’t skip `make release-prep`
- Don’t forget to update NEWS.md
- Don’t submit to CRAN without running checks
- Don’t use emojis or Unicode in output (for portability)

## Command Reference

### Most Common Commands

``` bash
# Daily development
make test
make check
make document

# Version management
make check-version
make version-patch
Rscript scripts/update-version.R    # Interactive

# Release preparation
make release-prep

# CRAN submission
Rscript scripts/submit-cran.R       # Interactive

# Documentation
make site
make preview-site

# Cleanup
make clean
```

### Full Command List

Run `make help` to see all available commands.

## Getting Help

- **Makefile Help**: `make help`
- **Makefile Documentation**: `.github/MAKEFILE-USAGE.md`
- **CRAN Submission**: `.github/CRAN-SUBMISSION.md`
- **Package Issues**: GitHub Issues

------------------------------------------------------------------------

*This workflow guide is maintained as part of the MAIVE package
repository. Updates and improvements are welcome.*
