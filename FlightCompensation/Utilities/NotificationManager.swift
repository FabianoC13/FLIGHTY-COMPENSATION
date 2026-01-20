import Foundation
import UserNotifications

final class NotificationManager {
    static let shared = NotificationManager()
    private init() {}

    func requestAuthorization(completion: @escaping (Bool) -> Void) {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { granted, _ in
            completion(granted)
        }
    }

    func scheduleLocalNotification(title: String, body: String, id: String = UUID().uuidString, secondsDelay: TimeInterval = 1) {
        let content = UNMutableNotificationContent()
        content.title = title
        content.body = body
        content.sound = .default

        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: max(1, secondsDelay), repeats: false)
        let request = UNNotificationRequest(identifier: id, content: content, trigger: trigger)

        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                print("❌ Failed to schedule notification: \(error.localizedDescription)")
            } else {
                print("✅ Scheduled notification: \(title)")
            }
        }
    }
    
    // MARK: - Payout Notifications
    
    /// Notify user that their payout has been initiated
    func notifyPayoutSent(amount: Double, claimReference: String) {
        scheduleLocalNotification(
            title: "💸 Payment Sent!",
            body: "Your compensation of €\(String(format: "%.2f", amount)) has been sent to your bank account.",
            id: "payout-sent-\(claimReference)"
        )
    }
    
    /// Notify user that their payout has settled
    func notifyPayoutSettled(amount: Double, claimReference: String) {
        scheduleLocalNotification(
            title: "✅ Payment Complete!",
            body: "€\(String(format: "%.2f", amount)) has arrived in your bank account.",
            id: "payout-settled-\(claimReference)"
        )
    }
    
    /// Notify user that their payout failed
    func notifyPayoutFailed(claimReference: String, reason: String? = nil) {
        let message = reason ?? "Please verify your bank details in the app."
        scheduleLocalNotification(
            title: "⚠️ Payment Issue",
            body: "There was an issue with your payment. \(message)",
            id: "payout-failed-\(claimReference)"
        )
    }
    
    /// Notify user that AESA funds were received
    func notifyFundsReceived(amount: Double, claimReference: String) {
        scheduleLocalNotification(
            title: "🎉 Compensation Received!",
            body: "We've received €\(String(format: "%.2f", amount)) for your claim. Payout coming within 48 hours!",
            id: "funds-received-\(claimReference)"
        )
    }
    
    /// Remind user to add bank details
    func remindBankDetails(claimReference: String) {
        scheduleLocalNotification(
            title: "📝 Add Bank Details",
            body: "Add your bank details now so we can send your compensation as soon as it arrives.",
            id: "bank-reminder-\(claimReference)",
            secondsDelay: 86400 // 24 hours
        )
    }
}
