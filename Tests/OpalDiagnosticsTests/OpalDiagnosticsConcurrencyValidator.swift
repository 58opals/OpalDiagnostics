// OpalDiagnosticsConcurrencyValidator.swift

import Testing
import OpalDiagnostics

@Suite("OpalDiagnostics concurrency")
struct OpalDiagnosticsConcurrencyValidator {
    @Test("async trace scope preserves main actor captures and results")
    @MainActor
    func validateAsyncTraceScopePreservesMainActor() async {
        let capture = MutableCapture()
        let traceID = OpalDiagnostics.TraceID(publicValue: "actor-trace")

        let result = await OpalDiagnostics.withTraceID(traceID) {
            MainActor.preconditionIsolated()
            await Task.yield()
            MainActor.preconditionIsolated()
            capture.count += 1
            #expect(OpalDiagnostics.currentTraceID == traceID)
            return capture
        }

        #expect(result === capture)
        #expect(capture.count == 1)
        #expect(OpalDiagnostics.currentTraceID == nil)
    }

    @Test("async configuration scope preserves main actor captures and results")
    @MainActor
    func validateAsyncConfigurationScopePreservesMainActor() async {
        let capture = MutableCapture()
        let previousConfiguration = OpalDiagnostics.configuration
        let configuration = OpalDiagnostics.Configuration(minimumLevel: .debug)

        let result = await OpalDiagnostics.withConfiguration(configuration) {
            MainActor.preconditionIsolated()
            await Task.yield()
            MainActor.preconditionIsolated()
            capture.count += 1
            #expect(OpalDiagnostics.configuration == configuration)
            return capture
        }

        #expect(result === capture)
        #expect(capture.count == 1)
        #expect(OpalDiagnostics.configuration == previousConfiguration)
    }

    @Test("async scopes preserve a custom actor")
    func validateAsyncScopesPreserveCustomActor() async {
        let actor = ScopeActor()
        #expect(await actor.runScopes() == 1)
    }

    @Test("async scopes restore their parent after failure or cancellation", arguments: [false, true])
    func validateAsyncScopesRestoreParentAfterFailure(cancelled: Bool) async {
        await withTaskGroup(of: Void.self) { group in
            if cancelled {
                group.cancelAll()
            }
            group.addTask {
                let initialConfiguration = OpalDiagnostics.configuration
                let initialTraceID = OpalDiagnostics.currentTraceID
                let outerConfiguration = OpalDiagnostics.Configuration(minimumLevel: .debug)
                let outerTraceID = OpalDiagnostics.TraceID(publicValue: "outer-scope")

                await OpalDiagnostics.withConfiguration(outerConfiguration) {
                    await OpalDiagnostics.withTraceID(outerTraceID) {
                        do {
                            try await OpalDiagnostics.withConfiguration(.init(minimumLevel: .error)) {
                                try await OpalDiagnostics.withTraceID(.init(publicValue: "inner-scope")) {
                                    await Task.yield()
                                    try Task.checkCancellation()
                                    throw ScopeFailure()
                                }
                            }
                            Issue.record("The inner operation must throw")
                        } catch {
                            #expect(cancelled ? error is CancellationError : error is ScopeFailure)
                        }

                        #expect(OpalDiagnostics.configuration == outerConfiguration)
                        #expect(OpalDiagnostics.currentTraceID == outerTraceID)
                    }
                }

                #expect(OpalDiagnostics.configuration == initialConfiguration)
                #expect(OpalDiagnostics.currentTraceID == initialTraceID)
            }
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

private extension OpalDiagnosticsConcurrencyValidator {
    final class MutableCapture {
        var count = 0
    }

    struct ScopeFailure: Error {}

    actor ScopeActor {
        private let capture = MutableCapture()

        func runScopes() async -> Int {
            await OpalDiagnostics.withConfiguration(.init()) {
                self.preconditionIsolated()
                await OpalDiagnostics.withTraceID(nil) {
                    self.preconditionIsolated()
                    await Task.yield()
                    self.preconditionIsolated()
                    capture.count += 1
                }
            }
            return capture.count
        }
    }
}
