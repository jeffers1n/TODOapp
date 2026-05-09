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
    @Published private(set) var stepProgressByTaskID: [UUID: StepGoalProgress] = [:]
    
    private let modelContext: ModelContext
    private let notificationManager: NotificationManager
    private let systemIntegrationManager: SystemIntegrationManager
    
    enum TaskFilter {
        case all, pending, completed
    }

    struct StepGoalProgress {
        let goal: Int
        let todaySteps: Int
        let achievedDays: Int
        let requiredDays: Int

        var isTodayCompleted: Bool { todaySteps >= goal }
    }
    
    init(
        modelContext: ModelContext,
        notificationManager: NotificationManager = .shared,
        systemIntegrationManager: SystemIntegrationManager = .shared
    ) {
        self.modelContext = modelContext
        self.notificationManager = notificationManager
        self.systemIntegrationManager = systemIntegrationManager
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
        Task { await refreshStepGoals() }
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
            Task { await refreshStepGoals() }
        }
    }
    
    func deleteTask(_ task: TodoTask) {
        tasks.removeAll { $0.id == task.id }
        applyFilter()
        saveTasks()
        notificationManager.cancelTaskReminder(taskID: task.id)
        Task { await refreshStepGoals() }
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
                    dailyStepGoal: task.dailyStepGoal,
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
                        dailyStepGoal: entity.dailyStepGoal,
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
        Task { await refreshStepGoals() }
    }

    func stepProgress(for task: TodoTask) -> StepGoalProgress? {
        stepProgressByTaskID[task.id]
    }

    private func shouldTrackSteps(for task: TodoTask) -> Bool {
        guard let goal = task.dailyStepGoal, goal > 0 else { return false }
        return task.category == .sport || task.category == .health
    }

    func refreshStepGoals() async {
        let trackedTasks = tasks.filter { shouldTrackSteps(for: $0) && !$0.isCompleted }
        guard !trackedTasks.isEmpty else {
            stepProgressByTaskID = [:]
            return
        }

        let now = Date()
        let calendar = Calendar.current
        let minStart = trackedTasks.map { calendar.startOfDay(for: $0.createdAt) }.min() ?? now
        let maxEnd = trackedTasks.map { min(calendar.startOfDay(for: $0.dueDate), calendar.startOfDay(for: now)) }.max() ?? now

        guard let stepsByDay = await systemIntegrationManager.fetchDailyStepCounts(
            from: minStart,
            to: maxEnd,
            requestAccessIfNeeded: false
        ) else {
            return
        }

        var updated: [UUID: StepGoalProgress] = [:]
        let today = calendar.startOfDay(for: now)

        for task in trackedTasks {
            guard let goal = task.dailyStepGoal, goal > 0 else { continue }
            let start = calendar.startOfDay(for: task.createdAt)
            let end = min(calendar.startOfDay(for: task.dueDate), today)
            guard start <= end else { continue }

            var current = start
            var requiredDays = 0
            var achievedDays = 0

            while current <= end {
                requiredDays += 1
                let daySteps = stepsByDay[current] ?? 0
                if daySteps >= goal {
                    achievedDays += 1
                }
                guard let next = calendar.date(byAdding: .day, value: 1, to: current) else { break }
                current = next
            }

            updated[task.id] = StepGoalProgress(
                goal: goal,
                todaySteps: stepsByDay[today] ?? 0,
                achievedDays: achievedDays,
                requiredDays: requiredDays
            )
        }

        stepProgressByTaskID = updated
    }
}

extension Notification.Name {
    static let taskCompleted = Notification.Name("taskCompleted")
} 
