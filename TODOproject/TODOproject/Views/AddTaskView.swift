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
                        addTask()
                    }
                    .disabled(title.isEmpty)
                }
            }
        }
    }
    
    private func addTask() {
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
            subtasks: sanitizedSubtasks
        )
        
        taskVM.addTask(task)
        dismiss()
    }
}
