// OpalDiagnostics+Field.swift

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
    }
}

extension OpalDiagnostics.Field {
    static let privateRedactionText = "<redacted>"

    var redactedForStorage: Self {
        Self(name: name, value: redactedValue, privacy: privacy)
    }
}
