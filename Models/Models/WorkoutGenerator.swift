import Foundation

class WorkoutGenerator {
    static func generateExercises(for day: WorkoutDay, equipment: [Equipment], fitnessLevel: FitnessLevel) -> [Exercise] {
        switch day {
        case .upperPush:
            return generateUpperPushExercises(equipment: equipment, fitnessLevel: fitnessLevel)
        case .lowerPower:
            return generateLowerPowerExercises(equipment: equipment, fitnessLevel: fitnessLevel)
        case .upperPull:
            return generateUpperPullExercises(equipment: equipment, fitnessLevel: fitnessLevel)
        case .fullBody:
            return generateFullBodyExercises(equipment: equipment, fitnessLevel: fitnessLevel)
        }
    }
    
    private static func generateUpperPushExercises(equipment: [Equipment], fitnessLevel: FitnessLevel) -> [Exercise] {
        var exercises: [Exercise] = []
        
        // Primary Push Movement
        if equipment.contains(where: { $0.name == "Barbell" }) {
            exercises.append(createBenchPress(fitnessLevel: fitnessLevel))
        } else if equipment.contains(where: { $0.name == "Dumbbells" }) {
            exercises.append(createDumbbellPress(fitnessLevel: fitnessLevel))
        } else {
            exercises.append(createPushUps(fitnessLevel: fitnessLevel))
        }
        
        // Shoulder Movement
        if equipment.contains(where: { $0.name == "Dumbbells" }) {
            exercises.append(createShoulderPress(fitnessLevel: fitnessLevel))
        } else {
            exercises.append(createPikePushUps(fitnessLevel: fitnessLevel))
        }
        
        // Tricep Movement
        if equipment.contains(where: { $0.name == "Dumbbells" }) {
            exercises.append(createTricepExtension(fitnessLevel: fitnessLevel))
        } else {
            exercises.append(createTricepDips(fitnessLevel: fitnessLevel))
        }
        
        // Accessory
        exercises.append(createLateralRaises(fitnessLevel: fitnessLevel))
        
        return exercises
    }
    
    private static func generateLowerPowerExercises(equipment: [Equipment], fitnessLevel: FitnessLevel) -> [Exercise] {
        var exercises: [Exercise] = []
        
        // Primary Lower Movement
        if equipment.contains(where: { $0.name == "Barbell" }) {
            exercises.append(createBarbellSquat(fitnessLevel: fitnessLevel))
        } else {
            exercises.append(createBodyweightSquats(fitnessLevel: fitnessLevel))
        }
        
        // Power Movement
        exercises.append(createJumpSquats(fitnessLevel: fitnessLevel))
        
        // Glute Movement
        exercises.append(createGluteBridges(fitnessLevel: fitnessLevel))
        
        // Single Leg
        exercises.append(createLunges(fitnessLevel: fitnessLevel))
        
        return exercises
    }
    
    private static func generateUpperPullExercises(equipment: [Equipment], fitnessLevel: FitnessLevel) -> [Exercise] {
        var exercises: [Exercise] = []
        
        // Primary Pull
        if equipment.contains(where: { $0.name == "Pull-up Bar" }) {
            exercises.append(createPullUps(fitnessLevel: fitnessLevel))
        } else if equipment.contains(where: { $0.name == "Dumbbells" }) {
            exercises.append(createBentOverRows(fitnessLevel: fitnessLevel))
        }
        
        // Bicep Movement
        if equipment.contains(where: { $0.name == "Dumbbells" }) {
            exercises.append(createBicepCurls(fitnessLevel: fitnessLevel))
        }
        
        // Rear Delt
        exercises.append(createRearDeltFlyes(fitnessLevel: fitnessLevel))
        
        return exercises
    }
    
    private static func generateFullBodyExercises(equipment: [Equipment], fitnessLevel: FitnessLevel) -> [Exercise] {
        var exercises: [Exercise] = []
        
        exercises.append(createBurpees(fitnessLevel: fitnessLevel))
        exercises.append(createMountainClimbers(fitnessLevel: fitnessLevel))
        exercises.append(createPlank(fitnessLevel: fitnessLevel))
        
        return exercises
    }
    
