import Foundation

struct Achievement: Identifiable, Codable {
    var id = UUID()
    let title: String
    let description: String
    var isUnlocked: Bool
    let imageName: String
} 