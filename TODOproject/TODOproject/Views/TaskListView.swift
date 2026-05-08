import SwiftUI

struct TaskListView: View {
    @EnvironmentObject var taskVM: TaskViewModel
    @EnvironmentObject var profileVM: UserProfileViewModel
    @State private var showingAddTask = false
    @State private var selectedTask: TodoTask?
    
    var body: some View {
        NavigationView {
            VStack {
                List {
                    ForEach(taskVM.filteredTasks) { task in
                        TaskRowView(taskVM: taskVM, task: task)
                            .onTapGesture {
                                selectedTask = task
                            }
                            .swipeActions(edge: .leading, allowsFullSwipe: true) {
                                Button {
                                    taskVM.completeTask(task)
                                } label: {
                                    Label("Завершить", systemImage: "checkmark.circle")
                                }
                                .tint(.green)
                            }
                            .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                                Button(role: .destructive) {
                                    taskVM.deleteTask(task)
                                } label: {
                                    Label("Удалить", systemImage: "trash")
                                }
                            }
                    }
                }
            }
            .navigationTitle("Мои задачи")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        showingAddTask = true
                    } label: {
                        Image(systemName: "plus.circle.fill")
                            .foregroundColor(.purple)
                    }
                }
                
                ToolbarItem(placement: .navigationBarLeading) {
                    HStack {
                        Menu {
                            Button("Все задачи") {
                                taskVM.selectedFilter = .all
                                taskVM.applyFilter()
                            }
                            Button("В ожидании") {
                                taskVM.selectedFilter = .pending
                                taskVM.applyFilter()
                            }
                            Button("Завершенные") {
                                taskVM.selectedFilter = .completed
                                taskVM.applyFilter()
                            }
                        } label: {
                            Image(systemName: "line.3.horizontal.decrease.circle")
                                .foregroundColor(.purple)
                        }
                        
                        Menu {
                            Button("Все категории") {
                                taskVM.selectedCategoryFilter = nil
                                taskVM.applyFilter()
                            }
                            Divider()
                            ForEach(TaskCategory.allCases) { category in
                                Button(category.rawValue) {
                                    taskVM.selectedCategoryFilter = category
                                    taskVM.applyFilter()
                                }
                            }
                        } label: {
                            Image(systemName: "tag.circle")
                                .foregroundColor(.purple)
                        }
                    }
                }
            }
            .sheet(isPresented: $showingAddTask) {
                AddTaskView()
            }
            .sheet(item: $selectedTask) { task in
                EditTaskView(task: task)
            }
            .sheet(isPresented: $taskVM.showingStickerSelection) {
                StickerSelectionView()
            }
        }
        .onAppear {
            taskVM.applyFilter()
        }
    }
}

struct TaskRowView: View {
    @ObservedObject var taskVM: TaskViewModel
    let task: TodoTask
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 8) {
                Text(task.title)
                    .font(.headline)
                    .strikethrough(task.isCompleted)
                
                HStack {
                    Image(systemName: task.category.icon)
                        .foregroundColor(.purple)
                    Text(task.category.rawValue)
                        .font(.caption)
                        .padding(4)
                        .background(Color.purple.opacity(0.1))
                        .cornerRadius(5)
                }
                
                Text(task.description)
                    .font(.subheadline)
                    .foregroundColor(.gray)
                
                if !task.subtasks.isEmpty {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Подзадачи: \(task.subtasks.filter { $0.isCompleted }.count)/\(task.subtasks.count)")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        if let nextSubtask = task.subtasks.filter({ !$0.isCompleted }).min(by: { $0.dueDate < $1.dueDate }) {
                            Text("Следующая: \(nextSubtask.title) - \(nextSubtask.dueDate, style: .date)")
                                .font(.caption2)
                                .foregroundColor(.gray)
                        }
                    }
                }
                
                Text("Срок: \(task.formattedDueDate)")
                    .font(.caption)
                    .foregroundColor(.blue)
            }
            .padding(.vertical, 8)
        }
    }
} 
