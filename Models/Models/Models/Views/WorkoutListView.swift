//
//  WorkoutListView.swift
//  GorillaMadnezz
//
//  Workout browsing and selection interface
//

import SwiftUI

struct WorkoutListView: View {
    @EnvironmentObject var workoutGenerator: WorkoutGenerator
    @EnvironmentObject var workoutManager: WorkoutManager
    @EnvironmentObject var themeManager: ThemeManager
    @EnvironmentObject var characterManager: CharacterManager
    @EnvironmentObject var equipmentManager: EquipmentManager
    
    @State private var selectedFilter: WorkoutFilter = .all
    @State private var showingWorkoutGenerator = false
    @State private var showingEquipmentSelector = false
    @State private var searchText = ""
    @State private var selectedWorkout: Workout?
    @State private var showingWorkoutDetail = false
    
    private var filteredWorkouts: [Workout] {
        let workouts = workoutGenerator.getWorkoutsForLevel(characterManager.currentTier.fitnessLevel)
        
        var filtered = workouts
        
        // Apply search filter
        if !searchText.isEmpty {
            filtered = filtered.filter { workout in
                workout.name.localizedCaseInsensitiveContains(searchText) ||
                workout.description.localizedCaseInsensitiveContains(searchText) ||
                workout.targetMuscleGroups.contains { $0.localizedCaseInsensitiveContains(searchText) }
            }
        }
        
        // Apply category filter
        switch selectedFilter {
        case .all:
            break
        case .strength:
            filtered = filtered.filter { $0.category == .strength }
        case .cardio:
            filtered = filtered.filter { $0.category == .cardio }
        case .hiit:
            filtered = filtered.filter { $0.category == .hiit }
        case .bodyweight:
            filtered = filtered.filter { $0.category == .bodyweight }
        case .recommended:
            filtered = Array(filtered.prefix(3)) // Top 3 as recommended
        }
        
        return filtered
    }
    
    var body: some View {
        NavigationView {
            ZStack {
                themeManager.currentTheme.backgroundColor
                    .ignoresSafeArea()
                
                VStack(spacing: 0) {
                    // Search and Filter Header
                    headerSection
                    
                    // Workout List
                    workoutListSection
                }
            }
            .navigationTitle("Workouts")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        showingWorkoutGenerator = true
                    }) {
                        Image(systemName: "plus.circle.fill")
                            .foregroundColor(themeManager.currentTheme.primaryColor)
                    }
                }
                
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(action: {
                        showingEquipmentSelector = true
                    }) {
                        Image(systemName: "slider.horizontal.3")
                            .foregroundColor(themeManager.currentTheme.primaryColor)
                    }
                }
            }
        }
        .sheet(isPresented: $showingWorkoutGenerator) {
            WorkoutGeneratorView()
        }
        .sheet(isPresented: $showingEquipmentSelector) {
            EquipmentSelectorView()
        }
        .sheet(item: $selectedWorkout) { workout in
            WorkoutDetailView(workout: workout)
        }
    }
    
    // MARK: - UI Components
    
    private var headerSection: some View {
        VStack(spacing: 15) {
            // Search Bar
            HStack {
                Image(systemName: "magnifyingglass")
                    .foregroundColor(.gray)
                
                TextField("Search workouts...", text: $searchText)
                    .textFieldStyle(PlainTextFieldStyle())
                
                if !searchText.isEmpty {
                    Button(action: {
                        searchText = ""
                    }) {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(.gray)
                    }
                }
            }
            .padding()
            .background(themeManager.currentTheme.surfaceColor)
            .cornerRadius(12)
            
            // Filter Chips
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(WorkoutFilter.allCases, id: \.self) { filter in
                        FilterChip(
                            title: filter.displayName,
                            isSelected: selectedFilter == filter,
                            action: {
                                selectedFilter = filter
                            }
                        )
                    }
                }
                .padding(.horizontal)
            }
            
            // Quick Stats
            quickStatsBar
        }
        .padding()
        .background(themeManager.currentTheme.backgroundColor)
    }
    
    private var quickStatsBar: some View {
        HStack {
            StatBadge(
                icon: "dumbbell.fill",
                title: "Available",
                value: "\(filteredWorkouts.count)",
                color: themeManager.currentTheme.primaryColor
            )
            
            StatBadge(
                icon: "target",
                title: "Level",
                value: characterManager.currentTier.displayName,
                color: themeManager.currentTheme.accentColor
            )
            
            StatBadge(
                icon: "gear",
                title: "Equipment",
                value: "\(equipmentManager.selectedEquipment.count)",
                color: .orange
            )
        }
    }
    
    private var workoutListSection: some View {
        ScrollView {
            LazyVStack(spacing: 16) {
                if filteredWorkouts.isEmpty {
                    emptyStateView
                } else {
                    ForEach(filteredWorkouts, id: \.id) { workout in
                        WorkoutCard(workout: workout) {
                            selectedWorkout = workout
                            showingWorkoutDetail = true
                        }
                    }
                }
            }
            .padding()
        }
    }
    
    private var emptyStateView: some View {
        VStack(spacing: 20) {
            Image(systemName: "dumbbell")
                .font(.system(size: 60))
                .foregroundColor(.gray)
            
            Text("No Workouts Found")
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(themeManager.currentTheme.textColor)
            
            Text("Try adjusting your search or filters, or create a new workout!")
                .font(.subheadline)
                .foregroundColor(themeManager.currentTheme.secondaryTextColor)
                .multilineTextAlignment(.center)
            
            Button("Create Workout") {
                showingWorkoutGenerator = true
            }
            .font(.headline)
            .foregroundColor(.white)
            .padding()
            .background(themeManager.currentTheme.primaryColor)
            .cornerRadius(12)
        }
        .padding(40)
    }
}

