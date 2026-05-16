// OpalDiagnostics+RecordQuery.swift

import Foundation

public extension OpalDiagnostics {
    /// Filters recent sanitized diagnostics without changing the runtime buffer.
    struct RecordQuery: Equatable, Sendable {
        public var category: Category?
        public var level: Level?
        public var traceID: TraceID?
        public var event: Event?
        public var startDate: Date?
        public var endDate: Date?

        public init(
            category: Category? = nil,
            level: Level? = nil,
            traceID: TraceID? = nil,
            event: Event? = nil,
            from startDate: Date? = nil,
            through endDate: Date? = nil
        ) {
            self.category = category
            self.level = level
            self.traceID = traceID
            self.event = event
            self.startDate = startDate
            self.endDate = endDate
        }
    }

    /// Returns recent sanitized records that match the supplied query.
    static func recentRecords(matching query: RecordQuery) -> [Record] {
        OpalDiagnosticsRuntime.shared.recentRecords.filter(query.matches)
    }
}

extension OpalDiagnostics.RecordQuery {
    func matches(_ record: OpalDiagnostics.Record) -> Bool {
        if let category, record.category != category {
            return false
        }

        if let level, record.level != level {
            return false
        }

        if let traceID, record.traceID != traceID {
            return false
        }

        if let event, record.event != event {
            return false
        }

        if let startDate, record.timestamp < startDate {
            return false
        }

        if let endDate, record.timestamp > endDate {
            return false
        }

        return true
    }
}
