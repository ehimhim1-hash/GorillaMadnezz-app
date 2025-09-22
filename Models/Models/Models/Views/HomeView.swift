import SwiftUI
import Combine

struct HomeView: View {
    @EnvironmentObject var authManager: AuthenticationManager
    @EnvironmentObject var workoutManager: WorkoutManager
    @EnvironmentObject var aiCoach: AICoachManager
    @EnvironmentObject var themeManager: ThemeManager
    @EnvironmentObject var progressManager: ProgressManager
    @EnvironmentObject var socialManager: SocialManager
    
    @State private var showingWorkoutGenerator = false
    @State private var showingProfile = false
    @State private var currentStreak = 0
    @State private var todaysProgress = 0.0
    @State private var animateStats = false
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    // Welcome Header
                    welcomeHeader
                    
                    // Quick Stats Cards
                    quickStatsSection
                    
                    // Today's Workout Suggestion
                    todaysWorkoutCard
                    
                    // AI Coach Insights
                    aiCoachSection
                    
                    // Recent Activity
                    recentActivitySection
                    
                    // Social Highlights
                    socialHighlights
                    
                    // Quick Actions
                    quickActionsSection
                    
                    Spacer(minLength: 100)
                }
                .padding(.horizontal)
                .padding(.top)
            }
            .background(themeManager.currentTheme.backgroundColor.ignoresSafeArea())
            .navigationBarHidden(true)
            .refreshable {
                await refreshData()
            }
        }
        .onAppear {
            loadDashboardData()
            withAnimation(.easeInOut(duration: 1.0)) {
                animateStats = true
            }
        }
        .sheet(isPresented: $showingWorkoutGenerator) {
            WorkoutGeneratorView()
        }
        .sheet(isPresented: $showingProfile) {
            ProfileView()
        }
    }
    
    // MARK: - Welcome Header
    private var welcomeHeader: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(greetingText())
                    .font(.title2)
                    .foregroundColor(themeManager.currentTheme.secondaryTextColor)
                
                HStack {
                    Text("Ready to go")
                    Text("🦍")
                        .scaleEffect(animateStats ? 1.2 : 1.0)
                        .animation(.easeInOut(duration: 0.8).repeatForever(autoreverses: true), value: animateStats)
                    Text("BEAST MODE?")
                }
                .font(.title)
                .fontWeight(.bold)
                .foregroundColor(themeManager.currentTheme.primaryTextColor)
            }
            
            Spacer()
            
            Button(action: { showingProfile = true }) {
                AsyncImage(url: URL(string: authManager.currentUser?.profileImageURL ?? "")) { image in
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                } placeholder: {
                    Image(systemName: "person.circle.fill")
                        .font(.title)
                        .foregroundColor(themeManager.currentTheme.accentColor)
                }
                .frame(width: 44, height: 44)
                .clipShape(Circle())
                .overlay(
                    Circle()
                        .stroke(themeManager.currentTheme.accentColor, lineWidth: 2)
                )
            }
        }
    }
    
    // MARK: - Quick Stats Section
    private var quickStatsSection: some View {
        LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2), spacing: 16) {
            StatCard(
                title: "Current Streak",
                value: "\(currentStreak)",
                subtitle: "days",
                icon: "flame.fill",
                color: .orange,
                animate: animateStats
            )
            
            StatCard(
                title: "Today's Goal",
                value: String(format: "%.0f%%", todaysProgress * 100),
                subtitle: "complete",
                icon: "target",
                color: themeManager.currentTheme.accentColor,
                animate: animateStats
            )
            
            StatCard(
                title: "Total Workouts",
                value: "\(progressManager.workoutHistory.count)",
                subtitle: "completed",
                icon: "dumbbell.fill",
                color: .blue,
                animate: animateStats
            )
            
            StatCard(
                title: "Gorilla Level",
                value: "\(authManager.currentUser?.level ?? 1)",
                subtitle: "strength",
                icon: "crown.fill",
                color: .yellow,
                animate: animateStats
            )
        }
    }
    
    // MARK: - Today's Workout Card
    private var todaysWorkoutCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("🎯 Today's Suggestion")
                    .font(.headline)
                    .foregroundColor(themeManager.currentTheme.primaryTextColor)
                Spacer()
                Text("AI Powered")
                    .font(.caption)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(themeManager.currentTheme.accentColor.opacity(0.2))
                    .foregroundColor(themeManager.currentTheme.accentColor)
                    .cornerRadius(8)
            }
            
            if let suggestedWorkout = aiCoach.todaysSuggestedWorkout {
                NavigationLink(destination: WorkoutDetailView(workout: suggestedWorkout)) {
                    WorkoutSuggestionCard(workout: suggestedWorkout)
                }
                .buttonStyle(PlainButtonStyle())
            } else {
                Button(action: { showingWorkoutGenerator = true }) {
                    GenerateWorkoutCard()
                }
            }
        }
        .padding()
        .background(themeManager.currentTheme.cardBackgroundColor)
        .cornerRadius(16)
        .shadow(color: Color.black.opacity(0.1), radius: 8, x: 0, y: 4)
    }
    
    // MARK: - AI Coach Section
    private var aiCoachSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("🤖 Coach Insights")
                    .font(.headline)
                    .foregroundColor(themeManager.currentTheme.primaryTextColor)
                Spacer()
                Text("Smart Analysis")
                    .font(.caption)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color.green.opacity(0.2))
                    .foregroundColor(.green)
                    .cornerRadius(8)
            }
            
            LazyVStack(spacing: 8) {
                ForEach(aiCoach.currentInsights.prefix(3)) { insight in
                    InsightCard(insight: insight)
                }
            }
        }
        .padding()
        .background(themeManager.currentTheme.cardBackgroundColor)
        .cornerRadius(16)
        .shadow(color: Color.black.opacity(0.1), radius: 8, x: 0, y: 4)
    }
    
    // MARK: - Recent Activity
    private var recentActivitySection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("📈 Recent Activity")
                    .font(.headline)
                    .foregroundColor(themeManager.currentTheme.primaryTextColor)
                Spacer()
                NavigationLink("View All", destination: ProgressView())
                    .font(.caption)
                    .foregroundColor(themeManager.currentTheme.accentColor)
            }
            
            LazyVStack(spacing: 8) {
                ForEach(progressManager.workoutHistory.prefix(3)) { session in
                    RecentActivityCard(session: session)
                }
            }
        }
        .padding()
        .background(themeManager.currentTheme.cardBackgroundColor)
        .cornerRadius(16)
        .shadow(color: Color.black.opacity(0.1), radius: 8, x: 0, y: 4)
    }
    
    // MARK: - Social Highlights
    private var socialHighlights: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("👥 Social Highlights")
                    .font(.headline)
                    .foregroundColor(themeManager.currentTheme.primaryTextColor)
                Spacer()
                NavigationLink("View All", destination: SocialView())
                    .font(.caption)
                    .foregroundColor(themeManager.currentTheme.accentColor)
            }
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(socialManager.friends.prefix(5)) { friend in
                        FriendHighlightCard(friend: friend)
                    }
                }
                .padding(.horizontal, 4)
            }
        }
        .padding()
        .background(themeManager.currentTheme.cardBackgroundColor)
        .cornerRadius(16)
        .shadow(color: Color.black.opacity(0.1), radius: 8, x: 0, y: 4)
    }
    
    // MARK: - Quick Actions
    private var quickActionsSection: some View {
        LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2), spacing: 16) {
            QuickActionButton(
                title: "Start Workout",
                subtitle: "Begin training",
                icon: "play.fill",
                color: themeManager.currentTheme.accentColor
            ) {
                // Navigate to workout selection
            }
            
            QuickActionButton(
                title: "Create Custom",
                subtitle: "Build your own",
                icon: "plus.circle.fill",
                color: .blue
            ) {
                showingWorkoutGenerator = true
            }
            
            QuickActionButton(
                title: "Progress Stats",
                subtitle: "View analytics",
                icon: "chart.line.uptrend.xyaxis",
                color: .green
            ) {
                // Navigate to progress view
            }
            
            QuickActionButton(
                title: "Challenge Friend",
                subtitle: "Start competition",
                icon: "person.2.fill",
                color: .purple
            ) {
                // Navigate to social challenges
            }
        }
    }
    
    // MARK: - Helper Functions
    private func greetingText() -> String {
        let hour = Calendar.current.component(.hour, from: Date())
        switch hour {
        case 5..<12: return "Good Morning"
        case 12..<17: return "Good Afternoon"
        case 17..<22: return "Good Evening"
        default: return "Good Evening"
        }
    }
    
    private func loadDashboardData() {
        // Calculate current streak
        currentStreak = calculateCurrentStreak()
        
        // Calculate today's progress
        todaysProgress = calculateTodaysProgress()
        
        // Refresh AI insights
        aiCoach.generateTodaysInsights()
    }
    
    private func calculateCurrentStreak() -> Int {
        let calendar = Calendar.current
        let today = Date()
        var streak = 0
        var currentDate = today
        
        // Check backwards from today to find streak
        while streak < 365 { // Max check 1 year
            let dayWorkouts = progressManager.workoutHistory.filter { session in
                calendar.isDate(session.date, inSameDayAs: currentDate)
            }
            
            if dayWorkouts.isEmpty {
                break
            }
            
            streak += 1
            currentDate = calendar.date(byAdding: .day, value: -1, to: currentDate) ?? currentDate
        }
        
        return streak
    }
    
    private func calculateTodaysProgress() -> Double {
        let calendar = Calendar.current
        let today = Date()
        
        let todaysWorkouts = progressManager.workoutHistory.filter { session in
            calendar.isDate(session.date, inSameDayAs: today)
        }
        
        // Simple progress calculation - could be more sophisticated
        let targetMinutes = 45.0
        let actualMinutes = todaysWorkouts.reduce(0) { $0 + $1.duration }
        
        return min(actualMinutes / targetMinutes, 1.0)
    }
    
    @MainActor
    private func refreshData() async {
        loadDashboardData()
        try? await Task.sleep(nanoseconds: 1_000_000_000) // 1 second delay for demo
    }
}

