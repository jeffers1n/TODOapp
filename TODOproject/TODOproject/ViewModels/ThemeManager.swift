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

@MainActor
final class ThemeManager: ObservableObject {
    @Published var selectedTheme: Theme {
        didSet {
            UserDefaults.standard.set(selectedTheme.rawValue, forKey: Self.storageKey)
        }
    }

    private static let storageKey = "theme"

    init() {
        let savedValue = UserDefaults.standard.string(forKey: Self.storageKey)
        selectedTheme = Theme(rawValue: savedValue ?? "") ?? .system
    }

    var colorScheme: ColorScheme? {
        switch selectedTheme {
        case .system:
            return nil
        case .light:
            return .light
        case .dark:
            return .dark
        }
    }
} 