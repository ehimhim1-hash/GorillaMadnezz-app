//
//  ProgressManager.swift
//  GorillaMadnezz
//
//  Tracks workout progress, personal records, and analytics
//

import Foundation
import Combine

class ProgressManager: ObservableObject {
    @Published var personalRecords: [String: PersonalRecord] = [:]
    @Published var workoutHistory: [WorkoutSession] = []
    @Published var weeklyStats: WeeklyStats = WeeklyStats()
    @Published var monthlyStats: MonthlyStats = MonthlyStats()
    @Published var progressCharts: [ProgressChart] = []
    @Published var bodyMeasurements: [BodyMeasurement] = []
    
    private var cancellables = Set<AnyCancellable>()
    
    init() {
        loadSampleData()
        calculateStats()
        setupProgressTracking()
    }
    
    // MARK: - Workout Tracking
    
    func recordWorkoutSession(_ session: WorkoutSession) {
        workoutHistory.insert(session, at: 0)
        updatePersonalRecords(from: session)
        calculateStats()
        
        // Notify other systems
        NotificationCenter.default.post(
            name: NSNotification.Name("WorkoutCompleted"),
            object: ["session": session, "totalCalories": session.totalCalories]
        )
    }
    
    func updateExerciseProgress(exerciseName: String, weight: Double, reps: Int, sets: Int) {
        let key = exerciseName.lowercased()
        let currentRecord = personalRecords[key]
        
        let oneRepMax = calculateOneRepMax(weight: weight, reps: reps)
        let totalVolume = weight * Double(reps * sets)
        
        var isNewRecord = false
        
        if let existing = currentRecord {
            if oneRepMax > existing.oneRepMax {
                personalRecords[key] = PersonalRecord(
                    exerciseName: exerciseName,
                    oneRepMax: oneRepMax,
                    maxWeight: max(existing.maxWeight, weight),
                    maxReps: max(existing.maxReps, reps),
                    bestVolume: max(existing.bestVolume, totalVolume),
                    dateAchieved: Date(),
                    previousRecord: existing.oneRepMax
                )
                isNewRecord = true
            }
        } else {
            personalRecords[key] = PersonalRecord(
                exerciseName: exerciseName,
                oneRepMax: oneRepMax,
                maxWeight: weight,
                maxReps: reps,
                bestVolume: totalVolume,
                dateAchieved: Date(),
                previousRecord: 0
            )
            isNewRecord = true
        }
        
        if isNewRecord {
            NotificationCenter.default.post(
                name: NSNotification.Name("PersonalRecordBroken"),
                object: ["exercise": exerciseName, "newRecord": oneRepMax]
            )
        }
    }
    
    // MARK: - Statistics Calculation
    
    private func calculateStats() {
        calculateWeeklyStats()
        calculateMonthlyStats()
        updateProgressCharts()
    }
    
    private func calculateWeeklyStats() {
        let calendar = Calendar.current
        let startOfWeek = calendar.dateInterval(of: .weekOfYear, for: Date())?.start ?? Date()
        
        let thisWeekWorkouts = workoutHistory.filter { session in
            session.date >= startOfWeek
        }
        
        weeklyStats = WeeklyStats(
            totalWorkouts: thisWeekWorkouts.count,
            totalMinutes: thisWeekWorkouts.reduce(0) { $0 + $1.duration },
            totalCalories: thisWeekWorkouts.reduce(0) { $0 + $1.totalCalories },
            totalVolume: thisWeekWorkouts.reduce(0) { $0 + $1.totalVolume },
            averageIntensity: thisWeekWorkouts.isEmpty ? 0 : thisWeekWorkouts.reduce(0) { $0 + $1.intensity } / Double(thisWeekWorkouts.count),
            mostUsedMuscleGroup: getMostUsedMuscleGroup(from: thisWeekWorkouts),
            streak: calculateCurrentStreak()
        )
    }
    
    private func calculateMonthlyStats() {
        let calendar = Calendar.current
        let startOfMonth = calendar.dateInterval(of: .month, for: Date())?.start ?? Date()
        
        let thisMonthWorkouts = workoutHistory.filter { session in
            session.date >= startOfMonth
        }
        
        monthlyStats = MonthlyStats(
            totalWorkouts: thisMonthWorkouts.count,
            totalHours: thisMonthWorkouts.reduce(0) { $0 + $1.duration } / 60,
            totalCalories: thisMonthWorkouts.reduce(0) { $0 + $1.totalCalories },
            personalRecordsBroken: getRecordsBrokenThisMonth(),
            favoriteExercise: getFavoriteExercise(from: thisMonthWorkouts),
            strengthGains: calculateStrengthGains(),
            workoutFrequency: Double(thisMonthWorkouts.count) / 4.0 // per week
        )
    }
    
