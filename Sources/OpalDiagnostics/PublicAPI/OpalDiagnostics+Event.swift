// OpalDiagnostics+Event.swift

public extension OpalDiagnostics {
    /// A stable, public-safe diagnostic event identifier.
    ///
    /// Event names should be static, non-sensitive, and low-cardinality. Pass dynamic runtime values through privacy-marked fields.
    struct Event: RawRepresentable, Hashable, Sendable, ExpressibleByStringLiteral, CustomStringConvertible {
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
