// RecentDiagnosticRecordBuffer.swift

struct RecentDiagnosticRecordBuffer {
    private let capacity: Int
    private var storedRecords: [OpalDiagnostics.Record] = []

    var records: [OpalDiagnostics.Record] {
        storedRecords
    }

    init(policy: OpalDiagnostics.BufferPolicy) {
        capacity = policy.capacity
    }

    mutating func append(_ record: OpalDiagnostics.Record) {
        guard capacity > 0 else {
            return
        }

        storedRecords.append(record)

        let overflowCount = storedRecords.count - capacity
        if overflowCount > 0 {
            storedRecords.removeFirst(overflowCount)
        }
    }

    mutating func clear() {
        storedRecords.removeAll(keepingCapacity: true)
    }
}
