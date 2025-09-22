import SwiftUI
import Combine

struct WorkoutGeneratorView: View {
    @EnvironmentObject var aiCoach: AICoachManager
    @EnvironmentObject var workoutManager: WorkoutManager
    @EnvironmentObject var themeManager: ThemeManager
    @EnvironmentObject var authManager: AuthenticationManager
    
    @Environment(\.dismiss) private var dismiss
    
    @State private var selectedGoal: WorkoutGoal = .strength
    @State private var selectedDuration: Int = 30
    @State private var selectedDifficulty: WorkoutDifficulty = .intermediate
    @State private var selectedEquipment: Set<Equipment> = []
    @State private var selectedMuscleGroups: Set<MuscleGroup> = []
    @State private var specialRequests: String = ""
    @State private var currentStep: GeneratorStep = .goal
    @State private var isGenerating = false
    @State private var generatedWorkout: Workout?
    @State private var showingPreview = false
    @State private var showingEquipmentSelector = false
    
    let durations = [15, 20, 30, 45, 60, 75, 90]
    
    var body: some View {
        NavigationView {
            ZStack {
                themeManager.currentTheme.backgroundColor.ignoresSafeArea()
                
                VStack(spacing: 0) {
                    // Progress Bar
                    progressBar
                    
                    // Content
                    ScrollView {
                        VStack(spacing: 24) {
                            headerSection
                            
                            switch currentStep {
                            case .goal:
                                goalSelectionSection
                            case .duration:
                                durationSelectionSection
                            case .difficulty:
                                difficultySelectionSection
                            case .equipment:
                                equipmentSelectionSection
                            case .muscleGroups:
                                muscleGroupSelectionSection
                            case .preferences:
                                preferencesSection
                            case .generating:
                                generatingSection
                            case .preview:
                                previewSection
                            }
                            
                            Spacer(minLength: 100)
                        }
                        .padding(.horizontal)
                        .padding(.top)
                    }
                    
                    // Navigation Buttons
                    navigationButtons
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    if currentStep == .preview {
                        Button("Save") {
                            saveWorkout()
                        }
                        .fontWeight(.semibold)
                        .foregroundColor(themeManager.currentTheme.accentColor)
                    }
                }
            }
        }
        .sheet(isPresented: $showingEquipmentSelector) {
            EquipmentSelectorView(selectedEquipment: $selectedEquipment)
        }
        .sheet(isPresented: $showingPreview) {
            if let workout = generatedWorkout {
                WorkoutDetailView(workout: workout)
            }
        }
    }
    
    // MARK: - Progress Bar
    private var progressBar: some View {
        GeometryReader { geometry in
            ZStack(alignment: .leading) {
                Rectangle()
                    .fill(Color.gray.opacity(0.3))
                    .frame(height: 4)
                
                Rectangle()
                    .fill(themeManager.currentTheme.accentColor)
                    .frame(width: geometry.size.width * progressPercentage, height: 4)
                    .animation(.easeInOut(duration: 0.3), value: progressPercentage)
            }
        }
        .frame(height: 4)
    }
    
    private var progressPercentage: CGFloat {
        switch currentStep {
        case .goal: return 0.14
        case .duration: return 0.28
        case .difficulty: return 0.42
        case .equipment: return 0.56
        case .muscleGroups: return 0.70
        case .preferences: return 0.84
        case .generating, .preview: return 1.0
        }
    }
    
    // MARK: - Header Section
    private var headerSection: some View {
        VStack(spacing: 8) {
            Text("🤖 AI Workout Generator")
                .font(.largeTitle)
                .fontWeight(.bold)
                .foregroundColor(themeManager.currentTheme.primaryTextColor)
            
            Text(stepDescription)
                .font(.subheadline)
                .foregroundColor(themeManager.currentTheme.secondaryTextColor)
                .multilineTextAlignment(.center)
        }
    }
    
    private var stepDescription: String {
        switch currentStep {
        case .goal:
            return "What's your main fitness goal for this workout?"
        case .duration:
            return "How much time do you have available?"
        case .difficulty:
            return "Choose your difficulty level"
        case .equipment:
            return "What equipment do you have access to?"
        case .muscleGroups:
            return "Which muscle groups would you like to target?"
        case .preferences:
            return "Any special requests or preferences?"
        case .generating:
            return "Creating your personalized workout..."
        case .preview:
            return "Here's your custom workout!"
        }
    }
    
