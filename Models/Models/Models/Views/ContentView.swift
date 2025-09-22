//
//  ContentView.swift
//  GorillaMadnezz
//
//  Main content view - the home dashboard of the app
//

import SwiftUI

struct ContentView: View {
    @EnvironmentObject var characterManager: CharacterManager
    @EnvironmentObject var themeManager: ThemeManager
    @EnvironmentObject var workoutManager: WorkoutManager
    @EnvironmentObject var progressManager: ProgressManager
    @EnvironmentObject var socialManager: SocialManager
    @EnvironmentObject var healthManager: HealthManager
    @EnvironmentObject var notificationManager: NotificationManager
    
    @State private var selectedTab = 0
    @State private var showQuickWorkout = false
    @State private var showProfile = false
    
    var body: some View {
        ZStack {
            // Dynamic background based on character tier
            themeManager.currentTheme.backgroundColor
                .ignoresSafeArea()
            
            TabView(selection: $selectedTab) {
                // Home Dashboard
                HomeView()
                    .tabItem {
                        Image(systemName: "house.fill")
                        Text("Home")
                    }
                    .tag(0)
                
                // Workouts
                WorkoutListView()
                    .tabItem {
                        Image(systemName: "dumbbell.fill")
                        Text("Workouts")
                    }
                    .tag(1)
                
                // Progress
                ProgressView()
                    .tabItem {
                        Image(systemName: "chart.line.uptrend.xyaxis")
                        Text("Progress")
                    }
                    .tag(2)
                
                // Social
                SocialView()
                    .tabItem {
                        Image(systemName: "person.2.fill")
                        Text("Social")
                    }
                    .tag(3)
                
                // Settings
                SettingsView()
                    .tabItem {
                        Image(systemName: "gearshape.fill")
                        Text("Settings")
                    }
                    .tag(4)
            }
            .accentColor(themeManager.currentTheme.primaryColor)
            
            // Floating Action Button for Quick Workout
            VStack {
                Spacer()
                HStack {
                    Spacer()
                    Button(action: {
                        showQuickWorkout = true
                    }) {
                        ZStack {
                            Circle()
                                .fill(themeManager.currentTheme.accentColor)
                                .frame(width: 60, height: 60)
                                .shadow(color: .black.opacity(0.3), radius: 8, x: 0, y: 4)
                            
                            Image(systemName: "bolt.fill")
                                .font(.title2)
                                .foregroundColor(.white)
                        }
                    }
                    .padding(.trailing, 20)
                    .padding(.bottom, 90) // Above tab bar
                }
            }
        }
        .onAppear {
            setupAppearance()
        }
        .sheet(isPresented: $showQuickWorkout) {
            QuickWorkoutView()
        }
        .sheet(isPresented: $showProfile) {
            ProfileView()
        }
    }
    
    private func setupAppearance() {
        // Customize tab bar appearance
        let appearance = UITabBarAppearance()
        appearance.configureWithOpaqueBackground()
        appearance.backgroundColor = UIColor(themeManager.currentTheme.surfaceColor)
        
        UITabBar.appearance().standardAppearance = appearance
        UITabBar.appearance().scrollEdgeAppearance = appearance
    }
}

// MARK: - Home Dashboard View
struct HomeView: View {
    @EnvironmentObject var characterManager: CharacterManager
    @EnvironmentObject var themeManager: ThemeManager
    @EnvironmentObject var workoutManager: WorkoutManager
    @EnvironmentObject var progressManager: ProgressManager
    @EnvironmentObject var healthManager: HealthManager
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    // Welcome Header
                    welcomeHeader
                    
                    // Character Status Card
                    characterStatusCard
                    
                    // Quick Stats Row
                    quickStatsRow
                    
                    // Today's Workout Card
                    todaysWorkoutCard
                    
                    // Recent Activity
                    recentActivityCard
                    
                    // Health Summary
                    healthSummaryCard
                    
