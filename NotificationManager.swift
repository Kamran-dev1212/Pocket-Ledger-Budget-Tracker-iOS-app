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
        content.title = "MyMoney Tracker"
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
