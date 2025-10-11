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

    // Logical start of the circular order (outer -> ... -> center)
    @State private var headIndex: Int = 0

    // Last center index to detect threshold crossing
    @State private var lastCenterIndex: Int? = nil

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

            // Compute current center index using shared math
            let centerIndex = SpiralMath.centerIndex(
                numberOfItems: numberOfItems,
                distanceBetweenItems: distanceBetweenItems,
                spiralOffset: spiralOffset
            )

            ZStack {
                // Spiral guide path
                SpiralPath(
                    distanceToCenter: distanceToCenter,
                    distanceBetweenCircles: distanceBetweenCircles
                )
                .stroke(Color.white.opacity(0.4), lineWidth: 1)

                // Place items - iterate by indices for O(1) access
                ForEach(generatedItems.indices, id: \.self) { i in
                    let item = generatedItems[i]
                    let position = spiralPosition(for: i, center: center)


                    SpiralItemView(item: item, circleSize: circleSize)
                        .position(position)
                }

                // Center item remains at the center
                SpiralCenterItemView(
                    // For the center content you may still want the full arrays; if not needed, refactor accordingly.
                    orderedIDS: generatedItems.map { $0.id }, // placeholder compatibility
                    generatedItems: generatedItems,
                    centerCircleSize: centerCircleSize
                )
                .position(center)
            }
            .onAppear {
                updateHeadIndex(spiralOffset: spiralOffset)
                lastCenterIndex = centerIndex
            }
            .onChange(of: centerIndex) { _, newCenter in
                if lastCenterIndex != newCenter {
                    lastCenterIndex = newCenter
                    updateHeadIndex(spiralOffset: spiralOffset)
                }
            }
        }
    }

    /// Update the logical head index based on current offset.
    private func updateHeadIndex(spiralOffset: CGFloat) {
        let n = numberOfItems
        guard n > 0 else {
            headIndex = 0
            return
        }
        // Align head with the computed start so that the last logical item corresponds to the center.
        let start = SpiralMath.centerIndex(
            numberOfItems: n,
            distanceBetweenItems: distanceBetweenItems,
            spiralOffset: spiralOffset
        )
        headIndex = start
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
