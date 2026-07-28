// OpalDiagnostics+Record.swift

import Foundation

public extension OpalDiagnostics {
    /// A diagnostic event retained for debug export.
    ///
    /// Private field values are redacted during record construction before the record can be retained or routed.
    struct Record: Identifiable, Equatable, Sendable {
        public let id: UUID
        public let timestamp: Date
        public let category: Category
        public let level: Level
        public let event: Event
        public let traceID: TraceID?
        public let fields: [Field]

        init(
            id: UUID = UUID(),
            timestamp: Date = Date(),
            category: Category,
            level: Level,
            event: Event,
            traceID: TraceID?,
            fields: [Field]
        ) {
            self.id = id
            self.timestamp = timestamp
            self.category = category
            self.level = level
            self.event = event
            self.traceID = traceID
            self.fields = fields.map(\.redactedForStorage)
        }
    }
}

extension OpalDiagnostics.Record {
    var formattedMessage: String {
        var components = ["event=\(Self.formatMessageValue(event.rawValue))"]

        if let traceID {
            components.append("trace_id=\(Self.formatMessageValue(traceID.rawValue))")
        }

        components += fields.map { "\(Self.formatMessageKey($0.name))=\(Self.formatMessageValue($0.redactedValue))" }

        return components.joined(separator: " ")
    }

    private static func formatMessageKey(_ value: String) -> String {
        guard needsQuotes(for: value) || value.contains("=") else {
            return value
        }

        return quoteMessageValue(value)
    }

    private static func formatMessageValue(_ value: String) -> String {
        guard needsQuotes(for: value) else {
            return value
        }

        return quoteMessageValue(value)
    }

    private static func needsQuotes(for value: String) -> Bool {
        value.isEmpty || value.contains { character in
            character.isWhitespace
                || character == "\""
                || character == "\\"
                || character.unicodeScalars.contains(where: requiresEscaping)
        }
    }

    private static func requiresEscaping(_ scalar: Unicode.Scalar) -> Bool {
        scalar.properties.generalCategory == .control || scalar.properties.isBidiControl
    }

    private static func quoteMessageValue(_ value: String) -> String {
        var escapedValue = ""

        for scalar in value.unicodeScalars {
            switch scalar {
            case "\\":
                escapedValue += "\\\\"
            case "\"":
                escapedValue += "\\\""
            case "\n":
                escapedValue += "\\n"
            case "\r":
                escapedValue += "\\r"
            case "\t":
                escapedValue += "\\t"
            case "\u{2028}":
                escapedValue += "\\u{2028}"
            case "\u{2029}":
                escapedValue += "\\u{2029}"
            default:
                if requiresEscaping(scalar) {
                    escapedValue += "\\u{\(String(scalar.value, radix: 16))}"
                } else {
                    escapedValue.unicodeScalars.append(scalar)
                }
            }
        }

        return "\"\(escapedValue)\""
    }
}