    private func updateProgressCharts() {
        progressCharts = [
            createWeightProgressChart(),
            createVolumeProgressChart(),
            createCalorieProgressChart(),
            createStrengthProgressChart()
        ]
    }
    
    // MARK: - Body Measurements
    
    func addBodyMeasurement(_ measurement: BodyMeasurement) {
        bodyMeasurements.insert(measurement, at: 0)
        
        // Check for progress milestones
        if measurement.type == .weight {
            checkWeightMilestones(measurement.value)
        }
    }
    
    func getLatestMeasurement(type: MeasurementType) -> BodyMeasurement? {
        return bodyMeasurements.first { $0.type == type }
    }
    
    func getMeasurementProgress(type: MeasurementType, days: Int = 30) -> Double {
        let cutoffDate = Calendar.current.date(byAdding: .day, value: -days, to: Date()) ?? Date()
        let measurements = bodyMeasurements.filter { $0.type == type && $0.date >= cutoffDate }
        
        guard measurements.count >= 2 else { return 0 }
        
        let latest = measurements.first?.value ?? 0
        let oldest = measurements.last?.value ?? 0
        
        return latest - oldest
    }
    
    // MARK: - Analytics
    
    func getWorkoutAnalytics(period: AnalyticsPeriod) -> WorkoutAnalytics {
        let calendar = Calendar.current
        let startDate: Date
        
        switch period {
        case .week:
            startDate = calendar.dateInterval(of: .weekOfYear, for: Date())?.start ?? Date()
        case .month:
            startDate = calendar.dateInterval(of: .month, for: Date())?.start ?? Date()
        case .year:
            startDate = calendar.dateInterval(of: .year, for: Date())?.start ?? Date()
        case .allTime:
            startDate = Date.distantPast
        }
        
        let filteredWorkouts = workoutHistory.filter { $0.date >= startDate }
        
        return WorkoutAnalytics(
            totalWorkouts: filteredWorkouts.count,
            totalTime: filteredWorkouts.reduce(0) { $0 + $1.duration },
            totalCalories: filteredWorkouts.reduce(0) { $0 + $1.totalCalories },
            averageWorkoutTime: filteredWorkouts.isEmpty ? 0 : filteredWorkouts.reduce(0) { $0 + $1.duration } / Double(filteredWorkouts.count),
            mostActiveDay: getMostActiveDay(from: filteredWorkouts),
            strongestMuscleGroup: getMostUsedMuscleGroup(from: filteredWorkouts)
        )
    }
    
    func getProgressTrends() -> [ProgressTrend] {
        return [
            ProgressTrend(metric: "Total Volume", change: calculateVolumeChange(), direction: .increasing),
            ProgressTrend(metric: "Workout Frequency", change: calculateFrequencyChange(), direction: .increasing),
            ProgressTrend(metric: "Average Intensity", change: calculateIntensityChange(), direction: .stable),
            ProgressTrend(metric: "Personal Records", change: Double(getRecordsBrokenThisMonth()), direction: .increasing)
        ]
    }
    
    // MARK: - Private Helpers
    
    private func calculateOneRepMax(weight: Double, reps: Int) -> Double {
        // Epley Formula: 1RM = weight × (1 + reps/30)
        return weight * (1 + Double(reps) / 30.0)
    }
    
    private func updatePersonalRecords(from session: WorkoutSession) {
        // This would be called after each workout to check for new records
        // Implementation would analyze the session exercises and update records
    }
    
    private func calculateCurrentStreak() -> Int {
        let calendar = Calendar.current
        var streak = 0
        var currentDate = Date()
        
        while true {
            let dayWorkouts = workoutHistory.filter { workout in
                calendar.isDate(workout.date, inSameDayAs: currentDate)
            }
            
            if dayWorkouts.isEmpty {
                break
            } else {
                streak += 1
                currentDate = calendar.date(byAdding: .day, value: -1, to: currentDate) ?? Date()
            }
        }
        
        return streak
    }
    
    private func getMostUsedMuscleGroup(from workouts: [WorkoutSession]) -> String {
        var muscleGroupCount: [String: Int] = [:]
        
        for workout in workouts {
            for exercise in workout.exercises {
                let muscleGroup = exercise.primaryMuscleGroup
                muscleGroupCount[muscleGroup, default: 0] += 1
            }
        }
        
        return muscleGroupCount.max(by: { $0.value < $1.value })?.key ?? "Chest"
    }
    
    private func getRecordsBrokenThisMonth() -> Int {
        let calendar = Calendar.current
        let startOfMonth = calendar.dateInterval(of: .month, for: Date())?.start ?? Date()
        
        return personalRecords.values.filter { $0.dateAchieved >= startOfMonth }.count
    }
    
