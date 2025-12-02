# Subset Anderson-Rubin CI for the slope coefficient

Computes weak-instrument-robust AR confidence interval for the slope
(Egger) coefficient by treating the intercept as a nuisance parameter.

## Usage

``` r
compute_AR_CI_slope_only(
  model,
  adjust_fun,
  bs,
  sebs,
  invNs,
  g,
  type_choice,
  weights = NULL
)
```

## Details

This method is robust under weak instruments and avoids the "banana
projection" artifact that can produce spuriously narrow CIs when
projecting from 2D joint AR regions.

Algorithm (per tjhavranek, Nov 2025): 1. For each candidate slope b1,
form residuals: r_i = y_i - b1 \* x_i 2. Run auxiliary regression: r ~
1 + z (intercept absorbs b0) 3. Use cluster-robust (CR2) variance for
the z coefficient 4. Test statistic: t_z^2 from the clustered test 5.
Accept b1 if t_z^2 \<= qchisq(0.95, df = 1) = 3.84

References: - Guggenberger, P., Kleibergen, F. (2012). Econometrica. -
Andrews, D. W. K., & Mikusheva, A. (2016). Econometrica.
