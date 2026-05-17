// OpalDiagnostics+Field.swift

import Foundation

public extension OpalDiagnostics {
    /// A key-value diagnostic field whose value is stored according to explicit privacy.
    struct Field: Hashable, Sendable {
        public let name: String
        public let value: String
        public let privacy: FieldPrivacy

        public var redactedValue: String {
            switch privacy {
            case .public:
                value
            case .private:
                Self.privateRedactionText
            }
        }

        public init(name: String, value: String, privacy: FieldPrivacy) {
            self.name = name
            self.value = value
            self.privacy = privacy
        }

        public init(name: String, publicValue: String) {
            self.init(name: name, value: publicValue, privacy: .public)
        }

        public init(name: String, value: Int, privacy: FieldPrivacy = .public) {
            self.init(name: name, value: String(value), privacy: privacy)
        }

        public init(name: String, value: UInt64, privacy: FieldPrivacy = .public) {
            self.init(name: name, value: String(value), privacy: privacy)
        }

        public init(name: String, value: Bool, privacy: FieldPrivacy = .public) {
            self.init(name: name, value: String(value), privacy: privacy)
        }

        public init(name: String, value: UUID, privacy: FieldPrivacy = .public) {
            self.init(name: name, value: value.uuidString, privacy: privacy)
        }

        public init(name: String, value: Duration, privacy: FieldPrivacy = .public) {
            self.init(name: name, value: Self.formatDuration(value), privacy: privacy)
        }

        public init(name: String, byteCount: UInt64, privacy: FieldPrivacy = .public) {
            self.init(name: name, value: byteCount, privacy: privacy)
        }
    }
}

extension OpalDiagnostics.Field {
    static let privateRedactionText = "<redacted>"

    var redactedForStorage: Self {
        Self(name: name, value: redactedValue, privacy: privacy)
    }
}

public extension OpalDiagnostics.Field {
    static func errorCode(_ code: OpalDiagnostics.ErrorCode) -> Self {
        Self(name: "error_code", publicValue: code.rawValue)
    }

    static func errorCode(_ rawValue: String) -> Self {
        errorCode(OpalDiagnostics.ErrorCode(rawValue: rawValue))
    }

    static func errorType(_ error: Swift.Error) -> Self {
        Self(name: "error_type", publicValue: String(reflecting: Swift.type(of: error)))
    }

    static func errorMessage(_ message: String) -> Self {
        Self(name: "error_message", value: message, privacy: .private)
    }
}

private extension OpalDiagnostics.Field {
    static func formatDuration(_ duration: Duration) -> String {
        let components = duration.components

        guard components.attoseconds != 0 else {
            return "\(components.seconds)s"
        }

        let isNegative = components.seconds < 0 || components.attoseconds < 0
        let seconds = components.seconds.magnitude
        let attosecondsText = String(components.attoseconds.magnitude)
        let paddedAttoseconds = String(repeating: "0", count: max(0, 18 - attosecondsText.count)) + attosecondsText
        var fractionalSeconds = paddedAttoseconds

        while fractionalSeconds.last == "0" {
            fractionalSeconds.removeLast()
        }

        return "\(isNegative ? "-" : "")\(seconds).\(fractionalSeconds)s"
    }
}
