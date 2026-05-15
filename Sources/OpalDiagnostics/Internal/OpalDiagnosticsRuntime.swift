// OpalDiagnosticsRuntime.swift

import Foundation
import OSLog

final class OpalDiagnosticsRuntime: @unchecked Sendable {
    static let shared = OpalDiagnosticsRuntime()

    private let lock = NSLock()
    private var activeConfiguration = OpalDiagnostics.Configuration()
    private var recentRecordBuffer = RecentDiagnosticRecordBuffer(policy: .disabled)

    var configuration: OpalDiagnostics.Configuration {
        lock.lock()
        defer { lock.unlock() }
        return activeConfiguration
    }

    var recentRecords: [OpalDiagnostics.Record] {
        lock.lock()
        defer { lock.unlock() }
        return recentRecordBuffer.records
    }

    func configure(_ configuration: OpalDiagnostics.Configuration) {
        lock.lock()
        activeConfiguration = configuration
        recentRecordBuffer = RecentDiagnosticRecordBuffer(policy: configuration.bufferPolicy)
        lock.unlock()
    }

    func clearRecentRecords() {
        lock.lock()
        recentRecordBuffer.clear()
        lock.unlock()
    }

    func record(
        _ message: String,
        category: OpalDiagnostics.Category,
        level: OpalDiagnostics.Level,
        traceID: OpalDiagnostics.TraceID?,
        fields: [OpalDiagnostics.Field]
    ) {
        let record: OpalDiagnostics.Record
        let subsystem: String

        lock.lock()

        let configuration = activeConfiguration
        guard level >= configuration.minimumLevel, configuration.categoryFilter.allows(category) else {
            lock.unlock()
            return
        }

        record = OpalDiagnostics.Record(
            category: category,
            level: level,
            message: message,
            traceID: traceID,
            fields: fields
        )
        recentRecordBuffer.append(record)
        subsystem = configuration.subsystem

        lock.unlock()

        route(record, subsystem: subsystem)
    }

    private init() {}

    private func route(_ record: OpalDiagnostics.Record, subsystem: String) {
        let logger = Logger(subsystem: subsystem, category: record.category.rawValue)
        logger.log(level: record.level.osLogType, "\(record.formattedMessage, privacy: .public)")
    }
}
