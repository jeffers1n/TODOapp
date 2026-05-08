import SwiftUI
import SwiftData

@MainActor
class TaskViewModel: ObservableObject {
    @Published var tasks: [TodoTask] = []
    @Published var filteredTasks: [TodoTask] = []
    @Published var selectedFilter: TaskFilter = .all
    @Published var selectedCategoryFilter: TaskCategory?
    @Published var showingStickerSelection = false
    @Published var taskToComplete: TodoTask?
    
    private let modelContext: ModelContext
    private let notificationManager: NotificationManager
    
    enum TaskFilter {
        case all, pending, completed
    }
    
    init(modelContext: ModelContext, notificationManager: NotificationManager = .shared) {
        self.modelContext = modelContext
        self.notificationManager = notificationManager
        loadTasks()
    }
    
    convenience init() {
        let schema = Schema([TaskEntity.self])
        let configuration = ModelConfiguration(isStoredInMemoryOnly: true)
        let container = try! ModelContainer(for: schema, configurations: configuration)
        self.init(modelContext: container.mainContext)
    }
    
    func addTask(_ task: TodoTask) {
        tasks.append(task)
        applyFilter()
        saveTasks()
        notificationManager.scheduleTaskReminder(for: task)
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
                notificationManager.cancelTaskReminder(taskID: tasks[index].id)
                NotificationCenter.default.post(name: .taskCompleted, object: tasks[index])
            } else {
                notificationManager.scheduleTaskReminder(for: tasks[index])
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
            if task.isCompleted {
                notificationManager.cancelTaskReminder(taskID: task.id)
            } else {
                notificationManager.scheduleTaskReminder(for: task)
            }
        }
    }
    
    func deleteTask(_ task: TodoTask) {
        tasks.removeAll { $0.id == task.id }
        applyFilter()
        saveTasks()
        notificationManager.cancelTaskReminder(taskID: task.id)
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
        do {
            let existing = try modelContext.fetch(FetchDescriptor<TaskEntity>())
            existing.forEach { modelContext.delete($0) }
            
            for task in tasks {
                let entity = TaskEntity(
                    id: task.id,
                    title: task.title,
                    taskDescription: task.description,
                    dueDate: task.dueDate,
                    categoryRawValue: task.category.rawValue,
                    isCompleted: task.isCompleted,
                    createdAt: task.createdAt
                )
                modelContext.insert(entity)
            }
            
            try modelContext.save()
        } catch {
            print("Failed to save tasks to SwiftData: \\(error)")
        }
    }
    
    private func loadTasks() {
        do {
            let descriptor = FetchDescriptor<TaskEntity>(sortBy: [SortDescriptor(\TaskEntity.createdAt)])
            let stored = try modelContext.fetch(descriptor)
            
            if stored.isEmpty {
                tasks = [TodoTask(title: "Моя первая задача", description: "Задача для начала!", dueDate: Date(), category: .general)]
            } else {
                tasks = stored.compactMap { entity in
                    guard let category = TaskCategory(rawValue: entity.categoryRawValue) else { return nil }
                    return TodoTask(
                        id: entity.id,
                        title: entity.title,
                        description: entity.taskDescription,
                        dueDate: entity.dueDate,
                        category: category,
                        isCompleted: entity.isCompleted,
                        subtasks: [],
                        createdAt: entity.createdAt
                    )
                }
            }
        } catch {
            print("Failed to load tasks from SwiftData: \\(error)")
            tasks = [TodoTask(title: "Моя первая задача", description: "Задача для начала!", dueDate: Date(), category: .general)]
        }

        for task in tasks {
            if task.isCompleted {
                notificationManager.cancelTaskReminder(taskID: task.id)
            } else {
                notificationManager.scheduleTaskReminder(for: task)
            }
        }

        applyFilter()
    }
}

extension Notification.Name {
    static let taskCompleted = Notification.Name("taskCompleted")
} 
