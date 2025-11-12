# MAIVE 0.0.4

## Initial CRAN submission

* Implemented MAIVE (Meta-Analysis Instrumental Variable Estimator) for addressing spurious precision in meta-analysis
* Core functions:
  * `maive()`: Main function implementing PET, PEESE, PET-PEESE, and Endogenous Kink (EK) methods
  * `waive()`: Robust extension with downweighting of spurious precision and outliers
* Features:
  * Instrumental variable approach using inverse sample sizes
  * Multiple weighting schemes (no weights, inverse-variance, MAIVE-adjusted, WAIVE)
  * Study-level correlation handling (fixed effects, clustering, or both)
  * Robust standard errors (CR0, CR1, CR2, wild bootstrap)
  * Anderson-Rubin confidence intervals for weak instruments
  * First-stage specification options (levels or log transformation)
  * Publication bias testing based on instrumented FAT
* Comprehensive test suite with 9 test files
* Documentation with examples and usage guidelines
