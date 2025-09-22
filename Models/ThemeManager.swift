import SwiftUI
import Combine

class ThemeManager: ObservableObject {
    @Published var currentTheme: AppTheme
    
    init(tier: CharacterTier = .beginner) {
        self.currentTheme = AppTheme.from(tier: tier)
    }
    
    func updateTheme(for tier: CharacterTier) {
        withAnimation(.easeInOut(duration: 1.0)) {
            currentTheme = AppTheme.from(tier: tier)
        }
    }
}

// MARK: - App Theme
struct AppTheme {
    let primary: Color
    let secondary: Color
    let accent: Color
    let background: Color
    let cardBackground: Color
    let textPrimary: Color
    let textSecondary: Color
    let tierName: String
    
    static func from(tier: CharacterTier) -> AppTheme {
