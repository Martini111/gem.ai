import SwiftUI

struct SpiralCarousel: View {
    let numberOfItems: Int
    let distanceBetweenCircles: CGFloat
    let distanceToCenter: CGFloat
    let circleSize: CGFloat
    let centerCircleSize: CGFloat
    let spiralOffset: CGFloat
    let distanceBetweenItems: CGFloat
    let minCurves: Int

    var body: some View {
        GeometryReader { geometry in
            let center = CGPoint(x: geometry.size.width / 2, y: geometry.size.height / 2)

            ZStack {
                SpiralPath(
                    minCurves: minCurves,
                    distanceToCenter: distanceToCenter,
                    distanceBetweenCircles: distanceBetweenCircles,
                    numberOfItems: numberOfItems,
                    distanceBetweenItems: distanceBetweenItems
                )
                .stroke(Color.black.opacity(0.2), lineWidth: 2)

                ForEach(0..<numberOfItems, id: \.self) { index in
                    let position = spiralPosition(for: index, center: center)

                    Circle()
                        .fill(Color.blue)
                        .frame(width: circleSize, height: circleSize)
                        .position(position)
                }

                // Center circle
                Circle()
                    .fill(Color.red)
                    .frame(width: centerCircleSize, height: centerCircleSize)
                    .position(center)
            }
        }
    }

    private func spiralPosition(for index: Int, center: CGPoint) -> CGPoint {
        // Parameters for the Archimedean spiral
        let a = distanceToCenter
        let theta_total = CGFloat(minCurves) * 2 * .pi
        let maxRadius = distanceBetweenCircles * CGFloat(minCurves)
        let b = maxRadius / theta_total

        // Calculate the total path length for infinite looping
        let totalPathLength = CGFloat(numberOfItems) * distanceBetweenItems

        // Apply offset and ensure infinite looping
        let adjustedPosition = (CGFloat(index) * distanceBetweenItems + spiralOffset)
            .truncatingRemainder(dividingBy: totalPathLength)
        let s = adjustedPosition < 0 ? adjustedPosition + totalPathLength : adjustedPosition

        // Solve for theta: (b/2) * theta^2 + a * theta - s = 0
        let discriminant = a * a + 2 * b * s
        let theta = (-a + sqrt(discriminant)) / b

        // Calculate angle and radius
        let angle = theta
        let radius = distanceToCenter + b * theta

        let x = center.x + radius * cos(angle)
        let y = center.y + radius * sin(angle)

        return CGPoint(x: x, y: y)
    }
}
