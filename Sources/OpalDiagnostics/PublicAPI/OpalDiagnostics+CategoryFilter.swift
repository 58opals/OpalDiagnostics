// OpalDiagnostics+CategoryFilter.swift

public extension OpalDiagnostics {
    /// Runtime category selection for diagnostics routing.
    enum CategoryFilter: Equatable, Sendable {
        case all
        case enabled(Set<Category>)
        /// Enables exact categories and their dotted subcategories.
        case enabledIncludingSubcategories(Set<Category>)
        case excluded(Set<Category>)
        /// Excludes exact categories and their dotted subcategories.
        case excludedIncludingSubcategories(Set<Category>)
    }
}

extension OpalDiagnostics.CategoryFilter {
    func allows(_ category: OpalDiagnostics.Category) -> Bool {
        switch self {
        case .all:
            true
        case let .enabled(categories):
            categories.contains(category)
        case let .enabledIncludingSubcategories(categories):
            categories.contains { category.isEqualToOrSubcategory(of: $0) }
        case let .excluded(categories):
            !categories.contains(category)
        case let .excludedIncludingSubcategories(categories):
            !categories.contains { category.isEqualToOrSubcategory(of: $0) }
        }
    }
}

private extension OpalDiagnostics.Category {
    func isEqualToOrSubcategory(of category: Self) -> Bool {
        rawValue == category.rawValue || (category.rawValue.isEmpty == false && rawValue.hasPrefix("\(category.rawValue)."))
    }
}
