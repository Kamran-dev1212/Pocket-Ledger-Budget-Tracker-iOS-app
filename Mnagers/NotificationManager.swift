import Foundation
import UserNotifications

final class NotificationManager {

    static let shared = NotificationManager()

    private init() {}

    private let reminderIdentifier = "incomeExpenseReminder"

    // MARK: - Permission (explicit request, returns whether granted)

    func requestPermission() async -> Bool {

        do {

            return try await UNUserNotificationCenter.current().requestAuthorization(
                options: [.alert, .sound, .badge]
            )

        } catch {

            return false

        }

    }

    // MARK: - Permission (used internally by the schedule* methods, unchanged)

    private func requestAuthorizationIfNeeded() {

        UNUserNotificationCenter.current().requestAuthorization(
            options: [.alert, .sound, .badge]
        ) { _, _ in }

    }

    // MARK: - Cancel
    /// Puts the stored reminder choice into effect at launch.
    ///
    /// The picker in Settings schedules on change, which meant a user who
    /// never opened Settings had nothing scheduled at all — the stored
    /// default said Daily and no notification ever arrived. Safe to call
    /// every launch: re-registering the same identifier replaces the
    /// pending request instead of stacking up duplicates.
    func applyStoredFrequency() {

        let stored = UserDefaults.standard
            .string(forKey: "incomeExpenseReminder")

        let frequency = ReminderFrequency(rawValue: stored ?? "") ?? .daily

        switch frequency {

        case .off:
            cancelIncomeExpenseReminder()

        case .daily:
            scheduleDailyReminder(hour: 20, minute: 0)

        case .weekly:
            scheduleWeeklyReminder(weekday: 1, hour: 20, minute: 0)

        case .monthly:
            scheduleMonthlyReminder(day: 1, hour: 20, minute: 0)

        }

    }
    func cancelIncomeExpenseReminder() {

        UNUserNotificationCenter.current().removePendingNotificationRequests(
            withIdentifiers: [reminderIdentifier]
        )

    }

    // MARK: - Daily

    func scheduleDailyReminder(hour: Int, minute: Int) {

        cancelIncomeExpenseReminder()
        requestAuthorizationIfNeeded()

        var dateComponents = DateComponents()
        dateComponents.hour = hour
        dateComponents.minute = minute

        let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: true)

        scheduleRequest(trigger: trigger)

    }

    // MARK: - Weekly

    func scheduleWeeklyReminder(weekday: Int, hour: Int, minute: Int) {

        cancelIncomeExpenseReminder()
        requestAuthorizationIfNeeded()

        var dateComponents = DateComponents()
        dateComponents.weekday = weekday
        dateComponents.hour = hour
        dateComponents.minute = minute

        let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: true)

        scheduleRequest(trigger: trigger)

    }

    // MARK: - Monthly

    func scheduleMonthlyReminder(day: Int, hour: Int, minute: Int) {

        cancelIncomeExpenseReminder()
        requestAuthorizationIfNeeded()

        var dateComponents = DateComponents()
        dateComponents.day = day
        dateComponents.hour = hour
        dateComponents.minute = minute

        let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: true)

        scheduleRequest(trigger: trigger)

    }

    // MARK: - Shared request builder

    private func scheduleRequest(trigger: UNCalendarNotificationTrigger) {

        let content = UNMutableNotificationContent()
        content.title = "Pocket Ledger"
        content.body = "Don't forget to log your income and expenses today."
        content.sound = .default

        let request = UNNotificationRequest(
            identifier: reminderIdentifier,
            content: content,
            trigger: trigger
        )

        UNUserNotificationCenter.current().add(request)

    }

}