    // MARK: - Goal Selection
    private var goalSelectionSection: some View {
        VStack(spacing: 16) {
            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2), spacing: 16) {
                ForEach(WorkoutGoal.allCases, id: \.self) { goal in
                    GoalCard(
                        goal: goal,
                        isSelected: selectedGoal == goal
                    ) {
                        selectedGoal = goal
                    }
                }
            }
        }
    }
    
    // MARK: - Duration Selection
    private var durationSelectionSection: some View {
        VStack(spacing: 20) {
            HStack {
                Text("Duration: \(selectedDuration) minutes")
                    .font(.headline)
                    .foregroundColor(themeManager.currentTheme.primaryTextColor)
                Spacer()
            }
            
            Slider(value: Binding(
                get: { Double(selectedDuration) },
                set: { selectedDuration = Int($0) }
            ), in: 15...90, step: 15)
            .accentColor(themeManager.currentTheme.accentColor)
            
            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 4), spacing: 12) {
                ForEach(durations, id: \.self) { duration in
                    Button("\(duration)m") {
                        selectedDuration = duration
                    }
                    .padding(.vertical, 8)
                    .frame(maxWidth: .infinity)
                    .background(selectedDuration == duration ? themeManager.currentTheme.accentColor : Color.gray.opacity(0.2))
                    .foregroundColor(selectedDuration == duration ? .white : themeManager.currentTheme.primaryTextColor)
                    .cornerRadius(8)
                }
            }
        }
    }
    
    // MARK: - Difficulty Selection
    private var difficultySelectionSection: some View {
        VStack(spacing: 16) {
            ForEach(WorkoutDifficulty.allCases, id: \.self) { difficulty in
                DifficultyCard(
                    difficulty: difficulty,
                    isSelected: selectedDifficulty == difficulty
                ) {
                    selectedDifficulty = difficulty
                }
            }
        }
    }
    
    // MARK: - Equipment Selection
    private var equipmentSelectionSection: some View {
        VStack(spacing: 16) {
            HStack {
                Text("Selected: \(selectedEquipment.count) items")
                    .font(.subheadline)
                    .foregroundColor(themeManager.currentTheme.secondaryTextColor)
                Spacer()
                Button("View All") {
                    showingEquipmentSelector = true
                }
                .font(.caption)
                .foregroundColor(themeManager.currentTheme.accentColor)
            }
            
            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 3), spacing: 12) {
                ForEach(Equipment.common, id: \.self) { equipment in
                    EquipmentCard(
                        equipment: equipment,
                        isSelected: selectedEquipment.contains(equipment)
                    ) {
                        if selectedEquipment.contains(equipment) {
                            selectedEquipment.remove(equipment)
                        } else {
                            selectedEquipment.insert(equipment)
                        }
                    }
                }
            }
            
            if selectedEquipment.isEmpty {
                BodyweightOnlyCard {
                    // Keep equipment empty for bodyweight workout
                }
            }
        }
    }
    
    // MARK: - Muscle Groups Selection
    private var muscleGroupSelectionSection: some View {
        VStack(spacing: 16) {
            HStack {
                Text("Target Groups: \(selectedMuscleGroups.count)")
                    .font(.subheadline)
                    .foregroundColor(themeManager.currentTheme.secondaryTextColor)
                Spacer()
                if !selectedMuscleGroups.isEmpty {
                    Button("Clear All") {
                        selectedMuscleGroups.removeAll()
                    }
                    .font(.caption)
                    .foregroundColor(themeManager.currentTheme.accentColor)
                }
            }
            
            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2), spacing: 12) {
                ForEach(MuscleGroup.allCases, id: \.self) { muscleGroup in
                    MuscleGroupCard(
                        muscleGroup: muscleGroup,
                        isSelected: selectedMuscleGroups.contains(muscleGroup)
                    ) {
                        if selectedMuscleGroups.contains(muscleGroup) {
                            selectedMuscleGroups.remove(muscleGroup)
                        } else {
                            selectedMuscleGroups.insert(muscleGroup)
                        }
                    }
                }
            }
            
            if selectedMuscleGroups.isEmpty {
                FullBodyCard {
                    // Keep muscle groups empty for full body
                }
            }
        }
    }
    
    // MARK: - Preferences Section
    private var preferencesSection: some View {
        VStack(spacing: 20) {
            VStack(alignment: .leading, spacing: 8) {
                Text("Special Requests")
                    .font(.headline)
                    .foregroundColor(themeManager.currentTheme.primaryTextColor)
                
                Text("Any injuries, preferences, or specific exercises you'd like included?")
                    .font(.caption)
                    .foregroundColor(themeManager.currentTheme.secondaryTextColor)
                
                TextField("e.g., No jumping exercises, focus on core, include push-ups...", text: $specialRequests, axis: .vertical)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .lineLimit(3...6)
            }
            
            // Summary Card
            WorkoutSummaryCard(
                goal: selectedGoal,
                duration: selectedDuration,
                difficulty: selectedDifficulty,
                equipmentCount: selectedEquipment.count,
                muscleGroupCount: selectedMuscleGroups.count
            )
        }
    }
    
    // MARK: - Generating Section
    private var generatingSection: some View {
        VStack(spacing: 24) {
            // Animation
            ZStack {
                Circle()
                    .stroke(themeManager.currentTheme.accentColor.opacity(0.3), lineWidth: 4)
                    .frame(width: 120, height: 120)
                
                Circle()
                    .trim(from: 0, to: 0.7)
                    .stroke(themeManager.currentTheme.accentColor, lineWidth: 4)
                    .frame(width: 120, height: 120)
                    .rotationEffect(.degrees(isGenerating ? 360 : 0))
                    .animation(.linear(duration: 2).repeatForever(autoreverses: false), value: isGenerating)
                
                Text("🦍")
                    .font(.system(size: 40))
                    .scaleEffect(isGenerating ? 1.2 : 1.0)
                    .animation(.easeInOut(duration: 1).repeatForever(autoreverses: true), value: isGenerating)
            }
            
            VStack(spacing: 8) {
                Text("Analyzing your preferences...")
                    .font(.headline)
                    .foregroundColor(themeManager.currentTheme.primaryTextColor)
                
                Text("This may take a few seconds")
                    .font(.caption)
                    .foregroundColor(themeManager.currentTheme.secondaryTextColor)
            }
        }
        .onAppear {
            isGenerating = true
            generateWorkout()
        }
    }
    
    // MARK: - Preview Section
    private var previewSection: some View {
        VStack(spacing: 20) {
            if let workout = generatedWorkout {
                WorkoutPreviewCard(workout: workout) {
                    showingPreview = true
                }
                
                // Quick Stats
                HStack(spacing: 20) {
                    StatItem(title: "Exercises", value: "\(workout.exercises.count)")
                    StatItem(title: "Duration", value: "\(workout.estimatedDuration)m")
                    StatItem(title: "Difficulty", value: workout.difficulty.rawValue.capitalized)
                    StatItem(title: "Calories", value: "~\(workout.estimatedCalories)")
                }
                .padding()
                .background(themeManager.currentTheme.cardBackgroundColor)
                .cornerRadius(12)
                
                // Action Buttons
                VStack(spacing: 12) {
                    Button("Start This Workout") {
                        startWorkout(workout)
                    }
                    .buttonStyle(PrimaryButtonStyle())
                    
                    HStack(spacing: 12) {
                        Button("Regenerate") {
                            regenerateWorkout()
                        }
                        .buttonStyle(SecondaryButtonStyle())
                        
                        Button("View Details") {
                            showingPreview = true
                        }
                        .buttonStyle(SecondaryButtonStyle())
                    }
                }
            }
        }
    }
    
    // MARK: - Navigation Buttons
    private var navigationButtons: some View {
        HStack(spacing: 16) {
            if currentStep != .goal && currentStep != .generating && currentStep != .preview {
                Button("Back") {
                    previousStep()
                }
                .buttonStyle(SecondaryButtonStyle())
            }
            
            if currentStep != .generating && currentStep != .preview {
                Button(currentStep == .preferences ? "Generate" : "Next") {
                    nextStep()
                }
                .buttonStyle(PrimaryButtonStyle())
                .disabled(!canProceed)
            }
        }
        .padding()
        .background(themeManager.currentTheme.backgroundColor)
    }
    
    private var canProceed: Bool {
        switch currentStep {
        case .goal, .duration, .difficulty:
            return true
        case .equipment:
            return true // Can proceed with no equipment (bodyweight)
        case .muscleGroups:
            return true // Can proceed with no selection (full body)
        case .preferences:
            return true
        case .generating, .preview:
            return false
        }
    }
    
    // MARK: - Navigation Logic
    private func nextStep() {
        withAnimation(.easeInOut(duration: 0.3)) {
            switch currentStep {
            case .goal:
                currentStep = .duration
            case .duration:
                currentStep = .difficulty
            case .difficulty:
                currentStep = .equipment
            case .equipment:
                currentStep = .muscleGroups
            case .muscleGroups:
                currentStep = .preferences
            case .preferences:
                currentStep = .generating
            case .generating, .preview:
                break
            }
        }
    }
    
    private func previousStep() {
        withAnimation(.easeInOut(duration: 0.3)) {
            switch currentStep {
            case .goal:
                break
            case .duration:
                currentStep = .goal
            case .difficulty:
                currentStep = .duration
            case .equipment:
                currentStep = .difficulty
            case .muscleGroups:
                currentStep = .equipment
            case .preferences:
                currentStep = .muscleGroups
            case .generating, .preview:
                currentStep = .preferences
            }
        }
    }
    
    // MARK: - Workout Generation
    private func generateWorkout() {
        Task {
            do {
                let request = WorkoutGenerationRequest(
                    goal: selectedGoal,
                    duration: selectedDuration,
                    difficulty: selectedDifficulty,
                    equipment: Array(selectedEquipment),
                    muscleGroups: Array(selectedMuscleGroups),
                    specialRequests: specialRequests.isEmpty ? nil : specialRequests,
                    userLevel: authManager.currentUser?.level ?? 1
                )
                
                let workout = try await aiCoach.generateCustomWorkout(request: request)
                
                await MainActor.run {
                    generatedWorkout = workout
                    currentStep = .preview
                    isGenerating = false
                }
            } catch {
                await MainActor.run {
                    // Handle error - could show alert
                    currentStep = .preferences
                    isGenerating = false
                }
            }
        }
    }
    
    private func regenerateWorkout() {
        currentStep = .generating
        generateWorkout()
    }
    
    private func startWorkout(_ workout: Workout) {
        workoutManager.startWorkout(workout)
        dismiss()
    }
    
    private func saveWorkout() {
        guard let workout = generatedWorkout else { return }
        workoutManager.addCustomWorkout(workout)
        dismiss()
    }
}

