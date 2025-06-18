import SwiftUI

struct ProfileView: View {
    @EnvironmentObject var profileVM: UserProfileViewModel
    @EnvironmentObject var themeManager: ThemeManager
    @EnvironmentObject var stickerVM: StickerViewModel
    @State private var showingStickerManagement = false
    
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
                        Text("Выполнено задач:")
                        Spacer()
                        Text("\(profileVM.userProfile.totalTasksCompleted)")
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
    }
}



