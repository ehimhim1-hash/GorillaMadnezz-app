//
//  WorkoutDetailView.swift
//  GorillaMadnezz
//
//  Detailed view of individual workouts with exercise breakdown
//

import SwiftUI

struct WorkoutDetailView: View {
    let workout: Workout
    
    @EnvironmentObject var workoutManager: WorkoutManager
    @EnvironmentObject var themeManager: ThemeManager
    @EnvironmentObject var characterManager: CharacterManager
    @EnvironmentObject var aiCoach: AICoach
    @Environment(\.dismiss) private var dismiss
    
    @State private var selectedExercise: Exercise?
    @State private var showingExerciseDetail = false
    @State private var showingSubstitutions = false
    @State private var expandedSections: Set<String> = []
    @State private var showingStartConfirmation = false
    @State private var estimatedDuration = 0
    
    var body: some View {
        NavigationView {
            ZStack {
                themeManager.currentTheme.backgroundColor
                    .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 20) {
                        // Workout Header
                        workoutHeaderSection
                        
                        // Quick Stats
                        quickStatsSection
                        
                        // Muscle Groups
                        muscleGroupsSection
                        
                        // Exercise List
                        exerciseListSection
                        
                        // AI Coach Insights
                        aiInsightsSection
                        
                        // Equipment Required
                        equipmentSection
                        
                        Spacer(minLength: 100) // Space for floating button
                    }
                    .padding()
                }
            }
            .navigationTitle(workout.name)
            .navigationBarTitleDisplayMode(.large)
            .navigationBarItems(
                leading: Button("Close") { dismiss() },
                trailing: Button("Save") { saveWorkout() }
            )
            .overlay(
                // Floating Start Button
                VStack {
                    Spacer()
                    startWorkoutButton
                }
                .padding()
            )
        }
        .onAppear {
            calculateEstimatedDuration()
        }
        .sheet(item: $selectedExercise) { exercise in
            ExerciseDetailView(exercise: exercise)
        }
        .alert("Start Workout", isPresented: $showingStartConfirmation) {
            Button("Cancel", role: .cancel) { }
            Button("Start") { startWorkout() }
        } message: {
            Text("Ready to begin your \(workout.name) workout? This will take approximately \(estimatedDuration) minutes.")
        }
    }
    
    // MARK: - UI Components
    
    private var workoutHeaderSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Workout Image/Icon
            ZStack {
                RoundedRectangle(cornerRadius: 16)
                    .fill(
                        LinearGradient(
                            colors: [
                                themeManager.currentTheme.primaryColor.opacity(0.8),
                                themeManager.currentTheme.accentColor.opacity(0.6)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(height: 120)
                
                VStack {
                    Image(systemName: getWorkoutIcon())
                        .font(.system(size: 40))
                        .foregroundColor(.white)
                    
                    Text(workout.category.displayName)
                        .font(.caption)
                        .fontWeight(.semibold)
                        .foregroundColor(.white.opacity(0.9))
                }
            }
            
            // Description
            Text(workout.description)
                .font(.body)
                .foregroundColor(themeManager.currentTheme.textColor)
                .lineLimit(nil)
            
            // Difficulty and Level Recommendation
            HStack {
                DifficultyBadge(difficulty: workout.difficulty)
                
                Spacer()
                
                if isWorkoutAppropriate() {
                    HStack {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(.green)
                        Text("Perfect for your level")
                            .font(.caption)
                            .foregroundColor(.green)
                    }
                } else {
                    HStack {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .foregroundColor(.orange)
                        Text("Challenging workout")
                            .font(.caption)
                            .foregroundColor(.orange)
                    }
                }
            }
        }
        .padding()
        .background(themeManager.currentTheme.surfaceColor)
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.1), radius: 4, x: 0, y: 2)
    }
    
    private var quickStatsSection: some View {
        HStack(spacing: 15) {
            QuickStatCard(
                icon: "clock.fill",
                title: "Duration",
                value: "\(estimatedDuration)",
                unit: "min",
                color: .blue
            )
            
            QuickStatCard(
                icon: "flame.fill",
                title: "Calories",
                value: "\(workout.estimatedCalories)",
                unit: "cal",
                color: .red
            )
            
            QuickStatCard(
                icon: "figure.strengthtraining.traditional",
                title: "Exercises",
                value: "\(workout.exercises.count)",
                unit: "total",
                color: themeManager.currentTheme.primaryColor
            )
        }
    }
    
    private var muscleGroupsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Target Muscle Groups")
                .font(.headline)
                .foregroundColor(themeManager.currentTheme.textColor)
            
            FlexibleView(
                data: workout.targetMuscleGroups,
                spacing: 8,
                alignment: .leading
            ) { muscle in
                MuscleGroupChip(muscleGroup: muscle)
            }
        }
        .padding()
        .background(themeManager.currentTheme.surfaceColor)
        .cornerRadius(12)
    }
    
    private var exerciseListSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("Exercises (\(workout.exercises.count))")
                    .font(.headline)
                    .foregroundColor(themeManager.currentTheme.textColor)
                
                Spacer()
                
                Button("Preview All") {
                    // Show exercise preview
                }
                .font(.caption)
                .foregroundColor(themeManager.currentTheme.primaryColor)
            }
            
            LazyVStack(spacing: 12) {
                ForEach(Array(workout.exercises.enumerated()), id: \.element.id) { index, exercise in
                    ExerciseRow(
                        exercise: exercise,
                        index: index + 1,
                        isExpanded: expandedSections.contains(exercise.id),
                        onTap: {
                            toggleExerciseExpansion(exercise.id)
                        },
                        onDetailTap: {
                            selectedExercise = exercise
                            showingExerciseDetail = true
                        },
                        onSubstitute: {
                            showExerciseSubstitutions(exercise)
                        }
                    )
                }
            }
        }
        .padding()
        .background(themeManager.currentTheme.surfaceColor)
        .cornerRadius(12)
    }
    
    private var aiInsightsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "brain.head.profile")
                    .foregroundColor(themeManager.currentTheme.accentColor)
                
                Text("AI Coach Insights")
                    .font(.headline)
                    .foregroundColor(themeManager.currentTheme.textColor)
            }
            
            VStack(alignment: .leading, spacing: 8) {
                ForEach(getAIInsights(), id: \.self) { insight in
                    HStack(alignment: .top) {
                        Image(systemName: "lightbulb.fill")
                            .foregroundColor(.yellow)
                            .font(.caption)
                        
                        Text(insight)
                            .font(.subheadline)
                            .foregroundColor(themeManager.currentTheme.textColor)
                            .lineLimit(nil)
                    }
                }
            }
        }
        .padding()
        .background(themeManager.currentTheme.surfaceColor)
        .cornerRadius(12)
    }
    
    private var equipmentSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Equipment Required")
                .font(.headline)
                .foregroundColor(themeManager.currentTheme.textColor)
            
            if getRequiredEquipment().isEmpty {
                HStack {
                    Image(systemName: "figure.run")
                        .foregroundColor(.green)
                    Text("No equipment needed - bodyweight only!")
                        .font(.subheadline)
                        .foregroundColor(.green)
                }
            } else {
                FlexibleView(
                    data: getRequiredEquipment(),
                    spacing: 8,
                    alignment: .leading
                ) { equipment in
                    EquipmentChip(equipment: equipment)
                }
            }
        }
        .padding()
        .background(themeManager.currentTheme.surfaceColor)
        .cornerRadius(12)
    }
    
    private var startWorkoutButton: some View {
        Button(action: {
            showingStartConfirmation = true
        }) {
            HStack {
                Image(systemName: "play.fill")
                    .font(.title2)
                
                Text("Start Workout")
                    .font(.headline)
                    .fontWeight(.semibold)
            }
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .padding()
            .background(
                LinearGradient(
                    colors: [
                        themeManager.currentTheme.primaryColor,
                        themeManager.currentTheme.accentColor
                    ],
                    startPoint: .leading,
                    endPoint: .trailing
                )
            )
            .cornerRadius(16)
            .shadow(color: themeManager.currentTheme.primaryColor.opacity(0.4), radius: 8, x: 0, y: 4)
        }
    }
    
    // MARK: - Helper Functions
    
    private func getWorkoutIcon() -> String {
        switch workout.category {
        case .strength: return "dumbbell.fill"
        case .cardio: return "heart.fill"
        case .hiit: return "bolt.fill"
        case .bodyweight: return "figure.strengthtraining.traditional"
        case .flexibility: return "figure.yoga"
        case .sports: return "sportscourt.fill"
        }
    }
    
    private func isWorkoutAppropriate() -> Bool {
        let userLevel = characterManager.currentTier.fitnessLevel
        switch (userLevel, workout.difficulty) {
        case (.beginner, .beginner), (.beginner, .intermediate):
            return true
        case (.intermediate, .beginner), (.intermediate, .intermediate), (.intermediate, .advanced):
            return true
        case (.advanced, _):
            return true
        default:
            return false
        }
    }
    
    private func calculateEstimatedDuration() {
        let baseTime = workout.exercises.reduce(0) { total, exercise in
            let exerciseTime = exercise.sets.count * 2 // 2 minutes per set on average
            let restTime = exercise.sets.count * 1 // 1 minute rest between sets
            return total + exerciseTime + restTime
        }
        
        estimatedDuration = max(baseTime, workout.estimatedDuration)
    }
    
    private func getAIInsights() -> [String] {
        return aiCoach.getWorkoutInsights(for: workout, userLevel: characterManager.currentTier.fitnessLevel)
    }
    
    private func getRequiredEquipment() -> [String] {
        let equipment = Set(workout.exercises.flatMap { $0.requiredEquipment })
        return Array(equipment).sorted()
    }
    
    private func toggleExerciseExpansion(_ exerciseId: String) {
        if expandedSections.contains(exerciseId) {
            expandedSections.remove(exerciseId)
        } else {
            expandedSections.insert(exerciseId)
        }
    }
    
    private func showExerciseSubstitutions(_ exercise: Exercise) {
        selectedExercise = exercise
        showingSubstitutions = true
    }
    
    private func startWorkout() {
        workoutManager.startWorkout(workout)
        dismiss()
    }
    
    private func saveWorkout() {
        // Save workout to favorites or custom workouts
        print("Workout saved!")
    }
}