// MARK: - Supporting Views

struct FilterChip: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void
    
    @EnvironmentObject var themeManager: ThemeManager
    
    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.subheadline)
                .fontWeight(.medium)
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(
                    isSelected
                        ? themeManager.currentTheme.primaryColor
                        : themeManager.currentTheme.surfaceColor
                )
                .foregroundColor(
                    isSelected
                        ? .white
                        : themeManager.currentTheme.textColor
                )
                .cornerRadius(20)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct StatBadge: View {
    let icon: String
    let title: String
    let value: String
    let color: Color
    
    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: icon)
                .foregroundColor(color)
                .font(.caption)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.caption2)
                    .foregroundColor(.secondary)
                
                Text(value)
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundColor(.primary)
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
        .background(Color(.systemBackground))
        .cornerRadius(8)
        .shadow(color: .black.opacity(0.1), radius: 2, x: 0, y: 1)
    }
}

struct WorkoutCard: View {
    let workout: Workout
    let action: () -> Void
    
    @EnvironmentObject var themeManager: ThemeManager
    @EnvironmentObject var workoutManager: WorkoutManager
    
    var body: some View {
        Button(action: action) {
            VStack(alignment: .leading, spacing: 12) {
                // Header
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(workout.name)
                            .font(.headline)
                            .fontWeight(.bold)
                            .foregroundColor(themeManager.currentTheme.textColor)
                            .lineLimit(2)
                        
                        Text(workout.category.displayName)
                            .font(.caption)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 2)
                            .background(themeManager.currentTheme.primaryColor.opacity(0.2))
                            .foregroundColor(themeManager.currentTheme.primaryColor)
                            .cornerRadius(4)
                    }
                    
                    Spacer()
                    
                    DifficultyIndicator(level: workout.difficulty)
                }
                
                // Description
                Text(workout.description)
                    .font(.subheadline)
                    .foregroundColor(themeManager.currentTheme.secondaryTextColor)
                    .lineLimit(2)
                
