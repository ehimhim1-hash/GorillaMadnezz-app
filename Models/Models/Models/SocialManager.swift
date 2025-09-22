//
//  SocialManager.swift
//  GorillaMadnezz
//
//  Social features and friend management system
//

import Foundation
import Combine

class SocialManager: ObservableObject {
    @Published var friends: [Friend] = []
    @Published var friendRequests: [FriendRequest] = []
    @Published var coopSessions: [CoopSession] = []
    @Published var leaderboard: [LeaderboardEntry] = []
    @Published var isOnline = false
    
    private var cancellables = Set<AnyCancellable>()
    
    init() {
        loadSampleData()
        setupPeriodicUpdates()
    }
    
    // MARK: - Friend Management
    
    func sendFriendRequest(to userId: String, username: String) {
        let request = FriendRequest(
            id: UUID().uuidString,
            fromUserId: "current_user",
            toUserId: userId,
            toUsername: username,
            status: .pending,
            dateSent: Date()
        )
        
        friendRequests.append(request)
        
        // Simulate network delay
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            self.updateRequestStatus(request.id, status: .accepted)
        }
    }
    
    func acceptFriendRequest(_ requestId: String) {
        guard let index = friendRequests.firstIndex(where: { $0.id == requestId }) else { return }
        let request = friendRequests[index]
        
        // Add as friend
        let newFriend = Friend(
            id: request.fromUserId,
            username: request.toUsername,
            level: Int.random(in: 1...25),
            isOnline: Bool.random(),
            lastWorkout: Date().addingTimeInterval(-Double.random(in: 0...86400)),
            sharedWorkouts: Int.random(in: 0...15)
        )
        
        friends.append(newFriend)
        friendRequests.remove(at: index)
    }
    
    func rejectFriendRequest(_ requestId: String) {
        friendRequests.removeAll { $0.id == requestId }
    }
    
    private func updateRequestStatus(_ requestId: String, status: FriendRequestStatus) {
        if let index = friendRequests.firstIndex(where: { $0.id == requestId }) {
            friendRequests[index].status = status
        }
    }
    
    // MARK: - Co-op Training
    
    func createCoopSession(with friendId: String, workoutType: CoopWorkoutType) {
        guard let friend = friends.first(where: { $0.id == friendId }) else { return }
        
        let session = CoopSession(
            id: UUID().uuidString,
            hostId: "current_user",
            partnerId: friendId,
            partnerName: friend.username,
            workoutType: workoutType,
            status: .waiting,
            createdAt: Date(),
            exercises: generateCoopExercises(for: workoutType)
        )
        
        coopSessions.append(session)
        
        // Simulate friend joining
        DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) {
            self.joinCoopSession(session.id)
        }
    }
    
    func joinCoopSession(_ sessionId: String) {
        if let index = coopSessions.firstIndex(where: { $0.id == sessionId }) {
            coopSessions[index].status = .active
            coopSessions[index].startedAt = Date()
        }
    }
    
    func completeCoopSession(_ sessionId: String) {
        if let index = coopSessions.firstIndex(where: { $0.id == sessionId }) {
            coopSessions[index].status = .completed
            coopSessions[index].completedAt = Date()
            
            // Award bonus XP for co-op completion
            NotificationCenter.default.post(
                name: NSNotification.Name("CoopSessionCompleted"),
                object: ["bonusXP": 50, "sessionId": sessionId]
            )
        }
    }
    
    // MARK: - Leaderboards
    
    func updateLeaderboard() {
        // Simulate fetching fresh leaderboard data
        leaderboard = generateLeaderboardData()
    }
    
    func getUserRank() -> Int {
        return leaderboard.firstIndex(where: { $0.isCurrentUser }) ?? 0
    }
    
    // MARK: - Challenge System
    
    func sendChallenge(to friendId: String, challengeType: ChallengeType) {
        guard let friend = friends.first(where: { $0.id == friendId }) else { return }
        
        let challenge = Challenge(
            id: UUID().uuidString,
            fromUserId: "current_user",
            toUserId: friendId,
            toUsername: friend.username,
            type: challengeType,
            status: .pending,
            createdAt: Date(),
            expiresAt: Date().addingTimeInterval(86400 * 7) // 7 days
        )
        
        // Add to friend's challenge list (simulated)
        print("Challenge sent to \(friend.username): \(challengeType.rawValue)")
    }
    
    // MARK: - Private Helpers
    
    private func generateCoopExercises(for workoutType: CoopWorkoutType) -> [CoopExercise] {
        switch workoutType {
        case .partnerWorkout:
            return [
                CoopExercise(name: "Partner Medicine Ball Toss", sets: 3, reps: 20, restTime: 60),
                CoopExercise(name: "Partner Plank High-Five", sets: 3, reps: 15, restTime: 45),
                CoopExercise(name: "Partner Squats", sets: 4, reps: 25, restTime: 90)
            ]
        case .challengeRace:
            return [
                CoopExercise(name: "Burpee Challenge", sets: 1, reps: 50, restTime: 0),
                CoopExercise(name: "Push-up Race", sets: 1, reps: 100, restTime: 0),
                CoopExercise(name: "Plank Hold Contest", sets: 1, reps: 1, restTime: 0)
            ]
        case .syncWorkout:
            return [
                CoopExercise(name: "Synchronized Squats", sets: 4, reps: 20, restTime: 60),
                CoopExercise(name: "Mirror Push-ups", sets: 3, reps: 15, restTime: 45),
                CoopExercise(name: "Partner Lunges", sets: 3, reps: 12, restTime: 60)
            ]
        }
    }
    
    private func generateLeaderboardData() -> [LeaderboardEntry] {
        return [
            LeaderboardEntry(rank: 1, username: "ShadowKing92", level: 28, totalXP: 15420, isCurrentUser: false),
            LeaderboardEntry(rank: 2, username: "IronBeast", level: 26, totalXP: 14230, isCurrentUser: false),
            LeaderboardEntry(rank: 3, username: "You", level: 24, totalXP: 13180, isCurrentUser: true),
            LeaderboardEntry(rank: 4, username: "FlexMaster", level: 23, totalXP: 12890, isCurrentUser: false),
            LeaderboardEntry(rank: 5, username: "GymShark", level: 22, totalXP: 12100, isCurrentUser: false)
        ]
    }
    
    private func loadSampleData() {
        friends = [
            Friend(id: "friend1", username: "IronBeast", level: 18, isOnline: true, lastWorkout: Date().addingTimeInterval(-3600), sharedWorkouts: 8),
            Friend(id: "friend2", username: "FlexMaster", level: 15, isOnline: false, lastWorkout: Date().addingTimeInterval(-86400), sharedWorkouts: 5),
            Friend(id: "friend3", username: "GymShark", level: 22, isOnline: true, lastWorkout: Date().addingTimeInterval(-1800), sharedWorkouts: 12)
        ]
        
        friendRequests = [
            FriendRequest(id: "req1", fromUserId: "user123", toUserId: "current_user", toUsername: "PowerLifter", status: .pending, dateSent: Date().addingTimeInterval(-3600))
        ]
    }
    
    private func setupPeriodicUpdates() {
        Timer.publish(every: 30, on: .main, in: .common)
            .autoconnect()
            .sink { _ in
                self.updateOnlineStatus()
            }
            .store(in: &cancellables)
    }
    
    private func updateOnlineStatus() {
        for i in friends.indices {
            friends[i].isOnline = Bool.random()
        }
        isOnline = true
    }
}

