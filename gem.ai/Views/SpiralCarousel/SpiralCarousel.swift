import SwiftUI

// Safe index access to avoid out-of-bounds crashes
private extension Collection {
    subscript(safe index: Index) -> Element? {
        indices.contains(index) ? self[index] : nil
    }
}

/// Carousel that lays out items along an Archimedean spiral.
/// Optimized: uses `headIndex` instead of building a rotated `orderedIDs` array.
struct SpiralCarousel: View {
    let numberOfItems: Int
    let distanceBetweenCircles: CGFloat
    let distanceToCenter: CGFloat
    let circleSize: CGFloat
    let centerCircleSize: CGFloat
    let distanceBetweenItems: CGFloat

    @Binding var spiralOffset: CGFloat

    // Stable items with persistent UUIDs
    @State private var generatedItems: [SpiralItem]

    init(
        numberOfItems: Int,
        distanceBetweenCircles: CGFloat,
        distanceToCenter: CGFloat,
        circleSize: CGFloat,
        centerCircleSize: CGFloat,
        distanceBetweenItems: CGFloat,
        spiralOffset: Binding<CGFloat>
    ) {
        // Preconditions for safe initialization
        precondition(numberOfItems >= 0, "numberOfItems must be >= 0")
        precondition(distanceBetweenCircles >= 0 && distanceBetweenItems >= 0, "Distances must be non-negative")
        precondition(circleSize > 0 && centerCircleSize > 0, "Circle sizes must be positive")

        self.numberOfItems = numberOfItems
        self.distanceBetweenCircles = distanceBetweenCircles
        self.distanceToCenter = distanceToCenter
        self.circleSize = circleSize
        self.centerCircleSize = centerCircleSize
        self.distanceBetweenItems = distanceBetweenItems
        self._spiralOffset = spiralOffset

        // Initialize stable items once
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

            let currentItem: SpiralItem? = generatedItems[safe: tailIndex]

            // Pre-calculate positions to avoid redundant computations
            let positions: [CGPoint] = generatedItems.indices.map { i in
                spiralPosition(for: i, center: center)
            }

            ZStack {
                // Spiral guide path
                SpiralPath(
                    distanceToCenter: distanceToCenter,
                    distanceBetweenCircles: distanceBetweenCircles
                )
                .stroke(Color.white.opacity(0.4), lineWidth: 1)
                .drawingGroup() // GPU render optimization

                // Iterate over elements with stable IDs for better diffing
                ForEach(Array(generatedItems.enumerated()), id: \.element.id) { i, item in
                    SpiralItemView(item: item, circleSize: circleSize)
                        .position(positions[i])
                }

                SpiralCenterItemView(
                    currentItem: currentItem,
                    centerCircleSize: centerCircleSize
                )
                .position(center)
            }
        }
        .onChange(of: numberOfItems) { _, newCount in
            generatedItems = generateSpiralItems(count: newCount)
        }
    }

    /// Calculates the position of an item on the spiral using shared math utilities.
    private func spiralPosition(for index: Int, center: CGPoint) -> CGPoint {
        let params = SpiralParams(
            distanceToCenter: distanceToCenter,
            distanceBetweenCircles: distanceBetweenCircles
        )
        return SpiralMath.position(
            center: center,
            index: index,
            numberOfItems: numberOfItems,
            distanceBetweenItems: distanceBetweenItems,
            spiralOffset: spiralOffset,
            params: params
        )
    }
}
