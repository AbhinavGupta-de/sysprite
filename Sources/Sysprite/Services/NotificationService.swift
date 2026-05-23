import Foundation
import UserNotifications

final class NotificationService {
    static let shared = NotificationService()
    private var lastAlert: Date = .distantPast
    private let minInterval: TimeInterval = 60

    func requestAuthorization() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound]) { _, _ in }
    }

    func alertHighCPU(percent: Double, threshold: Double) {
        let now = Date()
        guard now.timeIntervalSince(lastAlert) > minInterval else { return }
        lastAlert = now
        let content = UNMutableNotificationContent()
        content.title = "High CPU usage"
        content.body = String(format: "CPU at %.0f%% (threshold %.0f%%)", percent, threshold)
        content.sound = .default
        let req = UNNotificationRequest(identifier: UUID().uuidString, content: content, trigger: nil)
        UNUserNotificationCenter.current().add(req, withCompletionHandler: nil)
    }
}
