// OpalDiagnostics+Record.swift

import Foundation

public extension OpalDiagnostics {
    /// A sanitized diagnostic event retained for debug export.
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

        components += fields.map { "\(Self.formatMessageKey($0.name))=\(Self.formatMessageValue($0.value))" }

        return components.joined(separator: " ")
    }

    private static func formatMessageKey(_ value: String) -> String {
        guard messageValueNeedsQuotes(value) || value.contains("=") else {
            return value
        }

        return quotedMessageValue(value)
    }

    private static func formatMessageValue(_ value: String) -> String {
        guard messageValueNeedsQuotes(value) else {
            return value
        }

        return quotedMessageValue(value)
    }

    private static func messageValueNeedsQuotes(_ value: String) -> Bool {
        value.isEmpty || value.contains(where: { $0.isWhitespace || $0 == "\"" || $0 == "\\" })
    }

    private static func quotedMessageValue(_ value: String) -> String {
        var escapedValue = ""

        for character in value {
            switch character {
            case "\\":
                escapedValue += "\\\\"
            case "\"":
                escapedValue += "\\\""
            case "\r\n":
                escapedValue += "\\r\\n"
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
                escapedValue.append(character)
            }
        }

        return "\"\(escapedValue)\""
    }
}
