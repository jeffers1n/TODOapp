import SwiftUI

enum Theme: String, CaseIterable, Identifiable {
    case system
    case light
    case dark

    var id: String { self.rawValue }

    var displayName: String {
        switch self {
        case .system:
            return "Как в системе"
        case .light:
            return "Светлая"
        case .dark:
            return "Тёмная"
        }
    }
}

class ThemeManager: ObservableObject {
    @AppStorage("theme") var selectedTheme: Theme = .system
} 