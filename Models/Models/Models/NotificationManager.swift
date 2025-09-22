//
//  NotificationManager.swift
//  GorillaMadnezz
//
//  Handles local notifications, reminders, and achievement alerts
//

import Foundation
import UserNotifications
import Combine

class NotificationManager: ObservableObject {
    @Published var notificationPermission: UNAuthorizationStatus = .notDetermined
    @Published var scheduledNotifications: [ScheduledNotification] = []
    @Published var achievementNotifications: [AchievementNotification] = []
    
    private var cancellables = Set<AnyCancellable>()
    
    init() {
        checkNotificationPermission()
        setupNotificationObservers()
    }
    
    // MARK: - Permission Management
    
    func requestNotificationPermission() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .badge, .sound]) { granted, error in
            DispatchQueue.main.async {
                if granted {
                    self.notificationPermission = .authorized
                    self.scheduleDefaultReminders()
                } else {
                    self.notificationPermission = .denied
                }
            }
        }
    }
    
    private func checkNotificationPermission() {
        UNUserNotificationCenter.current().getNotificationSettings { settings in
            DispatchQueue.main.async {
                self.notificationPermission = settings.authorizationStatus
            }
        }
    }
    
    // MARK: - Workout Reminders
    
    func scheduleWorkoutReminder(title: String, body: String, date: Date, identifier: String) {
        guard notificationPermission == .authorized else { return }
        
        let content = UNMutableNotificationContent()
        content.title = title
        content.body = body
        content.sound = .default
        content.badge = 1
        content.categoryIdentifier = "WORKOUT_REMINDER"
        
        // Add motivational subtitle based on time
        let hour = Calendar.current.component(.hour, from: date)
        switch hour {
        case 6..<12:
            content.subtitle = "Rise and Grind! 💪"
        case 12..<17:
            content.subtitle = "Lunch Break Gains! 🔥"
        case 17..<21:
            content.subtitle = "Evening Power Session! ⚡"
        default:
            content.subtitle = "Late Night Warrior! 🌙"
        }
        
        let calendar = Calendar.current
        let components = calendar.dateComponents([.year, .month, .day, .hour, .minute], from: date)
        let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: false)
        
        let request = UNNotificationRequest(identifier: identifier, content: content, trigger: trigger)
        
        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                print("Error scheduling notification: \(error)")
            } else {
                DispatchQueue.main.async {
                    let scheduled = ScheduledNotification(
                        id: identifier,
                        title: title,
                        body: body,
                        scheduledDate: date,
                        type: .workoutReminder
                    )
                    self.scheduledNotifications.append(scheduled)
                }
            }
        }
    }
    
    func scheduleRecurringWorkoutReminders(days: [Weekday], time: Date) {
        for day in days {
            let identifier = "workout_reminder_\(day.rawValue)"
            let content = UNMutableNotificationContent()
            content.title = "Time to Train! 🦍"
            content.body = "Your \(day.displayName) workout is ready. Let's get those gains!"
            content.sound = .default
            content.categoryIdentifier = "WORKOUT_REMINDER"
            
            var components = DateComponents()
            components.weekday = day.calendarValue
            components.hour = Calendar.current.component(.hour, from: time)
            components.minute = Calendar.current.component(.minute, from: time)
            
            let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: true)
            let request = UNNotificationRequest(identifier: identifier, content: content, trigger: trigger)
            
            UNUserNotificationCenter.current().add(request)
        }
    }
    
    // MARK: - Achievement Notifications
    
    func showAchievementNotification(achievement: Achievement) {
        let notification = AchievementNotification(
            id: UUID().uuidString,
            achievement: achievement,
            timestamp: Date()
        )
        
        achievementNotifications.insert(notification, at: 0)
        
        // Schedule local notification
        let content = UNMutableNotificationContent()
        content.title = "🏆 Achievement Unlocked!"
        content.body = achievement.description
        content.sound = .default
        content.categoryIdentifier = "ACHIEVEMENT"
        
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 1, repeats: false)
        let request = UNNotificationRequest(
            identifier: "achievement_\(notification.id)",
            content: content,
            trigger: trigger
        )
        
        UNUserNotificationCenter.current().add(request)
    }
    
    func showLevelUpNotification(newLevel: Int, newTier: String) {
        let content = UNMutableNotificationContent()
        content.title = "🔥 LEVEL UP! 🔥"
        content.body = "You've reached Level \(newLevel) - \(newTier)!"
        content.subtitle = "Your power grows stronger..."
        content.sound = .default
        content.categoryIdentifier = "LEVEL_UP"
        
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 1, repeats: false)
        let request = UNNotificationRequest(
            identifier: "levelup_\(Date().timeIntervalSince1970)",
            content: content,
            trigger: trigger
        )
        
        UNUserNotificationCenter.current().add(request)
    }
    
    // MARK: - Streak Notifications
    
    func showStreakNotification(streakCount: Int) {
        let content = UNMutableNotificationContent()
        content.title = "🔥 \(streakCount)-Day Streak! 🔥"
        content.body = getStreakMessage(for: streakCount)
        content.sound = .default
        content.categoryIdentifier = "STREAK"
        
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 1, repeats: false)
        let request = UNNotificationRequest(
            identifier: "streak_\(streakCount)",
            content: content,
            trigger: trigger
        )
        
        UNUserNotificationCenter.current().add(request)
    }
    
    // MARK: - Rest Day Reminders
    
    func scheduleRestDayReminder() {
        let content = UNMutableNotificationContent()
        content.title = "Rest Day Warrior 😴"
        content.body = "Recovery is part of the journey. Take today to let your muscles rebuild stronger!"
        content.subtitle = "Even shadows need rest..."
        content.sound = .default
        content.categoryIdentifier = "REST_DAY"
        
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 3600, repeats: false) // 1 hour
        let request = UNNotificationRequest(
            identifier: "rest_day_\(Date().timeIntervalSince1970)",
            content: content,
            trigger: trigger
        )
        
        UNUserNotificationCenter.current().add(request)
    }
    
    // MARK: - Motivational Notifications
    
    func sendMotivationalNotification() {
        let messages = [
            "The shadows grow stronger with each rep! 🌑",
            "Your potential knows no limits! 💪",
            "Rise up, Shadow Monarch! 👑",
            "Every workout brings you closer to greatness! ⚡",
            "The gym awaits your return! 🏋️‍♂️",
            "Your future self is counting on you! 🔥",
            "Unleash the beast within! 🦍"
        ]
        
        let content = UNMutableNotificationContent()
        content.title = "Motivation Incoming! 💪"
        content.body = messages.randomElement() ?? "Keep pushing forward!"
        content.sound = .default
        content.categoryIdentifier = "MOTIVATION"
        
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 1, repeats: false)
        let request = UNNotificationRequest(
            identifier: "motivation_\(Date().timeIntervalSince1970)",
            content: content,
            trigger: trigger
        )
        
        UNUserNotificationCenter.current().add(request)
    }
    
    // MARK: - Notification Management
    
    func cancelNotification(identifier: String) {
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: [identifier])
        scheduledNotifications.removeAll { $0.id == identifier }
    }
    
    func cancelAllNotifications() {
        UNUserNotificationCenter.current().removeAllPendingNotificationRequests()
        scheduledNotifications.removeAll()
    }
    
    func markAchievementAsRead(_ notificationId: String) {
        if let index = achievementNotifications.firstIndex(where: { $0.id == notificationId }) {
            achievementNotifications[index].isRead = true
        }
    }
    
    // MARK: - Private Helpers
    
    private func scheduleDefaultReminders() {
        let defaultDays: [Weekday] = [.monday, .wednesday, .friday]
        let defaultTime = Calendar.current.date(bySettingHour: 18, minute: 0, second: 0, of: Date()) ?? Date()
        scheduleRecurringWorkoutReminders(days: defaultDays, time: defaultTime)
    }
    
    private func getStreakMessage(for count: Int) -> String {
        switch count {
        case 1...3:
            return "You're building momentum! Keep it up!"
        case 4...7:
            return "One week strong! The shadows are impressed!"
        case 8...14:
            return "Two weeks of dedication! Your power grows!"
        case 15...30:
            return "A month of dominance! You're unstoppable!"
        case 31...100:
            return "Shadow Monarch level consistency! 👑"
        default:
            return "You've transcended mortal limits! 🌟"
        }
    }
    
    private func setupNotificationObservers() {
        // Listen for character level ups
        NotificationCenter.default.publisher(for: NSNotification.Name("CharacterLevelUp"))
            .sink { notification in
                if let userInfo = notification.object as? [String: Any],
                   let level = userInfo["level"] as? Int,
                   let tier = userInfo["tier"] as? String {
                    self.showLevelUpNotification(newLevel: level, newTier: tier)
                }
            }
            .store(in: &cancellables)
        
        // Listen for achievement unlocks
        NotificationCenter.default.publisher(for: NSNotification.Name("AchievementUnlocked"))
            .sink { notification in
                if let achievement = notification.object as? Achievement {
                    self.showAchievementNotification(achievement: achievement)
                }
            }
            .store(in: &cancellables)
        
        // Listen for workout streaks
        NotificationCenter.default.publisher(for: NSNotification.Name("WorkoutStreakUpdated"))
            .sink { notification in
                if let userInfo = notification.object as? [String: Any],
                   let streakCount = userInfo["streakCount"] as? Int,
                   streakCount > 0 && streakCount % 7 == 0 { // Celebrate weekly milestones
                    self.showStreakNotification(streakCount: streakCount)
                }
            }
            .store(in: &cancellables)
    }
}

