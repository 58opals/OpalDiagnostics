// OpalDiagnostics+Record.swift

import Foundation

public extension OpalDiagnostics {
    /// A sanitized diagnostic event retained for debug export.
    struct Record: Identifiable, Equatable, Sendable {
        public let id: UUID
        public let timestamp: Date
        public let category: Category
        public let level: Level
        public let message: String
        public let traceID: TraceID?
        public let fields: [Field]

        init(
            id: UUID = UUID(),
            timestamp: Date = Date(),
            category: Category,
            level: Level,
            message: String,
            traceID: TraceID?,
            fields: [Field]
        ) {
            self.id = id
            self.timestamp = timestamp
            self.category = category
            self.level = level
            self.message = message
            self.traceID = traceID
            self.fields = fields.map(\.redactedForStorage)
        }
    }
}

extension OpalDiagnostics.Record {
    var formattedMessage: String {
        var components = [message]

        if let traceID {
            components.append("trace_id=\(traceID.rawValue)")
        }

        if fields.isEmpty == false {
            components.append(fields.map { "\($0.name)=\($0.value)" }.joined(separator: " "))
        }

        return components.joined(separator: " ")
    }
}
