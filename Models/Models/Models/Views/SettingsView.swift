import SwiftUI
import UserNotifications

struct SettingsView: View {
    @EnvironmentObject var settingsManager: SettingsManager
    @EnvironmentObject var authManager: AuthenticationManager
    @EnvironmentObject var themeManager: ThemeManager
    @EnvironmentObject var notificationManager: NotificationManager
    @EnvironmentObject var healthManager: HealthManager
    @EnvironmentObject var dataManager: DataManager
    
    @State private var showingProfileEdit = false
    @State private var showingDataExport = false
    @State private var showingDeleteAccount = false
    @State private var showingAbout = false
    @State private var showingSupport = false
    @State private var isHealthKitSyncing = false
    @State private var showingNotificationPermission = false
    
    var body: some View {
        NavigationView {
            List {
                // Profile Section
                profileSection
                
                // Preferences Section
                preferencesSection
                
                // Notifications Section
                notificationsSection
                
                // Health & Fitness Section
                healthFitnessSection
                
                // Data Management Section
                dataManagementSection
                
                // Support & About Section
                supportSection
                
                // Account Section
                accountSection
                
                // App Info
                appInfoSection
            }
            .listStyle(InsetGroupedListStyle())
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        // Handle done if needed
                    }
                    .foregroundColor(themeManager.currentTheme.accentColor)
                }
            }
        }
        .sheet(isPresented: $showingProfileEdit) {
            ProfileEditView()
        }
        .sheet(isPresented: $showingDataExport) {
            DataExportView()
        }
        .sheet(isPresented: $showingAbout) {
            AboutView()
        }
        .sheet(isPresented: $showingSupport) {
            SupportView()
        }
        .alert("Delete Account", isPresented: $showingDeleteAccount) {
            Button("Cancel", role: .cancel) { }
            Button("Delete", role: .destructive) {
                deleteAccount()
            }
        } message: {
            Text("This action cannot be undone. All your data will be permanently deleted.")
        }
        .alert("Enable Notifications", isPresented: $showingNotificationPermission) {
            Button("Cancel", role: .cancel) { }
            Button("Settings") {
                openAppSettings()
            }
        } message: {
            Text("Notifications are disabled. Enable them in Settings to receive workout reminders and achievement alerts.")
        }
    }
    
    // MARK: - Profile Section
    private var profileSection: some View {
        Section {
            HStack(spacing: 16) {
                // Profile Image
                AsyncImage(url: URL(string: authManager.currentUser?.profileImageURL ?? "")) { image in
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                } placeholder: {
                    Circle()
                        .fill(themeManager.currentTheme.accentColor.opacity(0.3))
                        .overlay(
                            Text(authManager.currentUser?.username.prefix(1).uppercased() ?? "U")
                                .font(.title2)
                                .fontWeight(.bold)
                                .foregroundColor(themeManager.currentTheme.accentColor)
                        )
                }
                .frame(width: 60, height: 60)
                .clipShape(Circle())
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(authManager.currentUser?.displayName ?? "Gorilla User")
                        .font(.headline)
                        .foregroundColor(themeManager.currentTheme.primaryTextColor)
                    
                    Text("@\(authManager.currentUser?.username ?? "gorilla")")
                        .font(.subheadline)
                        .foregroundColor(themeManager.currentTheme.secondaryTextColor)
                    
                    HStack(spacing: 12) {
                        Label("Level \(authManager.currentUser?.level ?? 1)", systemImage: "crown.fill")
                            .font(.caption)
                            .foregroundColor(.orange)
                        
                        Label("\(authManager.currentUser?.totalWorkouts ?? 0) workouts", systemImage: "dumbbell.fill")
                            .font(.caption)
                            .foregroundColor(.blue)
                    }
                }
                
                Spacer()
                
                Button("Edit") {
                    showingProfileEdit = true
                }
                .font(.caption)
                .foregroundColor(themeManager.currentTheme.accentColor)
            }
            .padding(.vertical, 8)
        } header: {
            Text("Profile")
        }
    }
    
    // MARK: - Preferences Section
    private var preferencesSection: some View {
        Section {
            // Theme Selection
            NavigationLink(destination: ThemeSelectionView()) {
                HStack {
                    Image(systemName: "paintpalette.fill")
                        .foregroundColor(.purple)
                        .frame(width: 24, height: 24)
                    
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Theme")
                            .foregroundColor(themeManager.currentTheme.primaryTextColor)
                        Text(themeManager.currentTheme.name)
                            .font(.caption)
                            .foregroundColor(themeManager.currentTheme.secondaryTextColor)
                    }
                    
                    Spacer()
                }
            }
            
            // Units
            HStack {
                Image(systemName: "ruler.fill")
                    .foregroundColor(.green)
                    .frame(width: 24, height: 24)
                
                Text("Units")
                    .foregroundColor(themeManager.currentTheme.primaryTextColor)
                
                Spacer()
                
                Picker("Units", selection: $settingsManager.userPreferences.preferredUnits) {
                    ForEach(UnitSystem.allCases, id: \.self) { unit in
                        Text(unit.rawValue).tag(unit)
                    }
                }
                .pickerStyle(MenuPickerStyle())
            }
            
            // Default Workout Duration
            HStack {
                Image(systemName: "clock.fill")
                    .foregroundColor(.blue)
                    .frame(width: 24, height: 24)
                
                Text("Default Workout Duration")
                    .foregroundColor(themeManager.currentTheme.primaryTextColor)
                
                Spacer()
                
                Picker("Duration", selection: $settingsManager.userPreferences.defaultWorkoutDuration) {
                    ForEach([15, 30, 45, 60, 75, 90], id: \.self) { duration in
                        Text("\(duration) min").tag(duration)
                    }
                }
                .pickerStyle(MenuPickerStyle())
            }
            
            // Auto-Start Rest Timers
            HStack {
                Image(systemName: "timer")
                    .foregroundColor(.orange)
                    .frame(width: 24, height: 24)
                
                Text("Auto-Start Rest Timers")
                    .foregroundColor(themeManager.currentTheme.primaryTextColor)
                
                Spacer()
                
                Toggle("", isOn: $settingsManager.userPreferences.autoStartRestTimers)
                    .toggleStyle(SwitchToggleStyle(tint: themeManager.currentTheme.accentColor))
            }
            
            // Show Advanced Stats
            HStack {
                Image(systemName: "chart.line.uptrend.xyaxis")
                    .foregroundColor(.red)
                    .frame(width: 24, height: 24)
                
                Text("Show Advanced Statistics")
                    .foregroundColor(themeManager.currentTheme.primaryTextColor)
                
                Spacer()
                
                Toggle("", isOn: $settingsManager.userPreferences.showAdvancedStats)
                    .toggleStyle(SwitchToggleStyle(tint: themeManager.currentTheme.accentColor))
            }
        } header: {
            Text("Preferences")
        }
    }
    
    // MARK: - Notifications Section
    private var notificationsSection: some View {
        Section {
            // Notification Permission Status
            HStack {
                Image(systemName: "bell.fill")
                    .foregroundColor(.blue)
                    .frame(width: 24, height: 24)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text("Notifications")
                        .foregroundColor(themeManager.currentTheme.primaryTextColor)
                    Text(notificationPermissionStatus)
                        .font(.caption)
                        .foregroundColor(notificationPermissionColor)
                }
                
                Spacer()
                
                if !notificationManager.isPermissionGranted {
                    Button("Enable") {
                        requestNotificationPermission()
                    }
                    .font(.caption)
                    .foregroundColor(themeManager.currentTheme.accentColor)
                }
            }
            
            if notificationManager.isPermissionGranted {
                // Workout Reminders
                HStack {
                    Image(systemName: "dumbbell.fill")
                        .foregroundColor(.green)
                        .frame(width: 24, height: 24)
                    
                    Text("Workout Reminders")
                        .foregroundColor(themeManager.currentTheme.primaryTextColor)
                    
                    Spacer()
                    
                    Toggle("", isOn: $settingsManager.notificationSettings.workoutReminders)
                        .toggleStyle(SwitchToggleStyle(tint: themeManager.currentTheme.accentColor))
                }
                
                // Achievement Notifications
                HStack {
                    Image(systemName: "trophy.fill")
                        .foregroundColor(.yellow)
                        .frame(width: 24, height: 24)
                    
                    Text("Achievement Alerts")
                        .foregroundColor(themeManager.currentTheme.primaryTextColor)
                    
                    Spacer()
                    
                    Toggle("", isOn: $settingsManager.notificationSettings.achievementNotifications)
                        .toggleStyle(SwitchToggleStyle(tint: themeManager.currentTheme.accentColor))
                }
                
                // Friend Activity
                HStack {
                    Image(systemName: "person.2.fill")
                        .foregroundColor(.purple)
                        .frame(width: 24, height: 24)
                    
                    Text("Friend Activity")
                        .foregroundColor(themeManager.currentTheme.primaryTextColor)
                    
                    Spacer()
                    
                    Toggle("", isOn: $settingsManager.notificationSettings.socialNotifications)
                        .toggleStyle(SwitchToggleStyle(tint: themeManager.currentTheme.accentColor))
                }
                
                // Reminder Time
                if settingsManager.notificationSettings.workoutReminders {
                    HStack {
                        Image(systemName: "clock")
                            .foregroundColor(.blue)
                            .frame(width: 24, height: 24)
                        
                        Text("Reminder Time")
                            .foregroundColor(themeManager.currentTheme.primaryTextColor)
                        
                        Spacer()
                        
                        DatePicker("", selection: $settingsManager.notificationSettings.reminderTime, displayedComponents: .hourAndMinute)
                            .labelsHidden()
                    }
                }
            }
        } header: {
            Text("Notifications")
        }
    }
    
    // MARK: - Health & Fitness Section
    private var healthFitnessSection: some View {
        Section {
            // HealthKit Sync
            HStack {
                Image(systemName: "heart.fill")
                    .foregroundColor(.red)
                    .frame(width: 24, height: 24)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text("Health App Sync")
                        .foregroundColor(themeManager.currentTheme.primaryTextColor)
                    Text(healthManager.isAuthorized ? "Connected" : "Not Connected")
                        .font(.caption)
                        .foregroundColor(healthManager.isAuthorized ? .green : .orange)
                }
                
                Spacer()
                
                if isHealthKitSyncing {
                    ProgressView()
                        .scaleEffect(0.8)
                } else {
                    Button(healthManager.isAuthorized ? "Sync Now" : "Connect") {
                        syncHealthKit()
                    }
                    .font(.caption)
                    .foregroundColor(themeManager.currentTheme.accentColor)
                }
            }
            
            if healthManager.isAuthorized {
                // Auto Sync Workouts
                HStack {
                    Image(systemName: "arrow.clockwise")
                        .foregroundColor(.blue)
                        .frame(width: 24, height: 24)
                    
                    Text("Auto-Sync Workouts")
                        .foregroundColor(themeManager.currentTheme.primaryTextColor)
                    
                    Spacer()
                    
                    Toggle("", isOn: $settingsManager.healthSettings.autoSyncWorkouts)
                        .toggleStyle(SwitchToggleStyle(tint: themeManager.currentTheme.accentColor))
                }
                
                // Import Heart Rate
                HStack {
                    Image(systemName: "waveform.path.ecg")
                        .foregroundColor(.red)
                        .frame(width: 24, height: 24)
                    
                    Text("Import Heart Rate Data")
                        .foregroundColor(themeManager.currentTheme.primaryTextColor)
                    
                    Spacer()
                    
                    Toggle("", isOn: $settingsManager.healthSettings.importHeartRate)
                        .toggleStyle(SwitchToggleStyle(tint: themeManager.currentTheme.accentColor))
                }
            }
            
            // Calorie Calculation Method
            HStack {
                Image(systemName: "flame.fill")
                    .foregroundColor(.orange)
                    .frame(width: 24, height: 24)
                
                Text("Calorie Calculation")
                    .foregroundColor(themeManager.currentTheme.primaryTextColor)
                
                Spacer()
                
                Picker("Method", selection: $settingsManager.healthSettings.calorieCalculationMethod) {
                    ForEach(CalorieCalculationMethod.allCases, id: \.self) { method in
                        Text(method.rawValue).tag(method)
                    }
                }
                .pickerStyle(MenuPickerStyle())
            }
        } header: {
            Text("Health & Fitness")
        }
    }
    
    // MARK: - Data Management Section
    private var dataManagementSection: some View {
        Section {
            // Storage Usage
            HStack {
                Image(systemName: "externaldrive.fill")
                    .foregroundColor(.blue)
                    .frame(width: 24, height: 24)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text("Storage Usage")
                        .foregroundColor(themeManager.currentTheme.primaryTextColor)
                    Text(dataManager.storageUsage)
                        .font(.caption)
                        .foregroundColor(themeManager.currentTheme.secondaryTextColor)
                }
                
                Spacer()
            }
            
            // Export Data
            Button(action: { showingDataExport = true }) {
                HStack {
                    Image(systemName: "square.and.arrow.up")
                        .foregroundColor(.green)
                        .frame(width: 24, height: 24)
                    
                    Text("Export Data")
                        .foregroundColor(themeManager.currentTheme.primaryTextColor)
                    
                    Spacer()
                    
                    Image(systemName: "chevron.right")
                        .foregroundColor(themeManager.currentTheme.secondaryTextColor)
                        .font(.caption)
                }
            }
            
            // Clear Cache
            Button(action: clearCache) {
                HStack {
                    Image(systemName: "trash.fill")
                        .foregroundColor(.orange)
                        .frame(width: 24, height: 24)
                    
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Clear Cache")
                            .foregroundColor(themeManager.currentTheme.primaryTextColor)
                        Text("Free up storage space")
                            .font(.caption)
                            .foregroundColor(themeManager.currentTheme.secondaryTextColor)
                    }
                    
                    Spacer()
                }
            }
            
            // Cloud Sync
            HStack {
                Image(systemName: "icloud.fill")
                    .foregroundColor(.blue)
                    .frame(width: 24, height: 24)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text("iCloud Sync")
                        .foregroundColor(themeManager.currentTheme.primaryTextColor)
                    Text(settingsManager.dataSettings.cloudSyncEnabled ? "Enabled" : "Disabled")
                        .font(.caption)
                        .foregroundColor(settingsManager.dataSettings.cloudSyncEnabled ? .green : .orange)
                }
                
                Spacer()
                
                Toggle("", isOn: $settingsManager.dataSettings.cloudSyncEnabled)
                    .toggleStyle(SwitchToggleStyle(tint: themeManager.currentTheme.accentColor))
            }
        } header: {
            Text("Data Management")
        }
    }
    
    // MARK: - Support Section
    private var supportSection: some View {
        Section {
            // Help & Support
            Button(action: { showingSupport = true }) {
                HStack {
                    Image(systemName: "questionmark.circle.fill")
                        .foregroundColor(.blue)
                        .frame(width: 24, height: 24)
                    
                    Text("Help & Support")
                        .foregroundColor(themeManager.currentTheme.primaryTextColor)
                    
                    Spacer()
                    
                    Image(systemName: "chevron.right")
                        .foregroundColor(themeManager.currentTheme.secondaryTextColor)
                        .font(.caption)
                }
            }
            
            // Send Feedback
            Button(action: sendFeedback) {
                HStack {
                    Image(systemName: "envelope.fill")
                        .foregroundColor(.green)
                        .frame(width: 24, height: 24)
                    
                    Text("Send Feedback")
                        .foregroundColor(themeManager.currentTheme.primaryTextColor)
                    
                    Spacer()
                    
                    Image(systemName: "arrow.up.right")
                        .foregroundColor(themeManager.currentTheme.secondaryTextColor)
                        .font(.caption)
                }
            }
            
            // Rate App
            Button(action: rateApp) {
                HStack {
                    Image(systemName: "star.fill")
                        .foregroundColor(.yellow)
                        .frame(width: 24, height: 24)
                    
                    Text("Rate Gorilla Madnezz")
                        .foregroundColor(themeManager.currentTheme.primaryTextColor)
                    
                    Spacer()
                    
                    Image(systemName: "arrow.up.right")
                        .foregroundColor(themeManager.currentTheme.secondaryTextColor)
                        .font(.caption)
                }
            }
            
            // About
            Button(action: { showingAbout = true }) {
                HStack {
                    Image(systemName: "info.circle.fill")
                        .foregroundColor(.blue)
                        .frame(width: 24, height: 24)
                    
                    Text("About")
                        .foregroundColor(themeManager.currentTheme.primaryTextColor)
                    
                    Spacer()
                    
                    Image(systemName: "chevron.right")
                        .foregroundColor(themeManager.currentTheme.secondaryTextColor)
                        .font(.caption)
                }
            }
        } header: {
            Text("Support")
        }
    }
    
    // MARK: - Account Section
    private var accountSection: some View {
        Section {
            // Privacy Settings
            NavigationLink(destination: PrivacySettingsView()) {
                HStack {
                    Image(systemName: "lock.fill")
                        .foregroundColor(.blue)
                        .frame(width: 24, height: 24)
                    
                    Text("Privacy Settings")
                        .foregroundColor(themeManager.currentTheme.primaryTextColor)
                    
                    Spacer()
                }
            }
            
            // Sign Out
            Button(action: signOut) {
                HStack {
                    Image(systemName: "rectangle.portrait.and.arrow.right")
                        .foregroundColor(.orange)
                        .frame(width: 24, height: 24)
                    
                    Text("Sign Out")
                        .foregroundColor(.orange)
                    
                    Spacer()
                }
            }
            
            // Delete Account
            Button(action: { showingDeleteAccount = true }) {
                HStack {
                    Image(systemName: "trash.fill")
                        .foregroundColor(.red)
                        .frame(width: 24, height: 24)
                    
                    Text("Delete Account")
                        .foregroundColor(.red)
                    
                    Spacer()
                }
            }
        } header: {
            Text("Account")
        }
    }
    
    // MARK: - App Info Section
    private var appInfoSection: some View {
        Section {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Gorilla Madnezz")
                        .font(.headline)
                        .foregroundColor(themeManager.currentTheme.primaryTextColor)
                    
                    Text("Version 1.0.0 (Build 1)")
                        .font(.caption)
                        .foregroundColor(themeManager.currentTheme.secondaryTextColor)
                    
                    Text("© 2025 Gorilla Madnezz. All rights reserved.")
                        .font(.caption2)
                        .foregroundColor(themeManager.currentTheme.secondaryTextColor)
                }
                
                Spacer()
                
                Text("🦍")
                    .font(.system(size: 32))
            }
            .padding(.vertical, 8)
        }
    }
    
    // MARK: - Computed Properties
    private var notificationPermissionStatus: String {
        if notificationManager.isPermissionGranted {
            return "Enabled"
        } else {
            return "Disabled"
        }
    }
    
    private var notificationPermissionColor: Color {
        notificationManager.isPermissionGranted ? .green : .orange
    }
    
    // MARK: - Helper Functions
    private func requestNotificationPermission() {
        notificationManager.requestNotificationPermission { granted in
            if !granted {
                DispatchQueue.main.async {
                    showingNotificationPermission = true
                }
            }
        }
    }
    
    private func openAppSettings() {
        if let settingsUrl = URL(string: UIApplication.openSettingsURLString) {
            UIApplication.shared.open(settingsUrl)
        }
    }
    
    private func syncHealthKit() {
        isHealthKitSyncing = true
        
        if healthManager.isAuthorized {
            healthManager.syncAllData()
            DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                isHealthKitSyncing = false
            }
        } else {
            healthManager.requestHealthKitPermission { success in
                DispatchQueue.main.async {
                    isHealthKitSyncing = false
                    if success {
                        healthManager.syncAllData()
                    }
                }
            }
        }
    }
    
    private func clearCache() {
        dataManager.clearCache()
        
        // Show success feedback
        let impact = UIImpactFeedbackGenerator(style: .medium)
        impact.impactOccurred()
    }
    
    private func sendFeedback() {
        if let url = URL(string: "mailto:feedback@gorillamadnezz.com?subject=Gorilla%20Madnezz%20Feedback") {
            UIApplication.shared.open(url)
        }
    }
    
    private func rateApp() {
        if let url = URL(string: "https://apps.apple.com/app/id123456789?action=write-review") {
            UIApplication.shared.open(url)
        }
    }
    
    private func signOut() {
        authManager.signOut()
    }
    
    private func deleteAccount() {
        authManager.deleteAccount { success in
            if success {
                // Account deleted successfully
                print("Account deleted")
            } else {
                // Handle error
                print("Failed to delete account")
            }
        }
    }
}

