// OpalDiagnostics+TracePropagation.swift

public extension OpalDiagnostics {
    /// Trace ID currently scoped to this task, if one has been installed.
    static var currentTraceID: TraceID? {
        OpalDiagnosticsRuntime.shared.currentTraceID
    }

    /// Runs an operation with a trace ID scoped to the current task and inherited child tasks.
    static func withTraceID<Success>(
        _ traceID: TraceID?,
        operation: () throws -> Success
    ) rethrows -> Success {
        try OpalDiagnosticsRuntime.shared.withTraceID(traceID, operation: operation)
    }

    /// Runs an async operation with a trace ID scoped to the current task and inherited child tasks.
    static func withTraceID<Success>(
        _ traceID: TraceID?,
        operation: () async throws -> Success
    ) async rethrows -> Success {
        try await OpalDiagnosticsRuntime.shared.withTraceID(traceID, operation: operation)
    }
}
