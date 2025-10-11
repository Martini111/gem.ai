import SwiftUI

struct ContentView: View {
    @StateObject private var vm = ContentVM()
    @GestureState private var dragStartOffset: CGFloat? = nil

    var body: some View {
        let drag = DragGesture(minimumDistance: 0)
            .updating($dragStartOffset) { _, state, _ in
                if state == nil { state = vm.spiralOffset }
            }
            .onChanged { value in
                vm.applyDrag(start: dragStartOffset ?? vm.spiralOffset, translation: value.translation)
            }
            .onEnded { value in
                vm.finishDrag(currentTranslation: value.translation, predictedTranslation: value.predictedEndTranslation)
            }

        let pinch = MagnificationGesture()
            .onEnded { vm.pinchEnded(scale: $0) }

        let spiralConfig = vm.tuned

        ZStack {
            Color("BGColor").ignoresSafeArea()

            SpiralCarousel(
                numberOfItems: spiralConfig.numberOfItems,
                distanceBetweenCircles: spiralConfig.distanceBetweenCircles,
                distanceToCenter: spiralConfig.distanceToCenter,
                circleSize: spiralConfig.circleSize,
                centerCircleSize: spiralConfig.centerCircleSize,
                distanceBetweenItems: spiralConfig.distanceBetweenItems,
                minCurves: vm.minCurves,
                spiralOffset: $vm.spiralOffset
            )
        }
        .contentShape(Rectangle())
        .gesture(drag.simultaneously(with: pinch))
    }
}

#Preview { ContentView() }
