//
//  DataManager.swift
//  GorillaMadnezz
//
//  Handles data persistence, storage, and synchronization
//

import Foundation
import CoreData
import Combine

class DataManager: ObservableObject {
    @Published var isSyncing = false
    @Published var lastSyncDate: Date?
    @Published var storageUsage: StorageInfo = StorageInfo()
    @Published var cloudSyncEnabled = true
    
    // Core Data Stack
    lazy var persistentContainer: NSPersistentContainer = {
        let container = NSPersistentContainer(name: "GorillaMadnezzDataModel")
        container.loadPersistentStores { _, error in
            if let error = error {
                print("Core Data error: \(error)")
            }
        }
        return container
    }()
    
    var context: NSManagedObjectContext {
        return persistentContainer.viewContext
    }
    
    private var cancellables = Set<AnyCancellable>()
    
    init() {
        setupPeriodicSync()
        calculateStorageUsage()
    }
    
    // MARK: - Core Data Operations
    
    func saveContext() {
        if context.hasChanges {
            do {
                try context.save()
                print("✅ Data saved successfully")
            } catch {
                print("❌ Save error: \(error)")
            }
        }
    }
    
    func fetch<T: NSManagedObject>(_ request: NSFetchRequest<T>) -> [T] {
        do {
            return try context.fetch(request)
        } catch {
            print("❌ Fetch error: \(error)")
            return []
        }
    }
    
    func delete(_ object: NSManagedObject) {
        context.delete(object)
        saveContext()
    }
    
    func deleteAll<T: NSManagedObject>(entityName: String, type: T.Type) {
        let request = NSFetchRequest<NSFetchRequestResult>(entityName: entityName)
        let deleteRequest = NSBatchDeleteRequest(fetchRequest: request)
        
        do {
            try context.execute(deleteRequest)
            saveContext()
        } catch {
            print("❌ Delete all error: \(error)")
        }
    }
    
    // MARK: - Workout Data Management
    
    func saveWorkout(_ workout: WorkoutSession) {
        let workoutEntity = WorkoutEntity(context: context)
        workoutEntity.id = workout.id
        workoutEntity.date = workout.date
        workoutEntity.duration = Int32(workout.duration)
        workoutEntity.totalCalories = Int32(workout.totalCalories)
        workoutEntity.totalVolume = workout.totalVolume
        workoutEntity.intensity = workout.intensity
        workoutEntity.notes = workout.notes
        
        // Save exercises
        for exercise in workout.exercises {
            let exerciseEntity = ExerciseEntity(context: context)
            exerciseEntity.name = exercise.name
            exerciseEntity.primaryMuscleGroup = exercise.primaryMuscleGroup
            exerciseEntity.workout = workoutEntity
            
            // Save sets
            for (index, set) in exercise.sets.enumerated() {
                let setEntity = SetEntity(context: context)
                setEntity.weight = set.weight
                setEntity.reps = Int32(set.reps)
                setEntity.restTime = Int32(set.restTime)
                setEntity.completed = set.completed
                setEntity.order = Int32(index)
                setEntity.exercise = exerciseEntity
            }
        }
        
        saveContext()
        
        // Trigger sync if enabled
        if cloudSyncEnabled {
            syncToCloud()
        }
    }
    
    func loadWorkouts(limit: Int = 100) -> [WorkoutSession] {
        let request: NSFetchRequest<WorkoutEntity> = WorkoutEntity.fetchRequest()
        request.sortDescriptors = [NSSortDescriptor(keyPath: \WorkoutEntity.date, ascending: false)]
        request.fetchLimit = limit
        
        let workoutEntities = fetch(request)
        
        return workoutEntities.compactMap { entity in
            guard let id = entity.id,
                  let date = entity.date else { return nil }
            
            let exercises = (entity.exercises?.allObjects as? [ExerciseEntity])?.compactMap { exerciseEntity in
                guard let name = exerciseEntity.name,
                      let muscleGroup = exerciseEntity.primaryMuscleGroup else { return nil }
                
                let sets = (exerciseEntity.sets?.allObjects as? [SetEntity])?.sorted { $0.order < $1.order }.map { setEntity in
                    SetData(
                        weight: setEntity.weight,
                        reps: Int(setEntity.reps),
                        restTime: Int(setEntity.restTime),
                        completed: setEntity.completed
                    )
                } ?? []
                
                return ExerciseSession(
                    name: name,
                    sets: sets,
                    primaryMuscleGroup: muscleGroup,
                    secondaryMuscleGroups: []
                )
            } ?? []
            
            return WorkoutSession(
                id: id,
                date: date,
                duration: Int(entity.duration),
                exercises: exercises,
                totalCalories: Int(entity.totalCalories),
                totalVolume: entity.totalVolume,
                intensity: entity.intensity,
                notes: entity.notes ?? ""
            )
        }
    }
    
