import Foundation
import SwiftData

/// SwiftData writes used to be fire-and-forget — `try? modelContext.save()`
/// — so a failure looked exactly like a success: the screen updated from
/// memory while nothing reached disk, and the change quietly vanished on
/// the next launch.
///
/// This reports failures from anywhere in the app through a single alert,
/// and rolls the change back so what's on screen matches what's stored.
final class SaveReporter: ObservableObject {

    static let shared = SaveReporter()

    private init() {}

    @Published var message: String?

    func save(
        _ context: ModelContext,
        failureMessage: String
    ) {

        do {

            try context.save()

        } catch {

            context.rollback()

            message = "\(failureMessage) Your data hasn't been changed."

        }

    }

}
