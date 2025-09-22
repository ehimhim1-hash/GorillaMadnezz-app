import SwiftUI
import Combine

class EquipmentManager: ObservableObject {
    @Published var availableEquipment: [Equipment] = []
    @Published var customEquipment: [Equipment] = []
    
    init() {
        loadDefaultEquipment()
    }
    
    private func loadDefaultEquipment() {
        availableEquipment = [
            // Free Weights
            Equipment(name: "Barbell", category: .freeWeights, icon: "minus.rectangle.fill", isAvailable: false),
            Equipment(name: "Dumbbells", category: .freeWeights, icon: "dumbbell.fill", isAvailable: false),
            Equipment(name: "Kettlebells", category: .freeWeights, icon: "circle.fill", isAvailable: false),
            Equipment(name: "Weight Plates", category: .freeWeights, icon: "circle.dashed", isAvailable: false),
            
            // Machines
            Equipment(name: "Leg Press", category: .machines, icon: "rectangle.fill", isAvailable: false),
            Equipment(name: "Lat Pulldown", category: .machines, icon: "arrow.down.square.fill", isAvailable: false),
            Equipment(name: "Chest Press", category: .machines, icon: "arrow.forward.square.fill", isAvailable: false),
            Equipment(name: "Cable Machine", category: .machines, icon: "cable.connector", isAvailable: false),
            Equipment(name: "Smith Machine", category: .machines, icon: "rectangle.grid.1x2.fill", isAvailable: false),
            
            // Cardio
            Equipment(name: "Treadmill", category: .cardio, icon: "figure.run", isAvailable: false),
            Equipment(name: "Stationary Bike", category: .cardio, icon: "bicycle", isAvailable: false),
            Equipment(name: "Elliptical", category: .cardio, icon: "figure.elliptical", isAvailable: false),
            Equipment(name: "Rowing Machine", category: .cardio, icon: "figure.rower", isAvailable: false),
            
            // Functional
            Equipment(name: "Pull-up Bar", category: .functional, icon: "figure.strengthtraining.functional", isAvailable: false),
            Equipment(name: "Resistance Bands", category: .functional, icon: "oval.fill", isAvailable: false),
            Equipment(name: "Medicine Ball", category: .functional, icon: "soccerball", isAvailable: false),
            Equipment(name: "Battle Ropes", category: .functional, icon: "waveform", isAvailable: false),
            Equipment(name: "TRX Suspension", category: .functional, icon: "triangle.fill", isAvailable: false),
            
            // Bodyweight
            Equipment(name: "Floor Space", category: .bodyweight, icon: "square.fill", isAvailable: true),
            Equipment(name: "Bench", category: .bodyweight, icon: "rectangle.fill", isAvailable: false),
            Equipment(name: "Box/Platform", category: .bodyweight, icon: "cube.fill", isAvailable: false)
        ]
    }
    
    func toggleEquipment(_ equipment: Equipment) {
        if let index = availableEquipment.firstIndex(where: { $0.id == equipment.id }) {
            availableEquipment[index].isAvailable.toggle()
        } else if let index = customEquipment.firstIndex(where: { $0.id == equipment.id }) {
            customEquipment[index].isAvailable.toggle()
        }
    }
    
    func addCustomEquipment(_ equipment: Equipment) {
        customEquipment.append(equipment)
    }
    
    func getEquipment(for category: EquipmentCategory, searchText: String = "") -> [Equipment] {
        let allEquipment = availableEquipment + customEquipment
        let categoryEquipment = allEquipment.filter { $0.category == category }
        
        if searchText.isEmpty {
            return categoryEquipment
        } else {
            return categoryEquipment.filter { $0.name.localizedCaseInsensitiveContains(searchText) }
        }
    }
    
    func getAvailableEquipment() -> [Equipment] {
        return (availableEquipment + customEquipment).filter { $0.isAvailable }
    }
}

// MARK: - Equipment Model
struct Equipment: Identifiable, Hashable {
    let id = UUID()
    let name: String
    let category: EquipmentCategory
    let icon: String
    var isAvailable: Bool
    let isCustom: Bool
    
    init(name: String, category: EquipmentCategory, icon: String, isAvailable: Bool, isCustom: Bool = false) {
        self.name = name
        self.category = category
        self.icon = icon
        self.isAvailable = isAvailable
        self.isCustom = isCustom
    }
}

// MARK: - Equipment Categories
enum EquipmentCategory: String, CaseIterable {
    case freeWeights = "free_weights"
    case machines = "machines"
    case cardio = "cardio"
    case functional = "functional"
    case bodyweight = "bodyweight"
    
    var displayName: String {
        switch self {
        case .freeWeights: return "Free Weights"
        case .machines: return "Machines"
        case .cardio: return "Cardio"
        case .functional: return "Functional"
        case .bodyweight: return "Bodyweight"
        }
    }
    
    var icon: String {
        switch self {
        case .freeWeights: return "dumbbell.fill"
        case .machines: return "gearshape.fill"
        case .cardio: return "heart.fill"
        case .functional: return "figure.strengthtraining.functional"
        case .bodyweight: return "figure.arms.open"
        }
    }
    
    var color: Color {
        switch self {
        case .freeWeights: return .red
        case .machines: return .blue
        case .cardio: return .green
        case .functional: return .orange
        case .bodyweight: return .purple
        }
    }
}
