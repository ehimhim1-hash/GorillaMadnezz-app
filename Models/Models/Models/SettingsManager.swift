//
//  SettingsManager.swift
//  GorillaMadnezz
//
//  Manages app settings, preferences, and user configuration
//

import Foundation
import Combine

class SettingsManager: ObservableObject {
    @Published var userPreferences: UserPreferences
    @Published var notificationSettings: NotificationSettings
    @Published var workoutSettings: WorkoutSettings
    @Published var privacySettings: PrivacySettings
    @Published var appearanceSettings: AppearanceSettings
    @Published var dataSettings: DataSettings
    
    private let userDefaults = UserDefaults.standard
    private var cancellables = Set<AnyCancellable>()
    
    init() {
        // Load saved settings or use defaults
        self.userPreferences = Self.loadUserPreferences()
        self.notificationSettings = Self.loadNotificationSettings()
        self.workoutSettings = Self.loadWorkoutSettings()
        self.privacySettings = Self.loadPrivacySettings()
        self.appearanceSettings = Self.loadAppearanceSettings()
        self.dataSettings = Self.loadDataSettings()
        
        setupAutoSave()
    }
    
    // MARK: - User Preferences
    
    func updateUserProfile(name: String, age: Int, weight: Double, height: Double, fitnessLevel: FitnessLevel) {
        userPreferences.name = name
        userPreferences.age = age
        userPreferences.weight = weight
        userPreferences.height = height
        userPreferences.fitnessLevel = fitnessLevel
        
        saveUserPreferences()
    }
    
    func updateFitnessGoals(_ goals: [FitnessGoal]) {
        userPreferences.fitnessGoals = goals
        saveUserPreferences()
    }
    
    func updatePreferredUnits(_ units: MeasurementUnits) {
        userPreferences.preferredUnits = units
        saveUserPreferences()
        
        // Notify other components about unit change
        NotificationCenter.default.post(
            name: NSNotification.Name("UnitsChanged"),
            object: units
        )
    }
    
    // MARK: - Notification Settings
    
    func updateNotificationSettings(
        workoutReminders: Bool,
        achievementAlerts: Bool,
        socialNotifications: Bool,
        weeklyReports: Bool,
        motivationalMessages: Bool
    ) {
        notificationSettings.workoutReminders = workoutReminders
        notificationSettings.achievementAlerts = achievementAlerts
        notificationSettings.socialNotifications = socialNotifications
        notificationSettings.weeklyReports = weeklyReports
        notificationSettings.motivationalMessages = motivationalMessages
        
        saveNotificationSettings()
        
        // Update system notifications
        NotificationCenter.default.post(
            name: NSNotification.Name("NotificationSettingsChanged"),
            object: notificationSettings
        )
    }
    
    func updateReminderTime(_ time: Date) {
        notificationSettings.reminderTime = time
        saveNotificationSettings()
    }
    
    func updateReminderDays(_ days: [Weekday]) {
        notificationSettings.reminderDays = days
        saveNotificationSettings()
    }
    
    // MARK: - Workout Settings
    
    func updateWorkoutSettings(
        defaultRestTime: Int,
        autoStartTimer: Bool,
        playWorkoutSounds: Bool,
        enableVoiceCoaching: Bool,
        showExerciseVideos: Bool
    ) {
        workoutSettings.defaultRestTime = defaultRestTime
        workoutSettings.autoStartTimer = autoStartTimer
        workoutSettings.playWorkoutSounds = playWorkoutSounds
        workoutSettings.enableVoiceCoaching = enableVoiceCoaching
        workoutSettings.showExerciseVideos = showExerciseVideos
        
        saveWorkoutSettings()
    }
    
    func updatePreferredWorkoutDays(_ days: [Weekday]) {
        workoutSettings.preferredWorkoutDays = days
        saveWorkoutSettings()
    }
    
    func updateWorkoutIntensity(_ intensity: WorkoutIntensity) {
        workoutSettings.defaultIntensity = intensity
        saveWorkoutSettings()
    }
    
    // MARK: - Privacy Settings
    
    func updatePrivacySettings(
        shareProgressWithFriends: Bool,
        allowFriendRequests: Bool,
        showOnlineStatus: Bool,
        shareWorkoutHistory: Bool,
        allowDataAnalytics: Bool
    ) {
        privacySettings.shareProgressWithFriends = shareProgressWithFriends
        privacySettings.allowFriendRequests = allowFriendRequests
        privacySettings.showOnlineStatus = showOnlineStatus
        privacySettings.shareWorkoutHistory = shareWorkoutHistory
        privacySettings.allowDataAnalytics = allowDataAnalytics
        
        savePrivacySettings()
        
        // Notify social manager about privacy changes
        NotificationCenter.default.post(
            name: NSNotification.Name("PrivacySettingsChanged"),
            object: privacySettings
        )
    }
    
