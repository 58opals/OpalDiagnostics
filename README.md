# Opal Diagnostics

Opal Diagnostics is the public Swift package reserved for the Opal stack diagnostics layer.

## Scope

This package hosts public-safe diagnostics primitives for observability, runtime diagnostic controls, trace correlation, privacy-aware fields, and recent-event export surfaces.

Out of scope for this package are app-specific UI and Wallet execution notes.

## Package Surfaces

- `OpalDiagnostics`: library target and public facade namespace.
- `OpalDiagnostics.Event`, `Category`, `Level`, `TraceID`, `Field`, and `FieldPrivacy`: public-safe diagnostic event primitives.
- `OpalDiagnostics.Configuration`, `CategoryFilter`, and `BufferPolicy`: runtime controls for host applications.
- `OpalDiagnostics.Logger`: category-bound event emitter that routes sanitized records through OSLog.
- `OpalDiagnostics.recentRecords`: disabled-by-default in-memory export surface for recent sanitized diagnostics.
- `OpalDiagnosticsTests`: local validation target for the public package surface.

## Event Privacy

Event names must be static, non-sensitive, and low-cardinality. Do not embed wallet data, user data, secrets, network responses, addresses, transaction details, or other runtime values in an event name. Pass all dynamic values through `OpalDiagnostics.Field` with explicit `FieldPrivacy` so private values are redacted before OSLog routing or recent-record export.

## Validation

Run the package tests with:

```sh
swift test
```
