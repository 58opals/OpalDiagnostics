// OpalDiagnostics+Configuration.swift

public extension OpalDiagnostics {
    /// Runtime diagnostics settings controlled by the host application.
    struct Configuration: Equatable, Sendable {
        public var subsystem: String
        public var minimumLevel: Level
        public var categoryFilter: CategoryFilter
        public var bufferPolicy: BufferPolicy

        public init(
            subsystem: String = "com.58opals.opal",
            minimumLevel: Level = .notice,
            categoryFilter: CategoryFilter = .all,
            bufferPolicy: BufferPolicy = .disabled
        ) {
            self.subsystem = subsystem
            self.minimumLevel = minimumLevel
            self.categoryFilter = categoryFilter
            self.bufferPolicy = bufferPolicy
        }
    }
}
