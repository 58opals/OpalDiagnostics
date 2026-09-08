// OpalDiagnosticsSurfaceValidator.swift

import Foundation
import Testing
import OpalDiagnostics

@Suite("OpalDiagnostics public API surface")
struct OpalDiagnosticsSurfaceValidator {
    @Test("Public category values remain stable")
    func validatePublicCategoryValuesRemainStable() {
        let categories: [OpalDiagnostics.Category] = [.diagnostics, .network, .persistence, .security, .base, .crypto, .fusion, .hedge, .fulcrum]

        #expect(categories.map(\.rawValue) == ["diagnostics", "network", "persistence", "security", "base", "crypto", "fusion", "hedge", "fulcrum"])
    }

    @Test("default configuration is public-safe")
    func validateDefaultConfigurationIsPublicSafe() {
        OpalDiagnostics.withConfiguration(.init()) {
            let configuration = OpalDiagnostics.configuration

            #expect(configuration.subsystem == "com.58opals.opal")
            #expect(configuration.minimumLevel == .notice)
            #expect(configuration.categoryFilter == .all)
            #expect(configuration.bufferPolicy == .disabled)
            #expect(configuration.routingPolicy == .disabled)

            OpalDiagnostics.logger(category: .diagnostics).record(event: "diagnostics.default", level: .notice)

            #expect(OpalDiagnostics.recentRecords.isEmpty)
        }
    }

    @Test("buffering is explicit and independent from routing")
    func validateBufferingIsExplicitAndIndependentFromRouting() {
        OpalDiagnostics.withConfiguration(.init(minimumLevel: .debug, bufferPolicy: .disabled, routingPolicy: .disabled)) {
            OpalDiagnostics.logger(category: .diagnostics).record(event: "diagnostics.unbuffered", level: .debug)

            #expect(OpalDiagnostics.recentRecords.isEmpty)
        }

        OpalDiagnostics.withConfiguration(.init(minimumLevel: .debug, bufferPolicy: .enabled(capacity: 10), routingPolicy: .disabled)) {
            OpalDiagnostics.logger(category: .diagnostics).record(event: "diagnostics.buffered", level: .debug)

            #expect(OpalDiagnostics.recentRecords.map(\.event.rawValue) == ["diagnostics.buffered"])
        }
    }

    @Test("level threshold filters routed records")
    func validateLevelThresholdFiltersRoutedRecords() {
        OpalDiagnostics.withConfiguration(.init(minimumLevel: .notice, bufferPolicy: .enabled(capacity: 10))) {
            let logger = OpalDiagnostics.logger(category: .diagnostics)
            #expect(!logger.isEnabled(level: .debug))
            #expect(logger.isEnabled(level: .notice))
            logger.record(event: "diagnostics.debug", level: .debug)
            logger.record(event: "diagnostics.notice", level: .notice)

            #expect(OpalDiagnostics.recentRecords.map(\.event.rawValue) == ["diagnostics.notice"])
        }
    }

    @Test(
        "Category filters preserve exact and dotted boundaries",
        arguments: [
            (OpalDiagnostics.CategoryFilter.enabled([.fulcrum]), ["fulcrum"]),
            (.excluded([.fulcrum]), ["fulcrum.jsonrpc", "fulcrum.websocket", "fulcrum.reconnect", "fulcrumx", "base"]),
            (.enabledIncludingSubcategories([.fulcrum]), ["fulcrum", "fulcrum.jsonrpc", "fulcrum.websocket", "fulcrum.reconnect"]),
            (.excludedIncludingSubcategories([.fulcrum]), ["fulcrumx", "base"])
        ]
    )
    func validateCategoryFilterBoundaries(
        scenario: (filter: OpalDiagnostics.CategoryFilter, expectedCategories: [String])
    ) {
        OpalDiagnostics.withConfiguration(.init(minimumLevel: .debug, categoryFilter: scenario.filter, bufferPolicy: .enabled(capacity: 6))) {
            let categories: [OpalDiagnostics.Category] = [.fulcrum, "fulcrum.jsonrpc", "fulcrum.websocket", "fulcrum.reconnect", "fulcrumx", .base]
            for category in categories {
                OpalDiagnostics.logger(category: category).record(event: "diagnostics.category_filtered", level: .debug)
            }

            #expect(OpalDiagnostics.recentRecords.map(\.category.rawValue) == scenario.expectedCategories)
        }
    }

    @Test("trace ID is retained with records")
    func validateTraceIDIsRetainedWithRecords() {
        OpalDiagnostics.withConfiguration(.init(minimumLevel: .debug, bufferPolicy: .enabled(capacity: 10))) {
            let traceID = OpalDiagnostics.TraceID(publicValue: "trace-123")
            let generatedTraceID = OpalDiagnostics.TraceID()

            OpalDiagnostics.logger(category: .hedge).record(event: "hedge.quoted", level: .debug, traceID: traceID)

            #expect(generatedTraceID.rawValue.isEmpty == false)
            #expect(traceID.rawValue == "trace-123")
            #expect(traceID.description == "trace-123")
            #expect(OpalDiagnostics.recentRecords.first?.traceID == traceID)
        }
    }