    // MARK: - Personal Records Management
    
    func savePersonalRecord(_ record: PersonalRecord) {
        let recordEntity = PersonalRecordEntity(context: context)
        recordEntity.exerciseName = record.exerciseName
        recordEntity.oneRepMax = record.oneRepMax
        recordEntity.maxWeight = record.maxWeight
        recordEntity.maxReps = Int32(record.maxReps)
        recordEntity.bestVolume = record.bestVolume
        recordEntity.dateAchieved = record.dateAchieved
        recordEntity.previousRecord = record.previousRecord
        
        saveContext()
    }
    
    func loadPersonalRecords() -> [String: PersonalRecord] {
        let request: NSFetchRequest<PersonalRecordEntity> = PersonalRecordEntity.fetchRequest()
        let recordEntities = fetch(request)
        
        var records: [String: PersonalRecord] = [:]
        
        for entity in recordEntities {
            guard let exerciseName = entity.exerciseName,
                  let dateAchieved = entity.dateAchieved else { continue }
            
            let record = PersonalRecord(
                exerciseName: exerciseName,
                oneRepMax: entity.oneRepMax,
                maxWeight: entity.maxWeight,
                maxReps: Int(entity.maxReps),
                bestVolume: entity.bestVolume,
                dateAchieved: dateAchieved,
                previousRecord: entity.previousRecord
            )
            
            records[exerciseName.lowercased()] = record
        }
        
        return records
    }
    
    // MARK: - Body Measurements Management
    
    func saveBodyMeasurement(_ measurement: BodyMeasurement) {
        let measurementEntity = MeasurementEntity(context: context)
        measurementEntity.type = measurement.type.rawValue
        measurementEntity.value = measurement.value
        measurementEntity.date = measurement.date
        measurementEntity.notes = measurement.notes
        
        saveContext()
    }
    
    func loadBodyMeasurements() -> [BodyMeasurement] {
        let request: NSFetchRequest<MeasurementEntity> = MeasurementEntity.fetchRequest()
        request.sortDescriptors = [NSSortDescriptor(keyPath: \MeasurementEntity.date, ascending: false)]
        
        let measurementEntities = fetch(request)
        
        return measurementEntities.compactMap { entity in
            guard let typeString = entity.type,
                  let type = MeasurementType(rawValue: typeString),
                  let date = entity.date else { return nil }
            
            return BodyMeasurement(
                type: type,
                value: entity.value,
                date: date,
                notes: entity.notes ?? ""
            )
        }
    }
    
    // MARK: - Cloud Synchronization
    
    func syncToCloud() {
        guard cloudSyncEnabled else { return }
        
        isSyncing = true
        
        // Simulate cloud sync process
        DispatchQueue.global(qos: .background).async {
            Thread.sleep(forTimeInterval: 2.0) // Simulate network delay
            
            DispatchQueue.main.async {
                self.isSyncing = false
                self.lastSyncDate = Date()
                print("☁️ Cloud sync completed")
                
                NotificationCenter.default.post(
                    name: NSNotification.Name("CloudSyncCompleted"),
                    object: nil
                )
            }
        }
    }
    
    func forceSyncFromCloud() {
        guard cloudSyncEnabled else { return }
        
        isSyncing = true
        
        // Simulate downloading data from cloud
        DispatchQueue.global(qos: .background).async {
            Thread.sleep(forTimeInterval: 3.0) // Simulate download
            
            DispatchQueue.main.async {
                self.isSyncing = false
                self.lastSyncDate = Date()
                print("☁️ Cloud data downloaded")
                
                NotificationCenter.default.post(
                    name: NSNotification.Name("CloudDataRefreshed"),
                    object: nil
                )
            }
        }
    }
    
    // MARK: - Data Export/Import
    
    func exportAllData() -> AppDataExport {
        let workouts = loadWorkouts(limit: 1000)
        let personalRecords = loadPersonalRecords()
        let bodyMeasurements = loadBodyMeasurements()
        
        return AppDataExport(
            workouts: workouts,
            personalRecords: Array(personalRecords.values),
            bodyMeasurements: bodyMeasurements,
            exportDate: Date(),
            appVersion: Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0",
            dataVersion: "1.0"
        )
    }
    
