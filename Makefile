# Makefile for MAIVE R Package Development
# Common commands for package development workflow

.PHONY: help install check test document build clean cran-check \
        update-docs coverage install-deps vignettes site preview-site \
        lint style check-version version-patch version-minor version-major \
        version-check

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
	@echo "Version Management (auto-commits, tags, and pushes):"
	@echo "  make check-version  Show current version"
	@echo "  make version-patch  Bump patch version (0.0.X) and release"
	@echo "  make version-minor  Bump minor version (0.X.0) and release"
	@echo "  make version-major  Bump major version (X.0.0) and release"
	@echo ""
	@echo "CRAN Submission:"
	@echo "  make cran-check     Comprehensive CRAN checks (required before submit)"
	@echo ""
	@echo "Note: For interactive version updates and CRAN submission,"
	@echo "      see scripts/ directory or run 'ls scripts/*.R'"
	@echo ""
	@echo "Release Workflows:"
	@echo "  make release-prep   Full release preparation (clean, doc, test, check)"
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
# Automatically commits, tags, and pushes to GitHub
_version-bump:
	@# Check for unstaged changes
	@if [ -n "$$(git status --porcelain)" ]; then \
		echo "[ERROR] Working directory is not clean."; \
		echo "Please commit or stash your changes before bumping the version."; \
		echo ""; \
		git status --short; \
		exit 1; \
	fi; \
	\
	# Calculate new version
	current=$$(grep '^Version:' DESCRIPTION | sed 's/Version: //'); \
	IFS='.' read -r major minor patch <<< "$$current"; \
	if [ "$(TYPE)" = "patch" ]; then \
		new="$$major.$$minor.$$((patch + 1))"; \
	elif [ "$(TYPE)" = "minor" ]; then \
		new="$$major.$$((minor + 1)).0"; \
	elif [ "$(TYPE)" = "major" ]; then \
		new="$$((major + 1)).0.0"; \
	fi; \
	\
	echo "Updating version: $$current -> $$new"; \
	\
	# Update DESCRIPTION
	sed -i.bak "s/^Version: .*/Version: $$new/" DESCRIPTION && rm DESCRIPTION.bak; \
	\
	# Commit the version bump
	echo "[*] Committing version bump..."; \
	git add DESCRIPTION; \
	git commit -m "chore: bump version to $$new"; \
	\
	# Create and push tag
	echo "[*] Creating tag v$$new..."; \
	git tag "v$$new"; \
	\
	echo "[*] Pushing to GitHub..."; \
	git push origin HEAD; \
	git push origin "v$$new"; \
	\
	echo ""; \
	echo "╔════════════════════════════════════════════════════════════════╗"; \
	echo "║              ✅ VERSION BUMP COMPLETE                          ║"; \
	echo "╚════════════════════════════════════════════════════════════════╝"; \
	echo ""; \
	echo "  Version: $$current -> $$new"; \
	echo "  Tag:     v$$new"; \
	echo ""; \
	echo "The tag push will trigger the CRAN submission workflow."; \
	echo "Monitor the workflow at: https://github.com/meta-analysis-es/maive/actions"; \
	echo ""

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
	@echo "╔════════════════════════════════════════════════════════════════╗"
	@echo "║              ✅ RELEASE PREPARATION COMPLETE                   ║"
	@echo "╚════════════════════════════════════════════════════════════════╝"
	@echo ""
	@echo "Current version: $$(grep '^Version:' DESCRIPTION | sed 's/Version: //')"
	@echo ""
	@echo "Checklist:"
	@echo "  [✓] Package cleaned"
	@echo "  [✓] Documentation updated"
	@echo "  [✓] Tests passed"
	@echo "  [✓] CRAN checks passed"
	@echo ""
	@echo "Before bumping version:"
	@echo "  1. Update NEWS.md with changes for the new version"
	@echo "  2. Commit all changes: git add -A && git commit -m 'Prepare release'"
	@echo ""
	@echo "To release (auto-commits, tags, and triggers CRAN submission):"
	@echo "  make version-patch   # For bug fixes (0.0.X)"
	@echo "  make version-minor   # For new features (0.X.0)"
	@echo "  make version-major   # For breaking changes (X.0.0)"
	@echo ""

# Quick check (no examples, no vignettes)
quick-check:
	@echo "[*] Running quick check..."
	@Rscript -e "devtools::check(vignettes = FALSE, run_dont_test = TRUE)"

# Auto-fix common style issues
fix-style: style document
	@echo "[OK] Style fixed and documentation updated"

