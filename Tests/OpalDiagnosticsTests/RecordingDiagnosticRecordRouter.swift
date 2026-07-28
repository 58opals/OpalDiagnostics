// RecordingDiagnosticRecordRouter.swift

import Synchronization
@testable import OpalDiagnostics

final class RecordingDiagnosticRecordRouter: Sendable, DiagnosticRecordRouting {
    private let routedRecords = Mutex<[(record: OpalDiagnostics.Record, subsystem: String)]>([])

    var routes: [(record: OpalDiagnostics.Record, subsystem: String)] {
        routedRecords.withLock { $0 }
    }

    func route(_ record: OpalDiagnostics.Record, subsystem: String) {
        routedRecords.withLock {
            $0.append((record, subsystem))
        }
    }
}
