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

    /// Runs an async operation on the caller's actor with a trace ID scoped to this task and inherited child tasks.
    static nonisolated(nonsending) func withTraceID<Success>(
        _ traceID: TraceID?,
        operation: nonisolated(nonsending) () async throws -> Success
    ) async rethrows -> Success {
        try await OpalDiagnosticsRuntime.shared.withTraceID(traceID, operation: operation)
    }
}
