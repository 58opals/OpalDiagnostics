// OpalDiagnostics+TraceID.swift

import Foundation

public extension OpalDiagnostics {
    /// An opaque, non-sensitive correlation identifier for following one action across package boundaries.
    ///
    /// Trace IDs are retained and routed as public diagnostic metadata. Use `init()` to generate a safe identifier, or pass only an explicitly public opaque token to `init(publicValue:)`.
    struct TraceID: Hashable, Sendable, CustomStringConvertible {
        public let rawValue: String

        public var description: String {
            rawValue
        }

        public init() {
            self.init(publicValue: UUID().uuidString)
        }

        public init(publicValue: String) {
            rawValue = publicValue
        }
    }
}
