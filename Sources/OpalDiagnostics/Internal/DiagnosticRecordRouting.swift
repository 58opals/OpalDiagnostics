// DiagnosticRecordRouting.swift

protocol DiagnosticRecordRouting: Sendable {
    func route(_ record: OpalDiagnostics.Record, subsystem: String)
}
