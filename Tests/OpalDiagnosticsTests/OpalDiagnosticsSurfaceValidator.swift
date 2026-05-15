// OpalDiagnosticsSurfaceValidator.swift

import Testing
import OpalDiagnostics

@Suite("OpalDiagnostics public API surface", .serialized)
struct OpalDiagnosticsSurfaceValidator {
    @Test("public facade is available to package clients")
    func validatePublicFacadeIsAvailableToPackageClients() {
        _ = OpalDiagnostics.self
        _ = OpalDiagnostics.logger(category: .diagnostics)

        let categories: [OpalDiagnostics.Category] = [
            .diagnostics,
            .network,
            .persistence,
            .security,
            .base,
            .crypto,
            .fusion,
            .hedge,
            .fulcrum
        ]
        #expect(categories.map(\.rawValue) == [
            "diagnostics",
            "network",
            "persistence",
            "security",
            "base",
            "crypto",
            "fusion",
            "hedge",
            "fulcrum"
        ])
    }

    @Test("default configuration is public safe")
    func validateDefaultConfigurationIsPublicSafe() {
        resetDiagnostics()

        let configuration = OpalDiagnostics.configuration

        #expect(configuration.subsystem == "com.58opals.opal")
        #expect(configuration.minimumLevel == .notice)
        #expect(configuration.categoryFilter == .all)
        #expect(configuration.bufferPolicy == .disabled)

        OpalDiagnostics.logger(category: .diagnostics).record("default event", level: .notice)

        #expect(OpalDiagnostics.recentRecords.isEmpty)
    }

    @Test("level threshold filters routed records")
    func validateLevelThresholdFiltersRoutedRecords() {
        resetDiagnostics()
        defer { resetDiagnostics() }

        OpalDiagnostics.configure(.init(minimumLevel: .notice, bufferPolicy: .enabled(capacity: 10)))

        let logger = OpalDiagnostics.logger(category: .diagnostics)
        logger.record("debug event", level: .debug)
        logger.record("notice event", level: .notice)

        #expect(OpalDiagnostics.recentRecords.map(\.message) == ["notice event"])
    }

    @Test("category filter includes and excludes records")
    func validateCategoryFilterIncludesAndExcludesRecords() {
        resetDiagnostics()
        defer { resetDiagnostics() }

        OpalDiagnostics.configure(.init(minimumLevel: .debug, categoryFilter: .enabled([.crypto]), bufferPolicy: .enabled(capacity: 10)))
        OpalDiagnostics.logger(category: .crypto).record("crypto event", level: .debug)
        OpalDiagnostics.logger(category: .base).record("base event", level: .debug)

        #expect(OpalDiagnostics.recentRecords.map(\.category) == [.crypto])

        OpalDiagnostics.configure(.init(minimumLevel: .debug, categoryFilter: .excluded([.security]), bufferPolicy: .enabled(capacity: 10)))
        OpalDiagnostics.logger(category: .security).record("security event", level: .debug)
        OpalDiagnostics.logger(category: .fusion).record("fusion event", level: .debug)

        #expect(OpalDiagnostics.recentRecords.map(\.category) == [.fusion])
    }

    @Test("trace ID is retained with records")
    func validateTraceIDIsRetainedWithRecords() {
        resetDiagnostics()
        defer { resetDiagnostics() }

        let traceID = OpalDiagnostics.TraceID(rawValue: "trace-123")
        let generatedTraceID = OpalDiagnostics.TraceID()
        OpalDiagnostics.configure(.init(minimumLevel: .debug, bufferPolicy: .enabled(capacity: 10)))

        OpalDiagnostics.logger(category: .hedge).record("hedge event", level: .debug, traceID: traceID)

        #expect(generatedTraceID.rawValue.isEmpty == false)
        #expect(OpalDiagnostics.recentRecords.first?.traceID == traceID)
    }

    @Test("private fields are redacted before buffering")
    func validatePrivateFieldsAreRedactedBeforeBuffering() {
        resetDiagnostics()
        defer { resetDiagnostics() }

        OpalDiagnostics.configure(.init(minimumLevel: .debug, bufferPolicy: .enabled(capacity: 10)))

        OpalDiagnostics.logger(category: .fulcrum).record(
            "fulcrum event",
            level: .debug,
            fields: [
                .init(name: "node", value: "testnet", privacy: .public),
                .init(name: "token", value: "secret-token", privacy: .private)
            ]
        )

        let fields = OpalDiagnostics.recentRecords.first?.fields
        #expect(fields?.map(\.value) == ["testnet", "<redacted>"])
        #expect(fields?.map(\.privacy) == [.public, .private])
    }

    @Test("ring buffer retains recent records within capacity")
    func validateRingBufferRetainsRecentRecordsWithinCapacity() {
        resetDiagnostics()
        defer { resetDiagnostics() }

        OpalDiagnostics.configure(.init(minimumLevel: .debug, bufferPolicy: .enabled(capacity: 2)))

        let logger = OpalDiagnostics.logger(category: .diagnostics)
        logger.record("first", level: .debug)
        logger.record("second", level: .debug)
        logger.record("third", level: .debug)

        #expect(OpalDiagnostics.recentRecords.map(\.message) == ["second", "third"])
    }

    @Test("recent records can be cleared")
    func validateRecentRecordsCanBeCleared() {
        resetDiagnostics()
        defer { resetDiagnostics() }

        OpalDiagnostics.configure(.init(minimumLevel: .debug, bufferPolicy: .enabled(capacity: 10)))
        OpalDiagnostics.logger(category: .diagnostics).record("event", level: .debug)

        #expect(OpalDiagnostics.recentRecords.isEmpty == false)

        OpalDiagnostics.clearRecentRecords()

        #expect(OpalDiagnostics.recentRecords.isEmpty)
    }

    private func resetDiagnostics() {
        OpalDiagnostics.configure(.init())
        OpalDiagnostics.clearRecentRecords()
    }
}
