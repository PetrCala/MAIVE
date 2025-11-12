# Getting Started with MAIVE

## Overview

MAIVE (Meta-Analysis Instrumental Variable Estimator) addresses a
fundamental problem in meta-analysis of observational research:
**spurious precision**. Traditional meta-analysis assigns more weight to
studies with lower standard errors, assuming higher precision. However,
in observational research, precision must be estimated and is vulnerable
to manipulation through practices like p-hacking to achieve statistical
significance.

This manipulation can invalidate:

- Inverse-variance weighting schemes
- Bias-correction methods like funnel plots
- Traditional publication bias corrections

MAIVE introduces an **instrumental variable approach** to limit bias
caused by spurious precision in meta-analysis.

## The Problem: Spurious Precision

In observational research, researchers can inadvertently or deliberately
manipulate their analyses to achieve statistically significant results.
This includes:

- Selective reporting of specifications
- Outcome switching
- Sample trimming
- Selective controls inclusion

These practices create **spuriously precise estimates** that appear more
reliable than they actually are. Traditional meta-analysis methods that
weight by inverse variance will overweight these manipulated studies,
leading to biased conclusions.

## The MAIVE Solution

MAIVE uses **instrumental variables** to correct for spurious precision:

1.  **First-stage regression**: Instruments the potentially manipulated
    standard errors using inverse sample sizes (which researchers cannot
    easily manipulate)
2.  **Second-stage regression**: Uses the instrumented standard errors
    in meta-regression models

This approach provides:

- Robust meta-estimates that account for spurious precision
- Hausman-type tests comparing IV and OLS estimates
- Anderson-Rubin confidence intervals for weak instruments
- Publication bias tests based on instrumented standard errors

## Installation

``` r
# Install from CRAN (once published)
install.packages("MAIVE")

# Or install development version from GitHub
install.packages("devtools")
devtools::install_github("meta-analysis-es/maive")
```

``` r
library(MAIVE)
```

## Data Structure

