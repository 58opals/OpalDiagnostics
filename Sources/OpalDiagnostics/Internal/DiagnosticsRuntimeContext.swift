// DiagnosticsRuntimeContext.swift

import Foundation

final class DiagnosticsRuntimeContext: @unchecked Sendable {
    private let lock = NSLock()
    private var activeConfiguration: OpalDiagnostics.Configuration
    private var recentRecordBuffer: RecentDiagnosticRecordBuffer

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

    init(configuration: OpalDiagnostics.Configuration) {
        activeConfiguration = configuration
        recentRecordBuffer = RecentDiagnosticRecordBuffer(policy: configuration.bufferPolicy)
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

    func isEnabled(category: OpalDiagnostics.Category, level: OpalDiagnostics.Level) -> Bool {
        lock.lock()
        defer { lock.unlock() }
        return recordingDecision(category: category, level: level) != nil
    }

    func record(
        event: OpalDiagnostics.Event,
        category: OpalDiagnostics.Category,
        level: OpalDiagnostics.Level,
        traceID: OpalDiagnostics.TraceID?,
        fields: [OpalDiagnostics.Field]
    ) -> (record: OpalDiagnostics.Record, subsystem: String, shouldRouteToOSLog: Bool)? {
        lock.lock()
        defer { lock.unlock() }

        guard let decision = recordingDecision(category: category, level: level) else {
            return nil
        }

        let record = OpalDiagnostics.Record(
            category: category,
            level: level,
            event: event,
            traceID: traceID,
            fields: fields
        )

        if decision.shouldRetainRecord {
            recentRecordBuffer.append(record)
        }

        return (record, decision.configuration.subsystem, decision.shouldRouteToOSLog)
    }

    private func recordingDecision(
        category: OpalDiagnostics.Category,
        level: OpalDiagnostics.Level
    ) -> (configuration: OpalDiagnostics.Configuration, shouldRetainRecord: Bool, shouldRouteToOSLog: Bool)? {
        let configuration = activeConfiguration
        guard level >= configuration.minimumLevel, configuration.categoryFilter.allows(category) else {
            return nil
        }

        let shouldRetainRecord = configuration.bufferPolicy.capacity > 0
        let shouldRouteToOSLog = configuration.routingPolicy == .osLog
        guard shouldRetainRecord || shouldRouteToOSLog else {
            return nil
        }

        return (configuration, shouldRetainRecord, shouldRouteToOSLog)
    }
}
