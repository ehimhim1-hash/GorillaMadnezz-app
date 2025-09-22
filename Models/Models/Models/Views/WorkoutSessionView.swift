import SwiftUI
import AVFoundation
import CoreHaptics

struct WorkoutSessionView: View {
    let workout: Workout
    
    @EnvironmentObject var workoutManager: WorkoutManager
    @EnvironmentObject var progressManager: ProgressManager
    @EnvironmentObject var themeManager: ThemeManager
    @EnvironmentObject var healthManager: HealthManager
    @EnvironmentObject var notificationManager: NotificationManager
    
    @Environment(\.dismiss) private var dismiss
    
    @State private var currentExerciseIndex = 0
    @State private var currentSetIndex = 0
    @State private var isResting = false
    @State private var restTimeRemaining = 0
    @State private var workoutTimeElapsed = 0
    @State private var sessionStartTime = Date()
    @State private var showingPauseMenu = false
    @State private var showingWorkoutComplete = false
    @State private var showingExitConfirmation = false
    @State private var exerciseNotes: [String: String] = [:]
    @State private var completedSets: [String: [ExerciseSet]] = [:]
    @State private var workoutPaused = false
    @State private var heartRate: Double = 0
    @State private var caloriesBurned: Double = 0
    @State private var restTimer: Timer?
    @State private var workoutTimer: Timer?
    @State private var hapticEngine: CHHapticEngine?
    
    private var currentExercise: Exercise {
        workout.exercises[currentExerciseIndex]
    }
    
    private var currentSet: ExerciseSet {
        currentExercise.sets[currentSetIndex]
    }
    
    private var isLastExercise: Bool {
        currentExerciseIndex == workout.exercises.count - 1
    }
    
    private var isLastSet: Bool {
        currentSetIndex == currentExercise.sets.count - 1
    }
    