    // MARK: - Appearance Settings
    
    func updateAppearanceSettings(
        useSystemTheme: Bool,
        preferredTheme: AppThemeMode,
        enableAnimations: Bool,
        enableHaptics: Bool,
        fontSize: FontSize
    ) {
        appearanceSettings.useSystemTheme = useSystemTheme
        appearanceSettings.preferredTheme = preferredTheme
        appearanceSettings.enableAnimations = enableAnimations
        appearanceSettings.enableHaptics = enableHaptics
        appearanceSettings.fontSize = fontSize
        
        saveAppearanceSettings()
        
        // Notify theme manager
        NotificationCenter.default.post(
            name: NSNotification.Name("AppearanceChanged"),
            object: appearanceSettings
        )
    }
    
    // MARK: - Data Settings
    
    func updateDataSettings(
        enableCloudSync: Bool,
        autoBackup: Bool,
        dataRetentionPeriod: DataRetentionPeriod,
        exportFormat: ExportFormat
    ) {
        dataSettings.enableCloudSync = enableCloudSync
        dataSettings.autoBackup = autoBackup
        dataSettings.dataRetentionPeriod = dataRetentionPeriod
        dataSettings.exportFormat = exportFormat
        
        saveDataSettings()
    }
    
    // MARK: - Data Export/Import
    
    func exportUserData() -> UserDataExport {
        return UserDataExport(
            userPreferences: userPreferences,
            notificationSettings: notificationSettings,
            workoutSettings: workoutSettings,
            privacySettings: privacySettings,
            appearanceSettings: appearanceSettings,
            dataSettings: dataSettings,
            exportDate: Date(),
            appVersion: Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0"
        )
    }
    
    func importUserData(_ data: UserDataExport) {
        userPreferences = data.userPreferences
        notificationSettings = data.notificationSettings
        workoutSettings = data.workoutSettings
        privacySettings = data.privacySettings
        appearanceSettings = data.appearanceSettings
        dataSettings = data.dataSettings
        
        saveAllSettings()
        
        // Notify all components about settings import
        NotificationCenter.default.post(
            name: NSNotification.Name("SettingsImported"),
            object: nil
        )
    }
    
    // MARK: - Reset Functions
    
    func resetToDefaults() {
        userPreferences = UserPreferences()
        notificationSettings = NotificationSettings()
        workoutSettings = WorkoutSettings()
        privacySettings = PrivacySettings()
        appearanceSettings = AppearanceSettings()
        dataSettings = DataSettings()
        
        clearAllStoredSettings()
        saveAllSettings()
    }
    
    func resetWorkoutSettings() {
        workoutSettings = WorkoutSettings()
        saveWorkoutSettings()
    }
    
    func resetNotificationSettings() {
        notificationSettings = NotificationSettings()
        saveNotificationSettings()
    }
    
    // MARK: - Private Helpers
    
    private func setupAutoSave() {
        // Auto-save when settings change
        $userPreferences
            .dropFirst()
            .debounce(for: .seconds(1), scheduler: RunLoop.main)
            .sink { _ in self.saveUserPreferences() }
            .store(in: &cancellables)
        
        $notificationSettings
            .dropFirst()
            .debounce(for: .seconds(1), scheduler: RunLoop.main)
            .sink { _ in self.saveNotificationSettings() }
            .store(in: &cancellables)
        
        $workoutSettings
            .dropFirst()
            .debounce(for: .seconds(1), scheduler: RunLoop.main)
            .sink { _ in self.saveWorkoutSettings() }
            .store(in: &cancellables)
        
        $privacySettings
            .dropFirst()
            .debounce(for: .seconds(1), scheduler: RunLoop.main)
            .sink { _ in self.savePrivacySettings() }
            .store(in: &cancellables)
        
        $appearanceSettings
            .dropFirst()
            .debounce(for: .seconds(1), scheduler: RunLoop.main)
            .sink { _ in self.saveAppearanceSettings() }
            .store(in: &cancellables)
        
        $dataSettings
            .dropFirst()
            .debounce(for: .seconds(1), scheduler: RunLoop.main)
            .sink { _ in self.saveDataSettings() }
            .store(in: &cancellables)
    }
    
    // MARK: - Storage Functions
    
