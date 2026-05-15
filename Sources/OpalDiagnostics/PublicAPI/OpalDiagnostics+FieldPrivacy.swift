// OpalDiagnostics+FieldPrivacy.swift

public extension OpalDiagnostics {
    /// Privacy handling for a diagnostic field value.
    enum FieldPrivacy: String, Sendable {
        case `public`
        case `private`
    }
}
