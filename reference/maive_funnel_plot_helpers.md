# Funnel plot (base graphics)

Components provided: - \`get_funnel_plot()\` as the public high-level
entrypoint - internal helpers to validate and map \`(dat, result)\` into
plot inputs - an internal base-graphics engine that draws onto the
current device

## Details

Device management (PNG/SVG/PDF), resolution, and any base64 encoding are
the caller's responsibility.