// MARK: - Supporting Views

struct DifficultyBadge: View {
    let difficulty: WorkoutDifficulty
    
    private var config: (color: Color, icon: String) {
        switch difficulty {
        case .beginner: return (.green, "leaf.fill")
        case .intermediate: return (.orange, "flame.fill")
        case .advanced: return (.red, "bolt.fill")
        case .expert: return (.purple, "crown.fill")
        }
    }
    
    var body: some View {
        HStack(spacing: 6) {
            Image(systemName: config.icon)
                .font(.caption)
            
            Text(difficulty.displayName)
                .font(.caption)
                .fontWeight(.semibold)
        }
        .foregroundColor(config.color)
        .padding(.horizontal, 10)
        .padding(.vertical, 4)
        .background(config.color.opacity(0.2))
        .cornerRadius(12)
    }
}

struct QuickStatCard: View {
    let icon: String
    let title: String
    let value: String
    let unit: String
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
                
                Text(unit)
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.1), radius: 2, x: 0, y: 1)
    }
}

struct MuscleGroupChip: View {
    let muscleGroup: String
    @EnvironmentObject var themeManager: ThemeManager
    
    var body: some View {
        Text(muscleGroup)
            .font(.caption)
            .fontWeight(.medium)
            .padding(.horizontal, 10)
            .padding(.vertical, 4)
            .background(themeManager.currentTheme.primaryColor.opacity(0.2))
            .foregroundColor(themeManager.currentTheme.primaryColor)
            .cornerRadius(8)
    }
}

