import SwiftUI

struct ContentView: View {
    @StateObject private var vm = ContentVM()

    // angle tracking - unchanged
    @GestureState private var previousAngleRadians: Double?
    // pinch anchor stores the last committed magnification to enable thresholded stepping mid-gesture
    @GestureState private var pinchAnchor: CGFloat = 1

    private func angleRadians(center: CGPoint, point: CGPoint) -> Double {
        Double(atan2(point.y - center.y, point.x - center.x))
    }

    private func normalizedDelta(from prev: Double, to next: Double) -> CGFloat {
        var d = next - prev
        d = remainder(d, 2 * .pi)
        if d > .pi { d -= 2 * .pi }
        if d < -Double.pi { d += 2 * .pi }
        return CGFloat(d)
    }

    var body: some View {
        GeometryReader { proxy in
            let center = CGPoint(x: proxy.size.width * 0.5, y: proxy.size.height * 0.5)

            // - New: live stepping pinch
            // - value is absolute since gesture start, so we keep a per-gesture anchor and fire steps whenever
            //   value/anchor crosses a threshold, then reset anchor to current value
            let pinch = MagnificationGesture()
                .updating($pinchAnchor) { value, state, _ in
                    // value starts at 1.0
                    let ratio = value / max(state, 0.0001)

                    if ratio <= vm.pinchInThreshold {
                        vm.pinchStep(direction: .in)
                        state = value
                    } else if ratio >= vm.pinchOutThreshold {
                        vm.pinchStep(direction: .out)
                        state = value
                    }
                }
                .onEnded { _ in
                    vm.pinchEndedCleanup()
                }

            let circular = DragGesture(minimumDistance: 0, coordinateSpace: .local)
                .updating($previousAngleRadians) { value, state, _ in
                    let current = angleRadians(center: center, point: value.location)
                    if let prev = state {
                        let delta = normalizedDelta(from: prev, to: current)
                        vm.applyAngle(deltaRadians: delta)
                        state = current
                    } else {
                        state = angleRadians(center: center, point: value.startLocation)
                    }
                }
                .onEnded { value in
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
                .drawingGroup()
            }
            .contentShape(Rectangle())
            .gesture(circular.simultaneously(with: pinch))
        }
        .ignoresSafeArea()
    }
}

#Preview { ContentView() }
