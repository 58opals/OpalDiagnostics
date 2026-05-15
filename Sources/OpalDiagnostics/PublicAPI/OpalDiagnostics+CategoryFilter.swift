// OpalDiagnostics+CategoryFilter.swift

public extension OpalDiagnostics {
    /// Runtime category selection for diagnostics routing.
    enum CategoryFilter: Equatable, Sendable {
        case all
        case enabled(Set<Category>)
        case excluded(Set<Category>)
    }
}

extension OpalDiagnostics.CategoryFilter {
    func allows(_ category: OpalDiagnostics.Category) -> Bool {
        switch self {
        case .all:
            true
        case let .enabled(categories):
            categories.contains(category)
        case let .excluded(categories):
            !categories.contains(category)
        }
    }
}
