// OpalDiagnostics+Runtime.swift

public extension OpalDiagnostics {
    /// The current runtime diagnostics settings.
    static var configuration: Configuration {
        OpalDiagnosticsRuntime.shared.configuration
    }

    /// Sanitized recent records retained by the current buffer policy.
    static var recentRecords: [Record] {
        OpalDiagnosticsRuntime.shared.recentRecords
    }

    /// Replaces the runtime diagnostics settings and resets the recent-record buffer.
    static func configure(_ configuration: Configuration) {
        OpalDiagnosticsRuntime.shared.configure(configuration)
    }

    /// Clears the retained recent-record buffer.
    static func clearRecentRecords() {
        OpalDiagnosticsRuntime.shared.clearRecentRecords()
    }
}
