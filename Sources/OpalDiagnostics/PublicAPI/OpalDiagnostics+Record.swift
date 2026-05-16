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

        if fields.isEmpty == false {
            components.append(fields.map { "\($0.name)=\(Self.formatMessageValue($0.value))" }.joined(separator: " "))
        }

        return components.joined(separator: " ")
    }

    private static func formatMessageValue(_ value: String) -> String {
        guard value.isEmpty || value.contains(where: \.isWhitespace) || value.contains("\"") || value.contains("\\") else {
            return value
        }

        var escapedValue = ""

        for character in value {
            switch character {
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
            default:
                escapedValue.append(character)
            }
        }

        return "\"\(escapedValue)\""
    }
}