    // MARK: - Exercise Creation Methods
    private static func createBenchPress(fitnessLevel: FitnessLevel) -> Exercise {
        let sets = generateSets(for: fitnessLevel, reps: 8, weight: 60.0)
        return Exercise(
            name: "Barbell Bench Press",
            muscleGroups: [.chest, .shoulders, .triceps],
            equipment: [Equipment(name: "Barbell", category: .freeWeights, icon: "minus.rectangle.fill", isAvailable: true)],
            sets: sets,
            instructions: "Lie on bench, grip bar slightly wider than shoulders, lower to chest, press up",
            difficulty: .intermediate,
            type: .compound
        )
    }
    
    private static func createPushUps(fitnessLevel: FitnessLevel) -> Exercise {
        let reps = fitnessLevel == .beginner ? 10 : fitnessLevel == .intermediate ? 15 : 20
        let sets = generateSets(for: fitnessLevel, reps: reps, weight: nil)
        return Exercise(
            name: "Push-ups",
            muscleGroups: [.chest, .shoulders, .triceps],
            equipment: [Equipment(name: "Floor Space", category: .bodyweight, icon: "square.fill", isAvailable: true)],
            sets: sets,
            instructions: "Start in plank position, lower chest to floor, push back up",
            difficulty: .beginner,
            type: .compound
        )
    }
    
    private static func createBodyweightSquats(fitnessLevel: FitnessLevel) -> Exercise {
        let reps = fitnessLevel == .beginner ? 15 : fitnessLevel == .intermediate ? 20 : 25
        let sets = generateSets(for: fitnessLevel, reps: reps, weight: nil)
        return Exercise(
            name: "Bodyweight Squats",
            muscleGroups: [.legs, .glutes],
            equipment: [Equipment(name: "Floor Space", category: .bodyweight, icon: "square.fill", isAvailable: true)],
            sets: sets,
            instructions: "Stand with feet shoulder-width apart, lower hips back and down, return to standing",
            difficulty: .beginner,
            type: .compound
        )
    }
    
    // Helper method to generate sets based on fitness level
    private static func generateSets(for fitnessLevel: FitnessLevel, reps: Int, weight: Double?) -> [ExerciseSet] {
        let setCount = fitnessLevel == .beginner ? 3 : fitnessLevel == .intermediate ? 4 : 5
        let restTime: TimeInterval = fitnessLevel == .beginner ? 90 : fitnessLevel == .intermediate ? 120 : 150
        
        return (0..<setCount).map { _ in
            ExerciseSet(
                targetReps: reps,
                targetWeight: weight,
                restTime: restTime
            )
        }
    }
    
    private static func createDumbbellPress(fitnessLevel: FitnessLevel) -> Exercise {
        let sets = generateSets(for: fitnessLevel, reps: 10, weight: 20.0)
        return Exercise(
            name: "Dumbbell Chest Press",
            muscleGroups: [.chest, .shoulders, .triceps],
            equipment: [Equipment(name: "Dumbbells", category: .freeWeights, icon: "dumbbell.fill", isAvailable: true)],
            sets: sets,
            instructions: "Lie on bench with dumbbells, press weights up and together",
            difficulty: .intermediate,
            type: .compound
        )
    }
    
    private static func createShoulderPress(fitnessLevel: FitnessLevel) -> Exercise {
        let sets = generateSets(for: fitnessLevel, reps: 12, weight: 15.0)
        return Exercise(
            name: "Dumbbell Shoulder Press",
            muscleGroups: [.shoulders, .triceps],
            equipment: [Equipment(name: "Dumbbells", category: .freeWeights, icon: "dumbbell.fill", isAvailable: true)],
            sets: sets,
            instructions: "Press dumbbells overhead from shoulder height",
            difficulty: .intermediate,
            type: .compound
        )
    }
    
    private static func createPikePushUps(fitnessLevel: FitnessLevel) -> Exercise {
        let reps = fitnessLevel == .beginner ? 8 : fitnessLevel == .intermediate ? 12 : 15
        let sets = generateSets(for: fitnessLevel, reps: reps, weight: nil)
        return Exercise(
            name: "Pike Push-ups",
            muscleGroups: [.shoulders, .triceps],
            equipment: [Equipment(name: "Floor Space", category: .bodyweight, icon: "square.fill", isAvailable: true)],
            sets: sets,
            instructions: "Start in downward dog position, lower head toward floor, push back up",
            difficulty: .intermediate,
            type: .compound
        )
    }
    
