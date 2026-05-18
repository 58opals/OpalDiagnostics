// OpalDiagnostics+Logger.swift

public extension OpalDiagnostics {
    /// Category-bound diagnostics emitter for package call sites.
    struct Logger: Sendable {
        public let category: Category

        init(category: Category) {
            self.category = category
        }

        /// Returns whether records at this level would be retained or routed for this logger category.
        public func isEnabled(level: Level) -> Bool {
            OpalDiagnosticsRuntime.shared.isEnabled(category: category, level: level)
        }

        /// Records a stable event name with optional trace and privacy-marked fields.
        public func record(
            event: Event,
            level: Level = .notice,
            traceID: TraceID? = nil,
            fields: [Field] = []
        ) {
            OpalDiagnosticsRuntime.shared.record(
                event: event,
                category: category,
                level: level,
                traceID: traceID ?? OpalDiagnostics.currentTraceID,
                fields: fields
            )
        }

        /// Records a stable event name with fields built only when diagnostics are enabled.
        public func record(
            event: Event,
            level: Level = .notice,
            traceID: TraceID? = nil,
            fields: () -> [Field]
        ) {
            guard isEnabled(level: level) else {
                return
            }

            let resolvedTraceID = traceID ?? OpalDiagnostics.currentTraceID
            OpalDiagnosticsRuntime.shared.record(
                event: event,
                category: category,
                level: level,
                traceID: resolvedTraceID,
                fields: fields()
            )
        }
    }

    /// Creates a category-bound diagnostics logger.
    static func logger(category: Category) -> Logger {
        Logger(category: category)
    }
}