struct EquipmentChip: View {
    let equipment: String
    
    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: "wrench.and.screwdriver.fill")
                .font(.caption2)
            
            Text(equipment)
                .font(.caption)
                .fontWeight(.medium)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(Color.orange.opacity(0.2))
        .foregroundColor(.orange)
        .cornerRadius(6)
    }
}

struct ExerciseRow: View {
    let exercise: Exercise
    let index: Int
    let isExpanded: Bool
    let onTap: () -> Void
    let onDetailTap: () -> Void
    let onSubstitute: () -> Void
    
    @EnvironmentObject var themeManager: ThemeManager
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Main exercise row
            Button(action: onTap) {
                HStack {
                    // Exercise number
                    ZStack {
                        Circle()
                            .fill(themeManager.currentTheme.primaryColor)
                            .frame(width: 30, height: 30)
                        
                        Text("\(index)")
                            .font(.caption)
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                    }
                    
                    // Exercise info
                    VStack(alignment: .leading, spacing: 4) {
                        Text(exercise.name)
                            .font(.subheadline)
                            .fontWeight(.medium)
                            .foregroundColor(themeManager.currentTheme.textColor)
                        
                        Text("\(exercise.sets.count) sets • \(exercise.primaryMuscleGroup)")
                            .font(.caption)
                            .foregroundColor(themeManager.currentTheme.secondaryTextColor)
                    }
                    
                    Spacer()
                    
                    // Actions
                    HStack(spacing: 8) {
                        Button(action: onSubstitute) {
                            Image(systemName: "arrow.triangle.2.circlepath")
                                .font(.caption)
                                .foregroundColor(themeManager.currentTheme.accentColor)
                        }
                        
                        Button(action: onDetailTap) {
                            Image(systemName: "info.circle")
                                .font(.caption)
                                .foregroundColor(themeManager.currentTheme.primaryColor)
                        }
                        
                        Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                            .font(.caption)
                            .foregroundColor(.gray)
                    }
                }
                .padding()
            }
            .buttonStyle(PlainButtonStyle())
            