// MARK: - Supporting Views

struct ThemeSelectionView: View {
    @EnvironmentObject var themeManager: ThemeManager
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        List {
            ForEach(AppTheme.allCases, id: \.self) { theme in
                Button(action: {
                    themeManager.setTheme(theme)
                    dismiss()
                }) {
                    HStack {
                        Circle()
                            .fill(theme.accentColor)
                            .frame(width: 32, height: 32)
                        
                        VStack(alignment: .leading, spacing: 2) {
                            Text(theme.name)
                                .foregroundColor(theme.primaryTextColor)
                                .fontWeight(.medium)
                            
                            Text(theme.description)
                                .font(.caption)
                                .foregroundColor(theme.secondaryTextColor)
                        }
                        
                        Spacer()
                        
                        if themeManager.currentTheme == theme {
                            Image(systemName: "checkmark")
                                .foregroundColor(theme.accentColor)
                                .fontWeight(.bold)
                        }
                    }
                    .padding(.vertical, 4)
                    .background(theme.cardBackgroundColor)
                    .cornerRadius(8)
                }
                .buttonStyle(PlainButtonStyle())
            }
        }
        .navigationTitle("Choose Theme")
        .navigationBarTitleDisplayMode(.inline)
    }
}

struct PrivacySettingsView: View {
    @EnvironmentObject var settingsManager: SettingsManager
    @EnvironmentObject var themeManager: ThemeManager
    
