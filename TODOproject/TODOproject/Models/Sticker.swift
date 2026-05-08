import SwiftUI

struct Sticker: Identifiable, Codable, Hashable {
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }

    static func == (lhs: Sticker, rhs: Sticker) -> Bool {
        lhs.id == rhs.id
    }

    var id: UUID = UUID()
    var imageData: Data
    var scale: Double
    var rotation: Double
    var position: CGPoint
    var isPlaced: Bool = false
    var createdAt: Date = Date()
    
    enum CodingKeys: String, CodingKey {
        case id
        case imageData
        case scale
        case rotation
        case positionX
        case positionY
        case isPlaced
        case createdAt
    }
    
    init(
        id: UUID = UUID(),
        imageData: Data,
        scale: Double = 1.0,
        rotation: Double = 0.0,
        position: CGPoint = .zero,
        isPlaced: Bool = false,
        createdAt: Date = Date()
    ) {
        self.id = id
        self.imageData = imageData
        self.scale = scale
        self.rotation = rotation
        self.position = position
        self.isPlaced = isPlaced
        self.createdAt = createdAt
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(UUID.self, forKey: .id)
        imageData = try container.decode(Data.self, forKey: .imageData)
        scale = try container.decode(Double.self, forKey: .scale)
        rotation = try container.decode(Double.self, forKey: .rotation)
        let x = try container.decode(Double.self, forKey: .positionX)
        let y = try container.decode(Double.self, forKey: .positionY)
        position = CGPoint(x: x, y: y)
        isPlaced = try container.decodeIfPresent(Bool.self, forKey: .isPlaced) ?? false
        createdAt = try container.decode(Date.self, forKey: .createdAt)
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(imageData, forKey: .imageData)
        try container.encode(scale, forKey: .scale)
        try container.encode(rotation, forKey: .rotation)
        try container.encode(position.x, forKey: .positionX)
        try container.encode(position.y, forKey: .positionY)
        try container.encode(isPlaced, forKey: .isPlaced)
        try container.encode(createdAt, forKey: .createdAt)
    }
} 