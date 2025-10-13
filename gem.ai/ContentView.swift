import SwiftUI

/// ContentView - single finger circular scroll + pinch to adjust spiral density.
/// Angle deltas are normalized to avoid jumps when crossing the -π/π boundary.
struct ContentView: View {
    @StateObject private var vm = ContentVM()

    // Gesture-scoped state for the previous angle during a drag
    @GestureState private var previousAngleRadians: Double?

    // Helper moved out of the body
    private func angleRadians(center: CGPoint, point: CGPoint) -> Double {
        Double(atan2(point.y - center.y, point.x - center.x))
    }

    /// Normalize raw angular difference into the smallest signed delta in [-π, π]
    private func normalizedDelta(from prev: Double, to next: Double) -> CGFloat {
        var d = next - prev
        // Wrap into [-π, π]
        d = remainder(d, 2 * .pi)
        if d > .pi { d -= 2 * .pi }
        if d < -Double.pi { d += 2 * .pi }
        return CGFloat(d)
    }

    var body: some View {
        GeometryReader { proxy in
            let center = CGPoint(x: proxy.size.width * 0.5, y: proxy.size.height * 0.5)

            // Pinch for spiral density control
            let pinch = MagnificationGesture()
                .onEnded { vm.pinchEnded(scale: $0) }

            // Single finger circular drag - convert movement to angular deltas around the view center
            let circular = DragGesture(minimumDistance: 0, coordinateSpace: .local)
                .updating($previousAngleRadians) { value, state, _ in
                    let current = angleRadians(center: center, point: value.location)
                    if let prev = state {
                        let delta = normalizedDelta(from: prev, to: current)
                        vm.applyAngle(deltaRadians: delta)
                        state = current
                    } else {
                        // Initialize reference on first update
                        state = angleRadians(center: center, point: value.startLocation)
                    }
                }
                .onEnded { value in
                    // Predictive momentum - also normalized to avoid 2π spikes
                    let last = angleRadians(center: center, point: value.location)
                    let predicted = angleRadians(center: center, point: value.predictedEndLocation)
                    let predictedDelta = normalizedDelta(from: last, to: predicted)
                    vm.finishAngleDrag(predictedDeltaRadians: predictedDelta)
                }

            ZStack {
                Color("BGColor").ignoresSafeArea()

                let tuned = vm.tuned
                SpiralCarousel(
                    numberOfItems: tuned.numberOfItems,
                    distanceBetweenCircles: tuned.distanceBetweenCircles,
                    distanceToCenter: tuned.distanceToCenter,
                    circleSize: tuned.circleSize,
                    centerCircleSize: tuned.centerCircleSize,
                    distanceBetweenItems: tuned.distanceBetweenItems,
                    spiralOffset: $vm.spiralOffset
                )
                .drawingGroup() // offscreen rendering for smoother animations
            }
            .contentShape(Rectangle())
            .gesture(circular.simultaneously(with: pinch))
        }
    }
}

#Preview { ContentView() }
