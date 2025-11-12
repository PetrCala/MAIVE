# Makefile for MAIVE R Package Development
# Common commands for package development workflow

.PHONY: help install check test document build clean cran-check submit-cran \
        update-docs coverage install-deps vignettes site preview-site \
        lint style check-version update-version version-patch version-minor \
        version-major version-check

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
	@echo "Version Management:"
	@echo "  make check-version  Show current version"
	@echo "  make update-version Interactive version updater (recommended)"
	@echo "  make version-patch  Bump patch version (0.0.X)"
	@echo "  make version-minor  Bump minor version (0.X.0)"
	@echo "  make version-major  Bump major version (X.0.0)"
	@echo ""
	@echo "CRAN Submission:"
	@echo "  make submit-cran    Interactive CRAN submission (uses helper script)"
	@echo ""
	@echo "Release Workflows:"
	@echo "  make release-prep   Full release preparation (clean, doc, test, check)"
	@echo "  make new-release    Complete guided release workflow"
	@echo "  make quick-check    Fast check (skip vignettes)"
	@echo ""
	@echo "Code Quality:"
	@echo "  make lint           Check code style"
	@echo "  make style          Auto-format code with styler"
	@echo "  make fix-style      Auto-format and update documentation"
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

# Version Management
check-version:
	@echo "Current version: $$(grep '^Version:' DESCRIPTION | sed 's/Version: //')"

version-check: check-version

update-version:
	@echo "[*] Starting interactive version updater..."
	@Rscript scripts/update-version.R

version-patch:
	@echo "[*] Bumping patch version (X.Y.Z -> X.Y.Z+1)..."
	@$(MAKE) _version-bump TYPE=patch

version-minor:
	@echo "[*] Bumping minor version (X.Y.Z -> X.Y+1.0)..."
	@$(MAKE) _version-bump TYPE=minor

version-major:
	@echo "[*] Bumping major version (X.Y.Z -> X+1.0.0)..."
	@$(MAKE) _version-bump TYPE=major

# Internal version bump (don't call directly)
_version-bump:
	@current=$$(grep '^Version:' DESCRIPTION | sed 's/Version: //'); \
	IFS='.' read -r major minor patch <<< "$$current"; \
	if [ "$(TYPE)" = "patch" ]; then \
		new="$$major.$$minor.$$((patch + 1))"; \
	elif [ "$(TYPE)" = "minor" ]; then \
		new="$$major.$$((minor + 1)).0"; \
	elif [ "$(TYPE)" = "major" ]; then \
		new="$$((major + 1)).0.0"; \
	fi; \
	echo "Updating version: $$current -> $$new"; \
	sed -i.bak "s/^Version: .*/Version: $$new/" DESCRIPTION && rm DESCRIPTION.bak; \
	echo ""; \
	echo "[OK] Version updated to $$new"; \
	echo ""; \
	echo "Next steps:"; \
	echo "  1. Update NEWS.md with changes for version $$new"; \
	echo "  2. Review changes: git diff DESCRIPTION"; \
	echo "  3. Commit: git commit -am 'Bump version to $$new'"; \
	echo "  4. Run checks: make release-prep"

# CRAN Submission
submit-cran:
	@echo "[*] Starting CRAN submission process..."
	@Rscript scripts/submit-cran.R

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
.PHONY: release-prep quick-check fix-style new-release

# Prepare for release
release-prep: clean document test cran-check
	@echo ""
	@echo "==============================================================="
	@echo "  Release Preparation Complete"
	@echo "==============================================================="
	@echo ""
	@echo "Checklist:"
	@echo "  [?] Version updated (current: $$(grep '^Version:' DESCRIPTION | sed 's/Version: //'))"
	@echo "  [?] NEWS.md updated with changes"
	@echo "  [?] cran-comments.md updated"
	@echo "  [?] All checks passed"
	@echo ""
	@echo "When ready:"
	@echo "  make submit-cran"
	@echo ""

# Complete new release workflow
new-release:
	@echo "==============================================================="
	@echo "  New Release Workflow"
	@echo "==============================================================="
	@echo ""
	@echo "This will guide you through a complete release."
	@echo ""
	@read -p "Press Enter to continue or Ctrl-C to cancel..." dummy
	@$(MAKE) update-version
	@echo ""
	@read -p "Version updated. Press Enter to run checks..." dummy
	@$(MAKE) release-prep
	@echo ""
	@echo "Release preparation complete!"
	@echo "Review everything and run 'make submit-cran' when ready."

# Quick check (no examples, no vignettes)
quick-check:
	@echo "[*] Running quick check..."
	@Rscript -e "devtools::check(vignettes = FALSE, run_dont_test = TRUE)"

# Auto-fix common style issues
fix-style: style document
	@echo "[OK] Style fixed and documentation updated"

