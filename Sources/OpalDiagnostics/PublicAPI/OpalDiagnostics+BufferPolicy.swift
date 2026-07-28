// OpalDiagnostics+BufferPolicy.swift

public extension OpalDiagnostics {
    /// Runtime policy for retaining recent sanitized diagnostic records.
    enum BufferPolicy: Equatable, Sendable {
        case disabled
        /// Retains up to `capacity` records. A nonpositive capacity disables retention.
        case enabled(capacity: Int)
    }
}

extension OpalDiagnostics.BufferPolicy {
    var capacity: Int {
        switch self {
        case .disabled:
            0
        case let .enabled(capacity):
            max(0, capacity)
        }
    }
}
