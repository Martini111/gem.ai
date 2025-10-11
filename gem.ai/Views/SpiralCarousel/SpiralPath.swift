import SwiftUI

/// Spiral path that auto-computes visible angular extent and samples evenly by arc length.
struct SpiralPath: Shape {
    // Core parameters
    var distanceToCenter: CGFloat
    var distanceBetweenCircles: CGFloat

    /// Draw from the outermost visible point toward the center when true
    var reverse: Bool = true

    /// Overscan margin in points to render slightly beyond edges
    var overscan: CGFloat = 0

    /// Sampling controls
    var targetPointSpacing: CGFloat = 2.0
    var minPoints: Int = 200
    var maxPoints: Int = 5000

    // Animate core CGFloats so changes are smooth
    var animatableData: AnimatablePair<CGFloat, CGFloat> {
        get { AnimatablePair(distanceToCenter, distanceBetweenCircles) }
        set {
            distanceToCenter = newValue.first
            distanceBetweenCircles = newValue.second
        }
    }

    func path(in rect: CGRect) -> Path {
        var path = Path()

        // Guard against degenerate inputs
        let params = SpiralParams(distanceToCenter: max(0, distanceToCenter),
                                  distanceBetweenCircles: max(0, distanceBetweenCircles))
        let b = SpiralMath.b(params)
        guard b > .ulpOfOne else { return path }

        // Visible angular extent
        let thetaEnd = SpiralMath.thetaEndVisible(in: rect, params: params, overscan: overscan)
        guard thetaEnd > 0 else { return path }

        // Total visible arc length
        let drawLength = SpiralMath.arcLength(a: params.distanceToCenter, b: b, theta: thetaEnd)

        // Adaptive sampling
        let estimated = max(Int((drawLength / max(targetPointSpacing, 0.25)).rounded()), minPoints)
        let totalPoints = min(estimated, maxPoints)

        let center = CGPoint(x: rect.midX, y: rect.midY)
        var points: [CGPoint] = []
        points.reserveCapacity(totalPoints)

        let a = params.distanceToCenter
        let bSafe = max(b, 0.0001)

        for i in 0..<totalPoints {
            let t = CGFloat(i) / CGFloat(max(totalPoints - 1, 1))
            let s = t * drawLength
            let sEffective = reverse ? (drawLength - s) : s

            let theta = SpiralMath.theta(fromArcLength: sEffective, a: a, b: bSafe)
            let p = SpiralMath.point(center: center, a: a, b: bSafe, theta: theta)
            points.append(p)
        }

        if let first = points.first {
            path.move(to: first)
            path.addLines(Array(points.dropFirst()))
        }

        return path
    }
}
