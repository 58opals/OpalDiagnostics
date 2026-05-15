# Opal Diagnostics

Opal Diagnostics is the public Swift package reserved for the Opal stack diagnostics layer.

## Scope

This package will host public-safe diagnostics primitives for observability, runtime diagnostic controls, trace correlation, privacy-aware fields, and recent-event export surfaces. The initial scaffold intentionally exposes only the package namespace so feature work can land in focused commits.

Out of scope for this package are app-specific UI and Wallet execution notes.

## Package Surfaces

- `OpalDiagnostics`: library target and public facade namespace.
- `OpalDiagnosticsTests`: local validation target for the public package surface.

## Validation

Run the package tests with:

```sh
swift test
```
