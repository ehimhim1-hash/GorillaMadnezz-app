//
//  HealthManager.swift
//  GorillaMadnezz
//
//  Manages HealthKit integration and health data tracking
//

import Foundation
import HealthKit
import Combine

class HealthManager: ObservableObject {
    @Published var isHealthKitAvailable = false
    @Published var hasHealthKitPermission = false
    @Published var todaysSteps: Int = 0
    @Published var todaysCalories: Int = 0
    @Published var heartRate: Int = 0
    @Published var activeEnergyBurned: Double = 0
    @Published var workoutMinutes: Int = 0
    @Published var restingHeartRate: Int = 0
    @Published var vo2Max: Double = 0
    
    private let healthStore = HKHealthStore()
    private var cancellables = Set<AnyCancellable>()
    
    // Health data types we want to read
    private let healthDataTypesToRead: Set<HKObjectType> = [
        HKQuantityType.quantityType(forIdentifier: .stepCount)!,
        HKQuantityType.quantityType(forIdentifier: .activeEnergyBurned)!,
        HKQuantityType.quantityType(forIdentifier: .basalEnergyBurned)!,
        HKQuantityType.quantityType(forIdentifier: .heartRate)!,
        HKQuantityType.quantityType(forIdentifier: .restingHeartRate)!,
        HKQuantityType.quantityType(forIdentifier: .vo2Max)!,
        HKQuantityType.quantityType(forIdentifier: .bodyMass)!,
        HKQuantityType.quantityType(forIdentifier: .bodyFatPercentage)!,
        HKQuantityType.quantityType(forIdentifier: .leanBodyMass)!,
        HKWorkoutType.workoutType()
    ]
    
    // Health data types we want to write
    private let healthDataTypesToWrite: Set<HKSampleType> = [
        HKQuantityType.quantityType(forIdentifier: .activeEnergyBurned)!,
        HKQuantityType.quantityType(forIdentifier: .bodyMass)!,
        HKWorkoutType.workoutType()
    ]
    
    init() {
        checkHealthKitAvailability()
        setupHealthDataObservers()
    }
    
    // MARK: - HealthKit Setup
    
    private func checkHealthKitAvailability() {
        isHealthKitAvailable = HKHealthStore.isHealthDataAvailable()
    }
    
    func requestHealthKitPermission() {
        guard isHealthKitAvailable else {
            print("HealthKit is not available on this device")
            return
        }
        
        healthStore.requestAuthorization(toShare: healthDataTypesToWrite, read: healthDataTypesToRead) { success, error in
            DispatchQueue.main.async {
                if success {
                    self.hasHealthKitPermission = true
                    self.startHealthDataQueries()
                    print("✅ HealthKit permission granted")
                } else {
                    self.hasHealthKitPermission = false
                    print("❌ HealthKit permission denied: \(error?.localizedDescription ?? "Unknown error")")
                }
            }
        }
    }
    
    // MARK: - Health Data Queries
    
    private func startHealthDataQueries() {
        fetchTodaysSteps()
        fetchTodaysCalories()
        fetchLatestHeartRate()
        fetchActiveEnergyBurned()
        fetchWorkoutMinutes()
        fetchRestingHeartRate()
        fetchVO2Max()
        
        // Setup real-time updates
        setupHealthDataObservers()
    }
    
    private func fetchTodaysSteps() {
        guard let stepType = HKQuantityType.quantityType(forIdentifier: .stepCount) else { return }
        
        let startOfDay = Calendar.current.startOfDay(for: Date())
        let predicate = HKQuery.predicateForSamples(withStart: startOfDay, end: Date(), options: .strictStartDate)
        
        let query = HKStatisticsQuery(quantityType: stepType, quantitySamplePredicate: predicate, options: .cumulativeSum) { _, result, error in
            DispatchQueue.main.async {
                if let sum = result?.sumQuantity() {
                    self.todaysSteps = Int(sum.doubleValue(for: HKUnit.count()))
                } else {
                    print("Steps query error: \(error?.localizedDescription ?? "Unknown error")")
                }
            }
        }
        
        healthStore.execute(query)
    }
    