// MARK: - Data Models

struct Friend: Identifiable, Codable {
    let id: String
    let username: String
    let level: Int
    var isOnline: Bool
    let lastWorkout: Date
    let sharedWorkouts: Int
}

struct FriendRequest: Identifiable, Codable {
    let id: String
    let fromUserId: String
    let toUserId: String
    let toUsername: String
    var status: FriendRequestStatus
    let dateSent: Date
}

enum FriendRequestStatus: String, Codable, CaseIterable {
    case pending = "pending"
    case accepted = "accepted"
    case rejected = "rejected"
}

struct CoopSession: Identifiable, Codable {
    let id: String
    let hostId: String
    let partnerId: String
    let partnerName: String
    let workoutType: CoopWorkoutType
    var status: CoopSessionStatus
    let createdAt: Date
    var startedAt: Date?
    var completedAt: Date?
    let exercises: [CoopExercise]
}

enum CoopWorkoutType: String, Codable, CaseIterable {
    case partnerWorkout = "Partner Workout"
    case challengeRace = "Challenge Race"
    case syncWorkout = "Sync Workout"
}

enum CoopSessionStatus: String, Codable, CaseIterable {
    case waiting = "waiting"
    case active = "active"
    case completed = "completed"
    case cancelled = "cancelled"
}

struct CoopExercise: Identifiable, Codable {
    let id = UUID()
    let name: String
    let sets: Int
    let reps: Int
    let restTime: Int // seconds
}

struct LeaderboardEntry: Identifiable, Codable {
    let id = UUID()
    let rank: Int
    let username: String
    let level: Int
    let totalXP: Int
    let isCurrentUser: Bool
}

struct Challenge: Identifiable, Codable {
    let id: String
    let fromUserId: String
    let toUserId: String
    let toUsername: String
    let type: ChallengeType
    var status: ChallengeStatus
    let createdAt: Date
    let expiresAt: Date
}

enum ChallengeType: String, Codable, CaseIterable {
    case weeklyWorkouts = "Weekly Workout Count"
    case totalWeight = "Total Weight Lifted"
    case cardioMinutes = "Cardio Minutes"
    case pushupChallenge = "Push-up Challenge"
}

enum ChallengeStatus: String, Codable, CaseIterable {
    case pending = "pending"
    case accepted = "accepted"
    case completed = "completed"
    case expired = "expired"
}
