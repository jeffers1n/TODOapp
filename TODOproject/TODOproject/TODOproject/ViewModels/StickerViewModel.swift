import SwiftUI

class StickerViewModel: ObservableObject {
    @Published var stickers: [Sticker] = []
    @Published var placingStickerID: UUID?
    private let stickersKey = "savedStickers"
    
    init() {
        loadStickers()
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
        if let encoded = try? JSONEncoder().encode(stickers) {
            UserDefaults.standard.set(encoded, forKey: stickersKey)
        }
    }
    
    private func loadStickers() {
        if let data = UserDefaults.standard.data(forKey: stickersKey),
           let decoded = try? JSONDecoder().decode([Sticker].self, from: data) {
            stickers = decoded
        }
    }
} 