    private func fetchTodaysCalories() {
        guard let calorieType = HKQuantityType.quantityType(forIdentifier: .activeEnergyBurned) else { return }
        
        let startOfDay = Calendar.current.startOfDay(for: Date())
        let predicate = HKQuery.predicateForSamples(withStart: startOfDay, end: Date(), options: .strictStartDate)
        
        let query = HKStatisticsQuery(quantityType: calorieType, quantitySamplePredicate: predicate, options: .cumulativeSum) { _, result, error in
            DispatchQueue.main.async {
                if let sum = result?.sumQuantity() {
                    self.todaysCalories = Int(sum.doubleValue(for: HKUnit.kilocalorie()))
                } else {
                    print("Calories query error: \(error?.localizedDescription ?? "Unknown error")")
                }
            }
        }
        
        healthStore.execute(query)
    }
    
    private func fetchLatestHeartRate() {
        guard let heartRateType = HKQuantityType.quantityType(forIdentifier: .heartRate) else { return }
        
        let sortDescriptor = NSSortDescriptor(key: HKSampleSortIdentifierEndDate, ascending: false)
        let query = HKSampleQuery(sampleType: heartRateType, predicate: nil, limit: 1, sortDescriptors: [sortDescriptor]) { _, samples, error in
            DispatchQueue.main.async {
                if let sample = samples?.first as? HKQuantitySample {
                    self.heartRate = Int(sample.quantity.doubleValue(for: HKUnit(from: "count/min")))
                } else {
                    print("Heart rate query error: \(error?.localizedDescription ?? "Unknown error")")
                }
            }
        }
        
        healthStore.execute(query)
    }
    
    private func fetchActiveEnergyBurned() {
        guard let energyType = HKQuantityType.quantityType(forIdentifier: .activeEnergyBurned) else { return }
        
        let startOfDay = Calendar.current.startOfDay(for: Date())
        let predicate = HKQuery.predicateForSamples(withStart: startOfDay, end: Date(), options: .strictStartDate)
        
        let query = HKStatisticsQuery(quantityType: energyType, quantitySamplePredicate: predicate, options: .cumulativeSum) { _, result, error in
            DispatchQueue.main.async {
                if let sum = result?.sumQuantity() {
                    self.activeEnergyBurned = sum.doubleValue(for: HKUnit.kilocalorie())
                }
            }
        }
        
        healthStore.execute(query)
    }
    
    private func fetchWorkoutMinutes() {
        let startOfDay = Calendar.current.startOfDay(for: Date())
        let predicate = HKQuery.predicateForSamples(withStart: startOfDay, end: Date(), options: .strictStartDate)
        
        let query = HKSampleQuery(sampleType: HKWorkoutType.workoutType(), predicate: predicate, limit: HKObjectQueryNoLimit, sortDescriptors: nil) { _, samples, error in
            DispatchQueue.main.async {
                if let workouts = samples as? [HKWorkout] {
                    let totalMinutes = workouts.reduce(0) { $0 + Int($1.duration / 60) }
                    self.workoutMinutes = totalMinutes
                }
            }
        }
        
        healthStore.execute(query)
    }
    
    private func fetchRestingHeartRate() {
        guard let restingHRType = HKQuantityType.quantityType(forIdentifier: .restingHeartRate) else { return }
        
        let sortDescriptor = NSSortDescriptor(key: HKSampleSortIdentifierEndDate, ascending: false)
        let query = HKSampleQuery(sampleType: restingHRType, predicate: nil, limit: 1, sortDescriptors: [sortDescriptor]) { _, samples, error in
            DispatchQueue.main.async {
                if let sample = samples?.first as? HKQuantitySample {
                    self.restingHeartRate = Int(sample.quantity.doubleValue(for: HKUnit(from: "count/min")))
                }
            }
        }
        
        healthStore.execute(query)
    }
    
    private func fetchVO2Max() {
        guard let vo2MaxType = HKQuantityType.quantityType(forIdentifier: .vo2Max) else { return }
        
        let sortDescriptor = NSSortDescriptor(key: HKSampleSortIdentifierEndDate, ascending: false)
        let query = HKSampleQuery(sampleType: vo2MaxType, predicate: nil, limit: 1, sortDescriptors: [sortDescriptor]) { _, samples, error in
            DispatchQueue.main.async {
                if let sample = samples?.first as? HKQuantitySample {
                    self.vo2Max = sample.quantity.doubleValue(for: HKUnit(from: "ml/kg*min"))
                }
            }
        }
        
        healthStore.execute(query)
    }
    
    // MARK: - Writing Health Data
    
