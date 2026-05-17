// OpalDiagnostics+RoutingPolicy.swift

public extension OpalDiagnostics {
    /// Runtime policy for routing accepted diagnostics to platform logging.
    enum RoutingPolicy: Equatable, Sendable {
        case disabled
        case osLog
    }
}
