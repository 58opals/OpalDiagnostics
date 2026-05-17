// OpalDiagnostics+ErrorCode.swift

public extension OpalDiagnostics {
    /// A stable, public-safe diagnostic error identifier.
    ///
    /// Error codes should be static, non-sensitive, and low-cardinality. Pass dynamic error details through privacy-marked fields.
    struct ErrorCode: RawRepresentable, Hashable, Sendable, ExpressibleByStringLiteral, CustomStringConvertible {
        public let rawValue: String

        public var description: String {
            rawValue
        }

        public init(rawValue: String) {
            self.rawValue = rawValue
        }

        public init(stringLiteral value: String) {
            self.init(rawValue: value)
        }
    }
}