    func saveWorkoutToHealth(_ workout: WorkoutSession) {
        guard hasHealthKitPermission else { return }
        
        let workoutType = mapWorkoutType(workout)
        let startDate = workout.date
        let endDate = workout.date.addingTimeInterval(TimeInterval(workout.duration * 60))
        
        let hkWorkout = HKWorkout(
            activityType: workoutType,
            start: startDate,
            end: endDate,
            duration: TimeInterval(workout.duration * 60),
            totalEnergyBurned: HKQuantity(unit: HKUnit.kilocalorie(), doubleValue: Double(workout.totalCalories)),
            totalDistance: nil,
            metadata: [
                HKMetadataKeyWorkoutBrandName: "Gorilla Madnezz",
                "WorkoutNotes": workout.notes
            ]
        )
        
        healthStore.save(hkWorkout) { success, error in
            if success {
                print("✅ Workout saved to HealthKit")
                
                // Also save calories burned as a separate sample
                self.saveCaloriesToHealth(calories: Double(workout.totalCalories), startDate: startDate, endDate: endDate)
            } else {
                print("❌ Failed to save workout: \(error?.localizedDescription ?? "Unknown error")")
            }
        }
    }
    
    private func saveCaloriesToHealth(calories: Double, startDate: Date, endDate: Date) {
        guard let calorieType = HKQuantityType.quantityType(forIdentifier: .activeEnergyBurned) else { return }
        
        let calorieQuantity = HKQuantity(unit: HKUnit.kilocalorie(), doubleValue: calories)
        let calorieSample = HKQuantitySample(
            type: calorieType,
            quantity: calorieQuantity,
            start: startDate,
            end: endDate,
            metadata: [HKMetadataKeyWorkoutBrandName: "Gorilla Madnezz"]
        )
        
        healthStore.save(calorieSample) { success, error in
            if success {
                print("✅ Calories saved to HealthKit")
            } else {
                print("❌ Failed to save calories: \(error?.localizedDescription ?? "Unknown error")")
            }
        }
    }
    
    func saveBodyWeight(_ weight: Double) {
        guard hasHealthKitPermission,
              let weightType = HKQuantityType.quantityType(forIdentifier: .bodyMass) else { return }
        
        let weightQuantity = HKQuantity(unit: HKUnit.pound(), doubleValue: weight)
        let weightSample = HKQuantitySample(
            type: weightType,
            quantity: weightQuantity,
            start: Date(),
            end: Date(),
            metadata: [HKMetadataKeyWorkoutBrandName: "Gorilla Madnezz"]
        )
        
        healthStore.save(weightSample) { success, error in
            if success {
                print("✅ Weight saved to HealthKit")
            } else {
                print("❌ Failed to save weight: \(error?.localizedDescription ?? "Unknown error")")
            }
        }
    }
    
    // MARK: - Health Data Analysis
    
    func getWeeklyHealthSummary() -> WeeklyHealthSummary {
        // This would normally fetch a week's worth of data
        // For now, returning current day data scaled up
        return WeeklyHealthSummary(
            totalSteps: todaysSteps * 7,
            totalCalories: todaysCalories * 7,
            averageHeartRate: heartRate,
            totalWorkoutMinutes: workoutMinutes * 7,
            restingHeartRateAverage: restingHeartRate,
            vo2MaxAverage: vo2Max
        )
    }
    
    func getHealthTrends(period: HealthTrendPeriod) -> [HealthTrend] {
        // Simulate health trends
        return [
            HealthTrend(metric: "Steps", value: Double(todaysSteps), change: 12.5, period: period),
            HealthTrend(metric: "Calories", value: Double(todaysCalories), change: 8.3, period: period),
            HealthTrend(metric: "Heart Rate", value: Double(heartRate), change: -2.1, period: period),
            HealthTrend(metric: "VO2 Max", value: vo2Max, change: 4.7, period: period)
        ]
    }
    
    func calculateHealthScore() -> HealthScore {
        let stepsScore = min(Double(todaysSteps) / 10000.0, 1.0) * 25 // 25 points for 10k steps
        let caloriesScore = min(Double(todaysCalories) / 500.0, 1.0) * 25 // 25 points for 500 calories
        let heartRateScore = heartRate > 0 ? 25.0 : 0.0 // 25 points for having heart rate data
        let workoutScore = min(Double(workoutMinutes) / 60.0, 1.0) * 25 // 25 points for 60 minutes
        
        let totalScore = stepsScore + caloriesScore + heartRateScore + workoutScore
        
        return HealthScore(
            score: Int(totalScore),
            maxScore: 100,
            breakdown: [
                "Steps": Int(stepsScore),
                "Calories": Int(caloriesScore),
                "Heart Rate": Int(heartRateScore),
                "Workouts": Int(workoutScore)
            ]
        )
    }
    
    // MARK: - Private Helpers
    
