import SwiftUI

/// Archimedean spiral path with adaptive sampling and animatable parameters.
struct SpiralPath: Shape {
    // Public parameters (vars to support animation)
    var curves: Int = 10
    var distanceToCenter: CGFloat
    var distanceBetweenCircles: CGFloat
    var numberOfItems: Int
    var distanceBetweenItems: CGFloat

    /// Draw from the outermost point toward the center when true
    var reverse: Bool = true

    // Animatable support - animate core CGFloats. For Int curves and item count we use CGFloat proxies.
    var animatableData: AnimatablePair<
        AnimatablePair<CGFloat, CGFloat>, // distanceToCenter, distanceBetweenCircles
        AnimatablePair<CGFloat, CGFloat>  // numberOfItemsProxy, distanceBetweenItems
    > {
        get {
            AnimatablePair(
                AnimatablePair(distanceToCenter, distanceBetweenCircles),
                AnimatablePair(CGFloat(numberOfItems), distanceBetweenItems)
            )
        }
        set {
            distanceToCenter = newValue.first.first
            distanceBetweenCircles = newValue.first.second
            numberOfItems = max(1, Int(newValue.second.first.rounded()))
            distanceBetweenItems = newValue.second.second
        }
    }

    func path(in rect: CGRect) -> Path {
        var path = Path()
        guard curves > 0 else { return path }

        let center = CGPoint(x: rect.midX, y: rect.midY)

        // Archimedean spiral: r = a + b * theta
        let a = distanceToCenter
        let thetaTotal = CGFloat(curves) * 2 * .pi
        let maxRadius = distanceBetweenCircles * CGFloat(curves)
        let b = maxRadius / max(thetaTotal, .leastNonzeroMagnitude)

        // Target path length coming from items spacing
        let totalPathLength = max(0, CGFloat(numberOfItems)) * max(distanceBetweenItems, 0)

        // Ensure at least the full number of curves is drawn
        let minS = (b / 2) * thetaTotal * thetaTotal + a * thetaTotal
        let drawLength = max(totalPathLength, minS)

        // Adaptive sampling - keep smoothness while avoiding huge arrays
        let targetPointSpacing: CGFloat = 2.0
        let estimatedPoints = max(Int((drawLength / max(targetPointSpacing, 0.25)).rounded()), 200)
        let clampedPoints = min(estimatedPoints, 5000)

        var points: [CGPoint] = []
        points.reserveCapacity(clampedPoints)

        for i in 0..<clampedPoints {
            // s in [0, drawLength]
            let t = CGFloat(i) / CGFloat(max(clampedPoints - 1, 1))
            let s = t * drawLength
            let sEffective = reverse ? (drawLength - s) : s

            // Solve (b/2) * theta^2 + a * theta - sEffective = 0
            let disc = max(0, a * a + 2 * b * sEffective)
            let theta = (-a + sqrt(disc)) / max(b, 0.0001)

            let r = a + b * theta
            let angle = theta

            let x = center.x + r * cos(angle)
            let y = center.y + r * sin(angle)
            points.append(CGPoint(x: x, y: y))
        }

        if let first = points.first {
            path.move(to: first)
            path.addLines(Array(points.dropFirst())) // convert ArraySlice to Array
        }

        return path
    }
}
