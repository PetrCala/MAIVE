# R code for MAIVE

R package for MAIVE: "Spurious Precision in Meta-Analysis of
Observational Research" by Zuzana Irsova, Pedro Bom, Tomas Havranek,
Petr Cala, and Heiko Rachinger.

## Usage

``` r
maive(dat, method, weight, instrument, studylevel, SE, AR, first_stage = 0L)
```

## Arguments

- dat:

  Data frame with columns bs, sebs, Ns, study_id (optional).

- method:

  1 FAT-PET, 2 PEESE, 3 PET-PEESE, 4 EK.

- weight:

  0 no weights, 1 standard weights, 2 MAIVE adjusted weights, 3 study
  weights.

- instrument:

  1 yes, 0 no.

- studylevel:

  Correlation at study level: 0 none, 1 fixed effects, 2 cluster.

- SE:

  SE estimator: 0 CR0 (Huber-White), 1 CR1 (Standard empirical
  correction), 2 CR2 (Bias-reduced estimator), 3 wild bootstrap.

- AR:

  Anderson Rubin corrected CI for weak instruments (available for
  unweighted and MAIVE-adjusted weight versions of PET, PEESE,
  PET-PEESE, not available for fixed effects): 0 no, 1 yes.

- first_stage:

  First-stage specification for the variance model: 0 levels, 1 log.

## Value

- beta: MAIVE meta-estimate

- SE: MAIVE standard error

- F-test: heteroskedastic robust F-test of the first step instrumented
  SEs

- beta_standard: point estimate from the method chosen

- SE_standard: standard error from the method chosen

- Hausman: Hausman type test: comparison between MAIVE and standard
  version

- Chi2: 5

- SE_instrumented: instrumented standard errors

- AR_CI: Anderson-Rubin confidence interval for weak instruments

- pub bias p-value: p-value of test for publication bias / p-hacking
  based on instrumented FAT

- egger_coef: Egger Coefficient (PET estimate)

- egger_se: Egger Standard Error (PET standard error)

- egger_boot_ci: Confidence interval for the Egger coefficient using the
  selected resampling scheme

- egger_ar_ci: Anderson-Rubin confidence interval for the Egger
  coefficient (when available)

- is_quadratic_fit: Details on quadratic selection and slope behaviour

- boot_result: Boot result

- slope_coef: Slope coefficient

- petpeese_selected: Which model (PET or PEESE) was selected when
  method=3 (NA otherwise)

- peese_se2_coef: Coefficient on SE^2 when PEESE is the final model (NA
  otherwise)

- peese_se2_se: Standard error of the PEESE SE^2 coefficient (NA
  otherwise)

## Details

Data `dat` can be imported from an Excel file via:
`dat <- read_excel("inputdata.xlsx")` or from a csv file via:
`dat <- read.csv("inputdata.csv")` It should contain:

- Estimates: bs

- Standard errors: sebs

- Number of observations: Ns

- Optional: study_id

Default option for MAIVE: MAIVE-PET-PEESE, unweighted, instrumented,
cluster SE, wild bootstrap, AR.