    func importData(_ importData: AppDataExport) {
        // Clear existing data
        deleteAll(entityName: "WorkoutEntity", type: WorkoutEntity.self)
        deleteAll(entityName: "PersonalRecordEntity", type: PersonalRecordEntity.self)
        deleteAll(entityName: "MeasurementEntity", type: MeasurementEntity.self)
        
        // Import workouts
        for workout in importData.workouts {
            saveWorkout(workout)
        }
        
        // Import personal records
        for record in importData.personalRecords {
            savePersonalRecord(record)
        }
        
        // Import body measurements
        for measurement in importData.bodyMeasurements {
            saveBodyMeasurement(measurement)
        }
        
        print("📥 Data import completed")
        
        NotificationCenter.default.post(
            name: NSNotification.Name("DataImported"),
            object: nil
        )
    }
    
    // MARK: - Storage Management
    
    func calculateStorageUsage() {
        DispatchQueue.global(qos: .utility).async {
            let documentsURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
            let storeURL = documentsURL.appendingPathComponent("GorillaMadnezzDataModel.sqlite")
            
            var totalSize: Int64 = 0
            
            if let attributes = try? FileManager.default.attributesOfItem(atPath: storeURL.path) {
                totalSize = attributes[.size] as? Int64 ?? 0
            }
            
            let workoutCount = self.fetch(WorkoutEntity.fetchRequest()).count
            let recordCount = self.fetch(PersonalRecordEntity.fetchRequest()).count
            let measurementCount = self.fetch(MeasurementEntity.fetchRequest()).count
            
            DispatchQueue.main.async {
                self.storageUsage = StorageInfo(
                    totalSize: totalSize,
                    workoutCount: workoutCount,
                    recordCount: recordCount,
                    measurementCount: measurementCount
                )
            }
        }
    }
    
    func clearOldData(olderThan days: Int) {
        let cutoffDate = Calendar.current.date(byAdding: .day, value: -days, to: Date()) ?? Date()
        
        // Delete old workouts
        let workoutRequest: NSFetchRequest<WorkoutEntity> = WorkoutEntity.fetchRequest()
        workoutRequest.predicate = NSPredicate(format: "date < %@", cutoffDate as NSDate)
        
        let oldWorkouts = fetch(workoutRequest)
        for workout in oldWorkouts {
            delete(workout)
        }
        
        // Delete old measurements
        let measurementRequest: NSFetchRequest<MeasurementEntity> = MeasurementEntity.fetchRequest()
        measurementRequest.predicate = NSPredicate(format: "date < %@", cutoffDate as NSDate)
        
        let oldMeasurements = fetch(measurementRequest)
        for measurement in oldMeasurements {
            delete(measurement)
        }
        
        saveContext()
        calculateStorageUsage()
        
        print("🗑️ Cleared data older than \(days) days")
    }
    
    // MARK: - Backup & Restore
    
    func createBackup() -> Bool {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd_HH-mm-ss"
        let timestamp = dateFormatter.string(from: Date())
        
        let documentsURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        let backupURL = documentsURL.appendingPathComponent("backup_\(timestamp).sqlite")
        let storeURL = documentsURL.appendingPathComponent("GorillaMadnezzDataModel.sqlite")
        
        do {
            try FileManager.default.copyItem(at: storeURL, to: backupURL)
            print("💾 Backup created: \(backupURL.lastPathComponent)")
            return true
        } catch {
            print("❌ Backup failed: \(error)")
            return false
        }
    }
    
    func restoreFromBackup(_ backupURL: URL) -> Bool {
        let documentsURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        let storeURL = documentsURL.appendingPathComponent("GorillaMadnezzDataModel.sqlite")
        
        do {
            // Remove current database
            try FileManager.default.removeItem(at: storeURL)
            
            // Copy backup to main location
            try FileManager.default.copyItem(at: backupURL, to: storeURL)
            
            // Reload persistent container
            persistentContainer = {
                let container = NSPersistentContainer(name: "GorillaMadnezzDataModel")
                container.loadPersistentStores { _, error in
                    if let error = error {
                        print("Core Data error after restore: \(error)")
                    }
                }
                return container
            }()
            
            print("🔄 Backup restored successfully")
            return true
        } catch {
            print("❌ Restore failed: \(error)")
            return false
        }
    }
    
    // MARK: - Private Helpers
    