// MARK: - Generator Steps
enum GeneratorStep: CaseIterable {
    case goal, duration, difficulty, equipment, muscleGroups, preferences, generating, preview
}

// MARK: - Supporting Views

struct GoalCard: View {
    let goal: WorkoutGoal
    let isSelected: Bool
    let action: () -> Void
    @EnvironmentObject var themeManager: ThemeManager
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 12) {
                Text(goal.emoji)
                    .font(.system(size: 32))
                
                Text(goal.rawValue.capitalized)
                    .font(.headline)
                    .fontWeight(.medium)
                
                Text(goal.description)
                    .font(.caption)
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
            }
            .frame(maxWidth: .infinity)
            .padding()
            .background(isSelected ? themeManager.currentTheme.accentColor.opacity(0.2) : themeManager.currentTheme.cardBackgroundColor)
            .foregroundColor(isSelected ? themeManager.currentTheme.accentColor : themeManager.currentTheme.primaryTextColor)
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(isSelected ? themeManager.currentTheme.accentColor : Color.clear, lineWidth: 2)
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct DifficultyCard: View {
    let difficulty: WorkoutDifficulty
    let isSelected: Bool
    let action: () -> Void
    @EnvironmentObject var themeManager: ThemeManager
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 16) {
                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Text(difficulty.rawValue.capitalized)
                            .font(.headline)
                            .fontWeight(.medium)
                        
                        Spacer()
                        
                        HStack(spacing: 2) {
                            ForEach(1...5, id: \.self) { level in
                                Circle()
                                    .fill(level <= difficulty.level ? difficulty.color : Color.gray.opacity(0.3))
                                    .frame(width: 8, height: 8)
                            }
                        }
                    }
                    
                    Text(difficulty.description)
                        .font(.caption)
                        .foregroundColor(themeManager.currentTheme.secondaryTextColor)
                }
                
                Spacer()
            }
            .padding()
            .background(isSelected ? themeManager.currentTheme.accentColor.opacity(0.1) : themeManager.currentTheme.cardBackgroundColor)
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(isSelected ? themeManager.currentTheme.accentColor : Color.clear, lineWidth: 2)
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct EquipmentCard: View {
    let equipment: Equipment
    let isSelected: Bool
    let action: () -> Void
    @EnvironmentObject var themeManager: ThemeManager
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 8) {
                Text(equipment.emoji)
                    .font(.title2)
                
                Text(equipment.name)
                    .font(.caption)
                    .fontWeight(.medium)
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
            .background(isSelected ? themeManager.currentTheme.accentColor.opacity(0.2) : themeManager.currentTheme.cardBackgroundColor)
            .foregroundColor(isSelected ? themeManager.currentTheme.accentColor : themeManager.currentTheme.primaryTextColor)
            .cornerRadius(8)
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(isSelected ? themeManager.currentTheme.accentColor : Color.clear, lineWidth: 1)
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct MuscleGroupCard: View {
    let muscleGroup: MuscleGroup
    let isSelected: Bool
    let action: () -> Void
    @EnvironmentObject var themeManager: ThemeManager
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 12) {
                Text(muscleGroup.emoji)
                    .font(.title3)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(muscleGroup.rawValue.capitalized)
                        .font(.subheadline)
                        .fontWeight(.medium)
                    
                    Text(muscleGroup.description)
                        .font(.caption2)
                        .foregroundColor(themeManager.currentTheme.secondaryTextColor)
                        .lineLimit(1)
                }
                
                Spacer()
            }
            .padding()
            .background(isSelected ? themeManager.currentTheme.accentColor.opacity(0.15) : themeManager.currentTheme.cardBackgroundColor)
            .cornerRadius(10)
            .overlay(
                RoundedRectangle(cornerRadius: 10)
                    .stroke(isSelected ? themeManager.currentTheme.accentColor : Color.clear, lineWidth: 1.5)
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct BodyweightOnlyCard: View {
    let action: () -> Void
    @EnvironmentObject var themeManager: ThemeManager
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 8) {
                Text("💪")
                    .font(.title)
                
                Text("Bodyweight Only")
                    .font(.subheadline)
                    .fontWeight(.medium)
                
                Text("No equipment needed")
                    .font(.caption)
                    .foregroundColor(themeManager.currentTheme.secondaryTextColor)
            }
            .frame(maxWidth: .infinity)
            .padding()
            .background(themeManager.currentTheme.accentColor.opacity(0.1))
            .foregroundColor(themeManager.currentTheme.accentColor)
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(themeManager.currentTheme.accentColor, lineWidth: 1)
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct FullBodyCard: View {
    let action: () -> Void
    @EnvironmentObject var themeManager: ThemeManager
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 8) {
                Text("🏋️")
                    .font(.title)
                
                Text("Full Body Workout")
                    .font(.subheadline)
                    .fontWeight(.medium)
                
                Text("Target all muscle groups")
                    .font(.caption)
                    .foregroundColor(themeManager.currentTheme.secondaryTextColor)
            }
            .frame(maxWidth: .infinity)
            .padding()
            .background(themeManager.currentTheme.accentColor.opacity(0.1))
            .foregroundColor(themeManager.currentTheme.accentColor)
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(themeManager.currentTheme.accentColor, lineWidth: 1)
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct WorkoutSummaryCard: View {
    let goal: WorkoutGoal
    let duration: Int
    let difficulty: WorkoutDifficulty
    let equipmentCount: Int
    let muscleGroupCount: Int
    @EnvironmentObject var themeManager: ThemeManager
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Workout Summary")
                .font(.headline)
                .foregroundColor(themeManager.currentTheme.primaryTextColor)
            
            VStack(spacing: 8) {
                SummaryRow(title: "Goal", value: goal.rawValue.capitalized, emoji: goal.emoji)
                SummaryRow(title: "Duration", value: "\(duration) minutes", emoji: "⏱️")
                SummaryRow(title: "Difficulty", value: difficulty.rawValue.capitalized, emoji: "🎯")
                SummaryRow(title: "Equipment", value: equipmentCount > 0 ? "\(equipmentCount) items" : "Bodyweight only", emoji: "🏋️")
                SummaryRow(title: "Target", value: muscleGroupCount > 0 ? "\(muscleGroupCount) muscle groups" : "Full body", emoji: "💪")
            }
        }
        .padding()
        .background(themeManager.currentTheme.cardBackgroundColor)
        .cornerRadius(12)
    }
}