    private func saveAllSettings() {
        saveUserPreferences()
        saveNotificationSettings()
        saveWorkoutSettings()
        savePrivacySettings()
        saveAppearanceSettings()
        saveDataSettings()
    }
    
    private func saveUserPreferences() {
        if let data = try? JSONEncoder().encode(userPreferences) {
            userDefaults.set(data, forKey: "UserPreferences")
        }
    }
    
    private func saveNotificationSettings() {
        if let data = try? JSONEncoder().encode(notificationSettings) {
            userDefaults.set(data, forKey: "NotificationSettings")
        }
    }
    
    private func saveWorkoutSettings() {
        if let data = try? JSONEncoder().encode(workoutSettings) {
            userDefaults.set(data, forKey: "WorkoutSettings")
        }
    }
    
    private func savePrivacySettings() {
        if let data = try? JSONEncoder().encode(privacySettings) {
            userDefaults.set(data, forKey: "PrivacySettings")
        }
    }
    
    private func saveAppearanceSettings() {
        if let data = try? JSONEncoder().encode(appearanceSettings) {
            userDefaults.set(data, forKey: "AppearanceSettings")
        }
    }
    
    private func saveDataSettings() {
        if let data = try? JSONEncoder().encode(dataSettings) {
            userDefaults.set(data, forKey: "DataSettings")
        }
    }
    
    private func clearAllStoredSettings() {
        userDefaults.removeObject(forKey: "UserPreferences")
        userDefaults.removeObject(forKey: "NotificationSettings")
        userDefaults.removeObject(forKey: "WorkoutSettings")
        userDefaults.removeObject(forKey: "PrivacySettings")
        userDefaults.removeObject(forKey: "AppearanceSettings")
        userDefaults.removeObject(forKey: "DataSettings")
    }
    
    // MARK: - Loading Functions
    
    private static func loadUserPreferences() -> UserPreferences {
        guard let data = UserDefaults.standard.data(forKey: "UserPreferences"),
              let preferences = try? JSONDecoder().decode(UserPreferences.self, from: data) else {
            return UserPreferences()
        }
        return preferences
    }
    
    private static func loadNotificationSettings() -> NotificationSettings {
        guard let data = UserDefaults.standard.data(forKey: "NotificationSettings"),
              let settings = try? JSONDecoder().decode(NotificationSettings.self, from: data) else {
            return NotificationSettings()
        }
        return settings
    }
    
    private static func loadWorkoutSettings() -> WorkoutSettings {
        guard let data = UserDefaults.standard.data(forKey: "WorkoutSettings"),
              let settings = try? JSONDecoder().decode(WorkoutSettings.self, from: data) else {
            return WorkoutSettings()
        }
        return settings
    }
    
    private static func loadPrivacySettings() -> PrivacySettings {
        guard let data = UserDefaults.standard.data(forKey: "PrivacySettings"),
              let settings = try? JSONDecoder().decode(PrivacySettings.self, from: data) else {
            return PrivacySettings()
        }
        return settings
    }
    
    private static func loadAppearanceSettings() -> AppearanceSettings {
        guard let data = UserDefaults.standard.data(forKey: "AppearanceSettings"),
              let settings = try? JSONDecoder().decode(AppearanceSettings.self, from: data) else {
            return AppearanceSettings()
        }
        return settings
    }
    
    private static func loadDataSettings() -> DataSettings {
        guard let data = UserDefaults.standard.data(forKey: "DataSettings"),
              let settings = try? JSONDecoder().decode(DataSettings.self, from: data) else {
            return DataSettings()
        }
        return settings
    }
}

// MARK: - Data Models

struct UserPreferences: Codable {
    var name: String = ""
    var age: Int = 25
    var weight: Double = 150.0 // lbs
    var height: Double = 70.0 // inches
    var fitnessLevel: FitnessLevel = .intermediate
    var fitnessGoals: [FitnessGoal] = [.buildMuscle, .loseWeight]
    var preferredUnits: MeasurementUnits = .imperial
    var gymLocation: String = ""
    var trainingExperience: Int = 2 // years
}

struct NotificationSettings: Codable {
    var workoutReminders: Bool = true
    var achievementAlerts: Bool = true
    var socialNotifications: Bool = true
    var weeklyReports: Bool = true
    var motivationalMessages: Bool = true
    var reminderTime: Date = Calendar.current.date(bySettingHour: 18, minute: 0, second: 0, of: Date()) ?? Date()
    var reminderDays: [Weekday] = [.monday, .wednesday, .friday]
    var soundEnabled: Bool = true
    var vibrationEnabled: Bool = true
}