    var body: some View {
        ZStack {
            // Background
            themeManager.currentTheme.backgroundColor.ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Header
                headerSection
                
                // Main Content
                ScrollView {
                    VStack(spacing: 24) {
                        // Progress Indicator
                        progressSection
                        
                        // Current Exercise
                        if !isResting {
                            currentExerciseSection
                        } else {
                            restTimerSection
                        }
                        
                        // Exercise Instructions
                        if !isResting {
                            exerciseInstructionsSection
                        }
                        
                        // Workout Stats
                        workoutStatsSection
                        
                        // Exercise History
                        if !isResting {
                            exerciseHistorySection
                        }
                        
                        Spacer(minLength: 120)
                    }
                    .padding(.horizontal)
                    .padding(.top)
                }
                
                // Bottom Action Area
                bottomActionSection
            }
        }
        .navigationBarHidden(true)
        .onAppear {
            setupWorkoutSession()
        }
        .onDisappear {
            cleanupWorkoutSession()
        }
        .sheet(isPresented: $showingPauseMenu) {
            WorkoutPauseMenuView(
                workout: workout,
                timeElapsed: workoutTimeElapsed,
                onResume: resumeWorkout,
                onExit: exitWorkout
            )
        }
        .sheet(isPresented: $showingWorkoutComplete) {
            WorkoutCompleteView(
                workout: workout,
                session: createWorkoutSession()
            )
        }
        .alert("Exit Workout?", isPresented: $showingExitConfirmation) {
            Button("Cancel", role: .cancel) { }
            Button("Exit", role: .destructive) {
                exitWorkout()
            }
        } message: {
            Text("Your progress will be saved, but the workout will be marked as incomplete.")
        }
    }
    
    // MARK: - Header Section
    private var headerSection: some View {
        HStack {
            Button(action: { showingExitConfirmation = true }) {
                Image(systemName: "xmark")
                    .font(.title2)
                    .foregroundColor(themeManager.currentTheme.primaryTextColor)
            }
            
            VStack(spacing: 2) {
                Text(workout.name)
                    .font(.headline)
                    .fontWeight(.bold)
                    .foregroundColor(themeManager.currentTheme.primaryTextColor)
                
                Text(formatTime(workoutTimeElapsed))
                    .font(.subheadline)
                    .foregroundColor(themeManager.currentTheme.secondaryTextColor)
                    .monospacedDigit()
            }
            
            Spacer()
            
            Button(action: { showingPauseMenu = true }) {
                Image(systemName: workoutPaused ? "play.fill" : "pause.fill")
                    .font(.title2)
                    .foregroundColor(themeManager.currentTheme.accentColor)
            }
        }
        .padding()
        .background(themeManager.currentTheme.cardBackgroundColor)
        .shadow(color: Color.black.opacity(0.1), radius: 4, x: 0, y: 2)
    }
    
    // MARK: - Progress Section
    private var progressSection: some View {
        VStack(spacing: 12) {
            // Overall Progress
            HStack {
                Text("Exercise \(currentExerciseIndex + 1) of \(workout.exercises.count)")
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(themeManager.currentTheme.primaryTextColor)
                
                Spacer()
                
                Text("\(Int(overallProgress * 100))% Complete")
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(themeManager.currentTheme.accentColor)
            }
            
            ProgressView(value: overallProgress)
                .progressViewStyle(LinearProgressViewStyle(tint: themeManager.currentTheme.accentColor))
                .scaleEffect(y: 1.5)
            
            // Set Progress
            if !isResting {
                HStack {
                    Text("Set \(currentSetIndex + 1) of \(currentExercise.sets.count)")
                        .font(.caption)
                        .foregroundColor(themeManager.currentTheme.secondaryTextColor)
                    
                    Spacer()
                    
                    HStack(spacing: 4) {
                        ForEach(0..<currentExercise.sets.count, id: \.self) { index in
                            Circle()
                                .fill(index <= currentSetIndex ? themeManager.currentTheme.accentColor : Color.gray.opacity(0.3))
                                .frame(width: 8, height: 8)
                        }
                    }
                }
            }
        }
        .padding()
        .background(themeManager.currentTheme.cardBackgroundColor)
        .cornerRadius(16)
        .shadow(color: Color.black.opacity(0.1), radius: 8, x: 0, y: 4)
    }
    
    // MARK: - Current Exercise Section
    private var currentExerciseSection: some View {
        VStack(spacing: 16) {
            // Exercise Header
            VStack(spacing: 8) {
                Text(currentExercise.name)
                    .font(.title)
                    .fontWeight(.bold)
                    .foregroundColor(themeManager.currentTheme.primaryTextColor)
                    .multilineTextAlignment(.center)
                
                HStack {
                    ForEach(currentExercise.muscleGroups, id: \.self) { muscle in
                        Text(muscle.rawValue.capitalized)
                            .font(.caption)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(muscle.color.opacity(0.2))
                            .foregroundColor(muscle.color)
                            .cornerRadius(8)
                    }
                }
            }
            
            // Exercise Animation/Image
            ExerciseAnimationView(exercise: currentExercise)
                .frame(height: 200)
                .cornerRadius(16)
            
            // Current Set Details
            VStack(spacing: 12) {
                Text("Set \(currentSetIndex + 1)")
                    .font(.headline)
                    .foregroundColor(themeManager.currentTheme.primaryTextColor)
                
                HStack(spacing: 32) {
                    if let reps = currentSet.reps {
                        StatDisplay(title: "Reps", value: "\(reps)", icon: "repeat")
                    }
                    
                    if let weight = currentSet.weight {
                        StatDisplay(title: "Weight", value: "\(Int(weight)) lbs", icon: "scalemass")
                    }
                    
                    if let duration = currentSet.duration {
                        StatDisplay(title: "Time", value: "\(duration)s", icon: "timer")
                    }
                    
                    if let distance = currentSet.distance {
                        StatDisplay(title: "Distance", value: "\(distance)m", icon: "figure.run")
                    }
                }
            }
            .padding()
            .background(themeManager.currentTheme.backgroundColor.opacity(0.5))
            .cornerRadius(12)
            
            // Notes Section
            VStack(alignment: .leading, spacing: 8) {
                Text("Notes for this set:")
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(themeManager.currentTheme.primaryTextColor)
                
                TextField("Add notes about weight, form, feeling...", text: Binding(
                    get: { exerciseNotes["\(currentExerciseIndex)-\(currentSetIndex)"] ?? "" },
                    set: { exerciseNotes["\(currentExerciseIndex)-\(currentSetIndex)"] = $0 }
                ))
                .textFieldStyle(RoundedBorderTextFieldStyle())
            }
        }
        .padding()
        .background(themeManager.currentTheme.cardBackgroundColor)
        .cornerRadius(16)
        .shadow(color: Color.black.opacity(0.1), radius: 8, x: 0, y: 4)
    }
    
    // MARK: - Rest Timer Section
    private var restTimerSection: some View {
        VStack(spacing: 24) {
            Text("Rest Time")
                .font(.title)
                .fontWeight(.bold)
                .foregroundColor(themeManager.currentTheme.primaryTextColor)
            
            // Circular Timer
            ZStack {
                Circle()
                    .stroke(Color.gray.opacity(0.3), lineWidth: 12)
                    .frame(width: 200, height: 200)
                
                Circle()
                    .trim(from: 0, to: restProgress)
                    .stroke(themeManager.currentTheme.accentColor, style: StrokeStyle(lineWidth: 12, lineCap: .round))
                    .frame(width: 200, height: 200)
                    .rotationEffect(.degrees(-90))
                    .animation(.linear(duration: 1), value: restProgress)
                
                VStack(spacing: 4) {
                    Text(formatTime(restTimeRemaining))
                        .font(.system(size: 36, weight: .bold, design: .rounded))
                        .foregroundColor(themeManager.currentTheme.primaryTextColor)
                        .monospacedDigit()
                    
                    Text("remaining")
                        .font(.caption)
                        .foregroundColor(themeManager.currentTheme.secondaryTextColor)
                }
            }
            
            // Rest Actions
            HStack(spacing: 20) {
                Button(action: addRestTime) {
                    VStack(spacing: 4) {
                        Image(systemName: "plus")
                            .font(.title2)
                        Text("+30s")
                            .font(.caption)
                    }
                    .foregroundColor(themeManager.currentTheme.accentColor)
                    .padding()
                    .background(themeManager.currentTheme.accentColor.opacity(0.1))
                    .cornerRadius(12)
                }
                
                Button(action: skipRest) {
                    VStack(spacing: 4) {
                        Image(systemName: "forward.fill")
                            .font(.title2)
                        Text("Skip")
                            .font(.caption)
                    }
                    .foregroundColor(.orange)
                    .padding()
                    .background(Color.orange.opacity(0.1))
                    .cornerRadius(12)
                }
            }
            
            Text("Next: \(getNextExerciseText())")
                .font(.subheadline)
                .foregroundColor(themeManager.currentTheme.secondaryTextColor)
                .padding()
                .background(themeManager.currentTheme.backgroundColor.opacity(0.5))
                .cornerRadius(8)
        }
        .padding()
        .background(themeManager.currentTheme.cardBackgroundColor)
        .cornerRadius(16)
        .shadow(color: Color.black.opacity(0.1), radius: 8, x: 0, y: 4)
    }
    
    // MARK: - Exercise Instructions Section
    private var exerciseInstructionsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Instructions")
                .font(.headline)
                .fontWeight(.bold)
                .foregroundColor(themeManager.currentTheme.primaryTextColor)
            
            ForEach(Array(currentExercise.instructions.enumerated()), id: \.offset) { index, instruction in
                HStack(alignment: .top, spacing: 12) {
                    Text("\(index + 1)")
                        .font(.caption)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                        .frame(width: 20, height: 20)
                        .background(themeManager.currentTheme.accentColor)
                        .clipShape(Circle())
                    
                    Text(instruction)
                        .font(.subheadline)
                        .foregroundColor(themeManager.currentTheme.primaryTextColor)
                        .fixedSize(horizontal: false, vertical: true)
                    
                    Spacer()
                }
            }
            
            if !currentExercise.tips.isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    Text("💡 Tips")
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(themeManager.currentTheme.primaryTextColor)
                    
                    ForEach(currentExercise.tips, id: \.self) { tip in
                        Text("• \(tip)")
                            .font(.caption)
                            .foregroundColor(themeManager.currentTheme.secondaryTextColor)
                    }
                }
                .padding()
                .background(Color.blue.opacity(0.1))
                .cornerRadius(8)
            }
        }
        .padding()
        .background(themeManager.currentTheme.cardBackgroundColor)
        .cornerRadius(16)
        .shadow(color: Color.black.opacity(0.1), radius: 8, x: 0, y: 4)
    }
    
    // MARK: - Workout Stats Section
    private var workoutStatsSection: some View {
        LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 3), spacing: 12) {
            StatCard(title: "Time", value: formatTime(workoutTimeElapsed), icon: "clock.fill", color: .blue)
            StatCard(title: "Calories", value: "\(Int(caloriesBurned))", icon: "flame.fill", color: .orange)
            
            if heartRate > 0 {
                StatCard(title: "Heart Rate", value: "\(Int(heartRate))", icon: "heart.fill", color: .red)
            } else {
                StatCard(title: "Exercises", value: "\(currentExerciseIndex + 1)/\(workout.exercises.count)", icon: "dumbbell.fill", color: .green)
            }
        }
        .padding()
        .background(themeManager.currentTheme.cardBackgroundColor)
        .cornerRadius(16)
        .shadow(color: Color.black.opacity(0.1), radius: 8, x: 0, y: 4)
    }
    
    // MARK: - Exercise History Section
    private var exerciseHistorySection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Previous Performance")
                .font(.headline)
                .fontWeight(.bold)
                .foregroundColor(themeManager.currentTheme.primaryTextColor)
            
            if let lastWorkout = progressManager.getLastWorkoutWith(exercise: currentExercise.name) {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Last time (\(lastWorkout.date, style: .relative))")
                        .font(.subheadline)
                        .foregroundColor(themeManager.currentTheme.secondaryTextColor)
                    
                    // Show previous sets
                    LazyVStack(spacing: 4) {
                        ForEach(Array(lastWorkout.exercises.enumerated()), id: \.offset) { index, exercise in
                            if exercise.name == currentExercise.name {
                                ForEach(Array(exercise.completedSets.enumerated()), id: \.offset) { setIndex, set in
                                    PreviousSetRow(setNumber: setIndex + 1, set: set)
                                }
                            }
                        }
                    }
                }
                .padding()
                .background(themeManager.currentTheme.backgroundColor.opacity(0.3))
                .cornerRadius(8)
            } else {
                Text("No previous data for this exercise")
                    .font(.subheadline)
                    .foregroundColor(themeManager.currentTheme.secondaryTextColor)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(themeManager.currentTheme.backgroundColor.opacity(0.3))
                    .cornerRadius(8)
            }
        }
        .padding()
        .background(themeManager.currentTheme.cardBackgroundColor)
        .cornerRadius(16)
        .shadow(color: Color.black.opacity(0.1), radius: 8, x: 0, y: 4)
    }
    
    // MARK: - Bottom Action Section
    private var bottomActionSection: some View {
        VStack(spacing: 12) {
            if !isResting {
                Button(action: completeSet) {
                    HStack {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.title2)
                        
                        Text(isLastSet && isLastExercise ? "Complete Workout" : isLastSet ? "Next Exercise" : "Complete Set")
                            .font(.headline)
                            .fontWeight(.semibold)
                    }
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(themeManager.currentTheme.accentColor)
                    .cornerRadius(16)
                }
                .buttonStyle(PressedButtonStyle())
            }
        }
        .padding()
        .background(themeManager.currentTheme.cardBackgroundColor)
        .shadow(color: Color.black.opacity(0.1), radius: 8, x: 0, y: -2)
    }
    
    // MARK: - Computed Properties
    private var overallProgress: Double {
        let totalExercises = workout.exercises.count
        let completedExercises = currentExerciseIndex
        let currentExerciseProgress = Double(currentSetIndex) / Double(currentExercise.sets.count)
        
        return (Double(completedExercises) + currentExerciseProgress) / Double(totalExercises)
    }
    
    private var restProgress: Double {
        let totalRestTime = currentExercise.restTime
        return totalRestTime > 0 ? 1.0 - (Double(restTimeRemaining) / Double(totalRestTime)) : 0
    }
    
    // MARK: - Helper Functions
    private func setupWorkoutSession() {
        sessionStartTime = Date()
        workoutManager.startWorkout(workout)
        
        // Start workout timer
        workoutTimer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { _ in
            if !workoutPaused {
                workoutTimeElapsed += 1
                updateCaloriesBurned()
            }
        }
        
        // Request heart rate data
        healthManager.startHeartRateMonitoring { rate in
            DispatchQueue.main.async {
                heartRate = rate
            }
        }
        
        // Setup haptics
        setupHapticEngine()
    }
    
    private func cleanupWorkoutSession() {
        workoutTimer?.invalidate()
        restTimer?.invalidate()
        healthManager.stopHeartRateMonitoring()
        hapticEngine?.stop()
    }
    
    private func setupHapticEngine() {
        do {
            hapticEngine = try CHHapticEngine()
            try hapticEngine?.start()
        } catch {
            print("Haptic engine failed to start: \(error)")
        }
    }
    
    private func completeSet() {
        // Save completed set
        let completedSet = ExerciseSet(
            reps: currentSet.reps,
            weight: currentSet.weight,
            duration: currentSet.duration,
            distance: currentSet.distance
        )
        
        if completedSets[currentExercise.id] == nil {
            completedSets[currentExercise.id] = []
        }
        completedSets[currentExercise.id]?.append(completedSet)
        
        // Provide haptic feedback
        let impact = UIImpactFeedbackGenerator(style: .medium)
        impact.impactOccurred()
        
        if isLastSet && isLastExercise {
            // Complete workout
            completeWorkout()
        } else if isLastSet {
            // Move to next exercise
            nextExercise()
        } else {
            // Move to next set with rest
            nextSet()
        }
    }
    
    private func nextSet() {
        currentSetIndex += 1
        startRestTimer()
    }
    
    private func nextExercise() {
        currentExerciseIndex += 1
        currentSetIndex = 0
        
        if currentExercise.restTime > 0 {
            startRestTimer()
        }
    }
    
    private func startRestTimer() {
        guard currentExercise.restTime > 0 else { return }
        
        isResting = true
        restTimeRemaining = currentExercise.restTime
        
        restTimer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { _ in
            if !workoutPaused {
                restTimeRemaining -= 1
                
                if restTimeRemaining <= 0 {
                    endRest()
                } else if restTimeRemaining <= 3 {
                    // Countdown haptic feedback
                    let impact = UIImpactFeedbackGenerator(style: .light)
                    impact.impactOccurred()
                }
            }
        }
    }
    
    private func endRest() {
        isResting = false
        restTimer?.invalidate()
        
        // Final haptic feedback
        let impact = UIImpactFeedbackGenerator(style: .heavy)
        impact.impactOccurred()
    }
    
    private func addRestTime() {
        restTimeRemaining += 30
    }
    
    private func skipRest() {
        endRest()
    }
    
    private func completeWorkout() {
        workoutTimer?.invalidate()
        restTimer?.invalidate()
        
        showingWorkoutComplete = true
    }
    
    private func pauseWorkout() {
        workoutPaused = true
        restTimer?.invalidate()
    }
    
    private func resumeWorkout() {
        workoutPaused = false
        if isResting && restTimeRemaining > 0 {
            startRestTimer()
        }
    }
    
    private func exitWorkout() {
        let session = createWorkoutSession()
        session.isCompleted = false
        progressManager.recordWorkoutSession(session)
        
        dismiss()
    }
    
    private func createWorkoutSession() -> WorkoutSession {
        let session = WorkoutSession(
            id: UUID().uuidString,
            workoutId: workout.id,
            workoutName: workout.name,
            date: sessionStartTime,
            duration: Double(workoutTimeElapsed) / 60.0, // Convert to minutes
            exercises: createCompletedExercises(),
            caloriesBurned: caloriesBurned,
            averageHeartRate: heartRate > 0 ? heartRate : nil,
            notes: exerciseNotes.values.joined(separator: "\n"),
            isCompleted: true
        )
        
        return session
    }
    
    private func createCompletedExercises() -> [CompletedExercise] {
        return workout.exercises.enumerated().map { index, exercise in
            let completedSetsForExercise = completedSets[exercise.id] ?? []
            return CompletedExercise(
                name: exercise.name,
                muscleGroups: exercise.muscleGroups,
                completedSets: completedSetsForExercise
            )
        }
    }
    
    private func updateCaloriesBurned() {
        // Simple calorie calculation based on time and intensity
        let baseRate = 8.0 // calories per minute
        let intensityMultiplier = workout.difficulty.calorieMultiplier
        caloriesBurned = Double(workoutTimeElapsed) / 60.0 * baseRate * intensityMultiplier
    }
    
    private func formatTime(_ seconds: Int) -> String {
        let minutes = seconds / 60
        let remainingSeconds = seconds % 60
        return String(format: "%02d:%02d", minutes, remainingSeconds)
    }
    
    private func getNextExerciseText() -> String {
        if isLastSet && isLastExercise {
            return "Workout Complete!"
        } else if isLastSet {
            let nextExercise = workout.exercises[currentExerciseIndex + 1]
            return nextExercise.name
        } else {
            return "\(currentExercise.name) - Set \(currentSetIndex + 2)"
        }
    }
}