                // Muscle Groups
                if !workout.targetMuscleGroups.isEmpty {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 6) {
                            ForEach(workout.targetMuscleGroups, id: \.self) { muscle in
                                Text(muscle)
                                    .font(.caption2)
                                    .padding(.horizontal, 6)
                                    .padding(.vertical, 3)
                                    .background(themeManager.currentTheme.accentColor.opacity(0.2))
                                    .foregroundColor(themeManager.currentTheme.accentColor)
                                    .cornerRadius(4)
                            }
                        }
                    }
                }
                
                // Workout Stats
                HStack {
                    WorkoutStat(icon: "clock", value: "\(workout.estimatedDuration)", unit: "min")
                    WorkoutStat(icon: "flame", value: "\(workout.estimatedCalories)", unit: "cal")
                    WorkoutStat(icon: "figure.strengthtraining.traditional", value: "\(workout.exercises.count)", unit: "exercises")
                    
                    Spacer()
                    
                    // Start Button
                    Button(action: {
                        startWorkout()
                    }) {
                        HStack(spacing: 4) {
                            Image(systemName: "play.fill")
                                .font(.caption)
                            Text("Start")
                                .font(.caption)
                                .fontWeight(.semibold)
                        }
                        .foregroundColor(.white)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(themeManager.currentTheme.accentColor)
                        .cornerRadius(8)
                    }
                    .buttonStyle(PlainButtonStyle())
                }
            }
            .padding()
            .background(themeManager.currentTheme.surfaceColor)
            .cornerRadius(16)
            .shadow(color: .black.opacity(0.1), radius: 4, x: 0, y: 2)
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    private func startWorkout() {
        workoutManager.startWorkout(workout)
    }
}

struct WorkoutStat: View {
    let icon: String
    let value: String
    let unit: String
    
    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: icon)
                .font(.caption2)
                .foregroundColor(.secondary)
            
            Text(value)
                .font(.caption)
                .fontWeight(.medium)
                .foregroundColor(.primary)
            
            Text(unit)
                .font(.caption2)
                .foregroundColor(.secondary)
        }
    }
}

struct DifficultyIndicator: View {
    let level: WorkoutDifficulty
    
    private var color: Color {
        switch level {
        case .beginner: return .green
        case .intermediate: return .orange
        case .advanced: return .red
        case .expert: return .purple
        }
    }
    
    private var stars: Int {
        switch level {
        case .beginner: return 1
        case .intermediate: return 2
        case .advanced: return 3
        case .expert: return 4
        }
    }
    
    var body: some View {
        VStack(alignment: .trailing, spacing: 2) {
            HStack(spacing: 2) {
                ForEach(0..<4) { index in
                    Image(systemName: index < stars ? "star.fill" : "star")
                        .font(.caption2)
                        .foregroundColor(index < stars ? color : .gray.opacity(0.3))
                }
            }
            
            Text(level.displayName)
                .font(.caption2)
                .foregroundColor(color)
                .fontWeight(.medium)
        }
    }
}

// MARK: - Enums

enum WorkoutFilter: CaseIterable {
    case all, recommended, strength, cardio, hiit, bodyweight
    
    var displayName: String {
        switch self {
        case .all: return "All"
        case .recommended: return "Recommended"
        case .strength: return "Strength"
        case .cardio: return "Cardio"
        case .hiit: return "HIIT"
        case .bodyweight: return "Bodyweight"
        }
    }
}

enum WorkoutDifficulty: String, CaseIterable {
    case beginner = "beginner"
    case intermediate = "intermediate"
    case advanced = "advanced"
    case expert = "expert"
    
    var displayName: String {
        return rawValue.capitalized
    }
}

// MARK: - Preview

#Preview {
    WorkoutListView()
        .environmentObject(WorkoutGenerator())
        .environmentObject(WorkoutManager())
        .environmentObject(ThemeManager())
        .environmentObject(CharacterManager())
        .environmentObject(EquipmentManager())
}
