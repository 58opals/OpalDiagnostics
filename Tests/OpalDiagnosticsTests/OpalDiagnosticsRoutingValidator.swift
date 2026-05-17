// OpalDiagnosticsRoutingValidator.swift

import Foundation
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

    @Test("OSLog routing is explicit and receives sanitized records")
    func validateOSLogRoutingIsExplicitAndReceivesSanitizedRecords() throws {
        let router = RecordingDiagnosticRecordRouter()

        OpalDiagnosticsRuntime.shared.withRecordRouter(router) {
            OpalDiagnostics.withConfiguration(.init(
                subsystem: "com.example.opal.test",
                minimumLevel: .debug,
                bufferPolicy: .disabled,
                routingPolicy: .osLog
            )) {
                OpalDiagnostics.logger(category: .security).record(
                    event: "security.token.rejected",
                    level: .error,
                    fields: [
                        .init(name: "token", value: "secret-token", privacy: .private),
                        .init(name: "reason", publicValue: "expired")
                    ]
                )

                #expect(OpalDiagnostics.recentRecords.isEmpty)
            }
        }

        let route = try #require(router.routes.first)
        #expect(router.routes.count == 1)
        #expect(route.subsystem == "com.example.opal.test")
        #expect(route.record.category == .security)
        #expect(route.record.level == .error)
        #expect(route.record.event == "security.token.rejected")
        #expect(route.record.fields.map(\.value) == ["<redacted>", "expired"])
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
