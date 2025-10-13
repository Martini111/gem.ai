import SwiftUI

struct SpiralItemView: View {
    let item: SpiralItem
    let circleSize: CGFloat

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 28)
                .fill(Color("BGColor"))
            RoundedRectangle(cornerRadius: 28)
                .stroke(item.color, lineWidth: 4)
        }
        .frame(width: circleSize, height: circleSize)
        .overlay(
            Text(item.id.uuidString.prefix(4))
                .foregroundColor(.white)
                .font(.system(size: 20))
                .padding(8)
        )
    }
}
