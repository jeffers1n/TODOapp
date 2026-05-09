import Foundation

struct Subtask: Identifiable, Codable, Hashable {
    var id: UUID = UUID()
    var title: String
    var isCompleted: Bool = false
    var dueDate: Date = Date()
}

struct TodoTask: Identifiable, Codable {
    var id: UUID = UUID()
    var title: String
    var description: String
    var dueDate: Date
    var category: TaskCategory = .general
    var dailyStepGoal: Int? = nil
    var isCompleted: Bool = false
    var subtasks: [Subtask] = []
    var createdAt: Date = Date()
    
    var formattedDueDate: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return formatter.string(from: dueDate)
    }
} 