    private func getFavoriteExercise(from workouts: [WorkoutSession]) -> String {
        var exerciseCount: [String: Int] = [:]
        
        for workout in workouts {
            for exercise in workout.exercises {
                exerciseCount[exercise.name, default: 0] += 1
            }
        }
        
        return exerciseCount.max(by: { $0.value < $1.value })?.key ?? "Bench Press"
    }
    
    private func calculateStrengthGains() -> Double {
        // Calculate average strength increase across all exercises
        let gains = personalRecords.values.compactMap { record in
            record.previousRecord > 0 ? ((record.oneRepMax - record.previousRecord) / record.previousRecord) * 100 : nil
        }
        
        return gains.isEmpty ? 0 : gains.reduce(0, +) / Double(gains.count)
    }
    
    private func createWeightProgressChart() -> ProgressChart {
        let data = bodyMeasurements
            .filter { $0.type == .weight }
            .prefix(30)
            .map { ChartDataPoint(date: $0.date, value: $0.value) }
        
        return ProgressChart(
            title: "Weight Progress",
            data: Array(data),
            unit: "lbs",
            color: "blue"
        )
    }
    
    private func createVolumeProgressChart() -> ProgressChart {
        let calendar = Calendar.current
        let last30Days = (0..<30).compactMap { dayOffset in
            calendar.date(byAdding: .day, value: -dayOffset, to: Date())
        }
        
        let data = last30Days.map { date in
            let dayWorkouts = workoutHistory.filter { calendar.isDate($0.date, inSameDayAs: date) }
            let totalVolume = dayWorkouts.reduce(0) { $0 + $1.totalVolume }
            return ChartDataPoint(date: date, value: totalVolume)
        }
        
        return ProgressChart(
            title: "Training Volume",
            data: data,
            unit: "lbs",
            color: "green"
        )
    }
    
    private func createCalorieProgressChart() -> ProgressChart {
        let calendar = Calendar.current
        let last30Days = (0..<30).compactMap { dayOffset in
            calendar.date(byAdding: .day, value: -dayOffset, to: Date())
        }
        
        let data = last30Days.map { date in
            let dayWorkouts = workoutHistory.filter { calendar.isDate($0.date, inSameDayAs: date) }
            let totalCalories = dayWorkouts.reduce(0) { $0 + $1.totalCalories }
            return ChartDataPoint(date: date, value: Double(totalCalories))
        }
        
        return ProgressChart(
            title: "Calories Burned",
            data: data,
            unit: "cal",
            color: "red"
        )
    }
    
    private func createStrengthProgressChart() -> ProgressChart {
        let benchPress = personalRecords["bench press"]
        let data = [ChartDataPoint(date: Date(), value: benchPress?.oneRepMax ?? 135)]
        
        return ProgressChart(
            title: "Strength Progress",
            data: data,
            unit: "lbs",
            color: "purple"
        )
    }
    
    private func calculateVolumeChange() -> Double {
        // Compare this month vs last month
        return 15.5 // Placeholder
    }
    
    private func calculateFrequencyChange() -> Double {
        return 2.3 // Placeholder
    }
    
    private func calculateIntensityChange() -> Double {
        return 0.8 // Placeholder
    }
    
    private func getMostActiveDay(from workouts: [WorkoutSession]) -> String {
        var dayCount: [String: Int] = [:]
        let formatter = DateFormatter()
        formatter.dateFormat = "EEEE"
        
        for workout in workouts {
            let dayName = formatter.string(from: workout.date)
            dayCount[dayName, default: 0] += 1
        }
        
        return dayCount.max(by: { $0.value < $1.value })?.key ?? "Monday"
    }
    
    private func checkWeightMilestones(_ weight: Double) {
        // Check for weight loss/gain milestones
        let previousWeights = bodyMeasurements.filter { $0.type == .weight }.dropFirst()
        
        if let previousWeight = previousWeights.first?.value {
            let difference = abs(weight - previousWeight)
            if difference >= 5.0 { // 5 lb milestone
                NotificationCenter.default.post(
                    name: NSNotification.Name("WeightMilestone"),
                    object: ["difference": difference, "direction": weight < previousWeight ? "loss" : "gain"]
                )
            }
        }
    }
    
