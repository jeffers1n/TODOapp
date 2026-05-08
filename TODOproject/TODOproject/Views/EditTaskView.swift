import SwiftUI

struct EditTaskView: View {
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var taskVM: TaskViewModel
    
    @State var task: TodoTask
    @State private var newSubtaskTitle = ""
    
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
                        task.subtasks = task.subtasks.map { subtask in
                            var updated = subtask
                            updated.dueDate = min(updated.dueDate, task.dueDate)
                            return updated
                        }
                        taskVM.updateTask(task)
                        dismiss()
                    }
                    .disabled(task.title.isEmpty)
                }
            }
        }
    }
} 