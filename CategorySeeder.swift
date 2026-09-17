import Foundation
import SwiftData

/// Turns the built-in categories into real rows the user can rename,
/// re-icon or delete.
///
/// Runs on every launch. The seeding happens once; the de-duplication is
/// what makes it safe — two devices can both seed before CloudKit syncs,
/// and without this you'd end up with two of every default.
enum CategorySeeder {

    static func run(in context: ModelContext) {

        guard let existing = try? context.fetch(FetchDescriptor<UserCategory>()) else {
            return
        }

        if !existing.contains(where: { $0.isDefault }) {
            seedDefaults(into: context)
        }

        removeDuplicates(in: context)

    }

    // MARK: - Seed

    private static func seedDefaults(into context: ModelContext) {

        let builtIns =
            CategoryManager.expenseCategories
            + CategoryManager.incomeCategories

        for builtIn in builtIns {

            context.insert(
                UserCategory(
                    name: builtIn.name,
                    icon: builtIn.icon,
                    type: builtIn.type,
                    isDefault: true,
                    seedKey: builtIn.name
                )
            )

        }

        try? context.save()

    }

    // MARK: - De-duplicate

    /// Matching on seedKey rather than name means a default the user has
    /// since renamed is still recognised as the same category — and the
    /// renamed copy is the one kept.
    private static func removeDuplicates(in context: ModelContext) {

        guard let all = try? context.fetch(FetchDescriptor<UserCategory>()) else {
            return
        }

        let seeded = all.filter { !$0.seedKey.isEmpty }

        let grouped = Dictionary(grouping: seeded) { category in
            "\(category.type)|\(category.seedKey)"
        }

        var didDelete = false

        for (_, duplicates) in grouped where duplicates.count > 1 {

            let keeper = duplicates.first { $0.name != $0.seedKey }
                ?? duplicates[0]

            for duplicate in duplicates where duplicate !== keeper {

                context.delete(duplicate)
                didDelete = true

            }

        }

        if didDelete {
            try? context.save()
        }

    }

}
