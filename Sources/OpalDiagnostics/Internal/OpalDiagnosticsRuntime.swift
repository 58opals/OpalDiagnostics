// OpalDiagnosticsRuntime.swift

import Foundation

final class OpalDiagnosticsRuntime: Sendable {
    static let shared = OpalDiagnosticsRuntime()

    @TaskLocal private static var scopedContext: DiagnosticsRuntimeContext?
    @TaskLocal private static var scopedRecordRouter: (any DiagnosticRecordRouting)?
    @TaskLocal private static var scopedTraceID: OpalDiagnostics.TraceID?

    private static let osLogRecordRouter = OSLogDiagnosticRecordRouter()

    private let globalContext = DiagnosticsRuntimeContext(configuration: .init())

    private var currentContext: DiagnosticsRuntimeContext {
        Self.scopedContext ?? globalContext
    }

    var configuration: OpalDiagnostics.Configuration {
        currentContext.configuration
    }

    var recentRecords: [OpalDiagnostics.Record] {
        currentContext.recentRecords
    }

    var currentTraceID: OpalDiagnostics.TraceID? {
        Self.scopedTraceID
    }

    func configure(_ configuration: OpalDiagnostics.Configuration) {
        currentContext.configure(configuration)
    }

    func clearRecentRecords() {
        currentContext.clearRecentRecords()
    }

    func isEnabled(category: OpalDiagnostics.Category, level: OpalDiagnostics.Level) -> Bool {
        currentContext.isEnabled(category: category, level: level)
    }

    func withConfiguration<Success>(
        _ configuration: OpalDiagnostics.Configuration,
        operation: () throws -> Success
    ) rethrows -> Success {
        let context = DiagnosticsRuntimeContext(configuration: configuration)
        return try Self.$scopedContext.withValue(context) {
            try operation()
        }
    }

    func withConfiguration<Success>(
        _ configuration: OpalDiagnostics.Configuration,
        operation: () async throws -> Success
    ) async rethrows -> Success {
        let context = DiagnosticsRuntimeContext(configuration: configuration)
        return try await Self.$scopedContext.withValue(context) {
            try await operation()
        }
    }

    func withRecordRouter<Success>(
        _ router: any DiagnosticRecordRouting,
        operation: () throws -> Success
    ) rethrows -> Success {
        try Self.$scopedRecordRouter.withValue(router) {
            try operation()
        }
    }

    func withRecordRouter<Success>(
        _ router: any DiagnosticRecordRouting,
        operation: () async throws -> Success
    ) async rethrows -> Success {
        try await Self.$scopedRecordRouter.withValue(router) {
            try await operation()
        }
    }

    func withTraceID<Success>(
        _ traceID: OpalDiagnostics.TraceID?,
        operation: () throws -> Success
    ) rethrows -> Success {
        try Self.$scopedTraceID.withValue(traceID) {
            try operation()
        }
    }

    func withTraceID<Success>(
        _ traceID: OpalDiagnostics.TraceID?,
        operation: () async throws -> Success
    ) async rethrows -> Success {
        try await Self.$scopedTraceID.withValue(traceID) {
            try await operation()
        }
    }

    func record(
        event: OpalDiagnostics.Event,
        category: OpalDiagnostics.Category,
        level: OpalDiagnostics.Level,
        traceID: OpalDiagnostics.TraceID?,
        fields: [OpalDiagnostics.Field]
    ) {
        guard let routedRecord = currentContext.record(
            event: event,
            category: category,
            level: level,
            traceID: traceID,
            fields: fields
        ) else {
            return
        }

        guard routedRecord.shouldRouteToOSLog else {
            return
        }

        (Self.scopedRecordRouter ?? Self.osLogRecordRouter).route(
            routedRecord.record,
            subsystem: routedRecord.subsystem
        )
    }

    private init() {}
}
