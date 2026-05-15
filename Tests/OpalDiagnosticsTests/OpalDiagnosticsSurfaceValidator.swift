// OpalDiagnosticsSurfaceValidator.swift

import Testing
import OpalDiagnostics

@Suite("OpalDiagnostics public API surface")
struct OpalDiagnosticsSurfaceValidator {
    @Test("public facade is available to package clients")
    func validatePublicFacadeIsAvailableToPackageClients() {
        _ = OpalDiagnostics.self
    }
}
