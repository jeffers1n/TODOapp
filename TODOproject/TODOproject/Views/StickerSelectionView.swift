import SwiftUI
import PhotosUI

struct StickerSelectionView: View {
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var taskVM: TaskViewModel
    @EnvironmentObject var stickerVM: StickerViewModel
    @EnvironmentObject var viewRouter: ViewRouter
    @State private var selectedItem: PhotosPickerItem?
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                Text("Выберите наклейку для завершения задачи")
                    .font(.headline)
                    .multilineTextAlignment(.center)
                    .padding()
                
                PhotosPicker(selection: $selectedItem,
                           matching: .images) {
                    VStack {
                        Image(systemName: "photo.on.rectangle.angled")
                            .font(.system(size: 40))
                        Text("Выбрать фото")
                            .font(.headline)
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.purple.opacity(0.1))
                    .cornerRadius(10)
                }
                
                Button("Завершить без наклейки") {
                    taskVM.confirmTaskCompletion()
                    dismiss()
                }
                .foregroundColor(.gray)
            }
            .padding()
            .navigationTitle("Наклейка")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Отмена") {
                        dismiss()
                    }
                }
            }
        }
        .onChange(of: selectedItem) { newItem in
            Task {
                if let data = try? await newItem?.loadTransferable(type: Data.self) {
                    let newSticker = Sticker(imageData: data,
                                             position: CGPoint(x: UIScreen.main.bounds.width / 2, y: UIScreen.main.bounds.height / 3),
                                             isPlaced: false)
                    await MainActor.run {
                        stickerVM.addSticker(newSticker)
                        stickerVM.placingStickerID = newSticker.id
                            taskVM.confirmTaskCompletion()
                        viewRouter.currentTab = .home
                            dismiss()
                        }
                }
            }
        }
    }
} 