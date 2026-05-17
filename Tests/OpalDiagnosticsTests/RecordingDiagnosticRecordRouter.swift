// RecordingDiagnosticRecordRouter.swift

import Foundation
@testable import OpalDiagnostics

final class RecordingDiagnosticRecordRouter: @unchecked Sendable, DiagnosticRecordRouting {
    private let lock = NSLock()
    private var routedRecords: [(record: OpalDiagnostics.Record, subsystem: String)] = []

    var routes: [(record: OpalDiagnostics.Record, subsystem: String)] {
        lock.lock()
        defer { lock.unlock() }
        return routedRecords
    }

    func route(_ record: OpalDiagnostics.Record, subsystem: String) {
        lock.lock()
        routedRecords.append((record, subsystem))
        lock.unlock()
    }
}
