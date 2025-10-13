import SwiftUI
import Combine

@MainActor
final class ContentVM: ObservableObject {

    enum SwipeDirection { case bottomToTop, topToBottom }
    enum PinchDirection { case `in`, out }

    // Public state
    @Published var spiralOffset: CGFloat = 0
    @Published var minCurves: Int = 1
    @Published var pinchLevel: Int = 0

    // Config
    var base = SpiralConfig()
    var swipeDirection: SwipeDirection = .topToBottom

    // Animation tuning
    let response: Double = 0.45
    let dampingFraction: Double = 0.78

    // Circular gesture tuning
    let radiansToOffset: CGFloat = 240
    let flickBoost: CGFloat = 1.0
    var rotationSpeed: CGFloat = 0.55

    // Pinch settings
    let pinchStep: CGFloat = 10
    let pinchLevelMin: Int = -3
    let pinchLevelMax: Int = 3

    // Thresholds for per-step trigger
    let pinchInThreshold: CGFloat = 0.96   // a bit tighter for snappier feel
    let pinchOutThreshold: CGFloat = 1.04

    // Legacy vertical drag constants
    let sensitivity: CGFloat = 0.3

    var animation: Animation {
        .spring(response: response, dampingFraction: dampingFraction)
    }

    var sign: CGFloat { swipeDirection == .bottomToTop ? -1 : 1 }

    var tuned: SpiralConfigTuned {
        base.tuned(pinchLevel: pinchLevel, step: pinchStep)
    }

    // MARK: - Circular gesture API

    func applyAngle(deltaRadians: CGFloat) {
        spiralOffset += sign * deltaRadians * radiansToOffset * rotationSpeed
    }

    func finishAngleDrag(predictedDeltaRadians: CGFloat) {
        let flick = sign * predictedDeltaRadians * radiansToOffset * flickBoost * rotationSpeed
        withAnimation(animation) { spiralOffset += flick }
    }

    // MARK: - Pinch - live stepping with animation

    func pinchStep(direction: PinchDirection) {
        switch direction {
        case .in:
            guard pinchLevel > pinchLevelMin else { return }
            withAnimation(animation) {
                minCurves += 2
                pinchLevel -= 1
            }
        case .out:
            guard pinchLevel < pinchLevelMax else { return }
            withAnimation(animation) {
                minCurves = max(1, minCurves - 2)
                pinchLevel += 1
            }
        }
    }

    // Optional cleanup hook - can be used to snap or coalesce state at gesture end
    func pinchEndedCleanup() {
        // nothing for now - keep state as-is
        // you can add subtle settling here if you later introduce fractional tuning
    }

    // MARK: - Legacy vertical drag API

    func applyDrag(start: CGFloat, translation: CGSize) {
        spiralOffset = start + sign * translation.height * sensitivity
    }

    func finishDrag(currentTranslation: CGSize, predictedTranslation: CGSize) {
        let vy = (predictedTranslation.height - currentTranslation.height)
        let flick = sign * vy * 0.1 * sensitivity
        spiralOffset += flick
    }
}