The
[`maive()`](https://meta-analysis-es.github.io/maive/reference/maive.md)
function expects a data frame with the following columns:

| Column | Label    | Description                                                   |
|--------|----------|---------------------------------------------------------------|
| 1      | bs       | Primary estimates (effect sizes)                              |
| 2      | sebs     | Standard errors (must be \> 0)                                |
| 3      | Ns       | Sample sizes (must be \> 0)                                   |
| 4      | study_id | Study identification (optional, for clustering/fixed effects) |

## Basic Usage

Let’s create a simple example dataset:

``` r
# Simulated meta-analysis data
set.seed(123)
n_studies <- 50

data <- data.frame(
  bs = rnorm(n_studies, mean = 0.3, sd = 0.2),
  sebs = runif(n_studies, min = 0.05, max = 0.3),
  Ns = sample(100:1000, n_studies, replace = TRUE),
  study_id = rep(1:10, each = 5)
)

head(data)
#>          bs      sebs  Ns study_id
#> 1 0.1879049 0.1999972 342        1
#> 2 0.2539645 0.1332059 961        1
#> 3 0.6117417 0.1721533 946        1
#> 4 0.3141017 0.2886185 891        1
#> 5 0.3258575 0.1707256 212        1
#> 6 0.6430130 0.2725876 718        2
```

### Default MAIVE Estimation

The default MAIVE estimator uses PET-PEESE with instrumented standard
errors, no weights, cluster-robust standard errors, and wild bootstrap:

``` r
# Run MAIVE with defaults
result <- maive(
  dat = data,
  method = 3,      # PET-PEESE (default)
  weight = 0,      # No weights (default)
  instrument = 1,  # Instrument SEs (default)
  studylevel = 2,  # Cluster-robust (default)
  SE = 3,          # Wild bootstrap (default)
  AR = 1           # Anderson-Rubin CI (default)
)

# View key results
cat("MAIVE Estimate:", round(result$Estimate, 3), "\n")
cat("MAIVE SE:", round(result$SE, 3), "\n")
cat("Standard Estimate:", round(result$StdEstimate, 3), "\n")
cat("Hausman Test:", round(result$Hausman, 3), "\n")
cat("First-stage F-test:", round(result$`F-test`, 3), "\n")
```

### Understanding the Output

The
[`maive()`](https://meta-analysis-es.github.io/maive/reference/maive.md)
function returns a list with the following key elements:

- `Estimate`: MAIVE point estimate (corrected for spurious precision)
- `SE`: MAIVE standard error
- `StdEstimate`: Standard (non-IV) estimate for comparison
- `Hausman`: Hausman-type test comparing IV vs OLS estimates (high value
  suggests spurious precision)
- `F-test`: First-stage F-test of instrument strength
- `AR_CI`: Anderson-Rubin confidence interval (robust to weak
  instruments)
- `pbias_pval`: p-value for publication bias test
- `SE_instrumented`: Vector of instrumented standard errors

## Method Options

MAIVE supports multiple meta-regression methods:

### 1. FAT-PET (Precision-Effect Test)

``` r
result_pet <- maive(
  dat = data,
  method = 1,  # FAT-PET
  weight = 0,
  instrument = 1,
  studylevel = 2,
  SE = 3,
  AR = 1
)

cat("PET Estimate:", round(result_pet$Estimate, 3), "\n")
```

### 2. PEESE (Precision-Effect Estimate with Standard Error)

``` r
result_peese <- maive(
  dat = data,
  method = 2,  # PEESE
  weight = 0,
  instrument = 1,
  studylevel = 2,
  SE = 3,
  AR = 1
)

cat("PEESE Estimate:", round(result_peese$Estimate, 3), "\n")
```

### 3. PET-PEESE (Conditional Method)

PET-PEESE uses PET if the PET estimate is not significantly different
from zero, otherwise uses PEESE:

``` r
result_petpeese <- maive(
  dat = data,
  method = 3,  # PET-PEESE (default)
  weight = 0,
  instrument = 1,
  studylevel = 2,
  SE = 3,
  AR = 1
)

cat("PET-PEESE Estimate:", round(result_petpeese$Estimate, 3), "\n")
```

### 4. Endogenous Kink (EK)

``` r
result_ek <- maive(
  dat = data,
  method = 4,  # EK
  weight = 0,
  instrument = 1,
  studylevel = 2,
  SE = 3,
  AR = 0  # AR not available for EK
)

cat("EK Estimate:", round(result_ek$Estimate, 3), "\n")
```

## Weighting Schemes

### No Weights (Default)

Unweighted regression, recommended when spurious precision is a concern:

``` r
result_noweight <- maive(
  dat = data,
  method = 3,
  weight = 0,  # No weights
  instrument = 1,
  studylevel = 2,
  SE = 3,
  AR = 1
)
```

### Inverse-Variance Weights

Traditional meta-analysis weighting:

``` r
result_ivweight <- maive(
  dat = data,
  method = 3,
  weight = 1,  # Inverse-variance weights
  instrument = 1,
  studylevel = 2,
  SE = 3,
  AR = 0  # AR not available with weights
)
```

### MAIVE-Adjusted Weights

Uses instrumented standard errors for weighting:

``` r
result_maiveweight <- maive(
  dat = data,
  method = 3,
  weight = 2,  # MAIVE-adjusted weights
  instrument = 1,
  studylevel = 2,
  SE = 3,
  AR = 1
)
```

## Study-Level Correlation

Control for study-level correlation when you have multiple estimates per
study:

``` r
# No study-level adjustment
result_none <- maive(data, method = 3, weight = 0, instrument = 1, 
                     studylevel = 0, SE = 0, AR = 1)

# Study fixed effects (demeaned)
result_fe <- maive(data, method = 3, weight = 0, instrument = 1,
                   studylevel = 1, SE = 1, AR = 0)  # AR not available with FE

# Cluster-robust standard errors
result_cluster <- maive(data, method = 3, weight = 0, instrument = 1,
                        studylevel = 2, SE = 3, AR = 1)

# Both fixed effects and clustering
result_both <- maive(data, method = 3, weight = 0, instrument = 1,
                     studylevel = 3, SE = 3, AR = 0)
```

## Standard Error Options

``` r
# CR0 (Huber-White)
result_cr0 <- maive(data, method = 3, weight = 0, instrument = 1,
                    studylevel = 2, SE = 0, AR = 1)

# CR1 (Standard empirical correction)
result_cr1 <- maive(data, method = 3, weight = 0, instrument = 1,
                    studylevel = 2, SE = 1, AR = 1)

# CR2 (Bias-reduced estimator)
result_cr2 <- maive(data, method = 3, weight = 0, instrument = 1,
                    studylevel = 2, SE = 2, AR = 1)

# Wild bootstrap (recommended, default)
result_boot <- maive(data, method = 3, weight = 0, instrument = 1,
                     studylevel = 2, SE = 3, AR = 1)
```

## First-Stage Specification

MAIVE allows two functional forms for the first-stage regression:

### Levels (Default)

Regresses variance (sebs²) on constant and 1/Ns:

``` r
result_levels <- maive(data, method = 3, weight = 0, instrument = 1,
                       studylevel = 2, SE = 3, AR = 1, first_stage = 0)

cat("First-stage (levels) F-test:", round(result_levels$`F-test`, 3), "\n")
```

### Log Specification

Log-linear regression with smearing retransformation:

``` r
result_log <- maive(data, method = 3, weight = 0, instrument = 1,
                    studylevel = 2, SE = 3, AR = 1, first_stage = 1)

cat("First-stage (log) F-test:", round(result_log$`F-test`, 3), "\n")
```

## WAIVE: Robust Extension

WAIVE (Weighted And Instrumented Variable Estimator) provides additional
robustness by downweighting studies with spurious precision or extreme
outliers:

``` r
result_waive <- waive(
  dat = data,
  method = 3,
  instrument = 1,
  studylevel = 2,
  SE = 3,
  AR = 1
)

cat("WAIVE Estimate:", round(result_waive$Estimate, 3), "\n")
cat("WAIVE SE:", round(result_waive$SE, 3), "\n")
```

WAIVE is particularly useful when:

- You suspect extreme outliers in your data
- Standard errors may be severely manipulated
- You want automatic downweighting of problematic studies

## Interpretation Guidelines

### Hausman Test

The Hausman test compares the MAIVE (IV) estimate with the standard
(OLS) estimate:

- **High value**: Suggests spurious precision is a problem; MAIVE
  estimate is preferred
- **Low value**: IV and OLS are similar; spurious precision may not be
  severe

### First-Stage F-test

Tests the strength of the instrument (inverse sample size):

- **F \> 10**: Strong instrument
- **F \< 10**: Weak instrument; use Anderson-Rubin CI

### Anderson-Rubin Confidence Interval

Provides inference robust to weak instruments. Always check this CI when
F-test is low.

### Publication Bias p-value

Tests for publication bias using instrumented FAT:

- **Low p-value**: Evidence of publication bias
- **High p-value**: Little evidence of publication bias

## References

Irsova, Z., Bom, P. R. D., Havranek, T., & Rachinger, H. (2024).
Spurious Precision in Meta-Analysis of Observational Research. Available
at: <https://meta-analysis.cz/maive>

Keane, M., & Neal, T. (2023). Instrument strength in IV estimation and
inference: A guide to theory and practice. *Journal of Econometrics*,
235(2), 1625-1653.

## See Also

- [`?maive`](https://meta-analysis-es.github.io/maive/reference/maive.md)
  for detailed parameter documentation
- [`?waive`](https://meta-analysis-es.github.io/maive/reference/waive.md)
  for the robust WAIVE estimator
- Project website: <https://meta-analysis.cz/maive>
