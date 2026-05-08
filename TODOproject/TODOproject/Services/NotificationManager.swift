import Foundation
import UserNotifications

final class NotificationManager {
    static let shared = NotificationManager()
    private let maxRemindersPerTask = 8

    private init() {}

    func requestAuthorizationIfNeeded() async {
        let center = UNUserNotificationCenter.current()
        let settings = await center.notificationSettings()

        guard settings.authorizationStatus == .notDetermined else {
            return
        }

        do {
            _ = try await center.requestAuthorization(options: [.alert, .sound, .badge])
        } catch {
            print("Failed to request notification permissions: \(error.localizedDescription)")
        }
    }

    func scheduleTaskReminder(for task: TodoTask) {
        cancelTaskReminder(taskID: task.id)

        guard !task.isCompleted else {
            return
        }

        let dates = buildReminderDates(for: task)
        guard !dates.isEmpty else {
            return
        }

        for (index, date) in dates.enumerated() {
            let content = UNMutableNotificationContent()
            content.title = "Напоминание о задаче"
            content.body = reminderBody(for: task, triggerDate: date)
            content.sound = .default

            let components = Calendar.current.dateComponents(
                [.year, .month, .day, .hour, .minute],
                from: date
            )
            let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: false)
            let request = UNNotificationRequest(
                identifier: notificationID(for: task.id, index: index),
                content: content,
                trigger: trigger
            )

            UNUserNotificationCenter.current().add(request) { error in
                if let error {
                    print("Failed to schedule task reminder: \(error.localizedDescription)")
                }
            }
        }
    }

    func cancelTaskReminder(taskID: UUID) {
        let ids = reminderIDs(for: taskID)
        let center = UNUserNotificationCenter.current()
        center.removePendingNotificationRequests(withIdentifiers: ids)
        center.removeDeliveredNotifications(withIdentifiers: ids)
    }

    private func notificationID(for taskID: UUID, index: Int) -> String {
        "task-reminder-\(taskID.uuidString)-\(index)"
    }

    private func reminderIDs(for taskID: UUID) -> [String] {
        (0..<maxRemindersPerTask).map { notificationID(for: taskID, index: $0) }
    }

    private func buildReminderDates(for task: TodoTask) -> [Date] {
        let now = Date()
        let dueDate = dueAnchorDate(for: task.dueDate)
        guard dueDate > now else { return [] }

        let secondsLeft = dueDate.timeIntervalSince(now)
        let daysLeft = max(1.0, secondsLeft / 86_400.0)

        // Для длинных задач последнее уведомление приходит за 1 день до дедлайна.
        let isLongTask = daysLeft >= 7
        let latestReminderDate = isLongTask
            ? dueDate.addingTimeInterval(-86_400)
            : dueDate.addingTimeInterval(-7_200)

        guard latestReminderDate > now else { return [] }

        // Адаптивный интервал:
        // - короткие задачи: чаще (6-18 часов)
        // - длинные задачи: реже (24-72 часа)
        let intervalSeconds: TimeInterval
        if isLongTask {
            let hours = min(72.0, max(24.0, sqrt(daysLeft) * 18.0))
            intervalSeconds = hours * 3_600
        } else {
            let hours = min(18.0, max(6.0, daysLeft * 6.0))
            intervalSeconds = hours * 3_600
        }

        var reminders: [Date] = []
        var nextDate = alignToDaytime(now.addingTimeInterval(intervalSeconds))

        while nextDate <= latestReminderDate, reminders.count < maxRemindersPerTask - 1 {
            reminders.append(nextDate)
            nextDate = alignToDaytime(nextDate.addingTimeInterval(intervalSeconds))
        }

        // Гарантируем финальное "мягкое" уведомление перед дедлайном.
        let finalReminder = alignToDaytime(latestReminderDate)
        if finalReminder > now,
           reminders.last?.timeIntervalSince(finalReminder) != 0,
           reminders.count < maxRemindersPerTask {
            reminders.append(finalReminder)
        }

        // Убираем дубликаты/прошедшие и сортируем.
        let unique = Array(Set(reminders.filter { $0 > now })).sorted()
        return Array(unique.prefix(maxRemindersPerTask))
    }

    private func dueAnchorDate(for dueDate: Date) -> Date {
        var components = Calendar.current.dateComponents([.year, .month, .day], from: dueDate)
        components.hour = 20
        components.minute = 0
        return Calendar.current.date(from: components) ?? dueDate
    }

    private func alignToDaytime(_ date: Date) -> Date {
        let calendar = Calendar.current
        let hour = calendar.component(.hour, from: date)

        if hour < 10 {
            return calendar.date(bySettingHour: 10, minute: 0, second: 0, of: date) ?? date
        }

        if hour > 20 {
            let nextDay = calendar.date(byAdding: .day, value: 1, to: date) ?? date
            return calendar.date(bySettingHour: 10, minute: 0, second: 0, of: nextDay) ?? nextDay
        }

        return date
    }

    private func reminderBody(for task: TodoTask, triggerDate: Date) -> String {
        let dueDate = dueAnchorDate(for: task.dueDate)
        let days = max(0, Calendar.current.dateComponents([.day], from: triggerDate, to: dueDate).day ?? 0)

        if days == 0 {
            return "Сегодня нужно завершить задачу \"\(task.title)\"."
        } else if days == 1 {
            return "До дедлайна задачи \"\(task.title)\" остался 1 день."
        } else {
            return "До дедлайна задачи \"\(task.title)\" осталось \(days) дн."
        }
    }
}