// MARK: - Supporting Views

struct StatDisplay: View {
    let title: String
    let value: String
    let icon: String
    @EnvironmentObject var themeManager: ThemeManager
    
    var body: some View {
        VStack(spacing: 4) {
            Image(systemName: icon)
                .foregroundColor(themeManager.currentTheme.accentColor)
                .font(.title3)
            
            Text(value)
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(themeManager.currentTheme.primaryTextColor)
            
            Text(title)
                .font(.caption)
                .foregroundColor(themeManager.currentTheme.secondaryTextColor)
        }
    }
}

struct StatCard: View {
    let title: String
    let value: String
    let icon: String
    let color: Color
    @EnvironmentObject var themeManager: ThemeManager
    
    var body: some View {
        VStack(spacing: 6) {
            Image(systemName: icon)
                .foregroundColor(color)
                .font(.title3)
            
            Text(value)
                .font(.headline)
                .fontWeight(.bold)
                .foregroundColor(themeManager.currentTheme.primaryTextColor)
            
            Text(title)
                .font(.caption)
                .foregroundColor(themeManager.currentTheme.secondaryTextColor)
        }
        .padding()
        .background(color.opacity(0.1))
        .cornerRadius(8)
    }
}

struct ExerciseAnimationView: View {
    let exercise: Exercise
    @State private var animationPhase = 0.0
    
    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 16)
                .fill(LinearGradient(
                    colors: [Color.blue.opacity(0.3), Color.purple.opacity(0.3)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                ))
            
            VStack(spacing: 12) {
                Text(exercise.category.emoji)
                    .font(.system(size: 60))
                    .scaleEffect(1.0 + sin(animationPhase) * 0.1)
                    .animation(.easeInOut(duration: 2).repeatForever(), value: animationPhase)
                
                Text("Exercise Animation")
                    .font(.caption)
                    .foregroundColor(.white)
                    .opacity(0.8)
            }
        }
        .onAppear {
            animationPhase = .pi
        }
    }
}

