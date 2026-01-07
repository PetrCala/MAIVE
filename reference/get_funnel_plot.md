# Draw a funnel plot (base graphics)

High-level wrapper that accepts the original input data and the result
returned by \`maive()\` / \`waive()\`, prepares the necessary
vectors/metadata, and draws the funnel plot on the currently active
graphics device.

## Usage

``` r
get_funnel_plot(dat, result, instrument = NULL, model_type = "MAIVE")
```

## Arguments

- dat:

  Data frame containing at least numeric columns \`bs\` (effect sizes)
  and \`sebs\` (standard errors).

- result:

  Result list returned by \`maive()\` or \`waive()\`.

- instrument:

  Optional indicator (0/1). If \`NULL\`, inferred from \`result\`.

- model_type:

  Label used for plot text/legend (e.g., \`"MAIVE"\` or \`"WAIVE"\`).

## Value

Invisibly returns \`NULL\`.

## Details

Device management (PNG/SVG/PDF, resolution, base64 encoding) is
intentionally left to the caller.
