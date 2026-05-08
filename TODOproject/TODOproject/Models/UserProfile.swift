import Foundation

struct UserProfile: Codable {
    var id: UUID = UUID()
    var name: String
    var totalTasksCompleted: Int = 0
    var currentStreak: Int = 0
    var bestStreak: Int = 0
    var mood: Mood = .neutral
    var lastCompletedDate: Date?
    var achievements: [Achievement] = []
    
    enum Mood: String, Codable {
        case happy, neutral, busy, accomplished
        
        var emoji: String {
            switch self {
            case .happy: return "😊"
            case .neutral: return "😐"
            case .busy: return "😅"
            case .accomplished: return "🌟"
            }
        }
    }
}
