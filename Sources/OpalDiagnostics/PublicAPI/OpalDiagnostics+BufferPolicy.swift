// OpalDiagnostics+BufferPolicy.swift

public extension OpalDiagnostics {
    /// Runtime policy for retaining recent sanitized diagnostic records.
    enum BufferPolicy: Equatable, Sendable {
        case disabled
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
