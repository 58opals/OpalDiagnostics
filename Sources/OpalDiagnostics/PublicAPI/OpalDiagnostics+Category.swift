// OpalDiagnostics+Category.swift

public extension OpalDiagnostics {
    /// A static, non-sensitive diagnostics category used for runtime filtering and OSLog routing.
    ///
    /// Category names are retained and passed to OSLog as public metadata. Do not include user data, secrets, identifiers, or other dynamic payload values.
    struct Category: RawRepresentable, Hashable, Sendable, ExpressibleByStringLiteral, CustomStringConvertible {
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

        public static let diagnostics = Self(rawValue: "diagnostics")
        public static let network = Self(rawValue: "network")
        public static let persistence = Self(rawValue: "persistence")
        public static let security = Self(rawValue: "security")
        public static let base = Self(rawValue: "base")
        public static let crypto = Self(rawValue: "crypto")
        public static let fusion = Self(rawValue: "fusion")
        public static let hedge = Self(rawValue: "hedge")
        public static let fulcrum = Self(rawValue: "fulcrum")
    }
}
