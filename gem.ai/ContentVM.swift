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
    let response: Double = 0.5
    let dampingFraction: Double = 0.7

    // Circular gesture tuning
    // radiansToOffset maps angular movement to spiral offset
    // Increase for faster looping, decrease for finer control
    let radiansToOffset: CGFloat = 240
    let flickBoost: CGFloat = 1.0

    // Additional multiplier to control rotation speed
    var rotationSpeed: CGFloat = 0.55

    // Pinch settings
    let pinchStep: CGFloat = 10
    let pinchLevelMin: Int = -3
    let pinchLevelMax: Int = 3
    let pinchInThreshold: CGFloat = 0.95
    let pinchOutThreshold: CGFloat = 1.05

    // Legacy vertical drag constants left for reference
    let sensitivity: CGFloat = 0.3

    var animation: Animation {
        .spring(response: response, dampingFraction: dampingFraction)
    }

    var sign: CGFloat { swipeDirection == .bottomToTop ? -1 : 1 }

    // Single place to fetch dynamic values
    var tuned: SpiralConfigTuned {
        base.tuned(pinchLevel: pinchLevel, step: pinchStep)
    }

    // MARK: - Circular gesture API

    /// Apply a small incremental angular delta in radians - already normalized by the caller
    func applyAngle(deltaRadians: CGFloat) {
        // Scale and accumulate
        spiralOffset += sign * deltaRadians * radiansToOffset * rotationSpeed
    }

    /// Apply predicted tail for momentum - delta is normalized by the caller
    func finishAngleDrag(predictedDeltaRadians: CGFloat) {
        let flick = sign * predictedDeltaRadians * radiansToOffset * flickBoost * rotationSpeed
        withAnimation(animation) {
            spiralOffset += flick
        }
    }

    // MARK: - Legacy vertical drag API (kept for reference or fallback)

    func applyDrag(start: CGFloat, translation: CGSize) {
        spiralOffset = start + sign * translation.height * sensitivity
    }

    func finishDrag(currentTranslation: CGSize, predictedTranslation: CGSize) {
        let vy = (predictedTranslation.height - currentTranslation.height)
        let flick = sign * vy * 0.1 * sensitivity
        spiralOffset += flick
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