    private static func createTricepExtension(fitnessLevel: FitnessLevel) -> Exercise {
        let sets = generateSets(for: fitnessLevel, reps: 12, weight: 10.0)
        return Exercise(
            name: "Tricep Extension",
            muscleGroups: [.triceps],
            equipment: [Equipment(name: "Dumbbells", category: .freeWeights, icon: "dumbbell.fill", isAvailable: true)],
            sets: sets,
            instructions: "Hold dumbbell overhead, lower behind head, extend back up",
            difficulty: .beginner,
            type: .isolation
        )
    }
    
    private static func createTricepDips(fitnessLevel: FitnessLevel) -> Exercise {
        let reps = fitnessLevel == .beginner ? 8 : fitnessLevel == .intermediate ? 12 : 15
        let sets = generateSets(for: fitnessLevel, reps: reps, weight: nil)
        return Exercise(
            name: "Tricep Dips",
            muscleGroups: [.triceps, .shoulders],
            equipment: [Equipment(name: "Bench", category: .bodyweight, icon: "rectangle.fill", isAvailable: true)],
            sets: sets,
            instructions: "Support body on bench, lower body down, push back up",
            difficulty: .intermediate,
            type: .compound
        )
    }
    
    private static func createLateralRaises(fitnessLevel: FitnessLevel) -> Exercise {
        let sets = generateSets(for: fitnessLevel, reps: 15, weight: 8.0)
        return Exercise(
            name: "Lateral Raises",
            muscleGroups: [.shoulders],
            equipment: [Equipment(name: "Dumbbells", category: .freeWeights, icon: "dumbbell.fill", isAvailable: true)],
            sets: sets,
            instructions: "Raise arms out to sides until parallel with floor",
            difficulty: .beginner,
            type: .isolation
        )
    }
    
    private static func createBarbellSquat(fitnessLevel: FitnessLevel) -> Exercise {
        let sets = generateSets(for: fitnessLevel, reps: 8, weight: 80.0)
        return Exercise(
            name: "Barbell Squat",
            muscleGroups: [.legs, .glutes, .core],
            equipment: [Equipment(name: "Barbell", category: .freeWeights, icon: "minus.rectangle.fill", isAvailable: true)],
            sets: sets,
            instructions: "Bar on upper back, squat down keeping knees over toes",
            difficulty: .intermediate,
            type: .compound
        )
    }
    
    private static func createJumpSquats(fitnessLevel: FitnessLevel) -> Exercise {
        let reps = fitnessLevel == .beginner ? 10 : fitnessLevel == .intermediate ? 15 : 20
        let sets = generateSets(for: fitnessLevel, reps: reps, weight: nil)
        return Exercise(
            name: "Jump Squats",
            muscleGroups: [.legs, .glutes],
            equipment: [Equipment(name: "Floor Space", category: .bodyweight, icon: "square.fill", isAvailable: true)],
            sets: sets,
            instructions: "Squat down then explode up into a jump",
            difficulty: .intermediate,
            type: .power
        )
    }
    
    private static func createGluteBridges(fitnessLevel: FitnessLevel) -> Exercise {
        let reps = fitnessLevel == .beginner ? 15 : fitnessLevel == .intermediate ? 20 : 25
        let sets = generateSets(for: fitnessLevel, reps: reps, weight: nil)
        return Exercise(
            name: "Glute Bridges",
            muscleGroups: [.glutes, .core],
            equipment: [Equipment(name: "Floor Space", category: .bodyweight, icon: "square.fill", isAvailable: true)],
            sets: sets,
            instructions: "Lie on back, lift hips up squeezing glutes",
            difficulty: .beginner,
            type: .isolation
        )
    }
    
    private static func createLunges(fitnessLevel: FitnessLevel) -> Exercise {
        let reps = fitnessLevel == .beginner ? 10 : fitnessLevel == .intermediate ? 12 : 15
        let sets = generateSets(for: fitnessLevel, reps: reps, weight: nil)
        return Exercise(
            name: "Walking Lunges",
            muscleGroups: [.legs, .glutes],
            equipment: [Equipment(name: "Floor Space", category: .bodyweight, icon: "square.fill", isAvailable: true)],
            sets: sets,
            instructions: "Step forward into lunge, alternate legs",
            difficulty: .intermediate,
            type: .compound
        )
    }
    
