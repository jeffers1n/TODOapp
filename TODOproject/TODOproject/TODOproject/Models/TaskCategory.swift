import Foundation
import SwiftUI

enum TaskCategory: String, CaseIterable, Codable, Identifiable {
    case general = "Общее"
    case work = "Работа"
    case study = "Учеба"
    case programming = "Программирование"
    case sport = "Спорт"
    case health = "Здоровье"
    case home = "Дом"
    case hobby = "Хобби"
    case music = "Музыка"
    case personalGrowth = "Личностный рост"
    case finance = "Финансы"
    case social = "Социальное"

    var id: String { self.rawValue }

    var icon: String {
        switch self {
        case .general: return "list.bullet"
        case .work: return "briefcase.fill"
        case .study: return "book.fill"
        case .programming: return "desktopcomputer"
        case .sport: return "figure.run"
        case .health: return "heart.fill"
        case .home: return "house.fill"
        case .hobby: return "gamecontroller.fill"
        case .music: return "guitars.fill"
        case .personalGrowth: return "arrow.up.right.circle.fill"
        case .finance: return "dollarsign.circle.fill"
        case .social: return "person.2.fill"
        }
    }
} 