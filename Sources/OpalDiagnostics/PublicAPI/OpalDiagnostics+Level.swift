// OpalDiagnostics+Level.swift

public extension OpalDiagnostics {
    /// A diagnostic severity level with threshold ordering.
    ///
    /// There is no separate warning level. Use `.notice` for noteworthy recoverable states and `.error` when an operation failed.
    enum Level: String, CaseIterable, Comparable, Sendable {
        case debug
        case info
        case notice
        case error
        case fault

        public static func < (lhs: Self, rhs: Self) -> Bool {
            lhs.rank < rhs.rank
        }
    }
}

extension OpalDiagnostics.Level {
    private var rank: Int {
        switch self {
        case .debug:
            0
        case .info:
            1
        case .notice:
            2
        case .error:
            3
        case .fault:
            4
        }
    }
}
