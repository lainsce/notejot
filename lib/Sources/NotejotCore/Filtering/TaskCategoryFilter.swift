public enum TaskCategoryFilter {
    public static func matching(
        _ categories: [TaskCategory],
        query: String
    ) -> [TaskCategory] {
        guard !query.isEmpty else { return categories }

        return categories.filter { category in
            category.title.localizedStandardContains(query)
                || category.items.contains { $0.text.localizedStandardContains(query) }
        }
    }
}