                    Spacer(minLength: 100) // Space for floating button
                }
                .padding()
            }
            .navigationTitle("Gorilla Madnezz")
            .navigationBarTitleDisplayMode(.large)
            .refreshable {
                await refreshData()
            }
        }
    }
    
    // MARK: - UI Components
    
    private var welcomeHeader: some View {
        HStack {
            VStack(alignment: .leading) {
                Text("Welcome back,")
                    .font(.title2)
                    .foregroundColor(themeManager.currentTheme.textColor)
                
                Text("Shadow Warrior")
                    .font(.title)
                    .fontWeight(.bold)
                    .foregroundColor(themeManager.currentTheme.primaryColor)
            }
            
            Spacer()
            
            Button(action: {
                // Show profile
            }) {
                ZStack {
                    Circle()
                        .fill(themeManager.currentTheme.primaryColor)
                        .frame(width: 50, height: 50)
                    
                    Text(characterManager.getTierEmoji())
                        .font(.title2)
                }
            }
        }
    }
    
    private var characterStatusCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Character Status")
                    .font(.headline)
                    .foregroundColor(themeManager.currentTheme.textColor)
                
                Spacer()
                
                Text(characterManager.currentTier.displayName)
                    .font(.caption)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(themeManager.currentTheme.primaryColor.opacity(0.2))
                    .cornerRadius(8)
                    .foregroundColor(themeManager.currentTheme.primaryColor)
            }
            
            // Level Progress
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text("Level \(characterManager.level)")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(themeManager.currentTheme.primaryColor)
                    
                    Spacer()
                    
                    Text("\(characterManager.currentXP)/\(characterManager.xpForNextLevel) XP")
                        .font(.caption)
                        .foregroundColor(themeManager.currentTheme.secondaryTextColor)
                }
                
                ProgressView(value: characterManager.progressToNextLevel)
                    .progressViewStyle(LinearProgressViewStyle(tint: themeManager.currentTheme.accentColor))
                    .scaleEffect(x: 1, y: 2, anchor: .center)
            }
        }
        .padding()
        .background(themeManager.currentTheme.surfaceColor)
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.1), radius: 4, x: 0, y: 2)
    }
    
    private var quickStatsRow: some View {
        HStack(spacing: 15) {
            StatCard(
                title: "Streak",
                value: "\(progressManager.weeklyStats.streak)",
                subtitle: "days",
                icon: "flame.fill",
                color: .orange
            )
            
            StatCard(
                title: "This Week",
                value: "\(progressManager.weeklyStats.totalWorkouts)",
                subtitle: "workouts",
                icon: "dumbbell.fill",
                color: themeManager.currentTheme.primaryColor
            )
            
            StatCard(
                title: "Steps",
                value: HealthDataFormatter.formatSteps(healthManager.todaysSteps),
                subtitle: "today",
                icon: "figure.walk",
                color: .green
            )
        }
    }
    
    private var todaysWorkoutCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Today's Workout")
                    .font(.headline)
                    .foregroundColor(themeManager.currentTheme.textColor)
                
                Spacer()
                
                Button("Start") {
                    // Start workout
                }
                .font(.caption)
                .fontWeight(.semibold)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(themeManager.currentTheme.accentColor)
                .foregroundColor(.white)
                .cornerRadius(8)
            }
            
            if let todaysWorkout = getTodaysWorkout() {
                VStack(alignment: .leading, spacing: 8) {
                    Text(todaysWorkout.name)
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(themeManager.currentTheme.textColor)
                    
                    Text("\(todaysWorkout.exercises.count) exercises • \(todaysWorkout.estimatedDuration) min")
                        .font(.caption)
                        .foregroundColor(themeManager.currentTheme.secondaryTextColor)
                    
                    // Exercise preview
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 8) {
                            ForEach(todaysWorkout.exercises.prefix(3), id: \.name) { exercise in
                                Text(exercise.name)
                                    .font(.caption2)
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 4)
                                    .background(themeManager.currentTheme.primaryColor.opacity(0.1))
                                    .cornerRadius(6)
                                    .foregroundColor(themeManager.currentTheme.primaryColor)
                            }
                            
                            if todaysWorkout.exercises.count > 3 {
                                Text("+\(todaysWorkout.exercises.count - 3) more")
                                    .font(.caption2)
                                    .foregroundColor(themeManager.currentTheme.secondaryTextColor)
                            }
                        }
                    }
                }
            } else {
                Text("No workout scheduled")
                    .font(.subheadline)
                    .foregroundColor(themeManager.currentTheme.secondaryTextColor)
            }
        }
        .padding()
        .background(themeManager.currentTheme.surfaceColor)
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.1), radius: 4, x: 0, y: 2)
    }
    
    private var recentActivityCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Recent Activity")
                .font(.headline)
                .foregroundColor(themeManager.currentTheme.textColor)
            
            if progressManager.workoutHistory.isEmpty {
                Text("No recent workouts")
                    .font(.subheadline)
                    .foregroundColor(themeManager.currentTheme.secondaryTextColor)
            } else {
                ForEach(progressManager.workoutHistory.prefix(3), id: \.id) { workout in
                    ActivityRow(workout: workout)
                }
            }
        }
        .padding()
        .background(themeManager.currentTheme.surfaceColor)
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.1), radius: 4, x: 0, y: 2)
    }
    
    private var healthSummaryCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Health Summary")
                .font(.headline)
                .foregroundColor(themeManager.currentTheme.textColor)
            
            HStack(spacing: 20) {
                HealthMetric(
                    title: "Calories",
                    value: "\(healthManager.todaysCalories)",
                    unit: "cal",
                    icon: "flame",
                    color: .red
                )
                
                HealthMetric(
                    title: "Heart Rate",
                    value: healthManager.heartRate > 0 ? "\(healthManager.heartRate)" : "--",
                    unit: "bpm",
                    icon: "heart",
                    color: .pink
                )
            }
        }
        .padding()
        .background(themeManager.currentTheme.surfaceColor)
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.1), radius: 4, x: 0, y: 2)
    }
    
    // MARK: - Helper Functions
    
    private func getTodaysWorkout() -> Workout? {
        let today = Calendar.current.component(.weekday, from: Date())
        // This would normally fetch from WorkoutManager
        return nil // Placeholder
    }
    
    private func refreshData() async {
        // Refresh all data
        try? await Task.sleep(nanoseconds: 1_000_000_000) // 1 second delay
    }
}

