// OpalDiagnostics+Configuration.swift

public extension OpalDiagnostics {
    /// Runtime diagnostics settings controlled by the host application.
    struct Configuration: Equatable, Sendable {
        /// A static, non-sensitive OSLog subsystem identifier.
        public var subsystem: String
        public var minimumLevel: Level
        public var categoryFilter: CategoryFilter
        public var bufferPolicy: BufferPolicy
        public var routingPolicy: RoutingPolicy

        public init(
            subsystem: String = "com.58opals.opal",
            minimumLevel: Level = .notice,
            categoryFilter: CategoryFilter = .all,
            bufferPolicy: BufferPolicy = .disabled,
            routingPolicy: RoutingPolicy = .disabled
        ) {
            self.subsystem = subsystem
            self.minimumLevel = minimumLevel
            self.categoryFilter = categoryFilter
            self.bufferPolicy = bufferPolicy
            self.routingPolicy = routingPolicy
        }
    }
}
