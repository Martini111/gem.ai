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

    // Circular gesture tuning
    // radiansToOffset maps angular movement to spiral offset
    // Increase for faster looping per small angle, decrease for finer control
    let radiansToOffset: CGFloat = 260
    let flickBoost: CGFloat = 1.0 // multiply predicted angular delta for momentum

    // Additional multiplier to control rotation speed independent of radiansToOffset
    // Set <1.0 for slower response, >1.0 for faster response
    var rotationSpeed: CGFloat = 0.5

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

    // MARK: - New circular gesture API

    // Apply a small incremental angular delta in radians
    func applyAngle(deltaRadians: CGFloat) {
        spiralOffset += sign * deltaRadians * radiansToOffset * rotationSpeed
    }

    // Apply predicted tail for momentum
    func finishAngleDrag(predictedDeltaRadians: CGFloat) {
        let flick = sign * predictedDeltaRadians * radiansToOffset * flickBoost * rotationSpeed
        withAnimation(animation) { spiralOffset += flick }
    }

    // MARK: - Legacy vertical drag API (kept for reference or fallback)

    func applyDrag(start: CGFloat, translation: CGSize) {
        spiralOffset = start + sign * translation.height * sensitivity
    }

    func finishDrag(currentTranslation: CGSize, predictedTranslation: CGSize) {
        let vy = (predictedTranslation.height - currentTranslation.height)
        let flick = sign * vy * 0.1 * sensitivity
        spiralOffset += flick
//        withAnimation(animation) {  }
    }

    // MARK: - Pinch

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