struct SummaryRow: View {
    let title: String
    let value: String
    let emoji: String
    @EnvironmentObject var themeManager: ThemeManager
    
    var body: some View {
        HStack {
            Text(emoji)
            Text(title)
                .foregroundColor(themeManager.currentTheme.secondaryTextColor)
            Spacer()
            Text(value)
                .fontWeight(.medium)
                .foregroundColor(themeManager.currentTheme.primaryTextColor)
        }
        .font(.subheadline)
    }
}

struct WorkoutPreviewCard: View {
    let workout: Workout
    let action: () -> Void
    @EnvironmentObject var themeManager: ThemeManager
    
    var body: some View {
        Button(action: action) {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Text(workout.name)
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(themeManager.currentTheme.primaryTextColor)
                    
                    Spacer()
                    
                    Text("Tap to view")
                        .font(.caption)
                        .foregroundColor(themeManager.currentTheme.accentColor)
                }
                
                Text(workout.description)
                    .font(.subheadline)
                    .foregroundColor(themeManager.currentTheme.secondaryTextColor)
                    .lineLimit(2)
                
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        ForEach(workout.exercises.prefix(3)) { exercise in
                            ExercisePreviewChip(exercise: exercise)
                        }
                        
                        if workout.exercises.count > 3 {
                            Text("+\(workout.exercises.count - 3) more")
                                .font(.caption)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(Color.gray.opacity(0.2))
                                .cornerRadius(8)
                        }
                    }
                    .padding(.horizontal, 4)
                }
            }
            .padding()
            .background(themeManager.currentTheme.cardBackgroundColor)
            .cornerRadius(12)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct ExercisePreviewChip: View {
    let exercise: Exercise
    
    var body: some View {
        Text(exercise.name)
            .font(.caption)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(Color.blue.opacity(0.1))
            .foregroundColor(.blue)
            .cornerRadius(8)
    }
}