// MARK: - Supporting Views

struct StatCard: View {
    let title: String
    let value: String
    let subtitle: String
    let icon: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(color)
            
            Text(value)
                .font(.title3)
                .fontWeight(.bold)
                .foregroundColor(.primary)
            
            VStack(spacing: 2) {
                Text(title)
                    .font(.caption2)
                    .foregroundColor(.secondary)
                
                Text(subtitle)
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.1), radius: 4, x: 0, y: 2)
    }
}

struct ActivityRow: View {
    let workout: WorkoutSession
    
    var body: some View {
        HStack {
            Circle()
                .fill(.green)
                .frame(width: 8, height: 8)
            
            VStack(alignment: .leading, spacing: 2) {
                Text("Workout Completed")
                    .font(.subheadline)
                    .fontWeight(.medium)
                
                Text(workout.date, style: .relative)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            Text("\(workout.duration) min")
                .font(.caption)
                .foregroundColor(.secondary)
        }
    }
}

struct HealthMetric: View {
    let title: String
    let value: String
    let unit: String
    let icon: String
    let color: Color
    
    var body: some View {
        HStack {
            Image(systemName: icon)
                .foregroundColor(color)
            
            VStack(alignment: .leading) {
                Text(title)
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                HStack(alignment: .bottom, spacing: 2) {
                    Text(value)
                        .font(.subheadline)
                        .fontWeight(.semibold)
                    
                    Text(unit)
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
            }
            
            Spacer()
        }
    }
}

#Preview {
    ContentView()
        .environmentObject(CharacterManager())
        .environmentObject(ThemeManager())
        .environmentObject(WorkoutManager())
        .environmentObject(ProgressManager())
        .environmentObject(SocialManager())
        .environmentObject(HealthManager())
        .environmentObject(NotificationManager())
}