    private func loadSampleData() {
        // Sample workout history
        workoutHistory = [
            WorkoutSession(
                id: UUID().uuidString,
                date: Date().addingTimeInterval(-86400), // Yesterday
                duration: 65,
                exercises: [],
                totalCalories: 320,
                totalVolume: 2450,
                intensity: 8.5,
                notes: "Great chest workout!"
            ),
            WorkoutSession(
                id: UUID().uuidString,
                date: Date().addingTimeInterval(-259200), // 3 days ago
                duration: 58,
                exercises: [],
                totalCalories: 285,
                totalVolume: 2200,
                intensity: 7.8,
                notes: "Focused on form"
            )
        ]
        
        // Sample personal records
        personalRecords = [
            "bench press": PersonalRecord(exerciseName: "Bench Press", oneRepMax: 225, maxWeight: 205, maxReps: 8, bestVolume: 4100, dateAchieved: Date(), previousRecord: 215),
            "squat": PersonalRecord(exerciseName: "Squat", oneRepMax: 275, maxWeight: 245, maxReps: 6, bestVolume: 5500, dateAchieved: Date(), previousRecord: 265),
            "deadlift": PersonalRecord(exerciseName: "Deadlift", oneRepMax: 315, maxWeight: 285, maxReps: 5, bestVolume: 4275, dateAchieved: Date(), previousRecord: 305)
        ]
        
        // Sample body measurements
        bodyMeasurements = [
            BodyMeasurement(type: .weight, value: 175.5, date: Date(), notes: "Morning weight"),
            BodyMeasurement(type: .bodyFat, value: 12.8, date: Date(), notes: "DEXA scan"),
            BodyMeasurement(type: .muscle, value: 152.4, date: Date(), notes: "Lean mass")
        ]
    }
    
    private func setupProgressTracking() {
        // Setup periodic progress calculations
        Timer.publish(every: 3600, on: .main, in: .common) // Every hour
            .autoconnect()
            .sink { _ in
                self.calculateStats()
            }
            .store(in: &cancellables)
    }
}

// MARK: - Data Models

struct PersonalRecord: Codable {
    let exerciseName: String
    let oneRepMax: Double
    let maxWeight: Double
    let maxReps: Int
    let bestVolume: Double
    let dateAchieved: Date
    let previousRecord: Double
}

struct WorkoutSession: Identifiable, Codable {
    let id: String
    let date: Date
    let duration: Int // minutes
    let exercises: [ExerciseSession]
    let totalCalories: Int
    let totalVolume: Double
    let intensity: Double // 1-10 scale
    let notes: String
}

struct ExerciseSession: Identifiable, Codable {
    let id = UUID()
    let name: String
    let sets: [SetData]
    let primaryMuscleGroup: String
    let secondaryMuscleGroups: [String]
}

struct SetData: Codable {
    let weight: Double
    let reps: Int
    let restTime: Int
    let completed: Bool
}

struct WeeklyStats: Codable {
    let totalWorkouts: Int
    let totalMinutes: Int
    let totalCalories: Int
    let totalVolume: Double
    let averageIntensity: Double
    let mostUsedMuscleGroup: String
    let streak: Int
    
    init() {
        totalWorkouts = 0
        totalMinutes = 0
        totalCalories = 0
        totalVolume = 0
        averageIntensity = 0
        mostUsedMuscleGroup = "Chest"
        streak = 0
    }
}

struct MonthlyStats: Codable {
    let totalWorkouts: Int
    let totalHours: Double
    let totalCalories: Int
    let personalRecordsBroken: Int
    let favoriteExercise: String
    let strengthGains: Double
    let workoutFrequency: Double
    
    init() {
        totalWorkouts = 0
        totalHours = 0
        totalCalories = 0
        personalRecordsBroken = 0
        favoriteExercise = "Bench Press"
        strengthGains = 0
        workoutFrequency = 0
    }
}

struct BodyMeasurement: Identifiable, Codable {
    let id = UUID()
    let type: MeasurementType
    let value: Double
    let date: Date
    let notes: String
}

enum MeasurementType: String, Codable, CaseIterable {
    case weight = "weight"
    case bodyFat = "body_fat"
    case muscle = "muscle_mass"
    case waist = "waist"
    case chest = "chest"
    case arms = "arms"
    case thighs = "thighs"
}

struct ProgressChart: Identifiable, Codable {
    let id = UUID()
    let title: String
    let data: [ChartDataPoint]
    let unit: String
    let color: String
}

struct ChartDataPoint: Codable {
    let date: Date
    let value: Double
}

struct WorkoutAnalytics: Codable {
    let totalWorkouts: Int
    let totalTime: Int
    let totalCalories: Int
    let averageWorkoutTime: Double
    let mostActiveDay: String
    let strongestMuscleGroup: String
}

struct ProgressTrend: Identifiable, Codable {
    let id = UUID()
    let metric: String
    let change: Double
    let direction: TrendDirection
}

enum TrendDirection: String, Codable, CaseIterable {
    case increasing = "increasing"
    case decreasing = "decreasing"
    case stable = "stable"
}

enum AnalyticsPeriod: String, CaseIterable {
    case week = "week"
    case month = "month"
    case year = "year"
    case allTime = "all_time"
}
