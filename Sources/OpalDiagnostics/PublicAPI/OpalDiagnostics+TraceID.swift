// OpalDiagnostics+TraceID.swift

import Foundation

public extension OpalDiagnostics {
    /// A correlation identifier for following one action across package boundaries.
    struct TraceID: RawRepresentable, Hashable, Sendable, ExpressibleByStringLiteral, CustomStringConvertible {
        public let rawValue: String

        public var description: String {
            rawValue
        }

        public init() {
            self.init(rawValue: UUID().uuidString)
        }

        public init(rawValue: String) {
            self.rawValue = rawValue
        }

        public init(stringLiteral value: String) {
            self.init(rawValue: value)
        }
    }
}
