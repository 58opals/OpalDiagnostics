// OpalDiagnosticsSurfaceValidator.swift

import Foundation
import Testing
import OpalDiagnostics

@Suite("OpalDiagnostics public API surface")
struct OpalDiagnosticsSurfaceValidator {
    @Test("public facade is available to package clients")
    func validatePublicFacadeIsAvailableToPackageClients() {
        _ = OpalDiagnostics.self
        _ = OpalDiagnostics.logger(category: .diagnostics)
        _ = OpalDiagnostics.Event(rawValue: "diagnostics.started")
        _ = OpalDiagnostics.ErrorCode(rawValue: "diagnostics.failed")
        _ = OpalDiagnostics.RecordQuery(category: .diagnostics)
        _ = OpalDiagnostics.RoutingPolicy.disabled
        _ = OpalDiagnostics.currentTraceID

        let categories: [OpalDiagnostics.Category] = [.diagnostics, .network, .persistence, .security, .base, .crypto, .fusion, .hedge, .fulcrum]

        #expect(categories.map(\.rawValue) == ["diagnostics", "network", "persistence", "security", "base", "crypto", "fusion", "hedge", "fulcrum"])
    }

    @Test("default configuration is public safe")
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

    @Test("scoped configuration keeps parallel capture isolated")
    func validateScopedConfigurationKeepsParallelCaptureIsolated() async {
        let cryptoTask = Task {
            OpalDiagnostics.withConfiguration(.init(minimumLevel: .debug, categoryFilter: .enabled([.crypto]), bufferPolicy: .enabled(capacity: 10))) {
                OpalDiagnostics.logger(category: .crypto).record(event: "crypto.verified", level: .debug)
                OpalDiagnostics.logger(category: .base).record(event: "base.loaded", level: .debug)
                return OpalDiagnostics.recentRecords.map(\.event.rawValue)
            }
        }
        let baseTask = Task {
            OpalDiagnostics.withConfiguration(.init(minimumLevel: .debug, categoryFilter: .enabled([.base]), bufferPolicy: .enabled(capacity: 10))) {
                OpalDiagnostics.logger(category: .base).record(event: "base.loaded", level: .debug)
                OpalDiagnostics.logger(category: .crypto).record(event: "crypto.verified", level: .debug)
                return OpalDiagnostics.recentRecords.map(\.event.rawValue)
            }
        }

        let cryptoEvents = await cryptoTask.value
        let baseEvents = await baseTask.value

        #expect(cryptoEvents == ["crypto.verified"])
        #expect(baseEvents == ["base.loaded"])
    }

    @Test("level threshold filters routed records")
    func validateLevelThresholdFiltersRoutedRecords() {
        OpalDiagnostics.withConfiguration(.init(minimumLevel: .notice, bufferPolicy: .enabled(capacity: 10))) {
            let logger = OpalDiagnostics.logger(category: .diagnostics)
            logger.record(event: "diagnostics.debug", level: .debug)
            logger.record(event: "diagnostics.notice", level: .notice)

            #expect(OpalDiagnostics.recentRecords.map(\.event.rawValue) == ["diagnostics.notice"])
        }
    }

