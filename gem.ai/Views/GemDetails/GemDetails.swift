import SwiftUI

struct GemDetails: View {
    let popupMessage: String
    let showCenterPopup: Bool
    let centerX: CGFloat

    var body: some View {
        if showCenterPopup {
            VStack(spacing: 6) {
                Text("Item dropped")
                    .font(.headline)
                    .foregroundColor(.white)
                Text(popupMessage)
                    .font(.subheadline)
                    .foregroundColor(.white)
                    .multilineTextAlignment(.center)
            }
            .padding(12)
            .background(Color.black.opacity(0.8))
            .cornerRadius(10)
            .shadow(radius: 6)
            .position(x: centerX, y: 80)
            .transition(.move(edge: .top).combined(with: .opacity))
            .animation(.easeInOut(duration: 0.2), value: showCenterPopup)
        }
    }
}

// Preview
struct GemDetails_Previews: PreviewProvider {
    static var previews: some View {
        ZStack {
            Color.gray.ignoresSafeArea()
            GemDetails(popupMessage: "ID: ABCD1234\nType: Link", showCenterPopup: true, centerX: 200)
        }
        .frame(width: 400, height: 300)
    }
}