struct PreviousSetRow: View {
    let setNumber: Int
    let set: ExerciseSet
    @EnvironmentObject var themeManager: ThemeManager
    
    var body: some View {
        HStack {
            Text("Set \(setNumber)")
                .font(.caption)
                .foregroundColor(themeManager.currentTheme.secondaryTextColor)
                .frame(width: 40, alignment: .leading)
            
            if let reps = set.reps {
                Text("\(reps) reps")
                    .font(.caption)
                    .foregroundColor(themeManager.currentTheme.primaryTextColor)
            }
            
            if let weight = set.weight {
                Text("@ \(Int(weight)) lbs")
                    .font(.caption)
                    .foregroundColor(themeManager.currentTheme.primaryTextColor)
            }
            
            Spacer()
        }
    }
}

struct PressedButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.95 : 1.0)
            .animation(.easeInOut(duration: 0.1), value: configuration.isPressed)
    }
}

// MARK: - Additional Views (would be in separate files in a real project)

struct WorkoutPauseMenuView: View {
    let workout: Workout
    let timeElapsed: Int
    let onResume: () -> Void
    let onExit: () -> Void
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            VStack(spacing: 24) {
                Text("⏸️")
                    .font(.system(size: 60))
                
                Text("Workout Paused")
                    .font(.title)
                    .fontWeight(.bold)
                
                Text("\(workout.name)")
                    .font(.headline)
                    .foregroundColor(.secondary)
                
                Text("Time Elapsed: \(formatTime(timeElapsed))")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                
                Spacer()
                
                VStack(spacing: 12) {
                    Button("Resume Workout") {
                        onResume()
                        dismiss()
                    }
                    .buttonStyle(.borderedProminent)
                    .controlSize(.large)
                    
                    Button("End Workout") {
                        onExit()
                        dismiss()
                    }
                    .buttonStyle(.bordered)
                    .foregroundColor(.red)
                }
            }
            .padding()
            .navigationTitle("Paused")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Resume") {
                        onResume()
                        dismiss()
                    }
                }
            }
        }
    }
    
    private func formatTime(_ seconds: Int) -> String {
        let minutes = seconds / 60
        let remainingSeconds = seconds % 60
        return String(format: "%02d:%02d", minutes, remainingSeconds)
    }
}