    @Test("category filters support exact and hierarchical matching")
    func validateCategoryFiltersSupportExactAndHierarchicalMatching() {
        OpalDiagnostics.withConfiguration(.init(minimumLevel: .debug, categoryFilter: .enabled([.fulcrum]), bufferPolicy: .enabled(capacity: 10))) {
            OpalDiagnostics.logger(category: .fulcrum).record(event: "fulcrum.connected", level: .debug)
            OpalDiagnostics.logger(category: "fulcrum.jsonrpc").record(event: "fulcrum.jsonrpc.sent", level: .debug)

            #expect(OpalDiagnostics.recentRecords.map(\.category.rawValue) == ["fulcrum"])
        }

        OpalDiagnostics.withConfiguration(.init(minimumLevel: .debug, categoryFilter: .enabledIncludingSubcategories([.fulcrum]), bufferPolicy: .enabled(capacity: 10))) {
            OpalDiagnostics.logger(category: .fulcrum).record(event: "fulcrum.connected", level: .debug)
            OpalDiagnostics.logger(category: "fulcrum.jsonrpc").record(event: "fulcrum.jsonrpc.sent", level: .debug)
            OpalDiagnostics.logger(category: "fulcrum.websocket").record(event: "fulcrum.websocket.opened", level: .debug)
            OpalDiagnostics.logger(category: "fulcrumx").record(event: "fulcrumx.filtered", level: .debug)

            #expect(OpalDiagnostics.recentRecords.map(\.category.rawValue) == ["fulcrum", "fulcrum.jsonrpc", "fulcrum.websocket"])
        }

        OpalDiagnostics.withConfiguration(.init(minimumLevel: .debug, categoryFilter: .excludedIncludingSubcategories([.fulcrum]), bufferPolicy: .enabled(capacity: 10))) {
            OpalDiagnostics.logger(category: "fulcrum.reconnect").record(event: "fulcrum.reconnect.started", level: .debug)
            OpalDiagnostics.logger(category: .base).record(event: "base.loaded", level: .debug)

            #expect(OpalDiagnostics.recentRecords.map(\.category) == [.base])
        }
    }

    @Test("trace ID is retained with records")
    func validateTraceIDIsRetainedWithRecords() {
        OpalDiagnostics.withConfiguration(.init(minimumLevel: .debug, bufferPolicy: .enabled(capacity: 10))) {
            let traceID = OpalDiagnostics.TraceID(rawValue: "trace-123")
            let generatedTraceID = OpalDiagnostics.TraceID()

            OpalDiagnostics.logger(category: .hedge).record(event: "hedge.quoted", level: .debug, traceID: traceID)

            #expect(generatedTraceID.rawValue.isEmpty == false)
            #expect(OpalDiagnostics.recentRecords.first?.traceID == traceID)
        }
    }

    @Test("task-local trace ID propagates through async work")
    func validateTaskLocalTraceIDPropagatesThroughAsyncWork() async {
        await OpalDiagnostics.withConfiguration(.init(minimumLevel: .debug, bufferPolicy: .enabled(capacity: 10))) {
            let traceID = OpalDiagnostics.TraceID(rawValue: "flow-123")

            await OpalDiagnostics.withTraceID(traceID) {
                #expect(OpalDiagnostics.currentTraceID == traceID)
                await Task.yield()
                OpalDiagnostics.logger(category: .fulcrum).record(event: "fulcrum.connected", level: .debug)
            }

            #expect(OpalDiagnostics.currentTraceID == nil)
            #expect(OpalDiagnostics.recentRecords.map(\.traceID) == [traceID])
        }
    }

    @Test("typed field helpers preserve string storage")
    func validateTypedFieldHelpersPreserveStringStorage() throws {
        let uuid = try #require(UUID(uuidString: "12345678-1234-1234-1234-1234567890AB"))
        let fields: [OpalDiagnostics.Field] = [
            .init(name: "message", publicValue: "connected"),
            .init(name: "attempt", value: 3),
            .init(name: "height", value: UInt64(840_000)),
            .init(name: "cached", value: true),
            .init(name: "request_id", value: uuid),
            .init(name: "elapsed", value: Duration.seconds(2)),
            .init(name: "payload_bytes", byteCount: UInt64(2_048))
        ]

        #expect(fields.map(\.value) == ["connected", "3", "840000", "true", uuid.uuidString, "2s", "2048"])
        #expect(fields.allSatisfy { $0.privacy == .public })
    }

    @Test("error code follows category and event raw value behavior")
    func validateErrorCodeFollowsCategoryAndEventRawValueBehavior() {
        let rawValue = "diagnostics.operation_failed"
        let category: OpalDiagnostics.Category = "diagnostics.operation_failed"
        let event: OpalDiagnostics.Event = "diagnostics.operation_failed"
        let errorCode: OpalDiagnostics.ErrorCode = "diagnostics.operation_failed"

        #expect(errorCode == OpalDiagnostics.ErrorCode(rawValue: rawValue))
        #expect(errorCode.rawValue == rawValue)
        #expect(errorCode.description == rawValue)
        #expect(errorCode.rawValue == category.rawValue)
        #expect(errorCode.description == event.description)
    }

