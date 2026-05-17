// OSLogDiagnosticRecordRouter.swift

import OSLog

struct OSLogDiagnosticRecordRouter: DiagnosticRecordRouting {
    func route(_ record: OpalDiagnostics.Record, subsystem: String) {
        let logger = Logger(subsystem: subsystem, category: record.category.rawValue)
        logger.log(level: record.level.osLogType, "\(record.formattedMessage, privacy: .public)")
    }
}

private extension OpalDiagnostics.Level {
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
}
