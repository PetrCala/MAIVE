# Joint Anderson-Rubin CI computation

Computes AR confidence intervals using a 2D grid search over (b0, b1)
with chi^2_2 critical value. For the slope (Egger) coefficient under
weak instruments, use method = "slope_only" instead.

## Usage

``` r
compute_AR_CI_optimized(
  model,
  adjust_fun,
  bs,
  sebs,
  invNs,
  g,
  type_choice,
  weights = NULL,
  method = "joint"
)
```

## Arguments

- model:

  Fitted lm object from second-stage regression

- adjust_fun:

  PET_adjust or PEESE_adjust function

- bs:

  Effect estimates

- sebs:

  Standard errors

- invNs:

  Inverse sample sizes (instrument)

- g:

  Cluster variable

- type_choice:

  CR variance type ("CR0", "CR1", "CR2")

- weights:

  Optional weights for weighted AR

- method:

  "joint" for 2D grid, "slope_only" for subset AR (robust under weak IV)
