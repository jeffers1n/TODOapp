import SwiftUI
import SwiftData

@MainActor
class StickerViewModel: ObservableObject {
    @Published var stickers: [Sticker] = []
    @Published var placingStickerID: UUID?
    private let modelContext: ModelContext
    
    init(modelContext: ModelContext) {
        self.modelContext = modelContext
        loadStickers()
    }
    
    /// Удобный инициализатор для превью/тестов (in-memory SwiftData)
    convenience init() {
        let schema = Schema([StickerEntity.self])
        let configuration = ModelConfiguration(isStoredInMemoryOnly: true)
        let container = try! ModelContainer(for: schema, configurations: configuration)
        self.init(modelContext: container.mainContext)
    }
    
    func addSticker(_ sticker: Sticker) {
        stickers.append(sticker)
        saveStickers()
    }
    
    func updateSticker(_ sticker: Sticker) {
        if let index = stickers.firstIndex(where: { $0.id == sticker.id }) {
            stickers[index] = sticker
            saveStickers()
        }
    }
    
    func deleteSticker(_ sticker: Sticker) {
        stickers.removeAll { $0.id == sticker.id }
        saveStickers()
    }
    
    func placeSticker(id: UUID) {
        if let index = stickers.firstIndex(where: { $0.id == id }) {
            stickers[index].isPlaced = true
            placingStickerID = nil
            saveStickers()
        }
    }
    
    private func saveStickers() {
        do {
            let existing = try modelContext.fetch(FetchDescriptor<StickerEntity>())
            existing.forEach { modelContext.delete($0) }
            
            for sticker in stickers {
                let entity = StickerEntity(
                    id: sticker.id,
                    imageData: sticker.imageData,
                    scale: sticker.scale,
                    rotation: sticker.rotation,
                    positionX: sticker.position.x,
                    positionY: sticker.position.y,
                    isPlaced: sticker.isPlaced,
                    createdAt: sticker.createdAt
                )
                modelContext.insert(entity)
            }
            
            try modelContext.save()
        } catch {
            print("Failed to save stickers to SwiftData: \\(error)")
        }
    }
    
    private func loadStickers() {
        do {
            let descriptor = FetchDescriptor<StickerEntity>(sortBy: [SortDescriptor(\StickerEntity.createdAt)])
            let stored = try modelContext.fetch(descriptor)
            stickers = stored.map { entity in
                Sticker(
                    id: entity.id,
                    imageData: entity.imageData,
                    scale: entity.scale,
                    rotation: entity.rotation,
                    position: CGPoint(x: entity.positionX, y: entity.positionY),
                    isPlaced: entity.isPlaced
                )
            }
        } catch {
            print("Failed to load stickers from SwiftData: \\(error)")
            stickers = []
        }
    }
} 