// MARK: - Data Models

struct ScheduledNotification: Identifiable, Codable {
    let id: String
    let title: String
    let body: String
    let scheduledDate: Date
    let type: NotificationType
}

struct AchievementNotification: Identifiable, Codable {
    let id: String
    let achievement: Achievement
    let timestamp: Date
    var isRead: Bool = false
}

enum NotificationType: String, Codable, CaseIterable {
    case workoutReminder = "workout_reminder"
    case achievement = "achievement"
    case levelUp = "level_up"
    case streak = "streak"
    case restDay = "rest_day"
    case motivation = "motivation"
}

enum Weekday: String, CaseIterable {
    case monday = "monday"
    case tuesday = "tuesday"
    case wednesday = "wednesday"
    case thursday = "thursday"
    case friday = "friday"
    case saturday = "saturday"
    case sunday = "sunday"
    
    var displayName: String {
        return rawValue.capitalized
    }
    
    var calendarValue: Int {
        switch self {
        case .sunday: return 1
        case .monday: return 2
        case .tuesday: return 3
        case .wednesday: return 4
        case .thursday: return 5
        case .friday: return 6
        case .saturday: return 7
        }
    }
}

struct Achievement: Identifiable, Codable {
    let id: String
    let title: String
    let description: String
    let icon: String
    let category: AchievementCategory
    let requirement: Int
    let isUnlocked: Bool
}

enum AchievementCategory: String, Codable, CaseIterable {
    case workouts = "workouts"
    case streak = "streak"
    case strength = "strength"
    case social = "social"
    case progress = "progress"
}