    var body: some View {
        List {
            Section {
                HStack {
                    Text("Profile Visibility")
                        .foregroundColor(themeManager.currentTheme.primaryTextColor)
                    
                    Spacer()
                    
                    Picker("Visibility", selection: $settingsManager.privacySettings.profileVisibility) {
                        ForEach(ProfileVisibility.allCases, id: \.self) { visibility in
                            Text(visibility.rawValue.capitalized).tag(visibility)
                        }
                    }
                    .pickerStyle(MenuPickerStyle())
                }
                
                HStack {
                    Text("Activity Sharing")
                        .foregroundColor(themeManager.currentTheme.primaryTextColor)
                    
                    Spacer()
                    
                    Toggle("", isOn: $settingsManager.privacySettings.allowActivitySharing)
                        .toggleStyle(SwitchToggleStyle(tint: themeManager.currentTheme.accentColor))
                }
                
                HStack {
                    Text("Friend Requests")
                        .foregroundColor(themeManager.currentTheme.primaryTextColor)
                    
                    Spacer()
                    
                    Toggle("", isOn: $settingsManager.privacySettings.allowFriendRequests)
                        .toggleStyle(SwitchToggleStyle(tint: themeManager.currentTheme.accentColor))
                }
                
                HStack {
                    Text("Leaderboard Participation")
                        .foregroundColor(themeManager.currentTheme.primaryTextColor)
                    
                    Spacer()
                    
                    Toggle("", isOn: $settingsManager.privacySettings.participateInLeaderboards)
                        .toggleStyle(SwitchToggleStyle(tint: themeManager.currentTheme.accentColor))
                }
            } header: {
                Text("Social Privacy")
            }
            
            Section {
                HStack {
                    Text("Data Analytics")
                        .foregroundColor(themeManager.currentTheme.primaryTextColor)
                    
                    Spacer()
                    
                    Toggle("", isOn: $settingsManager.privacySettings.allowAnalytics)
                        .toggleStyle(SwitchToggleStyle(tint: themeManager.currentTheme.accentColor))
                }
                
                HStack {
                    Text("Crash Reports")
                        .foregroundColor(themeManager.currentTheme.primaryTextColor)
                    
                    Spacer()
                    
                    Toggle("", isOn: $settingsManager.privacySettings.allowCrashReporting)
                        .toggleStyle(SwitchToggleStyle(tint: themeManager.currentTheme.accentColor))
                }
            } header: {
                Text("Data Collection")
            } footer: {
                Text("This data helps us improve the app and is never shared with third parties.")
                    .font(.caption)
                    .foregroundColor(themeManager.currentTheme.secondaryTextColor)
            }
        }
        .navigationTitle("Privacy Settings")
        .navigationBarTitleDisplayMode(.inline)
    }
}

// MARK: - Preview

#Preview {
    SettingsView()
        .environmentObject(SettingsManager())
        .environmentObject(AuthenticationManager())
        .environmentObject(ThemeManager())
        .environmentObject(NotificationManager())
        .environmentObject(HealthManager())
        .environmentObject(DataManager())
}
