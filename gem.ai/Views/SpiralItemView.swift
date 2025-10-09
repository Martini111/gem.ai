import SwiftUI

struct SpiralItemView: View {
    let item: SpiralItem
    let circleSize: CGFloat

    var body: some View {
        RoundedRectangle(cornerRadius: 28)
            .fill(item.color)
            .stroke(Color.black, lineWidth: 4)
            .frame(width: circleSize, height: circleSize)
            .overlay(
                Text(item.id.uuidString.prefix(4))
                    .foregroundColor(.white)
                    .font(.system(size: 20))
                    .padding(8)
            )
    }
}
