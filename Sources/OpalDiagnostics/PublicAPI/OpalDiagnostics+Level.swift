// OpalDiagnostics+Level.swift

import OSLog

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
    var osLogType: OSLogType {
        switch self {
        case .debug:
            .debug
        case .info:
            .info
        case .notice:
            .default
        case .error:
            .error
        case .fault:
            .fault
        }
    }

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
