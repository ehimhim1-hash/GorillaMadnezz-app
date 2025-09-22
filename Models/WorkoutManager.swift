import SwiftUI
import Combine

class WorkoutManager: ObservableObject {
    @Published var currentWorkout: Workout?
    @Published var workoutHistory: [Workout] = []
    @Published var isWorkoutActive = false
    @Published var showingAICoach = false
    @Published var aiCoachMessage = ""
    
    private let aiCoach = AICoach()
    
    func generateWorkout(for day: WorkoutDay, equipment: [Equipment], fitnessLevel: FitnessLevel) -> Workout {
        let exercises = WorkoutGenerator.generateExercises(for: day, equipment: equipment, fitnessLevel: fitnessLevel)
        
        let workout = Workout(
            day: day,
            exercises: exercises,
            date: Date(),
            isCompleted: false
        )
        
        return workout
    }
    
    func startWorkout(_ workout: Workout) {
        currentWorkout = workout
        isWorkoutActive = true
    }
    
    func completeExerciseSet(_ exerciseId: UUID, setIndex: Int, weight: Double, reps: Int) {
        guard var workout = currentWorkout,
              let exerciseIndex = workout.exercises.firstIndex(where: { $0.id == exerciseId }) else { return }
        
        workout.exercises[exerciseIndex].sets[setIndex].actualWeight = weight
        workout.exercises[exerciseIndex].sets[setIndex].actualReps = reps
        workout.exercises[exerciseIndex].sets[setIndex].isCompleted = true
        
        currentWorkout = workout
    }
    
    func substituteExercise(_ originalExercise: Exercise, with newExercise: Exercise, in workout: Workout) {
        guard var currentWorkout = currentWorkout,
              let exerciseIndex = currentWorkout.exercises.firstIndex(where: { $0.id == originalExercise.id }) else { return }
        
        // Get AI coaching feedback
        let feedback = aiCoach.analyzeSubstitution(original: originalExercise, substitute: newExercise)
        aiCoachMessage = feedback
        showingAICoach = true
        
        // Replace the exercise
        currentWorkout.exercises[exerciseIndex] = newExercise
        self.currentWorkout = currentWorkout
    }
    
    func completeWorkout() {
        guard var workout = currentWorkout else { return }
        
        workout.isCompleted = true
        workout.completedDate = Date()
        
        // Calculate total weight lifted
        let totalWeight = workout.exercises.reduce(0) { total, exercise in
            total + exercise.sets.reduce(0) { setTotal, set in
                setTotal + (set.actualWeight ?? 0) * Double(set.actualReps ?? 0)
            }
        }
        
        workout.totalWeightLifted = totalWeight
        
        // Get all muscle groups worked in this session
        let muscleGroupsWorked = Array(Set(workout.exercises.flatMap { $0.muscleGroups }))
        
        workoutHistory.append(workout)
        currentWorkout = nil
        isWorkoutActive = false
        
        // Trigger stretching suggestion
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            NotificationCenter.default.post(
                name: NSNotification.Name("WorkoutCompleted"), 
                object: muscleGroupsWorked
            )
        }
    }
    
    func dismissAICoach() {
        showingAICoach = false
        aiCoachMessage = ""
    }
}

// MARK: - Workout Models
struct Workout: Identifiable {
    let id = UUID()
    let day: WorkoutDay
    var exercises: [Exercise]
    let date: Date
    var isCompleted: Bool
    var completedDate: Date?
    var totalWeightLifted: Double = 0
    
    var duration: TimeInterval {
        guard let completedDate = completedDate else { return 0 }
        return completedDate.timeIntervalSince(date)
    }
}

struct Exercise: Identifiable, Hashable {
    let id = UUID()
    let name: String
    let muscleGroups: [MuscleGroup]
    let equipment: [Equipment]
    var sets: [ExerciseSet]
    let instructions: String
    let difficulty: ExerciseDifficulty
    let type: ExerciseType
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}

struct ExerciseSet: Identifiable {
    let id = UUID()
    let targetReps: Int
    let targetWeight: Double?
    let restTime: TimeInterval
    var actualReps: Int?
    var actualWeight: Double?
    var isCompleted: Bool = false
}

// MARK: - Enums
enum WorkoutDay: String, CaseIterable {
    case upperPush = "upper_push"
    case lowerPower = "lower_power"
    case upperPull = "upper_pull"
    case fullBody = "full_body"
    
    var displayName: String {
        switch self {
        case .upperPush: return "Upper Push"
        case .lowerPower: return "Lower Power"
        case .upperPull: return "Upper Pull"
        case .fullBody: return "Full Body"
        }
    }
    
    var description: String {
        switch self {
        case .upperPush: return "Chest, Shoulders, Triceps"
        case .lowerPower: return "Legs, Glutes, Power"
        case .upperPull: return "Back, Biceps, Rear Delts"
        case .fullBody: return "Compound Movements"
        }
    }
    
    var icon: String {
        switch self {
        case .upperPush: return "arrow.up.circle.fill"
        case .lowerPower: return "bolt.circle.fill"
        case .upperPull: return "arrow.down.circle.fill"
        case .fullBody: return "figure.strengthtraining.traditional"
        }
    }
}

enum MuscleGroup: String, CaseIterable {
    case chest, shoulders, triceps, back, biceps, legs, glutes, core, calves
    
    var displayName: String {
        return rawValue.capitalized
    }
}

enum ExerciseDifficulty: String, CaseIterable {
    case beginner, intermediate, advanced
    
    var color: Color {
        switch self {
        case .beginner: return .green
        case .intermediate: return .orange
        case .advanced: return .red
        }
    }
}

enum ExerciseType: String, CaseIterable {
    case compound, isolation, cardio, power
    
    var displayName: String {
        return rawValue.capitalized
    }
}

enum FitnessLevel: String, CaseIterable {
    case beginner, intermediate, advanced
    
    var displayName: String {
        return rawValue.capitalized
    }
}
