// OpalDiagnostics+FieldPrivacy.swift

public extension OpalDiagnostics {
    /// Privacy handling for a diagnostic field value.
    ///
    /// Public values may be retained and routed as written. Private values are replaced with redaction text before records leave the diagnostics runtime.
    enum FieldPrivacy: String, Sendable {
        case `public`
        case `private`
    }
}
