// OpalDiagnosticsRoutingValidator.swift

import Testing
@testable import OpalDiagnostics

@Suite("OpalDiagnostics routing")
struct OpalDiagnosticsRoutingValidator {
    @Test("default configuration does not buffer or route records")
    func validateDefaultConfigurationIsSilent() {
        let router = RecordingDiagnosticRecordRouter()

        OpalDiagnosticsRuntime.shared.withRecordRouter(router) {
            OpalDiagnostics.withConfiguration(.init()) {
                OpalDiagnostics.logger(category: .diagnostics).record(
                    event: "diagnostics.default",
                    level: .fault,
                    fields: [
                        .init(name: "token", value: "secret-token", privacy: .private)
                    ]
                )

                #expect(OpalDiagnostics.recentRecords.isEmpty)
            }
        }

        #expect(router.routes.isEmpty)
    }

    @Test("routing policy honors level and category filters")
    func validateRoutingPolicyHonorsLevelAndCategoryFilters() {
        let router = RecordingDiagnosticRecordRouter()

        OpalDiagnosticsRuntime.shared.withRecordRouter(router) {
            OpalDiagnostics.withConfiguration(.init(
                minimumLevel: .error,
                categoryFilter: .enabled([.security]),
                routingPolicy: .osLog
            )) {
                OpalDiagnostics.logger(category: .security).record(event: "security.notice", level: .notice)
                OpalDiagnostics.logger(category: .base).record(event: "base.error", level: .error)
                OpalDiagnostics.logger(category: .security).record(event: "security.error", level: .error)
            }
        }

        #expect(router.routes.map { $0.record.event.rawValue } == ["security.error"])
    }

    @Test(
        "logger enablement follows recording policies",
        arguments: [
            (OpalDiagnostics.Configuration(minimumLevel: .debug, bufferPolicy: .disabled, routingPolicy: .disabled), OpalDiagnostics.Category.diagnostics, OpalDiagnostics.Level.debug, false),
            (OpalDiagnostics.Configuration(minimumLevel: .notice, bufferPolicy: .enabled(capacity: 10)), OpalDiagnostics.Category.diagnostics, OpalDiagnostics.Level.debug, false),
            (OpalDiagnostics.Configuration(minimumLevel: .notice, bufferPolicy: .enabled(capacity: 10)), OpalDiagnostics.Category.diagnostics, OpalDiagnostics.Level.notice, true),
            (OpalDiagnostics.Configuration(minimumLevel: .debug, categoryFilter: .enabled([.security]), bufferPolicy: .enabled(capacity: 10)), OpalDiagnostics.Category.diagnostics, OpalDiagnostics.Level.error, false),
            (OpalDiagnostics.Configuration(minimumLevel: .debug, categoryFilter: .enabled([.security]), bufferPolicy: .enabled(capacity: 10)), OpalDiagnostics.Category.security, OpalDiagnostics.Level.debug, true),
            (OpalDiagnostics.Configuration(minimumLevel: .debug, bufferPolicy: .enabled(capacity: 0), routingPolicy: .disabled), OpalDiagnostics.Category.diagnostics, OpalDiagnostics.Level.debug, false),
            (OpalDiagnostics.Configuration(minimumLevel: .debug, bufferPolicy: .disabled, routingPolicy: .osLog), OpalDiagnostics.Category.diagnostics, OpalDiagnostics.Level.debug, true)
        ]
    )
    func validateLoggerEnablementFollowsRecordingPolicies(
        scenario: (
            configuration: OpalDiagnostics.Configuration,
            category: OpalDiagnostics.Category,
            level: OpalDiagnostics.Level,
            expectedIsEnabled: Bool
        )
    ) {
        OpalDiagnostics.withConfiguration(scenario.configuration) {
            #expect(OpalDiagnostics.logger(category: scenario.category).isEnabled(level: scenario.level) == scenario.expectedIsEnabled)
        }
    }

    @Test("lazy fields are not evaluated when diagnostics are disabled")
    func validateLazyFieldsAreNotEvaluatedWhenDiagnosticsAreDisabled() {
        var evaluationCount = 0

        func fields() -> [OpalDiagnostics.Field] {
            evaluationCount += 1
            return [.init(name: "payload", publicValue: "built")]
        }

        OpalDiagnostics.withConfiguration(.init()) {
            OpalDiagnostics.logger(category: .diagnostics).record(event: "diagnostics.default", level: .fault, fields: fields)
        }

        OpalDiagnostics.withConfiguration(.init(minimumLevel: .notice, bufferPolicy: .enabled(capacity: 10))) {
            OpalDiagnostics.logger(category: .diagnostics).record(event: "diagnostics.below_level", level: .debug, fields: fields)
        }

        OpalDiagnostics.withConfiguration(.init(minimumLevel: .debug, categoryFilter: .enabled([.security]), bufferPolicy: .enabled(capacity: 10))) {
            OpalDiagnostics.logger(category: .diagnostics).record(event: "diagnostics.filtered", level: .error, fields: fields)
        }

        OpalDiagnostics.withConfiguration(.init(minimumLevel: .debug, bufferPolicy: .disabled, routingPolicy: .disabled)) {
            OpalDiagnostics.logger(category: .diagnostics).record(event: "diagnostics.unrouted", level: .debug, fields: fields)
        }

        #expect(evaluationCount == 0)
    }

