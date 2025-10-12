import SwiftUI

/// Carousel that lays out items along an Archimedean spiral.
/// Optimized: uses `headIndex` instead of building a rotated `orderedIDS` array.
struct SpiralCarousel: View {
    let numberOfItems: Int
    let distanceBetweenCircles: CGFloat
    let distanceToCenter: CGFloat
    let circleSize: CGFloat
    let centerCircleSize: CGFloat
    let distanceBetweenItems: CGFloat
    let minCurves: Int   // kept for compatibility if used by other parts

    @Binding var spiralOffset: CGFloat

    // Stable items with persistent UUIDs
    @State private var generatedItems: [SpiralItem]

    // No persistent headIndex needed — centerIndex is computed from spiralOffset

    init(
        numberOfItems: Int,
        distanceBetweenCircles: CGFloat,
        distanceToCenter: CGFloat,
        circleSize: CGFloat,
        centerCircleSize: CGFloat,
        distanceBetweenItems: CGFloat,
        minCurves: Int,
        spiralOffset: Binding<CGFloat>
    ) {
        self.numberOfItems = numberOfItems
        self.distanceBetweenCircles = distanceBetweenCircles
        self.distanceToCenter = distanceToCenter
        self.circleSize = circleSize
        self.centerCircleSize = centerCircleSize
        self.distanceBetweenItems = distanceBetweenItems
        self.minCurves = minCurves
        self._spiralOffset = spiralOffset

        // Initialize stable items
        _generatedItems = State(initialValue: generateSpiralItems(count: numberOfItems))
    }

    var body: some View {
        GeometryReader { geometry in
            let center = CGPoint(x: geometry.size.width / 2, y: geometry.size.height / 2)
            
            let tailIndex = SpiralMath.tailIndex(
                numberOfItems: numberOfItems,
                distanceBetweenItems: distanceBetweenItems,
                spiralOffset: spiralOffset
            )
            
            let currentItem: SpiralItem? = generatedItems.indices.contains(tailIndex)
                ? generatedItems[tailIndex]
                : nil

            ZStack {
                // Spiral guide path
                SpiralPath(
                    distanceToCenter: distanceToCenter,
                    distanceBetweenCircles: distanceBetweenCircles
                )
                .stroke(Color.white.opacity(0.4), lineWidth: 1)


                ForEach(generatedItems.indices, id: \.self) { i in
                    let item = generatedItems[i]
                    let position = spiralPosition(for: i, center: center)


                    SpiralItemView(item: item, circleSize: circleSize)
                        .position(position)
                }
                

                SpiralCenterItemView(
                    currentItem: currentItem,
                    centerCircleSize: centerCircleSize
                )
                .position(center)
             }
         }
     }

    /// Position of item on the spiral using shared math utilities.
    private func spiralPosition(for index: Int, center: CGPoint) -> CGPoint {
        let params = SpiralParams(
            distanceToCenter: distanceToCenter,
            distanceBetweenCircles: distanceBetweenCircles
        )
        return SpiralMath.position(center: center,
           index: index,
           numberOfItems: numberOfItems,
           distanceBetweenItems: distanceBetweenItems,
           spiralOffset: spiralOffset,
           params: params
        )
    }
}
