import Foundation

class AICoach {
    func analyzeSubstitution(original: Exercise, substitute: Exercise) -> String {
        var feedback: [String] = []
        
        // Compare muscle groups
        let originalMuscles = Set(original.muscleGroups)
        let substituteMuscles = Set(substitute.muscleGroups)
        
        let commonMuscles = originalMuscles.intersection(substituteMuscles)
        let missingMuscles = originalMuscles.subtracting(substituteMuscles)
        let additionalMuscles = substituteMuscles.subtracting(originalMuscles)
        
        if commonMuscles.count == originalMuscles.count {
            feedback.append("💯 Perfect substitution! This targets the same muscle groups.")
        } else if !missingMuscles.isEmpty {
            let missingNames = missingMuscles.map { $0.displayName }.joined(separator: ", ")
            feedback.append("⚠️ Missing muscle groups: \(missingNames)")
        }
        
        if !additionalMuscles.isEmpty {
            let additionalNames = additionalMuscles.map { $0.displayName }.joined(separator: ", ")
            feedback.append("💪 Bonus: Also targets \(additionalNames)")
        }
        
        // Compare exercise types
        if original.type != substitute.type {
            feedback.append(analyzeTypeChange(from: original.type, to: substitute.type))
        }
        
        // Compare difficulty
        if original.difficulty != substitute.difficulty {
            feedback.append(analyzeDifficultyChange(from: original.difficulty, to: substitute.difficulty))
        }
        
        // Recovery impact
        feedback.append(analyzeRecoveryImpact(original: original, substitute: substitute))
        
        return feedback.joined(separator: " ")
    }
    
    private func analyzeTypeChange(from original: ExerciseType, to substitute: ExerciseType) -> String {
        switch (original, substitute) {
        case (.compound, .isolation):
            return "🔄 Switching from compound to isolation will reduce overall muscle activation."
        case (.isolation, .compound):
            return "💪 Upgrading to compound movement will work more muscles!"
        case (.compound, .power):
            return "⚡ Adding explosive power element - great for strength gains!"
        case (.power, .compound):
            return "🔄 Reducing explosive element but maintaining multi-muscle focus."
        default:
            return ""
        }
    }
    
    private func analyzeDifficultyChange(from original: ExerciseDifficulty, to substitute: ExerciseDifficulty) -> String {
        switch (original, substitute) {
        case (.beginner, .intermediate), (.intermediate, .advanced):
            return "📈 Increasing difficulty - make sure your form is perfect!"
        case (.advanced, .intermediate), (.intermediate, .beginner):
            return "📉 Reducing difficulty - good for active recovery or form focus."
        case (.beginner, .advanced):
            return "⚠️ Big jump in difficulty! Consider an intermediate variation first."
        case (.advanced, .beginner):
            return "🔄 Significant reduction in difficulty - great for deload or technique work."
        default:
            return ""
        }
    }
    
    private func analyzeRecoveryImpact(original: Exercise, substitute: Exercise) -> String {
        let originalLoad = calculateExerciseLoad(original)
        let substituteLoad = calculateExerciseLoad(substitute)
        
        let loadDifference = substituteLoad - originalLoad
        
        if abs(loadDifference) < 0.1 {
            return "🔄 Similar training load - minimal impact on recovery."
        } else if loadDifference > 0.2 {
            return "🔥 Higher training load - may increase fatigue for tomorrow's session."
        } else if loadDifference < -0.2 {
            return "😌 Lower training load - good for managing fatigue."
        } else if loadDifference > 0 {
            return "📈 Slightly higher load - monitor your energy levels."
        } else {
            return "📉 Slightly lower load - good for active recovery."
        }
    }
    
    private func calculateExerciseLoad(_ exercise: Exercise) -> Double {
        var load = 0.0
        
        // Base load from exercise type
        switch exercise.type {
        case .compound: load += 0.8
        case .isolation: load += 0.4
        case .power: load += 1.0
        case .cardio: load += 0.6
        }
        
        // Adjust for difficulty
        switch exercise.difficulty {
        case .beginner: load *= 0.7
        case .intermediate: load *= 1.0
        case .advanced: load *= 1.3
        }
        
        // Adjust for muscle groups involved
        load += Double(exercise.muscleGroups.count) * 0.1
        
        return load
    }
    
    func generateWorkoutFeedback(exercises: [Exercise], totalWeight: Double, duration: TimeInterval) -> String {
        var feedback: [String] = []
        
        // Workout intensity analysis
        let intensity = analyzeWorkoutIntensity(exercises: exercises, totalWeight: totalWeight, duration: duration)
        feedback.append(intensity)
        
        // Muscle group balance
        let balance = analyzeMuscleGroupBalance(exercises: exercises)
        feedback.append(balance)
        
        // Recovery recommendations
        let recovery = generateRecoveryRecommendations(intensity: totalWeight, duration: duration)
        feedback.append(recovery)
        
        return feedback.joined(separator: " ")
    }
    
    private func analyzeWorkoutIntensity(exercises: [Exercise], totalWeight: Double, duration: TimeInterval) -> String {
        let avgWeightPerMinute = totalWeight / (duration / 60)
        
        if avgWeightPerMinute > 500 {
            return "🔥 High-intensity session! Great work pushing your limits."
        } else if avgWeightPerMinute > 300 {
            return "💪 Solid moderate-intensity workout."
        } else {
            return "😌 Good active session - perfect for building consistency."
        }
    }
    
    private func analyzeMuscleGroupBalance(exercises: [Exercise]) -> String {
        let allMuscleGroups = exercises.flatMap { $0.muscleGroups }
        let muscleGroupCounts = Dictionary(grouping: allMuscleGroups, by: { $0 })
            .mapValues { $0.count }
        
        let maxCount = muscleGroupCounts.values.max() ?? 0
        let minCount = muscleGroupCounts.values.min() ?? 0
        
        if maxCount - minCount <= 1 {
            return "⚖️ Perfect muscle group balance!"
        } else if maxCount - minCount <= 2 {
            return "📈 Good muscle group distribution."
        } else {
            return "⚠️ Consider balancing muscle groups in future sessions."
        }
    }
    
    private func generateRecoveryRecommendations(intensity: Double, duration: TimeInterval) -> String {
        if intensity > 2000 || duration > 3600 { // High intensity or long duration
            return "🙏 Consider stretching and extra rest before your next session."
        } else if intensity > 1000 || duration > 2400 {
            return "🛋 Standard recovery should be sufficient."
        } else {
            return "⚡ You could potentially train again sooner with this lighter load."
        }
    }
}
