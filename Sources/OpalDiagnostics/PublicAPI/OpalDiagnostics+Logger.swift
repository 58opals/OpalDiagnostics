// OpalDiagnostics+Logger.swift

public extension OpalDiagnostics {
    /// Category-bound diagnostics emitter for package call sites.
    struct Logger: Sendable {
        public let category: Category

        init(category: Category) {
            self.category = category
        }

        public func record(
            _ message: String,
            level: Level = .notice,
            traceID: TraceID? = nil,
            fields: [Field] = []
        ) {
            OpalDiagnosticsRuntime.shared.record(
                message,
                category: category,
                level: level,
                traceID: traceID,
                fields: fields
            )
        }
    }

    /// Creates a category-bound diagnostics logger.
    static func logger(category: Category) -> Logger {
        Logger(category: category)
    }
}
