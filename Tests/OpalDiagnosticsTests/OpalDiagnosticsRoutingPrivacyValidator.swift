// OpalDiagnosticsRoutingPrivacyValidator.swift

import Testing
@testable import OpalDiagnostics

@Suite("OpalDiagnostics routing privacy")
struct OpalDiagnosticsRoutingPrivacyValidator {
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

    @Test("representative sensitive fields are redacted before buffering and routing")
    func validateRepresentativeSensitiveFieldsAreRedactedBeforeBufferingAndRouting() throws {
        let router = RecordingDiagnosticRecordRouter()
        let sensitiveValues: [(name: String, value: String)] = [
            ("mnemonic", "abandon ability able about above absent absorb abstract absurd abuse access accident"),
            ("raw_transaction_hex", "0200000001abcdefabcdefabcdefabcdefabcdefabcdefabcdefabcdefabcdefabcdef0000000000ffffffff0100f2052a010000001976a91489abcdefabbaabbaabbaabbaabbaabbaabba88ac00000000"),
            ("script_hex", "76a91489abcdefabbaabbaabbaabbaabbaabbaabba88ac"),
            ("private_key_material", "xprv9s21ZrQH143K3privatekeymaterialthatmustnotescape"),
            ("endpoint_url", "https://node.example.invalid/rpc?api_key=secret-token&wallet=alice"),
            ("address", "bitcoincash:qq1234567890exampleaddressvalue0000000000")
        ]
        let sensitiveFields = sensitiveValues.map { OpalDiagnostics.Field.privateField($0.name, value: $0.value) }
        var retainedRecords: [OpalDiagnostics.Record] = []

        OpalDiagnosticsRuntime.shared.withRecordRouter(router) {
            OpalDiagnostics.withConfiguration(.init(
                subsystem: "com.example.opal.privacy",
                minimumLevel: .debug,
                bufferPolicy: .enabled(capacity: 10),
                routingPolicy: .osLog
            )) {
                OpalDiagnostics.logger(category: .security).record(
                    event: "security.sensitive_values.detected",
                    level: .error,
                    fields: sensitiveFields + [
                        .publicField("network", value: "testnet")
                    ]
                )

                retainedRecords = OpalDiagnostics.recentRecords
            }
        }

        let retainedRecord = try #require(retainedRecords.first)
        let route = try #require(router.routes.first)
        let expectedValues = Array(repeating: "<redacted>", count: sensitiveValues.count) + ["testnet"]

        #expect(retainedRecords.count == 1)
        #expect(router.routes.count == 1)
        #expect(retainedRecord.fields.map(\.value) == expectedValues)
        #expect(route.record.fields.map(\.value) == expectedValues)
        #expect(route.record == retainedRecord)
        #expect(retainedRecord.formattedMessage.contains("network=testnet"))

        for sensitiveValue in sensitiveValues.map(\.value) {
            #expect(retainedRecord.formattedMessage.contains(sensitiveValue) == false)
            #expect(route.record.formattedMessage.contains(sensitiveValue) == false)
        }
    }
}