struct WorkoutCompleteView: View {
    let workout: Workout
    let session: WorkoutSession
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            VStack(spacing: 24) {
                Text("🎉")
                    .font(.system(size: 80))
                
                Text("Workout Complete!")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                
                Text("Amazing work! You've completed \(workout.name)")
                    .font(.headline)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                
                // Stats Summary
                VStack(spacing: 16) {
                    HStack(spacing: 32) {
                        VStack {
                            Text("\(Int(session.duration))")
                                .font(.title)
                                .fontWeight(.bold)
                            Text("Minutes")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        
                        VStack {
                            Text("\(Int(session.caloriesBurned))")
                                .font(.title)
                                .fontWeight(.bold)
                            Text("Calories")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        
                        VStack {
                            Text("\(session.exercises.count)")
                                .font(.title)
                                .fontWeight(.bold)
                            Text("Exercises")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                }
                .padding()
                .background(Color(.systemGray6))
                .cornerRadius(16)
                
                Spacer()
                
                VStack(spacing: 12) {
                    Button("Share Achievement") {
                        // Share workout completion
                    }
                    .buttonStyle(.borderedProminent)
                    .controlSize(.large)
                    
                    Button("Done") {
                        dismiss()
                    }
                    .buttonStyle(.bordered)
                }
            }
            .padding()
            .navigationTitle("Complete!")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}

#Preview {
    WorkoutSessionView(workout: Workout.sampleWorkouts[0])
        .environmentObject(WorkoutManager())
        .environmentObject(ProgressManager())
        .environmentObject(ThemeManager())
        .environmentObject(HealthManager())
        .environmentObject(NotificationManager())
}
