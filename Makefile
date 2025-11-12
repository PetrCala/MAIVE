# Makefile for MAIVE R Package Development
# Common commands for package development workflow

.PHONY: help install check test document build clean cran-check submit-cran \
        update-docs coverage install-deps vignettes site preview-site \
        lint style check-version

# Default target - show help
help:
	@echo "MAIVE Package Development Commands"
	@echo "==================================="
	@echo ""
	@echo "Building & Installation:"
	@echo "  make install        Install package locally"
	@echo "  make install-deps   Install package dependencies"
	@echo "  make build          Build package tarball"
	@echo ""
	@echo "Checking & Testing:"
	@echo "  make check          Run R CMD check"
	@echo "  make test           Run test suite"
	@echo "  make cran-check     Run comprehensive CRAN checks (uses helper script)"
	@echo "  make coverage       Generate test coverage report"
	@echo ""
	@echo "Documentation:"
	@echo "  make document       Generate documentation (roxygen2)"
	@echo "  make vignettes      Build vignettes"
	@echo "  make site           Build pkgdown site"
	@echo "  make preview-site   Preview pkgdown site in browser"
	@echo "  make update-docs    Update all documentation (document + site)"
	@echo ""
	@echo "CRAN Submission:"
	@echo "  make submit-cran    Interactive CRAN submission (uses helper script)"
	@echo "  make check-version  Check current version"
	@echo ""
	@echo "Code Quality:"
	@echo "  make lint           Check code style"
	@echo "  make style          Auto-format code with styler"
	@echo ""
	@echo "Cleanup:"
	@echo "  make clean          Remove built files"
	@echo "  make clean-all      Deep clean (including docs/)"

# Installation
install: document
	@echo "[*] Installing package..."
	@R CMD INSTALL --no-multiarch --with-keep.source .
	@echo "[OK] Package installed"

install-deps:
	@echo "[*] Installing dependencies..."
	@Rscript -e "if (!requireNamespace('remotes', quietly = TRUE)) install.packages('remotes'); remotes::install_deps(dependencies = TRUE)"
	@echo "[OK] Dependencies installed"

# Building
build: document
	@echo "[*] Building package tarball..."
	@R CMD build .
	@echo "[OK] Package built"

# Documentation
document:
	@echo "[*] Generating documentation..."
	@Rscript -e "devtools::document()"
	@echo "[OK] Documentation generated"

vignettes:
	@echo "[*] Building vignettes..."
	@Rscript -e "devtools::build_vignettes()"
	@echo "[OK] Vignettes built"

site:
	@echo "[*] Building pkgdown site..."
	@Rscript -e "pkgdown::build_site()"
	@echo "[OK] Site built in docs/"

preview-site: site
	@echo "[*] Opening site preview..."
	@Rscript -e "pkgdown::preview_site()"

update-docs: document site
	@echo "[OK] All documentation updated"

# Testing
test:
	@echo "[*] Running test suite..."
	@Rscript -e "devtools::test()"

check: document
	@echo "[*] Running R CMD check..."
	@Rscript -e "devtools::check()"

cran-check:
	@echo "[*] Running comprehensive CRAN checks..."
	@Rscript scripts/check-cran.R

coverage:
	@echo "[*] Generating coverage report..."
	@Rscript -e "covr::report()"

# CRAN Submission
submit-cran:
	@echo "[*] Starting CRAN submission process..."
	@Rscript scripts/submit-cran.R

check-version:
	@echo "[*] Current version:"
	@grep "^Version:" DESCRIPTION | sed 's/Version: //'

# Code Quality
lint:
	@echo "[*] Checking code style..."
	@Rscript -e "lintr::lint_package()"

style:
	@echo "[*] Auto-formatting code..."
	@Rscript -e "styler::style_pkg()"

# Cleanup
clean:
	@echo "[*] Cleaning built files..."
	@rm -f *.tar.gz
	@rm -rf *.Rcheck
	@rm -rf src/*.o src/*.so src/*.dll
	@rm -rf vignettes/*.html vignettes/*.R
	@echo "[OK] Cleaned"

clean-all: clean
	@echo "[*] Deep cleaning..."
	@rm -rf docs/
	@rm -rf inst/doc/
	@echo "[OK] Deep cleaned"

# Advanced targets for specific workflows
.PHONY: release-prep quick-check fix-style

# Prepare for release
release-prep: clean document test cran-check
	@echo ""
	@echo "==============================================================="
	@echo "  Release Preparation Complete"
	@echo "==============================================================="
	@echo ""
	@echo "Checklist:"
	@echo "  [?] Update NEWS.md with changes"
	@echo "  [?] Update cran-comments.md"
	@echo "  [?] Run 'make submit-cran' when ready"
	@echo ""

# Quick check (no examples, no vignettes)
quick-check:
	@echo "[*] Running quick check..."
	@Rscript -e "devtools::check(vignettes = FALSE, run_dont_test = TRUE)"

# Auto-fix common style issues
fix-style: style document
	@echo "[OK] Style fixed and documentation updated"

