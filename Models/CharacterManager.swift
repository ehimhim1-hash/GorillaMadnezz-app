import SwiftUI
import Combine

class CharacterManager: ObservableObject {
    @Published var character: Character
    @Published var currentTier: CharacterTier
    
    let tierUpgradePublisher = PassthroughSubject<CharacterTier, Never>()
    
    init() {
        self.character = Character(
            level: 1,
            experience: 0,
            strength: 10,
            endurance: 10,
            totalWeightLifted: 0
        )
        self.currentTier = .beginner
    }
    
    func addExperience(_ amount: Int) {
        character.experience += amount
        checkLevelUp()
    }
    
    func addStrength(_ amount: Int) {
        character.strength += amount
        character.experience += amount * 10 // Bonus XP for strength gains
        checkLevelUp()
    }
    
    func addEndurance(_ amount: Int) {
        character.endurance += amount
        character.experience += amount * 8 // Bonus XP for endurance gains
        checkLevelUp()
    }
    
    func recordWorkout(totalWeight: Double, exercises: Int) {
        character.totalWeightLifted += totalWeight
        
        // XP calculation based on workout intensity
        let baseXP = exercises * 50
        let weightBonus = Int(totalWeight / 10)
        let totalXP = baseXP + weightBonus
        
        addExperience(totalXP)
    }
    
    private func checkLevelUp() {
        let newLevel = calculateLevel(from: character.experience)
        
        if newLevel > character.level {
            character.level = newLevel
            checkTierUpgrade()
        }
    }
    
    private func checkTierUpgrade() {
        let newTier = CharacterTier.from(level: character.level)
        
        if newTier != currentTier {
            currentTier = newTier
            tierUpgradePublisher.send(newTier)
        }
    }
    
    private func calculateLevel(from experience: Int) -> Int {
        // Exponential leveling formula
        return Int(sqrt(Double(experience) / 100)) + 1
    }
    
    func getCharacterImageName() -> String {
        return currentTier.imageName
    }
    
    func getCharacterDescription() -> String {
        return currentTier.description
    }
}

// MARK: - Character Model
struct Character {
    var level: Int
    var experience: Int
    var strength: Int
    var endurance: Int
    var totalWeightLifted: Double
    
    var experienceToNextLevel: Int {
        let nextLevel = level + 1
        let requiredXP = (nextLevel * nextLevel - nextLevel) * 100
        return max(0, requiredXP - experience)
    }
}

// MARK: - Character Tiers
enum CharacterTier: CaseIterable {
    case beginner      // Level 1-25
    case intermediate  // Level 26-50
    case advanced      // Level 51-75
    case elite         // Level 76-100
    case legendary     // Level 101+
    
    static func from(level: Int) -> CharacterTier {
        switch level {
        case 1...25: return .beginner
        case 26...50: return .intermediate
        case 51...75: return .advanced
        case 76...100: return .elite
        default: return .legendary
        }
    }
    
    var imageName: String {
        switch self {
        case .beginner: return "character_tier_1"
        case .intermediate: return "character_tier_2"
        case .advanced: return "character_tier_3"
        case .elite: return "character_tier_4"
        case .legendary: return "character_tier_5"
        }
    }
    
    var description: String {
        switch self {
        case .beginner: return "Novice Trainee"
        case .intermediate: return "Dedicated Lifter"
        case .advanced: return "Strength Warrior"
        case .elite: return "Iron Champion"
        case .legendary: return "Shadow Monarch"
        }
    }
    
    var color: Color {
        switch self {
        case .beginner: return .gray
        case .intermediate: return .blue
        case .advanced: return .purple
        case .elite: return .orange
        case .legendary: return .red
        }
    }
}
