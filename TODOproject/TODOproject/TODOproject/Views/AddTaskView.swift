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
                        DatePicker("Срок выполнения:", selection: $newSubtaskDueDate, displayedComponents: .date)
                        
                        Button(action: {
                            let subtask = Subtask(title: newSubtaskTitle, dueDate: newSubtaskDueDate)
                            subtasks.append(subtask)
                            newSubtaskTitle = ""
                            newSubtaskDueDate = Date()
                        }) {
                            Label("Добавить подзадачу", systemImage: "plus.circle.fill")
                        }
                        .disabled(newSubtaskTitle.isEmpty)
                    }
                }
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
        let task = TodoTask(
            title: title,
            description: description,
            dueDate: dueDate,
            category: category,
            subtasks: subtasks
        )
        
        taskVM.addTask(task)
        dismiss()
    }
}