    @Test("ring buffer retains recent records within capacity")
    func validateRingBufferRetainsRecentRecordsWithinCapacity() {
        OpalDiagnostics.withConfiguration(.init(minimumLevel: .debug, bufferPolicy: .enabled(capacity: 2))) {
            let logger = OpalDiagnostics.logger(category: .diagnostics)
            logger.record(event: "diagnostics.first", level: .debug)
            logger.record(event: "diagnostics.second", level: .debug)
            logger.record(event: "diagnostics.third", level: .debug)

            #expect(OpalDiagnostics.recentRecords.map(\.event.rawValue) == ["diagnostics.second", "diagnostics.third"])
        }
    }

    @Test("recent records can be cleared")
    func validateRecentRecordsCanBeCleared() {
        OpalDiagnostics.withConfiguration(.init(minimumLevel: .debug, bufferPolicy: .enabled(capacity: 10))) {
            OpalDiagnostics.logger(category: .diagnostics).record(event: "diagnostics.clearable", level: .debug)

            #expect(OpalDiagnostics.recentRecords.isEmpty == false)

            OpalDiagnostics.clearRecentRecords()

            #expect(OpalDiagnostics.recentRecords.isEmpty)
        }
    }

    @Test("configure replaces scoped settings and clears retained records")
    func validateConfigureReplacesScopedSettingsAndClearsRetainedRecords() {
        let replacement = OpalDiagnostics.Configuration(
            subsystem: "com.example.opal.reconfigured",
            minimumLevel: .error,
            categoryFilter: .enabled([.security]),
            bufferPolicy: .enabled(capacity: 2)
        )

        OpalDiagnostics.withConfiguration(.init(minimumLevel: .debug, bufferPolicy: .enabled(capacity: 10))) {
            OpalDiagnostics.logger(category: .diagnostics).record(event: "diagnostics.before_reconfigure", level: .debug)
            #expect(OpalDiagnostics.recentRecords.count == 1)

            OpalDiagnostics.configure(replacement)

            #expect(OpalDiagnostics.configuration == replacement)
            #expect(OpalDiagnostics.recentRecords.isEmpty)
        }
    }

    @Test("recent record queries filter by public dimensions")
    func validateRecentRecordQueriesFilterByPublicDimensions() {
        OpalDiagnostics.withConfiguration(.init(minimumLevel: .debug, bufferPolicy: .enabled(capacity: 10))) {
            let traceID = OpalDiagnostics.TraceID(publicValue: "query-123")
            let startDate = Date()
            let logger = OpalDiagnostics.logger(category: .fulcrum)

            logger.record(event: "fulcrum.connected", level: .debug, traceID: traceID)
            OpalDiagnostics.logger(category: .base).record(event: "base.loaded", level: .error)
            let endDate = Date()

            #expect(OpalDiagnostics.recentRecords(matching: .init(category: .fulcrum)).map(\.event.rawValue) == ["fulcrum.connected"])
            #expect(OpalDiagnostics.recentRecords(matching: .init(level: .error)).map(\.event.rawValue) == ["base.loaded"])
            #expect(OpalDiagnostics.recentRecords(matching: .init(traceID: traceID)).map(\.event.rawValue) == ["fulcrum.connected"])
            #expect(OpalDiagnostics.recentRecords(matching: .init(event: "base.loaded")).map(\.category) == [.base])
            #expect(OpalDiagnostics.recentRecords(matching: .init(from: startDate, through: endDate)).count == 2)
            #expect(OpalDiagnostics.recentRecords(matching: .init(from: Date(timeIntervalSinceNow: 60))).isEmpty)
        }
    }

    @Test("stable event names keep dynamic values in fields")
    func validateStableEventNamesKeepDynamicValuesInFields() {
        OpalDiagnostics.withConfiguration(.init(minimumLevel: .debug, bufferPolicy: .enabled(capacity: 10))) {
            let event = OpalDiagnostics.Event(rawValue: "wallet.action.started")

            OpalDiagnostics.logger(category: .diagnostics).record(
                event: event,
                level: .debug,
                fields: [
                    .init(name: "wallet_id", value: "wallet-123", privacy: .private),
                    .init(name: "action", publicValue: "sync")
                ]
            )

            let record = OpalDiagnostics.recentRecords.first
            #expect(record?.event == event)
            #expect(record?.fields.map(\.name) == ["wallet_id", "action"])
            #expect(record?.fields.map(\.value) == ["<redacted>", "sync"])
        }
    }

    @Test("severity levels are ordered without a warning case")
    func validateSeverityLevelsAreOrderedWithoutWarningCase() {
        let levels = OpalDiagnostics.Level.allCases

        #expect(levels.map(\.rawValue) == ["debug", "info", "notice", "error", "fault"])
        #expect(zip(levels, levels.dropFirst()).allSatisfy { $0 < $1 })
    }
}
