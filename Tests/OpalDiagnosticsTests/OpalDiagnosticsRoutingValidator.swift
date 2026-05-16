// OpalDiagnosticsRoutingValidator.swift

import Testing
@testable import OpalDiagnostics

@Suite("OpalDiagnostics routing")
struct OpalDiagnosticsRoutingValidator {
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
                .init(name: "line", publicValue: "a\nb"),
                .init(name: "empty", publicValue: "")
            ]
        )

        #expect(record.formattedMessage == #"event=diagnostics.message trace_id="trace 1" message="hello world" quote="a \"b\"" line="a\nb" empty="""#)
    }
}
