import Foundation

struct Challenge: Identifiable, Codable {
    var id = UUID()
    let title: String
    let description: String
    let category: TaskCategory
    let targetCount: Int
    var progress: Int
    let startDate: Date
    let endDate: Date
    
    var isCompleted: Bool {
        progress >= targetCount
    }
    
    var isExpired: Bool {
        Date() > endDate
    }
} 