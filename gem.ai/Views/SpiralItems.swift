import SwiftUI

enum ItemType {
    case link, voice, video, text, image
}

struct SpiralItem {
    let id: Int
    let color: Color
    let type: ItemType
}

func generateSpiralItems(count: Int) -> [SpiralItem] {
    let colors: [Color] = [.red, .blue, .green, .yellow, .purple, .orange]
    let types: [ItemType] = [.link, .voice, .video, .text, .image]
    return (0..<count).map { i in
        let randomType = types[Int.random(in: 0..<types.count)]
        SpiralItem(id: i, color: colors[i % colors.count], type: randomType)
    }
}