    @Test("lazy fields are evaluated for retained and routed records")
    func validateLazyFieldsAreEvaluatedForRetainedAndRoutedRecords() throws {
        let router = RecordingDiagnosticRecordRouter()
        let traceID = OpalDiagnostics.TraceID(rawValue: "lazy-trace")
        var evaluationCount = 0
        var retainedRecords: [OpalDiagnostics.Record] = []

        OpalDiagnosticsRuntime.shared.withRecordRouter(router) {
            OpalDiagnostics.withConfiguration(.init(
                subsystem: "com.example.opal.lazy",
                minimumLevel: .debug,
                bufferPolicy: .enabled(capacity: 10),
                routingPolicy: .osLog
            )) {
                OpalDiagnostics.logger(category: .diagnostics).record(
                    event: "diagnostics.lazy",
                    level: .debug,
                    traceID: traceID,
                    fields: {
                        evaluationCount += 1
                        return [
                            .init(name: "token", value: "secret-token", privacy: .private),
                            .init(name: "payload", publicValue: "built")
                        ]
                    }
                )
                retainedRecords = OpalDiagnostics.recentRecords
            }
        }

        let record = try #require(retainedRecords.first)
        let route = try #require(router.routes.first)
        #expect(evaluationCount == 1)
        #expect(retainedRecords.count == 1)
        #expect(router.routes.count == 1)
        #expect(record.event == "diagnostics.lazy")
        #expect(record.traceID == traceID)
        #expect(record.fields.map(\.value) == ["<redacted>", "built"])
        #expect(route.subsystem == "com.example.opal.lazy")
        #expect(route.record == record)
    }

    @Test("async scoped routing uses the active record router")
    func validateAsyncScopedRoutingUsesActiveRecordRouter() async {
        let router = RecordingDiagnosticRecordRouter()

        await OpalDiagnosticsRuntime.shared.withRecordRouter(router) {
            await OpalDiagnostics.withConfiguration(.init(
                minimumLevel: .debug,
                routingPolicy: .osLog
            )) {
                await Task.yield()
                OpalDiagnostics.logger(category: .fulcrum).record(event: "fulcrum.async.connected", level: .debug)
            }
        }

        #expect(router.routes.map { $0.record.event.rawValue } == ["fulcrum.async.connected"])
    }

    @Test("formatted messages quote event names that would break key-value output")
    func validateFormattedMessagesQuoteUnsafeEventNames() {
        let record = OpalDiagnostics.Record(
            category: .diagnostics,
            level: .debug,
            event: "diagnostics message\nstarted",
            traceID: nil,
            fields: []
        )

        #expect(record.formattedMessage == #"event="diagnostics message\nstarted""#)
    }

    @Test("formatted messages quote values that would break key-value output")
    func validateFormattedMessagesQuoteUnsafeValues() {
        let record = OpalDiagnostics.Record(
            category: .diagnostics,
            level: .debug,
            event: "diagnostics.message",
            traceID: "trace 1",
            fields: [
                .init(name: "message", publicValue: "hello world"),
                .init(name: "quote", publicValue: "a \"b\""),
                .init(name: "crlf", publicValue: "a\r\nb"),
                .init(name: "line", publicValue: "a\nb"),
                .init(name: "line_separator", publicValue: "a\u{2028}b"),
                .init(name: "paragraph_separator", publicValue: "a\u{2029}b"),
                .init(name: "empty", publicValue: "")
            ]
        )

        #expect(record.formattedMessage == #"event=diagnostics.message trace_id="trace 1" message="hello world" quote="a \"b\"" crlf="a\r\nb" line="a\nb" line_separator="a\u{2028}b" paragraph_separator="a\u{2029}b" empty="""#)
    }

    @Test("formatted messages quote field names that would break key-value output")
    func validateFormattedMessagesQuoteUnsafeFieldNames() {
        let record = OpalDiagnostics.Record(
            category: .diagnostics,
            level: .debug,
            event: "diagnostics.message",
            traceID: nil,
            fields: [
                .init(name: "bad name", publicValue: "space"),
                .init(name: "bad=key", publicValue: "equals")
            ]
        )

        #expect(record.formattedMessage == #"event=diagnostics.message "bad name"=space "bad=key"=equals"#)
    }
}
