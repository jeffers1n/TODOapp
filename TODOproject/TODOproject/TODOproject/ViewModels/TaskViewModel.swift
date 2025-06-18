import SwiftUI

class TaskViewModel: ObservableObject {
    @Published var tasks: [TodoTask] = []
    @Published var filteredTasks: [TodoTask] = []
    @Published var selectedFilter: TaskFilter = .all
    @Published var selectedCategoryFilter: TaskCategory?
    @Published var showingStickerSelection = false
    @Published var taskToComplete: TodoTask?
    
    private let tasksKey = "savedTasks"
    
    enum TaskFilter {
        case all, pending, completed
    }
    
    init() {
        loadTasks()
    }
    
    func addTask(_ task: TodoTask) {
        tasks.append(task)
        applyFilter()
        saveTasks()
    }
    
    func completeTask(_ task: TodoTask) {
        taskToComplete = task
        showingStickerSelection = true
    }
    
    func confirmTaskCompletion() {
        guard let task = taskToComplete else { return }
        
        if let index = tasks.firstIndex(where: { $0.id == task.id }) {
            tasks[index].isCompleted.toggle()
            applyFilter()
            saveTasks()
            if tasks[index].isCompleted {
                NotificationCenter.default.post(name: .taskCompleted, object: tasks[index])
            }
        }
        
        taskToComplete = nil
        showingStickerSelection = false
    }
    
    func updateTask(_ task: TodoTask) {
        if let index = tasks.firstIndex(where: { $0.id == task.id }) {
            tasks[index] = task
            applyFilter()
            saveTasks()
        }
    }
    
    func deleteTask(_ task: TodoTask) {
        tasks.removeAll { $0.id == task.id }
        applyFilter()
        saveTasks()
    }
    
    func applyFilter() {
        var tempTasks = tasks

        switch selectedFilter {
        case .all:
            break
        case .pending:
            tempTasks = tempTasks.filter { !$0.isCompleted }
        case .completed:
            tempTasks = tempTasks.filter { $0.isCompleted }
        }
        
        if let category = selectedCategoryFilter {
            tempTasks = tempTasks.filter { $0.category == category }
        }

        filteredTasks = tempTasks
        filteredTasks.sort(by: { !$0.isCompleted && $1.isCompleted })
    }
    
    private func saveTasks() {
        if let encoded = try? JSONEncoder().encode(tasks) {
            UserDefaults.standard.set(encoded, forKey: tasksKey)
        }
    }
    
    private func loadTasks() {
        if let data = UserDefaults.standard.data(forKey: tasksKey),
           let decoded = try? JSONDecoder().decode([TodoTask].self, from: data) {
            tasks = decoded
        } else {
            tasks.append(TodoTask(title: "Моя первая задача", description: "Задача для начала!", dueDate: Date(), category: .general))
        }
        applyFilter()
    }
}

extension Notification.Name {
    static let taskCompleted = Notification.Name("taskCompleted")
} 
