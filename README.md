# Opal Diagnostics

Opal Diagnostics is the public Swift package reserved for the Opal stack diagnostics layer.

## Scope

This package hosts public-safe diagnostics primitives for observability, runtime diagnostic controls, trace correlation, privacy-aware fields, and recent-event export surfaces.

Out of scope for this package are app-specific UI and Wallet execution notes.

## Package Surfaces

- `OpalDiagnostics`: library target and public facade namespace.
- `OpalDiagnostics.Event`, `Category`, `Level`, `TraceID`, `Field`, and `FieldPrivacy`: public-safe diagnostic event primitives.
- `OpalDiagnostics.Configuration`, `CategoryFilter`, `BufferPolicy`, and `RoutingPolicy`: runtime controls for host applications.
- `OpalDiagnostics.Logger`: category-bound event emitter that is silent until the host application enables OSLog routing and/or buffering.
- `OpalDiagnostics.recentRecords`: disabled-by-default in-memory export surface for recent sanitized diagnostics.
- `OpalDiagnostics.withConfiguration(_:operation:)`: task-scoped diagnostics settings for tests and temporary capture without resetting global runtime state.
- `OpalDiagnostics.withTraceID(_:operation:)` and `OpalDiagnostics.currentTraceID`: optional task-local trace propagation for multi-step flows.
- `OpalDiagnostics.RecordQuery` and `OpalDiagnostics.recentRecords(matching:)`: small filtered export helpers for category, level, trace ID, event, and time ranges.
- `OpalDiagnosticsTests`: local validation target for the public package surface.

## Runtime Controls

Host apps own the active routing policy, subsystem, minimum level, category filter, and buffer policy. The default configuration is silent: `routingPolicy` is `.disabled` and `bufferPolicy` is `.disabled`, so record calls do not route to OSLog and do not retain recent records. Enable `.osLog` routing when the app wants platform logging, enable buffering only when the app wants sanitized recent-record export, or enable both when both destinations are needed.

Exact category filters preserve exact matching with `.enabled(_:)` and `.excluded(_:)`. Use `.enabledIncludingSubcategories(_:)` or `.excludedIncludingSubcategories(_:)` when a root category such as `fulcrum` should also match dotted subcategories such as `fulcrum.jsonrpc`, `fulcrum.websocket`, and `fulcrum.reconnect`.

## Event Privacy

Event names must be static, non-sensitive, and low-cardinality. Do not embed wallet data, user data, secrets, network responses, addresses, transaction details, or other runtime values in an event name. Pass all dynamic values through `OpalDiagnostics.Field` with explicit `FieldPrivacy` so private values are redacted before enabled OSLog routing or recent-record export.

`OpalDiagnostics.Field` stores values as strings and provides public-safe convenience initializers for `Int`, `UInt64`, `Bool`, `UUID`, `Duration`, byte counts, and explicit public strings. Keep private or sensitive runtime strings on `init(name:value:privacy:)` with `.private`.

## Levels

OpalDiagnostics intentionally does not define a separate `warning` level. Map warning-like, recoverable states to `.notice`; use `.error` when an operation failed and needs error-level diagnostics.

## Migration Notes

Existing calls to `configure`, `logger(category:)`, `record(event:level:traceID:fields:)`, and `recentRecords` continue to compile. Package tests and temporary capture can move from global configure/reset patterns to `withConfiguration(_:operation:)`, and adopters that want prefix-style category filtering can replace `.enabled([.fulcrum])` with `.enabledIncludingSubcategories([.fulcrum])`.

## Validation

Run the package tests with:

```sh
swift test
```
