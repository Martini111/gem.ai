import SwiftUI
import Foundation

enum ItemType: String {
    case link = "Link"
    case voice = "Voice"
    case video = "Video"
    case text = "Text"
    case image = "Image"
}

struct SpiralItem {
    let id: UUID
    let color: Color
    let type: ItemType
}

func generateSpiralItems(count: Int) -> [SpiralItem] {
    let colors: [Color] = [.red, .blue, .green, .yellow, .purple, .orange]
    let types: [ItemType] = [.link, .voice, .video, .text, .image]
    return (0..<count).map { i in
        let randomType = types[Int.random(in: 0..<types.count)]
        return SpiralItem(id: UUID(), color: colors[i % colors.count], type: randomType)
    }
}
