# Opal Diagnostics

Opal Diagnostics is the public Swift package reserved for the Opal stack diagnostics layer.

## Requirements

- Swift tools version: `6.4`
- Platforms: `macOS 26`, `iOS 26`, `watchOS 26`, `tvOS 26`, `visionOS 26`

## Installation

Use the public `develop` branch for the current Swift 6.4 package stack:

```swift
dependencies: [
    .package(url: "https://github.com/58opals/OpalDiagnostics.git", branch: "develop")
]
```

## Scope

This package hosts public-safe diagnostics primitives for observability, runtime diagnostic controls, trace correlation, privacy-aware fields, and recent-record export surfaces.

Out of scope for this package are app-specific UI and Wallet execution notes.

## Package Surfaces

- `OpalDiagnostics`: library target and public facade namespace.
- `OpalDiagnostics.Event`, `Category`, `ErrorCode`, `Level`, `TraceID`, `Field`, and `FieldPrivacy`: public-safe diagnostic event primitives.
- `OpalDiagnostics.Configuration`, `CategoryFilter`, `BufferPolicy`, and `RoutingPolicy`: runtime controls for host applications.
- `OpalDiagnostics.Logger`: category-bound event emitter that is silent until the host application enables OSLog routing and/or buffering.
- `OpalDiagnostics.recentRecords`: disabled-by-default in-memory export surface for recent records with private field values redacted.
- `OpalDiagnostics.withConfiguration(_:operation:)`: task-scoped diagnostics settings for tests and temporary capture without resetting global runtime state.
- `OpalDiagnostics.withTraceID(_:operation:)` and `OpalDiagnostics.currentTraceID`: optional task-local trace propagation for multi-step flows.
- `OpalDiagnostics.RecordQuery` and `OpalDiagnostics.recentRecords(matching:)`: small filtered export helpers for category, level, trace ID, event, and time ranges.
- `OpalDiagnosticsTests`: local validation target for the public package surface.

## Runtime Controls

Host apps own the active routing policy, subsystem, minimum level, category filter, and buffer policy. The default configuration is silent: `routingPolicy` is `.disabled` and `bufferPolicy` is `.disabled`, so record calls do not route to OSLog and do not retain recent records. Enable `.osLog` routing when the app wants platform logging, enable buffering only when the app wants recent-record export with private field values redacted, or enable both when both destinations are needed.

Exact category filters preserve exact matching with `.enabled(_:)` and `.excluded(_:)`. Use `.enabledIncludingSubcategories(_:)` or `.excludedIncludingSubcategories(_:)` when a root category such as `fulcrum` should also match dotted subcategories such as `fulcrum.jsonrpc`, `fulcrum.websocket`, and `fulcrum.reconnect`.

## Diagnostic Privacy

Event names, category names, field names, and the configured subsystem must be static, non-sensitive, and low-cardinality because they are retained or routed as public diagnostic metadata. Do not embed wallet data, user data, secrets, network responses, addresses, transaction details, or other runtime payloads in this metadata. Pass dynamic payload values through `OpalDiagnostics.Field` with an explicit public or private classification so private values are redacted before enabled OSLog routing or recent-record export.

Trace IDs are the intentional dynamic-metadata exception: generate one with `OpalDiagnostics.TraceID()` or construct one from an explicitly public, opaque correlation token with `OpalDiagnostics.TraceID(publicValue:)`. Never use wallet IDs, account IDs, addresses, or other sensitive identifiers as trace IDs because trace IDs are retained and routed publicly.

`OpalDiagnostics.Field` stores values as strings and supports `Int`, `UInt64`, `Bool`, `UUID`, `Duration`, byte counts, and explicit public strings. Typed value initializers require an explicit `privacy` argument so amounts, identifiers, and other sensitive values cannot become public by omission. Use `OpalDiagnostics.Field.publicField(_:value:)` only for stable, low-cardinality strings that are safe in retained records and OSLog. Use `OpalDiagnostics.Field.privateField(_:value:)` for payloads, secrets, user-chain identifiers, endpoint details, addresses, and other sensitive runtime strings unless a public classification has been explicitly justified.

Use `OpalDiagnostics.ErrorCode` for stable, package-owned error identifiers that should be emitted as diagnostics fields without introducing package-local diagnostics error-code types. `OpalDiagnostics.Field.errorCode(_:)` writes public `error_code`, `errorType(_:)` writes public `error_type`, and `errorMessage(_:)` writes private `error_message` so messages are redacted before routing or recent-record export.

## Levels

OpalDiagnostics intentionally does not define a separate `warning` level. Map warning-like, recoverable states to `.notice`; use `.error` when an operation failed and needs error-level diagnostics.

## Migration Notes

The runtime entry points `configure`, `logger(category:)`, `record(event:level:traceID:fields:)`, and `recentRecords` remain available. Two intentional source-breaking migrations make public metadata classification visible at the call site: typed `Field` initializers must now pass `privacy:` explicitly, and `TraceID` no longer conforms to `RawRepresentable` or `ExpressibleByStringLiteral`; custom trace identifiers use `TraceID(publicValue:)`. Package tests and temporary capture can move from global configure/reset patterns to `withConfiguration(_:operation:)`, and adopters that want prefix-style category filtering can replace `.enabled([.fulcrum])` with `.enabledIncludingSubcategories([.fulcrum])`.

## Validation

Run the package tests with:

```sh
swift test
```