struct StatItem: View {
    let title: String
    let value: String
    @EnvironmentObject var themeManager: ThemeManager
    
    var body: some View {
        VStack(spacing: 4) {
            Text(value)
                .font(.headline)
                .fontWeight(.bold)
                .foregroundColor(themeManager.currentTheme.primaryTextColor)
            
            Text(title)
                .font(.caption)
                .foregroundColor(themeManager.currentTheme.secondaryTextColor)
        }
    }
}

// MARK: - Button Styles

struct PrimaryButtonStyle: ButtonStyle {
    @EnvironmentObject var themeManager: ThemeManager
    
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.headline)
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .padding()
            .background(themeManager.currentTheme.accentColor)
            .cornerRadius(12)
            .scaleEffect(configuration.isPressed ? 0.95 : 1.0)
            .animation(.easeInOut(duration: 0.1), value: configuration.isPressed)
    }
}

struct SecondaryButtonStyle: ButtonStyle {
    @EnvironmentObject var themeManager: ThemeManager
    
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.headline)
            .foregroundColor(themeManager.currentTheme.accentColor)
            .frame(maxWidth: .infinity)
            .padding()
            .background(themeManager.currentTheme.accentColor.opacity(0.1))
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(themeManager.currentTheme.accentColor, lineWidth: 1)
            )
            .scaleEffect(configuration.isPressed ? 0.95 : 1.0)
            .animation(.easeInOut(duration: 0.1), value: configuration.isPressed)
    }
}

#Preview {
    WorkoutGeneratorView()
        .environmentObject(AICoachManager())
        .environmentObject(WorkoutManager())
        .environmentObject(ThemeManager())
        .environmentObject(AuthenticationManager())
}
