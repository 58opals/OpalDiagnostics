// OpalDiagnosticsConcurrencyValidator.swift

import Testing
import OpalDiagnostics

@Suite("OpalDiagnostics concurrency")
struct OpalDiagnosticsConcurrencyValidator {
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

    @Test("task-local trace ID propagates through async work")
    func validateTaskLocalTraceIDPropagatesThroughAsyncWork() async {
        await OpalDiagnostics.withConfiguration(.init(minimumLevel: .debug, bufferPolicy: .enabled(capacity: 10))) {
            let traceID = OpalDiagnostics.TraceID(publicValue: "flow-123")

            await OpalDiagnostics.withTraceID(traceID) {
                #expect(OpalDiagnostics.currentTraceID == traceID)
                await Task.yield()
                OpalDiagnostics.logger(category: .fulcrum).record(event: "fulcrum.connected", level: .debug)
            }

            #expect(OpalDiagnostics.currentTraceID == nil)
            #expect(OpalDiagnostics.recentRecords.map(\.traceID) == [traceID])
        }
    }

    @Test("scoped configuration and trace ID propagate to child tasks")
    func validateScopedConfigurationAndTraceIDPropagateToChildTasks() async {
        await OpalDiagnostics.withConfiguration(.init(minimumLevel: .debug, bufferPolicy: .enabled(capacity: 32))) {
            let traceID = OpalDiagnostics.TraceID(publicValue: "child-flow-123")

            await OpalDiagnostics.withTraceID(traceID) {
                await withTaskGroup(of: Void.self) { group in
                    for index in 0..<32 {
                        group.addTask {
                            OpalDiagnostics.logger(category: .diagnostics).record(
                                event: "diagnostics.child.recorded",
                                level: .debug,
                                fields: [
                                    .init(name: "index", value: index, privacy: .public)
                                ]
                            )
                        }
                    }
                }
            }

            let records = OpalDiagnostics.recentRecords
            let expectedIndexes = Set((0..<32).map(String.init))

            #expect(records.count == 32)
            #expect(Set(records.compactMap { $0.fields.first?.value }) == expectedIndexes)
            #expect(records.allSatisfy { $0.traceID == traceID })
        }
    }
}
