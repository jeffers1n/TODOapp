import SwiftUI

struct ProfileView: View {
    @EnvironmentObject var profileVM: UserProfileViewModel
    @EnvironmentObject var themeManager: ThemeManager
    @EnvironmentObject var stickerVM: StickerViewModel
    @EnvironmentObject var taskVM: TaskViewModel
    @State private var showingStickerManagement = false

    private var totalTasks: Int {
        taskVM.tasks.count
    }

    private var completedTasks: [TodoTask] {
        taskVM.tasks.filter(\.isCompleted)
    }

    private var completionRate: Int {
        guard totalTasks > 0 else { return 0 }
        return Int((Double(completedTasks.count) / Double(totalTasks) * 100).rounded())
    }

    private var topCategoryText: String {
        let grouped = Dictionary(grouping: completedTasks, by: \.category)
        guard let top = grouped.max(by: { $0.value.count < $1.value.count })?.key else {
            return "Нет данных"
        }
        return top.rawValue
    }

    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Внешний вид")) {
                    Picker("Тема", selection: $themeManager.selectedTheme) {
                        ForEach(Theme.allCases) { theme in
                            Text(theme.displayName).tag(theme)
                        }
                    }
                }
                
                Section(header: Text("Статистика")) {
                    HStack {
                        Text("Всего задач:")
                        Spacer()
                        Text("\(totalTasks)")
                    }

                    HStack {
                        Text("Выполнено:")
                        Spacer()
                        Text("\(completedTasks.count)")
                    }

                    HStack {
                        Text("Процент выполнения:")
                        Spacer()
                        Text("\(completionRate)%")
                    }

                    HStack {
                        Text("Топ-категория:")
                        Spacer()
                        Text(topCategoryText)
                    }

                    NavigationLink {
                        TaskStatsView()
                    } label: {
                        HStack {
                            Text("Подробная статистика")
                            Spacer()
                            Image(systemName: "chart.pie.fill")
                                .foregroundColor(.purple)
                        }
                    }
                }
                
                Section(header: Text("Наклейки")) {
                    HStack {
                        Text("Управление наклейками")
                        Spacer()
                        Text("\(stickerVM.stickers.count)")
                            .foregroundColor(.secondary)
                    }
                    .contentShape(Rectangle())
                    .onTapGesture {
                        showingStickerManagement = true
                    }
                }
            }
            .navigationTitle("Профиль")
            .sheet(isPresented: $showingStickerManagement) {
                StickerManagementView()
            }
        }
    }
}

struct StickerManagementView: View {
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var stickerVM: StickerViewModel
    
    var body: some View {
        NavigationView {
            List {
                ForEach(stickerVM.stickers) { sticker in
                    if let image = UIImage(data: sticker.imageData) {
                        HStack {
                            Image(uiImage: image)
                                .resizable()
                                .scaledToFit()
                                .frame(height: 60)
                                .cornerRadius(8)
                            
                            VStack(alignment: .leading) {
                                Text("Наклейка")
                                    .font(.headline)
                                Text("Размещена: \(sticker.createdAt.formatted(date: .abbreviated, time: .shortened))")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            
                            Spacer()
                            
                            Button(action: {
                                stickerVM.deleteSticker(sticker)
                            }) {
                                Image(systemName: "trash")
                                    .foregroundColor(.red)
                            }
                        }
                    }
                }
            }
            .navigationTitle("Управление наклейками")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Готово") {
                        dismiss()
                    }
                }
            }
        }
    }
}

struct ProfileView_Previews: PreviewProvider {
    static var previews: some View {
        ProfileView()
            .environmentObject(UserProfileViewModel())
            .environmentObject(ThemeManager())
            .environmentObject(StickerViewModel())
            .environmentObject(TaskViewModel())
    }
}