    private func setupPeriodicSync() {
        // Auto-sync every 30 minutes when app is active
        Timer.publish(every: 1800, on: .main, in: .common)
            .autoconnect()
            .sink { _ in
                if self.cloudSyncEnabled {
                    self.syncToCloud()
                }
            }
            .store(in: &cancellables)
        
        // Recalculate storage usage every 5 minutes
        Timer.publish(every: 300, on: .main, in: .common)
            .autoconnect()
            .sink { _ in
                self.calculateStorageUsage()
            }
            .store(in: &cancellables)
    }
}

// MARK: - Data Models

struct StorageInfo: Codable {
    let totalSize: Int64
    let workoutCount: Int
    let recordCount: Int
    let measurementCount: Int
    
    init() {
        totalSize = 0
        workoutCount = 0
        recordCount = 0
        measurementCount = 0
    }
    
    init(totalSize: Int64, workoutCount: Int, recordCount: Int, measurementCount: Int) {
        self.totalSize = totalSize
        self.workoutCount = workoutCount
        self.recordCount = recordCount
        self.measurementCount = measurementCount
    }
    
    var formattedSize: String {
        let formatter = ByteCountFormatter()
        return formatter.string(fromByteCount: totalSize)
    }
}

struct AppDataExport: Codable {
    let workouts: [WorkoutSession]
    let personalRecords: [PersonalRecord]
    let bodyMeasurements: [BodyMeasurement]
    let exportDate: Date
    let appVersion: String
    let dataVersion: String
}

// MARK: - Core Data Entities (would be defined in .xcdatamodeld file)

// Note: These would normally be auto-generated from Core Data model
// This is just for reference of the entity structure

@objc(WorkoutEntity)
public class WorkoutEntity: NSManagedObject {
    @NSManaged public var id: String?
    @NSManaged public var date: Date?
    @NSManaged public var duration: Int32
    @NSManaged public var totalCalories: Int32
    @NSManaged public var totalVolume: Double
    @NSManaged public var intensity: Double
    @NSManaged public var notes: String?
    @NSManaged public var exercises: NSSet?
}

@objc(ExerciseEntity)
public class ExerciseEntity: NSManagedObject {
    @NSManaged public var name: String?
    @NSManaged public var primaryMuscleGroup: String?
    @NSManaged public var workout: WorkoutEntity?
    @NSManaged public var sets: NSSet?
}

@objc(SetEntity)
public class SetEntity: NSManagedObject {
    @NSManaged public var weight: Double
    @NSManaged public var reps: Int32
    @NSManaged public var restTime: Int32
    @NSManaged public var completed: Bool
    @NSManaged public var order: Int32
    @NSManaged public var exercise: ExerciseEntity?
}

@objc(PersonalRecordEntity)
public class PersonalRecordEntity: NSManagedObject {
    @NSManaged public var exerciseName: String?
    @NSManaged public var oneRepMax: Double
    @NSManaged public var maxWeight: Double
    @NSManaged public var maxReps: Int32
    @NSManaged public var bestVolume: Double
    @NSManaged public var dateAchieved: Date?
    @NSManaged public var previousRecord: Double
}

@objc(MeasurementEntity)
public class MeasurementEntity: NSManagedObject {
    @NSManaged public var type: String?
    @NSManaged public var value: Double
    @NSManaged public var date: Date?
    @NSManaged public var notes: String?
}

// Fetch Request Extensions
extension WorkoutEntity {
    @nonobjc public class func fetchRequest() -> NSFetchRequest<WorkoutEntity> {
        return NSFetchRequest<WorkoutEntity>(entityName: "WorkoutEntity")
    }
}

extension ExerciseEntity {
    @nonobjc public class func fetchRequest() -> NSFetchRequest<ExerciseEntity> {
        return NSFetchRequest<ExerciseEntity>(entityName: "ExerciseEntity")
    }
}

extension SetEntity {
    @nonobjc public class func fetchRequest() -> NSFetchRequest<SetEntity> {
        return NSFetchRequest<SetEntity>(entityName: "SetEntity")
    }
}

extension PersonalRecordEntity {
    @nonobjc public class func fetchRequest() -> NSFetchRequest<PersonalRecordEntity> {
        return NSFetchRequest<PersonalRecordEntity>(entityName: "PersonalRecordEntity")
    }
}

extension MeasurementEntity {
    @nonobjc public class func fetchRequest() -> NSFetchRequest<MeasurementEntity> {
        return NSFetchRequest<MeasurementEntity>(entityName: "MeasurementEntity")
    }
}
