import SwiftUI
import Combine

@MainActor
final class ContentVM: ObservableObject {

    enum SwipeDirection { case bottomToTop, topToBottom }

    // Public state
    @Published var spiralOffset: CGFloat = 0
    @Published var minCurves: Int = 1
    @Published var pinchLevel: Int = 0

    // Config
    var base = SpiralConfig()
    var swipeDirection: SwipeDirection = .topToBottom

    // Animation tuning
    let sensitivity: CGFloat = 0.3
    let response: Double = 0.5
    let dampingFraction: Double = 0.7

    // Pinch settings
    let pinchStep: CGFloat = 10
    let pinchLevelMin: Int = -3
    let pinchLevelMax: Int = 3
    let pinchInThreshold: CGFloat = 0.95
    let pinchOutThreshold: CGFloat = 1.05

    var animation: Animation {
        .spring(response: response, dampingFraction: dampingFraction)
    }

    var sign: CGFloat { swipeDirection == .bottomToTop ? -1 : 1 }

    // Single place to fetch dynamic values
    var tuned: SpiralConfigTuned {
        base.tuned(pinchLevel: pinchLevel, step: pinchStep)
    }

    // Gestures
    func applyDrag(start: CGFloat, translation: CGSize) {
        spiralOffset = start + sign * translation.height * sensitivity
    }

    func finishDrag(currentTranslation: CGSize, predictedTranslation: CGSize) {
        let vy = (predictedTranslation.height - currentTranslation.height)
        let flick = sign * vy * 0.1 * sensitivity
        withAnimation(animation) { spiralOffset += flick }
    }

    func pinchEnded(scale: CGFloat) {
        if scale < pinchInThreshold {
            withAnimation(.bouncy(duration: 0.2)) {
                minCurves += 2
                pinchLevel = max(pinchLevelMin, pinchLevel - 1)
            }
        } else if scale > pinchOutThreshold {
            withAnimation(.bouncy(duration: 0.2)) {
                minCurves = max(1, minCurves - 2)
                pinchLevel = min(pinchLevelMax, pinchLevel + 1)
            }
        }
    }
}
