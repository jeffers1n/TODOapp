import SwiftUI

struct AddTaskView: View {
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var taskVM: TaskViewModel
    
    @State private var title = ""
    @State private var description = ""
    @State private var dueDate = Date()
    @State private var category: TaskCategory = .general
    @State private var subtasks: [Subtask] = []
    @State private var newSubtaskTitle = ""
    @State private var newSubtaskDueDate = Date()
    @State private var dailyStepGoalText = ""
    @State private var shouldAddToCalendar = true
    @State private var shouldOpenClockAfterCreation = false

    private var parsedStepGoal: Int? {
        guard !dailyStepGoalText.isEmpty else { return nil }
        guard let value = Int(dailyStepGoalText), value > 0 else { return nil }
        return value
    }

    private var requiresStepGoal: Bool {
        category == .sport || category == .health
    }
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Детали задачи")) {
                    TextField("Название", text: $title)
                    TextField("Описание", text: $description)
                    DatePicker("Срок выполнения", selection: $dueDate, displayedComponents: [.date])
                    Picker("Категория", selection: $category) {
                        ForEach(TaskCategory.allCases) { category in
                            Text(category.rawValue).tag(category)
                        }
                    }
                }
                
                Section(header: Text("Подзадачи")) {
                    ForEach(subtasks) { subtask in
                        VStack(alignment: .leading) {
                            Text(subtask.title)
                            Text("Срок: \(subtask.dueDate.formatted(date: .abbreviated, time: .omitted))")
                                .font(.caption)
                                .foregroundColor(.gray)
                        }
                    }
                    .onDelete { offsets in
                        subtasks.remove(atOffsets: offsets)
                    }
                    
                    VStack(alignment: .leading, spacing: 10) {
                        TextField("Название новой подзадачи", text: $newSubtaskTitle)
                        DatePicker("Срок выполнения:", selection: $newSubtaskDueDate, in: ...dueDate, displayedComponents: .date)
                        
                        Button(action: {
                            let subtaskDate = min(newSubtaskDueDate, dueDate)
                            let subtask = Subtask(title: newSubtaskTitle, dueDate: subtaskDate)
                            subtasks.append(subtask)
                            newSubtaskTitle = ""
                            newSubtaskDueDate = dueDate
                        }) {
                            Label("Добавить подзадачу", systemImage: "plus.circle.fill")
                        }
                        .disabled(newSubtaskTitle.isEmpty)
                    }
                }

                if category == .sport || category == .health {
                    Section(header: Text("Цель по шагам")) {
                        TextField("Шагов в день (например, 10000)", text: $dailyStepGoalText)
                            .keyboardType(.numberPad)
                        if !dailyStepGoalText.isEmpty && parsedStepGoal == nil {
                            Text("Введите корректное положительное число шагов.")
                                .font(.caption)
                                .foregroundColor(.red)
                        }
                        Text("Для задач Спорт/Здоровье прогресс будет считаться по данным Apple Health за каждый день до дедлайна.")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }

                Section(header: Text("Системные приложения")) {
                    Toggle("Добавить в Календарь", isOn: $shouldAddToCalendar)
                    Toggle("Открыть Будильник после добавления", isOn: $shouldOpenClockAfterCreation)
                }
            }
            .onChange(of: dueDate) { newDueDate in
                subtasks = subtasks.map { subtask in
                    var updated = subtask
                    updated.dueDate = min(updated.dueDate, newDueDate)
                    return updated
                }
                newSubtaskDueDate = min(newSubtaskDueDate, newDueDate)
            }
            .navigationTitle("Новая задача")
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Отмена") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Добавить") {
                        Task {
                            await addTask()
                        }
                    }
                    .disabled(title.isEmpty || (requiresStepGoal && parsedStepGoal == nil))
                }
            }
        }
    }
    
    private func addTask() async {
        let sanitizedSubtasks = subtasks.map { subtask in
            var updated = subtask
            updated.dueDate = min(updated.dueDate, dueDate)
            return updated
        }

        let task = TodoTask(
            title: title,
            description: description,
            dueDate: dueDate,
            category: category,
            dailyStepGoal: requiresStepGoal ? parsedStepGoal : nil,
            subtasks: sanitizedSubtasks
        )
        
        taskVM.addTask(task)

        if shouldAddToCalendar {
            _ = await SystemIntegrationManager.shared.addTaskToCalendar(task)
        }

        if shouldOpenClockAfterCreation {
            await MainActor.run {
                SystemIntegrationManager.shared.openClockApp()
            }
        }

        dismiss()
    }
}