    @Test("error fields use stable public and private privacy defaults")
    func validateErrorFieldsUseStablePublicAndPrivatePrivacyDefaults() {
        let error: Swift.Error = URLError(.badServerResponse)

        let fields: [OpalDiagnostics.Field] = [
            .errorCode(OpalDiagnostics.ErrorCode(rawValue: "diagnostics.operation_failed")),
            .errorCode("diagnostics.raw_operation_failed"),
            .errorType(error),
            .errorMessage("private failure reason")
        ]

        #expect(fields.map(\.name) == ["error_code", "error_code", "error_type", "error_message"])
        #expect(fields.map(\.value) == ["diagnostics.operation_failed", "diagnostics.raw_operation_failed", String(reflecting: Swift.type(of: error)), "private failure reason"])
        #expect(fields.map(\.privacy) == [.public, .public, .public, .private])
    }

    @Test("error messages are redacted before buffering")
    func validateErrorMessagesAreRedactedBeforeBuffering() {
        OpalDiagnostics.withConfiguration(.init(minimumLevel: .debug, bufferPolicy: .enabled(capacity: 10))) {
            OpalDiagnostics.logger(category: .diagnostics).record(
                event: "diagnostics.operation_failed",
                level: .error,
                fields: [
                    .errorCode("diagnostics.operation_failed"),
                    .errorMessage("private failure reason")
                ]
            )

            let fields = OpalDiagnostics.recentRecords.first?.fields
            #expect(fields?.map(\.name) == ["error_code", "error_message"])
            #expect(fields?.map(\.value) == ["diagnostics.operation_failed", "<redacted>"])
            #expect(fields?.map(\.privacy) == [.public, .private])
        }
    }

    @Test("error fields do not change silent default behavior")
    func validateErrorFieldsDoNotChangeSilentDefaultBehavior() {
        OpalDiagnostics.withConfiguration(.init()) {
            OpalDiagnostics.logger(category: .diagnostics).record(
                event: "diagnostics.operation_failed",
                level: .error,
                fields: [
                    .errorCode("diagnostics.operation_failed"),
                    .errorType(URLError(.badServerResponse)),
                    .errorMessage("private failure reason")
                ]
            )

            #expect(OpalDiagnostics.recentRecords.isEmpty)
        }
    }

    @Test("private fields are redacted before buffering")
    func validatePrivateFieldsAreRedactedBeforeBuffering() {
        OpalDiagnostics.withConfiguration(.init(minimumLevel: .debug, bufferPolicy: .enabled(capacity: 10))) {
            OpalDiagnostics.logger(category: .fulcrum).record(
                event: "fulcrum.connected",
                level: .debug,
                fields: [
                    .init(name: "node", publicValue: "testnet"),
                    .init(name: "token", value: "secret-token", privacy: .private)
                ]
            )

            let fields = OpalDiagnostics.recentRecords.first?.fields
            #expect(fields?.map(\.value) == ["testnet", "<redacted>"])
            #expect(fields?.map(\.privacy) == [.public, .private])
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

    @Test("recent record queries filter by public dimensions")
    func validateRecentRecordQueriesFilterByPublicDimensions() {
        OpalDiagnostics.withConfiguration(.init(minimumLevel: .debug, bufferPolicy: .enabled(capacity: 10))) {
            let traceID = OpalDiagnostics.TraceID(rawValue: "query-123")
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

    @Test("warning-like diagnostics map to notice or error")
    func validateWarningLikeDiagnosticsMapToNoticeOrError() {
        #expect(OpalDiagnostics.Level.allCases.map(\.rawValue) == ["debug", "info", "notice", "error", "fault"])
    }
}