    private static func createPullUps(fitnessLevel: FitnessLevel) -> Exercise {
        let reps = fitnessLevel == .beginner ? 5 : fitnessLevel == .intermediate ? 8 : 12
        let sets = generateSets(for: fitnessLevel, reps: reps, weight: nil)
        return Exercise(
            name: "Pull-ups",
            muscleGroups: [.back, .biceps],
            equipment: [Equipment(name: "Pull-up Bar", category: .functional, icon: "figure.strengthtraining.functional", isAvailable: true)],
            sets: sets,
            instructions: "Hang from bar, pull body up until chin over bar",
            difficulty: .advanced,
            type: .compound
        )
    }
    
    private static func createBentOverRows(fitnessLevel: FitnessLevel) -> Exercise {
        let sets = generateSets(for: fitnessLevel, reps: 10, weight: 25.0)
        return Exercise(
            name: "Bent Over Dumbbell Rows",
            muscleGroups: [.back, .biceps],
            equipment: [Equipment(name: "Dumbbells", category: .freeWeights, icon: "dumbbell.fill", isAvailable: true)],
            sets: sets,
            instructions: "Bend over, row dumbbells to sides of torso",
            difficulty: .intermediate,
            type: .compound
        )
    }
    
    private static func createBicepCurls(fitnessLevel: FitnessLevel) -> Exercise {
        let sets = generateSets(for: fitnessLevel, reps: 12, weight: 15.0)
        return Exercise(
            name: "Bicep Curls",
            muscleGroups: [.biceps],
            equipment: [Equipment(name: "Dumbbells", category: .freeWeights, icon: "dumbbell.fill", isAvailable: true)],
            sets: sets,
            instructions: "Curl dumbbells up to shoulders",
            difficulty: .beginner,
            type: .isolation
        )
    }
    
    private static func createRearDeltFlyes(fitnessLevel: FitnessLevel) -> Exercise {
        let sets = generateSets(for: fitnessLevel, reps: 15, weight: 8.0)
        return Exercise(
            name: "Rear Delt Flyes",
            muscleGroups: [.shoulders],
            equipment: [Equipment(name: "Dumbbells", category: .freeWeights, icon: "dumbbell.fill", isAvailable: true)],
            sets: sets,
            instructions: "Bend over, fly arms out to sides",
            difficulty: .beginner,
            type: .isolation
        )
    }
    
    private static func createBurpees(fitnessLevel: FitnessLevel) -> Exercise {
        let reps = fitnessLevel == .beginner ? 8 : fitnessLevel == .intermediate ? 12 : 15
        let sets = generateSets(for: fitnessLevel, reps: reps, weight: nil)
        return Exercise(
            name: "Burpees",
            muscleGroups: [.chest, .legs, .core],
            equipment: [Equipment(name: "Floor Space", category: .bodyweight, icon: "square.fill", isAvailable: true)],
            sets: sets,
            instructions: "Squat, jump back to plank, push-up, jump feet in, jump up",
            difficulty: .advanced,
            type: .compound
        )
    }
    
    private static func createMountainClimbers(fitnessLevel: FitnessLevel) -> Exercise {
        let reps = fitnessLevel == .beginner ? 20 : fitnessLevel == .intermediate ? 30 : 40
        let sets = generateSets(for: fitnessLevel, reps: reps, weight: nil)
        return Exercise(
            name: "Mountain Climbers",
            muscleGroups: [.core, .shoulders],
            equipment: [Equipment(name: "Floor Space", category: .bodyweight, icon: "square.fill", isAvailable: true)],
            sets: sets,
            instructions: "Plank position, alternate bringing knees to chest",
            difficulty: .intermediate,
            type: .cardio
        )
    }
    
    private static func createPlank(fitnessLevel: FitnessLevel) -> Exercise {
        let time = fitnessLevel == .beginner ? 30 : fitnessLevel == .intermediate ? 45 : 60
        let sets = generateSets(for: fitnessLevel, reps: time, weight: nil)
        return Exercise(
            name: "Plank Hold",
            muscleGroups: [.core],
            equipment: [Equipment(name: "Floor Space", category: .bodyweight, icon: "square.fill", isAvailable: true)],
            sets: sets,
            instructions: "Hold plank position keeping body straight",
            difficulty: .beginner,
            type: .isolation
        )
    }
}
