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

            // Use an explicit array from the indices when iterating to avoid ForEach overload ambiguity
            // (avoid accidentally matching the `Binding`-based ForEach initializer)
            let explicitIndices: [Int] = Array(generatedItems.indices)

            // Calculate adjusted arc-length for each item (0..totalS) so we can apply fade near 0/totalS wrap
            let totalS = CGFloat(max(1, numberOfItems)) * distanceBetweenItems

            // Fade range (how many points of arc-length near the center/start to fade). Tweak as needed.
            // Cover two items from the center so the closest items are faded to 0.
            // Using distanceBetweenItems ensures pinch-level tuning adjusts this range.
            let fadeRange = max(distanceBetweenItems * 2.0, distanceBetweenItems)

            // Precompute adjusted positions along the spiral and corresponding opacities to keep the ViewBuilder
            // closure free of non-View mutable statements (which can cause "() cannot conform to View").
            let adjustedS: [CGFloat] = generatedItems.indices.map { i in
                SpiralMath.posMod(CGFloat(i) * distanceBetweenItems + spiralOffset, totalS)
            }

            let opacities: [CGFloat] = adjustedS.map { adj in
                if adj <= fadeRange {
                    return max(0, adj / fadeRange)
                } else if adj >= totalS - fadeRange {
                    return max(0, (totalS - adj) / fadeRange)
                } else {
                    return 1
                }
            }

            ZStack {
                // Spiral guide path
                SpiralPath(
                    distanceToCenter: distanceToCenter,
                    distanceBetweenCircles: distanceBetweenCircles
                )
                .stroke(Color.white.opacity(0.4), lineWidth: 1)
                .drawingGroup() // GPU render optimization

                // Iterate over integer indices to avoid key-path issues with tuple types in ForEach
                ForEach(explicitIndices, id: \.self) { (i: Int) in
                    let item = generatedItems[i]
                    let opacity = opacities[i]

                    SpiralItemView(item: item, circleSize: circleSize)
                        .position(positions[i])
                        .opacity(Double(opacity))
                        .animation(.easeInOut(duration: 0.18), value: spiralOffset)
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
