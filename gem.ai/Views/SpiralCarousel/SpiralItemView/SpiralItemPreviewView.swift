import SwiftUI

struct SpiralItemPreviewView: View {
    let item: SpiralItem
    let size: CGFloat

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 28)
                .fill(item.color.opacity(0.9))
            RoundedRectangle(cornerRadius: 28)
                .stroke(Color.white, lineWidth: 4)
            Text(item.id.uuidString.prefix(4))
                .foregroundColor(.white)
                .font(.system(size: 20))
        }
        .frame(width: size, height: size)
    }
}