struct WorkoutSettings: Codable {
    var defaultRestTime: Int = 90 // seconds
    var autoStartTimer: Bool = true
    var playWorkoutSounds: Bool = true
    var enableVoiceCoaching: Bool = false
    var showExerciseVideos: Bool = true
    var preferredWorkoutDays: [Weekday] = [.monday, .wednesday, .friday]
    var defaultIntensity: WorkoutIntensity = .moderate
    var warmupDuration: Int = 10 // minutes
    var cooldownDuration: Int = 5 // minutes
}

struct PrivacySettings: Codable {
    var shareProgressWithFriends: Bool = true
    var allowFriendRequests: Bool = true
    var showOnlineStatus: Bool = true
    var shareWorkoutHistory: Bool = false
    var allowDataAnalytics: Bool = true
    var enableCrashReporting: Bool = true
    var shareLocationForWorkouts: Bool = false
}

struct AppearanceSettings: Codable {
    var useSystemTheme: Bool = true
    var preferredTheme: AppThemeMode = .system
    var enableAnimations: Bool = true
    var enableHaptics: Bool = true
    var fontSize: FontSize = .medium
    var enableReducedMotion: Bool = false
    var highContrastMode: Bool = false
}

struct DataSettings: Codable {
    var enableCloudSync: Bool = true
    var autoBackup: Bool = true
    var dataRetentionPeriod: DataRetentionPeriod = .oneYear
    var exportFormat: ExportFormat = .json
    var enableOfflineMode: Bool = true
    var dataCachingEnabled: Bool = true
}

struct UserDataExport: Codable {
    let userPreferences: UserPreferences
    let notificationSettings: NotificationSettings
    let workoutSettings: WorkoutSettings
    let privacySettings: PrivacySettings
    let appearanceSettings: AppearanceSettings
    let dataSettings: DataSettings
    let exportDate: Date
    let appVersion: String
}

// MARK: - Enums

enum FitnessLevel: String, Codable, CaseIterable {
    case beginner = "beginner"
    case intermediate = "intermediate"
    case advanced = "advanced"
    case expert = "expert"
    
    var displayName: String {
        return rawValue.capitalized
    }
}

enum FitnessGoal: String, Codable, CaseIterable {
    case buildMuscle = "build_muscle"
    case loseWeight = "lose_weight"
    case improveEndurance = "improve_endurance"
    case increaseStrength = "increase_strength"
    case improveFlexibility = "improve_flexibility"
    case maintainFitness = "maintain_fitness"
    
    var displayName: String {
        switch self {
        case .buildMuscle: return "Build Muscle"
        case .loseWeight: return "Lose Weight"
        case .improveEndurance: return "Improve Endurance"
        case .increaseStrength: return "Increase Strength"
        case .improveFlexibility: return "Improve Flexibility"
        case .maintainFitness: return "Maintain Fitness"
        }
    }
}

enum MeasurementUnits: String, Codable, CaseIterable {
    case imperial = "imperial" // lbs, inches, feet
    case metric = "metric" // kg, cm, meters
    
    var displayName: String {
        switch self {
        case .imperial: return "Imperial (lbs, ft/in)"
        case .metric: return "Metric (kg, cm)"
        }
    }
}

enum WorkoutIntensity: String, Codable, CaseIterable {
    case light = "light"
    case moderate = "moderate"
    case high = "high"
    case extreme = "extreme"
    
    var displayName: String {
        return rawValue.capitalized
    }
}

enum AppThemeMode: String, Codable, CaseIterable {
    case system = "system"
    case light = "light"
    case dark = "dark"
    
    var displayName: String {
        return rawValue.capitalized
    }
}

enum FontSize: String, Codable, CaseIterable {
    case small = "small"
    case medium = "medium"
    case large = "large"
    case extraLarge = "extra_large"
    
    var displayName: String {
        switch self {
        case .extraLarge: return "Extra Large"
        default: return rawValue.capitalized
        }
    }
}

enum DataRetentionPeriod: String, Codable, CaseIterable {
    case oneMonth = "one_month"
    case threeMonths = "three_months"
    case sixMonths = "six_months"
    case oneYear = "one_year"
    case forever = "forever"
    
    var displayName: String {
        switch self {
        case .oneMonth: return "1 Month"
        case .threeMonths: return "3 Months"
        case .sixMonths: return "6 Months"
        case .oneYear: return "1 Year"
        case .forever: return "Forever"
        }
    }
}

enum ExportFormat: String, Codable, CaseIterable {
    case json = "json"
    case csv = "csv"
    case pdf = "pdf"
    
    var displayName: String {
        return rawValue.uppercased()
    }
}
