import SwiftUI

struct ContentView: View {
    @StateObject private var vm = ContentVM()
    @GestureState private var dragStartOffset: CGFloat? = nil
    @GestureState private var rotationStart: Angle? = nil
    @GestureState private var rotationStartOffset: CGFloat? = nil

    // Helper moved out of the body to avoid declaring functions inside a ViewBuilder closure
    private func angle(center: CGPoint, point: CGPoint) -> Angle {
        Angle(radians: Double(atan2(point.y - center.y, point.x - center.x)))
    }

    var body: some View {
        // Replace linear drag + RotationGesture with a single-finger circular drag around the view center.
        // We'll compute angle from the center to the touch point and convert angular delta to spiral offset via ContentVM.applyRotation.

        let pinch = MagnificationGesture()
            .onEnded { vm.pinchEnded(scale: $0) }

        let spiralConfig = vm.tuned

        GeometryReader { proxy in
            let center = CGPoint(x: proxy.size.width / 2, y: proxy.size.height / 2)

            // Single-finger circular drag gesture — compute incremental angle deltas in the updating closure
            let circular = DragGesture(minimumDistance: 0, coordinateSpace: .local)
                .updating($rotationStart) { value, state, _ in
                    let current = angle(center: center, point: value.location)
                    if let prev = state {
                        // apply incremental delta immediately
                        let delta = CGFloat(current.radians - prev.radians)
                        vm.applyAngle(deltaRadians: delta)
                        state = current
                    } else {
                        // initialize stored angle at gesture start
                        state = angle(center: center, point: value.startLocation)
                    }
                }
                .onEnded { value in
                    // compute predicted delta for momentum using predicted end location
                    let last = angle(center: center, point: value.location)
                    let predicted = angle(center: center, point: value.predictedEndLocation)
                    let predictedDelta = CGFloat(predicted.radians - last.radians)
                    vm.finishAngleDrag(predictedDeltaRadians: predictedDelta)
                }

            ZStack {
                Color("BGColor").ignoresSafeArea()

                SpiralCarousel(
                    numberOfItems: spiralConfig.numberOfItems,
                    distanceBetweenCircles: spiralConfig.distanceBetweenCircles,
                    distanceToCenter: spiralConfig.distanceToCenter,
                    circleSize: spiralConfig.circleSize,
                    centerCircleSize: spiralConfig.centerCircleSize,
                    distanceBetweenItems: spiralConfig.distanceBetweenItems,
                    spiralOffset: $vm.spiralOffset
                )
            }
            .contentShape(Rectangle())
            // Use circular (single-finger) swipe and pinch together
            .gesture(circular.simultaneously(with: pinch))
        }
    }
}

#Preview { ContentView() }
