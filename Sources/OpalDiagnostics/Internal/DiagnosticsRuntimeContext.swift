// DiagnosticsRuntimeContext.swift

import Synchronization

final class DiagnosticsRuntimeContext: Sendable {
    private let state: Mutex<(
        configuration: OpalDiagnostics.Configuration,
        recentRecordBuffer: RecentDiagnosticRecordBuffer
    )>

    var configuration: OpalDiagnostics.Configuration {
        state.withLock { $0.configuration }
    }

    var recentRecords: [OpalDiagnostics.Record] {
        state.withLock { $0.recentRecordBuffer.records }
    }

    init(configuration: OpalDiagnostics.Configuration) {
        state = Mutex((
            configuration: configuration,
            recentRecordBuffer: RecentDiagnosticRecordBuffer(policy: configuration.bufferPolicy)
        ))
    }

    func configure(_ configuration: OpalDiagnostics.Configuration) {
        state.withLock {
            $0 = (
                configuration: configuration,
                recentRecordBuffer: RecentDiagnosticRecordBuffer(policy: configuration.bufferPolicy)
            )
        }
    }

    func clearRecentRecords() {
        state.withLock {
            $0.recentRecordBuffer.clear()
        }
    }

    func isEnabled(category: OpalDiagnostics.Category, level: OpalDiagnostics.Level) -> Bool {
        state.withLock {
            Self.resolveRecordingDecision(
                configuration: $0.configuration,
                category: category,
                level: level
            ) != nil
        }
    }

    func record(
        event: OpalDiagnostics.Event,
        category: OpalDiagnostics.Category,
        level: OpalDiagnostics.Level,
        traceID: OpalDiagnostics.TraceID?,
        fields: [OpalDiagnostics.Field]
    ) -> (record: OpalDiagnostics.Record, subsystem: String, shouldRouteToOSLog: Bool)? {
        state.withLock { state in
            guard let decision = Self.resolveRecordingDecision(
                configuration: state.configuration,
                category: category,
                level: level
            ) else {
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
                state.recentRecordBuffer.append(record)
            }

            return (record, decision.configuration.subsystem, decision.shouldRouteToOSLog)
        }
    }

    private static func resolveRecordingDecision(
        configuration: OpalDiagnostics.Configuration,
        category: OpalDiagnostics.Category,
        level: OpalDiagnostics.Level
    ) -> (configuration: OpalDiagnostics.Configuration, shouldRetainRecord: Bool, shouldRouteToOSLog: Bool)? {
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
