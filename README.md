# Opal Diagnostics

Opal Diagnostics is the public Swift package reserved for the Opal stack diagnostics layer.

## Scope

This package hosts public-safe diagnostics primitives for observability, runtime diagnostic controls, trace correlation, privacy-aware fields, and recent-event export surfaces.

Out of scope for this package are app-specific UI and Wallet execution notes.

## Package Surfaces

- `OpalDiagnostics`: library target and public facade namespace.
- `OpalDiagnostics.Category`, `Level`, `TraceID`, `Field`, and `FieldPrivacy`: public-safe diagnostic event primitives.
- `OpalDiagnostics.Configuration`, `CategoryFilter`, and `BufferPolicy`: runtime controls for host applications.
- `OpalDiagnostics.Logger`: category-bound event emitter that routes sanitized records through OSLog.
- `OpalDiagnostics.recentRecords`: disabled-by-default in-memory export surface for recent sanitized diagnostics.
- `OpalDiagnosticsTests`: local validation target for the public package surface.

## Validation

Run the package tests with:

```sh
swift test
```
