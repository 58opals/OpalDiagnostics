// OpalDiagnosticsSurfaceValidator.swift

import Testing
import OpalDiagnostics

@Suite("OpalDiagnostics public API surface", .serialized)
struct OpalDiagnosticsSurfaceValidator {
    @Test("public facade is available to package clients")
    func validatePublicFacadeIsAvailableToPackageClients() {
        _ = OpalDiagnostics.self
        _ = OpalDiagnostics.logger(category: .diagnostics)
        _ = OpalDiagnostics.Event(rawValue: "diagnostics.started")

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

        OpalDiagnostics.logger(category: .diagnostics).record(event: "diagnostics.default", level: .notice)

        #expect(OpalDiagnostics.recentRecords.isEmpty)
    }

    @Test("level threshold filters routed records")
    func validateLevelThresholdFiltersRoutedRecords() {
        resetDiagnostics()
        defer { resetDiagnostics() }

        OpalDiagnostics.configure(.init(minimumLevel: .notice, bufferPolicy: .enabled(capacity: 10)))

        let logger = OpalDiagnostics.logger(category: .diagnostics)
        logger.record(event: "diagnostics.debug", level: .debug)
        logger.record(event: "diagnostics.notice", level: .notice)

        #expect(OpalDiagnostics.recentRecords.map(\.event.rawValue) == ["diagnostics.notice"])
    }

    @Test("category filter includes and excludes records")
    func validateCategoryFilterIncludesAndExcludesRecords() {
        resetDiagnostics()
        defer { resetDiagnostics() }

        OpalDiagnostics.configure(.init(minimumLevel: .debug, categoryFilter: .enabled([.crypto]), bufferPolicy: .enabled(capacity: 10)))
        OpalDiagnostics.logger(category: .crypto).record(event: "crypto.verified", level: .debug)
        OpalDiagnostics.logger(category: .base).record(event: "base.loaded", level: .debug)

        #expect(OpalDiagnostics.recentRecords.map(\.category) == [.crypto])

        OpalDiagnostics.configure(.init(minimumLevel: .debug, categoryFilter: .excluded([.security]), bufferPolicy: .enabled(capacity: 10)))
        OpalDiagnostics.logger(category: .security).record(event: "security.filtered", level: .debug)
        OpalDiagnostics.logger(category: .fusion).record(event: "fusion.loaded", level: .debug)

        #expect(OpalDiagnostics.recentRecords.map(\.category) == [.fusion])
    }

    @Test("trace ID is retained with records")
    func validateTraceIDIsRetainedWithRecords() {
        resetDiagnostics()
        defer { resetDiagnostics() }

        let traceID = OpalDiagnostics.TraceID(rawValue: "trace-123")
        let generatedTraceID = OpalDiagnostics.TraceID()
        OpalDiagnostics.configure(.init(minimumLevel: .debug, bufferPolicy: .enabled(capacity: 10)))

        OpalDiagnostics.logger(category: .hedge).record(event: "hedge.quoted", level: .debug, traceID: traceID)

        #expect(generatedTraceID.rawValue.isEmpty == false)
        #expect(OpalDiagnostics.recentRecords.first?.traceID == traceID)
    }

    @Test("private fields are redacted before buffering")
    func validatePrivateFieldsAreRedactedBeforeBuffering() {
        resetDiagnostics()
        defer { resetDiagnostics() }

        OpalDiagnostics.configure(.init(minimumLevel: .debug, bufferPolicy: .enabled(capacity: 10)))

        OpalDiagnostics.logger(category: .fulcrum).record(
            event: "fulcrum.connected",
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
        logger.record(event: "diagnostics.first", level: .debug)
        logger.record(event: "diagnostics.second", level: .debug)
        logger.record(event: "diagnostics.third", level: .debug)

        #expect(OpalDiagnostics.recentRecords.map(\.event.rawValue) == ["diagnostics.second", "diagnostics.third"])
    }

    @Test("recent records can be cleared")
    func validateRecentRecordsCanBeCleared() {
        resetDiagnostics()
        defer { resetDiagnostics() }

        OpalDiagnostics.configure(.init(minimumLevel: .debug, bufferPolicy: .enabled(capacity: 10)))
        OpalDiagnostics.logger(category: .diagnostics).record(event: "diagnostics.clearable", level: .debug)

        #expect(OpalDiagnostics.recentRecords.isEmpty == false)

        OpalDiagnostics.clearRecentRecords()

        #expect(OpalDiagnostics.recentRecords.isEmpty)
    }

    @Test("stable event names keep dynamic values in fields")
    func validateStableEventNamesKeepDynamicValuesInFields() {
        resetDiagnostics()
        defer { resetDiagnostics() }

        let event = OpalDiagnostics.Event(rawValue: "wallet.action.started")
        OpalDiagnostics.configure(.init(minimumLevel: .debug, bufferPolicy: .enabled(capacity: 10)))

        OpalDiagnostics.logger(category: .diagnostics).record(
            event: event,
            level: .debug,
            fields: [
                .init(name: "wallet_id", value: "wallet-123", privacy: .private),
                .init(name: "action", value: "sync", privacy: .public)
            ]
        )

        let record = OpalDiagnostics.recentRecords.first
        #expect(record?.event == event)
        #expect(record?.fields.map(\.name) == ["wallet_id", "action"])
        #expect(record?.fields.map(\.value) == ["<redacted>", "sync"])
    }

    private func resetDiagnostics() {
        OpalDiagnostics.configure(.init())
        OpalDiagnostics.clearRecentRecords()
    }
}
