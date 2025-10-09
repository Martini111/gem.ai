import SwiftUI

struct SpiralItemView: View {
    let item: SpiralItem
    let circleSize: CGFloat
    // position in parent's coordinate space (passed from SpiralCarousel)
    let centerPosition: CGPoint

    // Parent-provided geometry for drop target checking
    let center: CGPoint
    let centerCircleSize: CGFloat

    // Bindings to parent drag state so this view can update the floating preview.
    @Binding var draggingItem: SpiralItem?
    @Binding var dragStartPosition: CGPoint
    @Binding var dragLocation: CGPoint
    @Binding var showPreview: Bool

    // Callback to notify parent when an item was dropped into center
    var onItemDropped: ((SpiralItem) -> Void)? = nil

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
        // Long press (0.2s) arms the drag. Quick tap or swipe acts normally.
        .gesture(
            LongPressGesture(minimumDuration: 0.2, maximumDistance: 20)
                .updating($isLongPressing) { value, state, _ in
                    state = value
                    if value && !isPressed {
                        withAnimation(.easeIn(duration: 0.12)) {
                            isPressed = true
                        }
                    }
                }
                .onEnded { _ in
                    // Begin drag: set parent drag state so the preview can be shown
                    hasStartedDrag = true
                    draggingItem = item
                    dragStartPosition = centerPosition
                    dragLocation = centerPosition

                    // Inform parent/other listeners that DnD started
                    NotificationCenter.default.post(name: .spiralDragDidStart, object: nil)

                    withAnimation(.easeIn(duration: 0.12)) {
                        showPreview = true
                    }
                }
                .sequenced(before:
                    DragGesture(minimumDistance: 0)
                        .onChanged { value in
                            guard hasStartedDrag else { return }
                            // Update preview location relative to drag start
                            dragLocation = CGPoint(x: dragStartPosition.x + value.translation.width,
                                                   y: dragStartPosition.y + value.translation.height)
                        }
                        .onEnded { value in
                            guard hasStartedDrag else { return }

                            // Reset pressed visual state
                            withAnimation(.easeOut(duration: 0.18)) {
                                isPressed = false
                            }
                            hasStartedDrag = false

                            let final = CGPoint(x: dragStartPosition.x + value.translation.width,
                                                y: dragStartPosition.y + value.translation.height)

                            // Check if final point is inside center circle
                            let distanceToCenter = hypot(final.x - center.x, final.y - center.y)
                            if distanceToCenter <= centerCircleSize / 2 {
                                // Dropped on center - inform parent
                                onItemDropped?(item)
                            }

                            // Hide preview and clear state
                            withAnimation(.easeOut(duration: 0.18)) {
                                showPreview = false
                            }

                            // Delay clearing to allow fade-out animation
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.18) {
                                draggingItem = nil
                                // Inform parent/other listeners that DnD ended
                                NotificationCenter.default.post(name: .spiralDragDidEnd, object: nil)
                            }
                        }
                )
        )
    }
}
