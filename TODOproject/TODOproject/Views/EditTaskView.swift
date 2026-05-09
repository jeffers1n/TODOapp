import SwiftUI

struct EditTaskView: View {
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var taskVM: TaskViewModel
    
    @State var task: TodoTask
    @State private var newSubtaskTitle = ""
    @State private var dailyStepGoalText: String

    private var parsedStepGoal: Int? {
        guard !dailyStepGoalText.isEmpty else { return nil }
        guard let value = Int(dailyStepGoalText), value > 0 else { return nil }
        return value
    }

    init(task: TodoTask) {
        _task = State(initialValue: task)
        _dailyStepGoalText = State(initialValue: task.dailyStepGoal.map(String.init) ?? "")
    }
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Детали задачи")) {
                    TextField("Название", text: $task.title)
                    TextField("Описание", text: $task.description)
                    DatePicker("Срок выполнения", selection: $task.dueDate, displayedComponents: [.date])
                    Picker("Категория", selection: $task.category) {
                        ForEach(TaskCategory.allCases) { category in
                            Text(category.rawValue).tag(category)
                        }
                    }
                }
                
                Section(header: Text("Подзадачи")) {
                    ForEach($task.subtasks) { $subtask in
                        VStack(alignment: .leading) {
                            HStack {
                                Button(action: { subtask.isCompleted.toggle() }) {
                                    Image(systemName: subtask.isCompleted ? "checkmark.circle.fill" : "circle")
                                }
                                .buttonStyle(BorderlessButtonStyle())
                                TextField("Подзадача", text: $subtask.title)
                            }
                            DatePicker("Срок:", selection: $subtask.dueDate, in: ...task.dueDate, displayedComponents: [.date])
                                .font(.caption)
                        }
                    }
                    .onDelete { offsets in
                        task.subtasks.remove(atOffsets: offsets)
                    }
                    
                    HStack {
                        TextField("Новая подзадача", text: $newSubtaskTitle)
                        Button(action: {
                            let subtask = Subtask(title: newSubtaskTitle, dueDate: task.dueDate)
                            task.subtasks.append(subtask)
                            newSubtaskTitle = ""
                        }) {
                            Image(systemName: "plus.circle.fill")
                        }
                        .disabled(newSubtaskTitle.isEmpty)
                    }
                }

                if task.category == .sport || task.category == .health {
                    Section(header: Text("Цель по шагам")) {
                        TextField("Шагов в день", text: $dailyStepGoalText)
                            .keyboardType(.numberPad)
                        if !dailyStepGoalText.isEmpty && parsedStepGoal == nil {
                            Text("Введите корректное положительное число шагов.")
                                .font(.caption)
                                .foregroundColor(.red)
                        }
                    }
                }
            }
            .onChange(of: task.dueDate) { newDueDate in
                task.subtasks = task.subtasks.map { subtask in
                    var updated = subtask
                    updated.dueDate = min(updated.dueDate, newDueDate)
                    return updated
                }
            }
            .navigationTitle("Редактировать задачу")
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Отмена") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Сохранить") {
                        if task.category == .sport || task.category == .health {
                            task.dailyStepGoal = parsedStepGoal
                        } else {
                            task.dailyStepGoal = nil
                        }
                        task.subtasks = task.subtasks.map { subtask in
                            var updated = subtask
                            updated.dueDate = min(updated.dueDate, task.dueDate)
                            return updated
                        }
                        taskVM.updateTask(task)
                        dismiss()
                    }
                    .disabled(task.title.isEmpty || ((task.category == .sport || task.category == .health) && parsedStepGoal == nil))
                }
            }
        }
    }
} 