// MARK: - Supporting Views

struct StatCard: View {
    let title: String
    let value: String
    let subtitle: String
    let icon: String
    let color: Color
    let animate: Bool
    
    var body: some View {
        VStack(spacing: 8) {
            HStack {
                Image(systemName: icon)
                    .foregroundColor(color)
                    .font(.title2)
                Spacer()
            }
            
            VStack(alignment: .leading, spacing: 2) {
                Text(value)
                    .font(.title2)
                    .fontWeight(.bold)
                    .scaleEffect(animate ? 1.0 : 0.8)
                    .animation(.spring(response: 0.6, dampingFraction: 0.8).delay(0.1), value: animate)
                
                Text(subtitle)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
}

struct WorkoutSuggestionCard: View {
    let workout: Workout
    @EnvironmentObject var themeManager: ThemeManager
    
    var body: some View {
        HStack(spacing: 12) {
            // Workout Image/Icon
            ZStack {
                RoundedRectangle(cornerRadius: 8)
                    .fill(LinearGradient(
                        colors: [Color.blue.opacity(0.3), Color.purple.opacity(0.3)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ))
                    .frame(width: 60, height: 60)
                
                Text(workout.category.emoji)
                    .font(.title2)
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text(workout.name)
                    .font(.headline)
                    .foregroundColor(themeManager.currentTheme.primaryTextColor)
                
                Text("\(workout.exercises.count) exercises • \(workout.estimatedDuration) min")
                    .font(.caption)
                    .foregroundColor(themeManager.currentTheme.secondaryTextColor)
                
                HStack {
                    DifficultyBadge(difficulty: workout.difficulty)
                    Spacer()
                    Text("Tap to start")
                        .font(.caption)
                        .foregroundColor(themeManager.currentTheme.accentColor)
                }
            }
            
            Spacer()
        }
        .padding()
        .background(themeManager.currentTheme.backgroundColor.opacity(0.5))
        .cornerRadius(12)
    }
}

struct GenerateWorkoutCard: View {
    @EnvironmentObject var themeManager: ThemeManager
    
    var body: some View {
        HStack(spacing: 12) {
            ZStack {
                RoundedRectangle(cornerRadius: 8)
                    .fill(LinearGradient(
                        colors: [themeManager.currentTheme.accentColor.opacity(0.3), themeManager.currentTheme.accentColor.opacity(0.1)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ))
                    .frame(width: 60, height: 60)
                
                Image(systemName: "sparkles")
                    .font(.title2)
                    .foregroundColor(themeManager.currentTheme.accentColor)
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text("Generate Custom Workout")
                    .font(.headline)
                    .foregroundColor(themeManager.currentTheme.primaryTextColor)
                
                Text("AI will create a personalized routine")
                    .font(.caption)
                    .foregroundColor(themeManager.currentTheme.secondaryTextColor)
                
                Text("Tap to create")
                    .font(.caption)
                    .foregroundColor(themeManager.currentTheme.accentColor)
            }
            
            Spacer()
        }
        .padding()
        .background(themeManager.currentTheme.backgroundColor.opacity(0.5))
        .cornerRadius(12)
    }
}

struct InsightCard: View {
    let insight: AIInsight
    @EnvironmentObject var themeManager: ThemeManager
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: insight.icon)
                .foregroundColor(insight.priority.color)
                .font(.title3)
                .frame(width: 24, height: 24)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(insight.title)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(themeManager.currentTheme.primaryTextColor)
                
                Text(insight.message)
                    .font(.caption)
                    .foregroundColor(themeManager.currentTheme.secondaryTextColor)
                    .lineLimit(2)
            }
            
            Spacer()
            
            Text(insight.confidence, format: .percent)
                .font(.caption2)
                .foregroundColor(insight.priority.color)
        }
        .padding(.vertical, 8)
        .padding(.horizontal, 12)
        .background(themeManager.currentTheme.backgroundColor.opacity(0.3))
        .cornerRadius(8)
    }
}

struct RecentActivityCard: View {
    let session: WorkoutSession
    @EnvironmentObject var themeManager: ThemeManager
    
