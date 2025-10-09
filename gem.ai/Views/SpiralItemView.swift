import SwiftUI

struct SpiralItemView: View {
    let item: SpiralItem
    let circleSize: CGFloat
    // position in parent's coordinate space (passed from SpiralCarousel)
    let centerPosition: CGPoint

    // Callbacks to inform parent about drag lifecycle. Translations are relative to the start.
    var onDragStart: ((CGPoint) -> Void)? = nil
    var onDragChanged: ((CGSize) -> Void)? = nil
    var onDragEnd: ((CGSize) -> Void)? = nil

    @State private var isPressed: Bool = false
    @State private var hasStartedDrag: Bool = false
    @GestureState private var isLongPressing: Bool = false

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 28)
                .fill(item.color)
            RoundedRectangle(cornerRadius: 28)
                .stroke(Color.white, lineWidth: 4)

            // Mask shown while pressing/dragging
            if isPressed {
                RoundedRectangle(cornerRadius: 28)
                    .fill(Color.black.opacity(0.25))
                    .transition(.opacity)
            }
        }
        .frame(width: circleSize, height: circleSize)
        .overlay(
            Text(item.id.uuidString.prefix(4))
                .foregroundColor(.white)
                .font(.system(size: 20))
                .padding(8)
        )
        // Long press (1s) arms the drag. Quick tap or swipe acts normally.
        .gesture(
            LongPressGesture(minimumDuration: 1, maximumDistance: 20)
                .updating($isLongPressing) { value, state, _ in
                    state = value
                    if value && !isPressed {
                        withAnimation(.easeIn(duration: 0.12)) {
                            isPressed = true
                        }
                    }
                }
                .onEnded { _ in
                    hasStartedDrag = true
                    onDragStart?(centerPosition)
                }
                .sequenced(before:
                    DragGesture(minimumDistance: 0)
                        .onChanged { value in
                            guard hasStartedDrag else { return }
                            onDragChanged?(value.translation)
                        }
                        .onEnded { value in
                            guard hasStartedDrag else { return }
                            withAnimation(.easeOut(duration: 0.18)) {
                                isPressed = false
                            }
                            hasStartedDrag = false
                            onDragEnd?(value.translation)
                        }
                )
        )
    }
}