    private func mapWorkoutType(_ workout: WorkoutSession) -> HKWorkoutActivityType {
        // Map our workout to HealthKit workout types
        let primaryMuscleGroups = workout.exercises.map { $0.primaryMuscleGroup }
        
        if primaryMuscleGroups.contains(where: { ["Legs", "Glutes"].contains($0) }) {
            return .functionalStrengthTraining
        } else if primaryMuscleGroups.contains("Cardio") {
            return .other // or .cardio if available
        } else {
            return .traditionalStrengthTraining
        }
    }
    
    private func setupHealthDataObservers() {
        // Setup observers for real-time health data updates
        guard hasHealthKitPermission else { return }
        
        // Observe step count changes
        if let stepType = HKQuantityType.quantityType(forIdentifier: .stepCount) {
            let query = HKObserverQuery(sampleType: stepType, predicate: nil) { _, _, error in
                if error == nil {
                    DispatchQueue.main.async {
                        self.fetchTodaysSteps()
                    }
                }
            }
            healthStore.execute(query)
        }
        
        // Observe calorie changes
        if let calorieType = HKQuantityType.quantityType(forIdentifier: .activeEnergyBurned) {
            let query = HKObserverQuery(sampleType: calorieType, predicate: nil) { _, _, error in
                if error == nil {
                    DispatchQueue.main.async {
                        self.fetchTodaysCalories()
                    }
                }
            }
            healthStore.execute(query)
        }
        
        // Setup periodic refresh
        Timer.publish(every: 300, on: .main, in: .common) // Every 5 minutes
            .autoconnect()
            .sink { _ in
                if self.hasHealthKitPermission {
                    self.fetchTodaysSteps()
                    self.fetchTodaysCalories()
                    self.fetchLatestHeartRate()
                }
            }
            .store(in: &cancellables)
    }
}

// MARK: - Data Models

struct WeeklyHealthSummary: Codable {
    let totalSteps: Int
    let totalCalories: Int
    let averageHeartRate: Int
    let totalWorkoutMinutes: Int
    let restingHeartRateAverage: Int
    let vo2MaxAverage: Double
}

struct HealthTrend: Identifiable, Codable {
    let id = UUID()
    let metric: String
    let value: Double
    let change: Double // percentage change
    let period: HealthTrendPeriod
}

struct HealthScore: Codable {
    let score: Int
    let maxScore: Int
    let breakdown: [String: Int]
    
    var percentage: Double {
        return Double(score) / Double(maxScore) * 100
    }
    
    var grade: String {
        switch percentage {
        case 90...100: return "A+"
        case 80..<90: return "A"
        case 70..<80: return "B"
        case 60..<70: return "C"
        case 50..<60: return "D"
        default: return "F"
        }
    }
}

enum HealthTrendPeriod: String, Codable, CaseIterable {
    case week = "week"
    case month = "month"
    case quarter = "quarter"
    case year = "year"
    
    var displayName: String {
        switch self {
        case .week: return "This Week"
        case .month: return "This Month"
        case .quarter: return "This Quarter"
        case .year: return "This Year"
        }
    }
}

// MARK: - Health Permissions Helper

struct HealthPermissions {
    static func getRequiredPermissions() -> [String] {
        return [
            "Steps",
            "Active Calories",
            "Heart Rate",
            "Workouts",
            "Body Weight",
            "VO2 Max"
        ]
    }
    
    static func getOptionalPermissions() -> [String] {
        return [
            "Body Fat Percentage",
            "Lean Body Mass",
            "Resting Heart Rate",
            "Sleep Analysis"
        ]
    }
}

// MARK: - Health Data Formatter

struct HealthDataFormatter {
    static func formatSteps(_ steps: Int) -> String {
        if steps >= 1000 {
            return String(format: "%.1fK", Double(steps) / 1000.0)
        }
        return "\(steps)"
    }
    
    static func formatCalories(_ calories: Int) -> String {
        return "\(calories) cal"
    }
    
    static func formatHeartRate(_ heartRate: Int) -> String {
        return "\(heartRate) bpm"
    }
    
    static func formatDistance(_ meters: Double) -> String {
        let miles = meters * 0.000621371
        return String(format: "%.2f mi", miles)
    }
    
    static func formatDuration(_ seconds: TimeInterval) -> String {
        let minutes = Int(seconds) / 60
        let hours = minutes / 60
        let remainingMinutes = minutes % 60
        
        if hours > 0 {
            return "\(hours)h \(remainingMinutes)m"
        } else {
            return "\(minutes)m"
        }
    }
}
