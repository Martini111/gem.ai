import SwiftUI

struct SpiralPath: Shape {
    let minCurves: Int
    let distanceToCenter: CGFloat
    let distanceBetweenCircles: CGFloat
    let numberOfItems: Int
    let distanceBetweenItems: CGFloat

    func path(in rect: CGRect) -> Path {
        var path = Path()
        let center = CGPoint(x: rect.width / 2, y: rect.height / 2)

        // Parameters for the Archimedean spiral
        let a = distanceToCenter
        let theta_total = CGFloat(minCurves) * 2 * .pi
        let maxRadius = distanceBetweenCircles * CGFloat(minCurves)
        let b = maxRadius / theta_total
        let totalPathLength = CGFloat(numberOfItems) * distanceBetweenItems

        // Ensure at least 3 curves are displayed
        let minTheta = CGFloat(minCurves) * 2 * .pi
        let minS = (b / 2) * minTheta * minTheta + a * minTheta
        let drawLength = max(totalPathLength, minS)

        // Create smooth spiral path with many points
        // Adaptive sampling: pick number of points based on the length we need to draw
        // This keeps the curve smooth but avoids extremely large arrays on big draw lengths.
        let targetPointSpacing: CGFloat = 2.0 // desired spacing between points (in points/pixels)
        let estimatedPoints = max(Int((drawLength / targetPointSpacing).rounded()), 200)
        let maxPoints = 5000 // upper bound to avoid heavy CPU/GPU work
        let totalPoints = min(estimatedPoints, maxPoints)

        for i in 0..<totalPoints {
            let s = (CGFloat(i) / CGFloat(totalPoints - 1)) * drawLength
            let reversedS = drawLength - s

            // Solve for theta: (b/2) * theta^2 + a * theta - reversedS = 0
            let discriminant = a * a + 2 * b * reversedS
            let theta = (-a + sqrt(discriminant)) / b

            // Calculate angle and radius
            let angle = theta
            let radius = distanceToCenter + b * theta

            let x = center.x + radius * cos(angle)
            let y = center.y + radius * sin(angle)

            if i == 0 {
                path.move(to: CGPoint(x: x, y: y))
            } else {
                path.addLine(to: CGPoint(x: x, y: y))
            }
        }

        return path
    }
}
