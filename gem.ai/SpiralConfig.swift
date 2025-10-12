import SwiftUI

/// Static base configuration for the spiral.
/// All dynamic values are derived from this config and the pinchLevel.
struct SpiralConfig {
    var numberOfItems: Int = 100
    var distanceBetweenItems: CGFloat = 120
    var distanceBetweenCircles: CGFloat = 120
    var distanceToCenter: CGFloat = 80
    var circleSize: CGFloat = 90
    var centerCircleSize: CGFloat = 200
}

/// Snapshot of dynamic values computed from a base config.
struct SpiralConfigTuned {
    let numberOfItems: Int
    let distanceBetweenItems: CGFloat
    let distanceBetweenCircles: CGFloat
    let distanceToCenter: CGFloat
    let circleSize: CGFloat
    let centerCircleSize: CGFloat
}

extension SpiralConfig {
    /// Produce a tuned config for a given pinchLevel and step.
    func tuned(pinchLevel: Int, step: CGFloat = 10) -> SpiralConfigTuned {
        SpiralConfigTuned(
            numberOfItems: numberOfItems,
            distanceBetweenItems: distanceBetweenItems + CGFloat(pinchLevel) * step,
            distanceBetweenCircles: distanceBetweenCircles + CGFloat(pinchLevel) * step,
            distanceToCenter: distanceToCenter + CGFloat(pinchLevel) * step,
            circleSize: circleSize + CGFloat(pinchLevel) * step,
            centerCircleSize: centerCircleSize + CGFloat(pinchLevel) * step
        )
    }
}