            // Expanded details
            if isExpanded {
                VStack(alignment: .leading, spacing: 8) {
                    ForEach(Array(exercise.sets.enumerated()), id: \.offset) { setIndex, set in
                        HStack {
                            Text("Set \(setIndex + 1):")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            
                            Text("\(set.reps) reps")
                                .font(.caption)
                                .fontWeight(.medium)
                            
                            if set.weight > 0 {
                                Text("@ \(Int(set.weight)) lbs")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            
                            Spacer()
                            
                            Text("\(set.restTime)s rest")
                                .font(.caption2)
                                .foregroundColor(.secondary)
                        }
                    }
                    
                    if !exercise.instructions.isEmpty {
                        Text("Instructions: \(exercise.instructions)")
                            .font(.caption)
                            .foregroundColor(themeManager.currentTheme.secondaryTextColor)
                            .padding(.top, 4)
                    }
                }
                .padding(.horizontal)
                .padding(.bottom)
            }
        }
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.05), radius: 2, x: 0, y: 1)
    }
}

// MARK: - FlexibleView for wrapping content
struct FlexibleView<Data: Collection, Content: View>: View where Data.Element: Hashable {
    let data: Data
    let spacing: CGFloat
    let alignment: HorizontalAlignment
    let content: (Data.Element) -> Content
    
    var body: some View {
        VStack(alignment: alignment, spacing: spacing) {
            // This is a simplified version - a real implementation would calculate line wrapping
            HStack {
                ForEach(Array(data), id: \.self) { item in
                    content(item)
                }
            }
        }
    }
}

#Preview {
    WorkoutDetailView(workout: Workout(
        id: "1",
        name: "Upper Body Strength",
        description: "Build powerful upper body strength with compound movements",
        category: .strength,
        difficulty: .intermediate,
        estimatedDuration: 45,
        estimatedCalories: 300,
        targetMuscleGroups: ["Chest", "Back", "Shoulders", "Arms"],
        exercises: []
    ))
    .environmentObject(WorkoutManager())
    .environmentObject(ThemeManager())
    .environmentObject(CharacterManager())
    .environmentObject(AICoach())
}
