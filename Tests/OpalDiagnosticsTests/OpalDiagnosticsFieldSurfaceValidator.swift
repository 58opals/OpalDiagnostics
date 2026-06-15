// OpalDiagnosticsFieldSurfaceValidator.swift

import Foundation
import Testing
import OpalDiagnostics

@Suite("OpalDiagnostics field public API surface")
struct OpalDiagnosticsFieldSurfaceValidator {
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

    @Test("canonical field helpers make public and private intent explicit")
    func validateCanonicalFieldHelpersMakePublicAndPrivateIntentExplicit() {
        let publicFields: [OpalDiagnostics.Field] = [
            .publicField("network", value: "testnet"),
            .publicField("sync_state", value: "connected"),
            .errorCode("diagnostics.operation_failed"),
            .errorType(URLError(.badServerResponse))
        ]
        let privateFields: [OpalDiagnostics.Field] = [
            .privateField("payload", value: "raw payload"),
            .privateField("secret", value: "secret-token"),
            .privateField("user_chain_identifier", value: "wallet-123"),
            .privateField("endpoint_url", value: "https://node.example.invalid/rpc?token=secret"),
            .privateField("address", value: "bitcoincash:qq1234567890exampleaddressvalue0000000000"),
            .errorMessage("dynamic failure for bitcoincash:qq1234567890exampleaddressvalue0000000000")
        ]

        #expect(publicFields.map(\.privacy) == [.public, .public, .public, .public])
        #expect(publicFields.map(\.redactedValue) == publicFields.map(\.value))
        #expect(privateFields.allSatisfy { $0.privacy == .private })
        #expect(privateFields.map(\.redactedValue) == Array(repeating: "<redacted>", count: privateFields.count))
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
}
