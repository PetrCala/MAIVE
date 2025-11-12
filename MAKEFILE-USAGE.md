# Makefile Usage Guide

This document describes how to use the Makefile for efficient MAIVE
package development.

## Quick Start

Simply run `make` or `make help` to see all available commands:

``` bash
make help
```

## Common Workflows

### Daily Development

``` bash
# After modifying R code
make document test    # Update docs and run tests

# Before committing
make check           # Run R CMD check
```

### Documentation Updates

``` bash
# Update roxygen2 docs
make document

# Build pkgdown site
make site

# Preview site in browser
make preview-site

# Update everything
make update-docs
```

### Testing

``` bash
# Run all tests
make test

# Quick check (faster, skips vignettes)
make quick-check

# Full CRAN check
make cran-check

# Coverage report
make coverage
```

### CRAN Submission

``` bash
# Full pre-release preparation
make release-prep

# Check current version
make check-version

# Interactive submission
make submit-cran
```

### Code Quality

``` bash
# Check code style
make lint

# Auto-format code
make style

# Fix style and update docs
make fix-style
```

### Installation

``` bash
# Install dependencies
make install-deps

# Install package locally
make install
```

### Cleanup

``` bash
# Remove built files
make clean

# Deep clean (including docs/)
make clean-all
```

## Command Reference

### Building & Installation

| Command             | Description                               |
|---------------------|-------------------------------------------|
| `make install`      | Install package locally with dependencies |
| `make install-deps` | Install package dependencies only         |
| `make build`        | Build package tarball (.tar.gz)           |

### Checking & Testing

| Command            | Description                                       |
|--------------------|---------------------------------------------------|
| `make check`       | Run standard R CMD check                          |
| `make test`        | Run test suite with testthat                      |
| `make cran-check`  | Run comprehensive CRAN checks (via helper script) |
| `make quick-check` | Fast check (skip vignettes and examples)          |
| `make coverage`    | Generate and view test coverage report            |

### Documentation

| Command             | Description                                   |
|---------------------|-----------------------------------------------|
| `make document`     | Generate roxygen2 documentation               |
| `make vignettes`    | Build vignettes                               |
| `make site`         | Build pkgdown website                         |
| `make preview-site` | Build and preview pkgdown site                |
| `make update-docs`  | Update all documentation (roxygen2 + pkgdown) |

### CRAN Submission

| Command              | Description                                        |
|----------------------|----------------------------------------------------|
| `make submit-cran`   | Interactive CRAN submission process                |
| `make check-version` | Display current package version                    |
| `make release-prep`  | Full release preparation (clean, doc, test, check) |

### Code Quality

| Command          | Description                          |
|------------------|--------------------------------------|
| `make lint`      | Check code style with lintr          |
| `make style`     | Auto-format code with styler         |
| `make fix-style` | Auto-format and update documentation |

### Cleanup

| Command          | Description                               |
|------------------|-------------------------------------------|
| `make clean`     | Remove built tarballs and check artifacts |
| `make clean-all` | Deep clean including docs/ directory      |

## Integration with Development Workflow

### Example: Feature Development

``` bash
# 1. Start fresh
make clean
make install-deps

# 2. Develop feature
# ... edit R files ...

# 3. Update docs and test
make document test

# 4. Check everything works
make check

# 5. Commit when passing
git add .
git commit -m "Add new feature"
```

### Example: Release Process

``` bash
# 1. Update version number
# Edit DESCRIPTION and NEWS.md

# 2. Full preparation
make release-prep

# 3. Review checks
# All tests should pass

# 4. Submit to CRAN
make submit-cran

# 5. After acceptance, tag release
git tag v0.0.5
git push --tags
```

### Example: Documentation Work

``` bash
# 1. Edit roxygen comments or vignettes
# ... edit files ...

# 2. Rebuild everything
make update-docs

# 3. Preview changes
make preview-site

# 4. When satisfied, commit
git add .
git commit -m "Update documentation"
```

## Makefile Customization

The Makefile is located at the project root and can be customized for
your specific needs. Common customizations:

### Add Custom Targets

``` make
# Add to Makefile
my-custom-task:
 @echo "Running my custom task..."
 @Rscript -e "my_function()"
```

### Chain Commands

``` make
# Create workflows by chaining existing targets
my-workflow: document test check
 @echo "Workflow complete!"
```

## Tips & Tricks

### 1. Tab Completion

Enable tab completion for make targets:

``` bash
# Add to ~/.bashrc or ~/.zshrc
complete -W "$(make -qp | awk -F':' '/^[a-zA-Z0-9][^$#\/\t=]*:([^=]|$)/ {split($1,A,/ /);for(i in A)print A[i]}' | sort -u)" make
```

### 2. Parallel Execution

Some targets can run in parallel:

``` bash
make -j4 document test  # Run 4 jobs in parallel
```

### 3. Verbose Output

See full R output:

``` bash
make check VERBOSE=1
```

### 4. Dry Run

See what would be executed without running:

``` bash
make -n check
```

## Troubleshooting

### “No rule to make target”

- Ensure you’re in the package root directory
- Check that Makefile exists and is properly formatted
- Make sure you’re using tab characters (not spaces) for indentation

### “Command not found”

- Ensure R is in your PATH: `which R`
- Install required R packages: `make install-deps`

### Permission Denied

Make sure Makefile is readable:

``` bash
chmod 644 Makefile
```

## IDE Integration

### RStudio

Add keyboard shortcuts for common make commands:

1.  Tools → Modify Keyboard Shortcuts
2.  Add shortcuts for “Run Make” commands

### VS Code

Add tasks to `.vscode/tasks.json`:

``` json
{
  "version": "2.0.0",
  "tasks": [
    {
      "label": "R: Check Package",
      "type": "shell",
      "command": "make check",
      "group": "build"
    }
  ]
}
```

### Vim/Neovim

Add key mappings to `.vimrc`:

``` vim
nnoremap <leader>mc :!make check<CR>
nnoremap <leader>mt :!make test<CR>
nnoremap <leader>md :!make document<CR>
```

## Benefits of Using Make

1.  **Consistency**: Same commands work across all environments
2.  **Documentation**: Self-documenting workflow
3.  **Efficiency**: Common tasks reduced to simple commands
4.  **Automation**: Easy to chain commands together
5.  **Team collaboration**: Everyone uses the same workflow

## Additional Resources

- [GNU Make Manual](https://www.gnu.org/software/make/manual/)
- [R Packages Book](https://r-pkgs.org/)
- [devtools Documentation](https://devtools.r-lib.org/)

------------------------------------------------------------------------

*This Makefile is maintained as part of the MAIVE package repository.*