    var body: some View {
        HStack(spacing: 12) {
            Text(session.workoutName.prefix(2))
                .font(.caption)
                .fontWeight(.bold)
                .frame(width: 32, height: 32)
                .background(themeManager.currentTheme.accentColor.opacity(0.2))
                .foregroundColor(themeManager.currentTheme.accentColor)
                .cornerRadius(8)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(session.workoutName)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(themeManager.currentTheme.primaryTextColor)
                
                Text("\(Int(session.duration)) min • \(session.exercises.count) exercises")
                    .font(.caption)
                    .foregroundColor(themeManager.currentTheme.secondaryTextColor)
            }
            
            Spacer()
            
            Text(session.date, style: .relative)
                .font(.caption2)
                .foregroundColor(themeManager.currentTheme.secondaryTextColor)
        }
        .padding(.vertical, 8)
        .padding(.horizontal, 12)
        .background(themeManager.currentTheme.backgroundColor.opacity(0.3))
        .cornerRadius(8)
    }
}

struct FriendHighlightCard: View {
    let friend: Friend
    @EnvironmentObject var themeManager: ThemeManager
    
    var body: some View {
        VStack(spacing: 6) {
            AsyncImage(url: URL(string: friend.profileImageURL)) { image in
                image
                    .resizable()
                    .aspectRatio(contentMode: .fill)
            } placeholder: {
                Circle()
                    .fill(themeManager.currentTheme.accentColor.opacity(0.3))
                    .overlay(
                        Text(friend.username.prefix(1).uppercased())
                            .font(.caption)
                            .fontWeight(.bold)
                            .foregroundColor(themeManager.currentTheme.accentColor)
                    )
            }
            .frame(width: 40, height: 40)
            .clipShape(Circle())
            
            Text(friend.username)
                .font(.caption2)
                .foregroundColor(themeManager.currentTheme.primaryTextColor)
                .lineLimit(1)
            
            if friend.isOnline {
                Circle()
                    .fill(Color.green)
                    .frame(width: 6, height: 6)
            }
        }
        .frame(width: 60)
    }
}

struct QuickActionButton: View {
    let title: String
    let subtitle: String
    let icon: String
    let color: Color
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.title2)
                    .foregroundColor(color)
                
                VStack(spacing: 2) {
                    Text(title)
                        .font(.caption)
                        .fontWeight(.medium)
                    
                    Text(subtitle)
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
                .multilineTextAlignment(.center)
            }
            .frame(maxWidth: .infinity)
            .padding()
            .background(Color(.systemGray6))
            .cornerRadius(12)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct DifficultyBadge: View {
    let difficulty: WorkoutDifficulty
    
    var body: some View {
        Text(difficulty.rawValue.capitalized)
            .font(.caption2)
            .fontWeight(.medium)
            .padding(.horizontal, 6)
            .padding(.vertical, 2)
            .background(difficulty.color.opacity(0.2))
            .foregroundColor(difficulty.color)
            .cornerRadius(4)
    }
}

#Preview {
    HomeView()
        .environmentObject(AuthenticationManager())
        .environmentObject(WorkoutManager())
        .environmentObject(AICoachManager())
        .environmentObject(ThemeManager())
        .environmentObject(ProgressManager())
        .environmentObject(SocialManager())
}
