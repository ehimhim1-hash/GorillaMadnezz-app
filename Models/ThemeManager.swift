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
        switch tier {
        case .beginner:
            return AppTheme(
                primary: .blue,
                secondary: .cyan,
                accent: .blue.opacity(0.8),
                background: Color.black,
                cardBackground: Color.gray.opacity(0.1),
                textPrimary: .white,
                textSecondary: .gray,
                tierName: "Novice"
            )
            
        case .intermediate:
            return AppTheme(
                primary: .green,
                secondary: .mint,
                accent: .green.opacity(0.8),
                background: Color.black,
                cardBackground: Color.gray.opacity(0.1),
                textPrimary: .white,
                textSecondary: .gray,
                tierName: "Warrior"
            )
            
        case .advanced:
            return AppTheme(
                primary: .orange,
                secondary: .yellow,
                accent: .orange.opacity(0.8),
                background: Color.black,
                cardBackground: Color.gray.opacity(0.1),
                textPrimary: .white,
                textSecondary: .gray,
                tierName: "Champion"
            )
            
        case .elite:
            return AppTheme(
                primary: .red,
                secondary: .pink,
                accent: .red.opacity(0.8),
                background: Color.black,
                cardBackground: Color.gray.opacity(0.1),
                textPrimary: .white,
                textSecondary: .gray,
                tierName: "Elite Beast"
            )
            
        case .legendary:
            return AppTheme(
                primary: .purple,
                secondary: .indigo,
                accent: .purple.opacity(0.8),
                background: Color.black,
                cardBackground: Color.gray.opacity(0.05),
                textPrimary: .white,
                textSecondary: .gray,
                tierName: "Shadow Monarch"
            )
        }
    }
    
    // Gradient backgrounds for different tiers
    var backgroundGradient: LinearGradient {
        LinearGradient(
            colors: [background, primary.opacity(0.1), background],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }
    
    var primaryGradient: LinearGradient {
        LinearGradient(
            colors: [primary, secondary],
            startPoint: .leading,
            endPoint: .trailing
        )
    }
    
    var shadowColor: Color {
        primary.opacity(0.3)
    }
}

// MARK: - Theme Environment Key
struct ThemeEnvironmentKey: EnvironmentKey {
    static let defaultValue = AppTheme.from(tier: .beginner)
}

extension EnvironmentValues {
    var appTheme: AppTheme {
        get { self[ThemeEnvironmentKey.self] }
        set { self[ThemeEnvironmentKey.self] = newValue }
    }
}

// MARK: - Theme-Aware View Modifier
struct ThemedBackground: ViewModifier {
    @Environment(\.appTheme) var theme
    
    func body(content: Content) -> some View {
        content
            .background(theme.backgroundGradient)
            .preferredColorScheme(.dark)
    }
}

struct ThemedCard: ViewModifier {
    @Environment(\.appTheme) var theme
    let cornerRadius: CGFloat
    
    init(cornerRadius: CGFloat = 15) {
        self.cornerRadius = cornerRadius
    }
    
    func body(content: Content) -> some View {
        content
            .background(
                RoundedRectangle(cornerRadius: cornerRadius)
                    .fill(theme.cardBackground)
                    .shadow(color: theme.shadowColor, radius: 8)
            )
    }
}

struct ThemedButton: ViewModifier {
    @Environment(\.appTheme) var theme
    let isPrimary: Bool
    
    init(isPrimary: Bool = true) {
        self.isPrimary = isPrimary
    }
    
    func body(content: Content) -> some View {
        content
            .foregroundColor(isPrimary ? .black : theme.textPrimary)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(isPrimary ? theme.primaryGradient : theme.cardBackground)
                    .shadow(color: theme.shadowColor, radius: isPrimary ? 10 : 3)
            )
    }
}

// MARK: - View Extensions
extension View {
    func themedBackground() -> some View {
        modifier(ThemedBackground())
    }
    
    func themedCard(cornerRadius: CGFloat = 15) -> some View {
        modifier(ThemedCard(cornerRadius: cornerRadius))
    }
    
    func themedButton(isPrimary: Bool = true) -> some View {
        modifier(ThemedButton(isPrimary: isPrimary))
    }
}
