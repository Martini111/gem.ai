import SwiftUI

struct SpiralCarousel: View {
    let numberOfItems: Int
    let distanceBetweenCircles: CGFloat
    let distanceToCenter: CGFloat
    let circleSize: CGFloat
    let centerCircleSize: CGFloat
    let effectiveSpiralOffset: CGFloat
    let distanceBetweenItems: CGFloat
    let minCurves: Int
    @Binding var spiralOffset: CGFloat

    // Store generated items so their ids are stable across view updates
    @State private var generatedItems: [SpiralItem]

    // New state requested by user: ordered IDs from first on spiral (outer) to last (center)
    @State private var orderedIDS: [UUID] = []

    // Keep last center index to detect when an item reaches the center
    @State private var lastCenterIndex: Int? = nil

    init(
        numberOfItems: Int,
        distanceBetweenCircles: CGFloat,
        distanceToCenter: CGFloat,
        circleSize: CGFloat,
        centerCircleSize: CGFloat,
        effectiveSpiralOffset: CGFloat,
        distanceBetweenItems: CGFloat,
        minCurves: Int,
        spiralOffset: Binding<CGFloat>
    ) {
        self.numberOfItems = numberOfItems
        self.distanceBetweenCircles = distanceBetweenCircles
        self.distanceToCenter = distanceToCenter
        self.circleSize = circleSize
        self.centerCircleSize = centerCircleSize
        self.effectiveSpiralOffset = effectiveSpiralOffset
        self.distanceBetweenItems = distanceBetweenItems
        self.minCurves = minCurves
        self._spiralOffset = spiralOffset

        // Initialize state-backed items with stable UUIDs
        _generatedItems = State(initialValue: generateSpiralItems(count: numberOfItems))
        // Initial ordered IDS will be set onAppear (geometry available) — keep empty for now
        _orderedIDS = State(initialValue: _generatedItems.wrappedValue.map { $0.id })
    }

    var body: some View {
        GeometryReader { geometry in
            let center = CGPoint(x: geometry.size.width / 2, y: geometry.size.height / 2)
            let totalPathLength = CGFloat(numberOfItems) * distanceBetweenItems
            let temp = floor((totalPathLength - spiralOffset) / distanceBetweenItems)
            let centerIndex = ((Int(temp) % numberOfItems) + numberOfItems) % numberOfItems

            ZStack {
                SpiralPath(
                    minCurves: minCurves,
                    distanceToCenter: distanceToCenter,
                    distanceBetweenCircles: distanceBetweenCircles,
                    numberOfItems: numberOfItems,
                    distanceBetweenItems: distanceBetweenItems
                )
                .stroke(Color.white.opacity(0.4), lineWidth: 1)

                ForEach($generatedItems, id: \.id) { $item in
                    let item = $item.wrappedValue
                    let index = generatedItems.firstIndex(where: { $0.id == item.id })!
                    let position = spiralPosition(for: index, center: center)

                    let isEndEdge = (orderedIDS.last == item.id)
                    let isStartEdge = (orderedIDS.first == item.id)

                    let opacity = isStartEdge ? 0.8 : isEndEdge ? 0.0 : 1.0

                    SpiralItemView(
                        item: item,
                        circleSize: circleSize
                    )
                    .position(position)
                    .opacity(opacity)
                    .animation(.easeInOut(duration: 0), value: orderedIDS)
                }

                // Center circle moved to its own view file
                SpiralCenterItemView(
                    orderedIDS: orderedIDS,
                    generatedItems: generatedItems,
                    centerCircleSize: centerCircleSize
                )
                .position(center)

            }
            // When the view appears, compute initial ordering
            .onAppear {
                updateOrderedIDs(spiralOffset: spiralOffset)
                lastCenterIndex = centerIndex
            }
            // Update ordered IDs when center index changes — this indicates an item reached the end/center
            .onChange(of: centerIndex) { _, newCenter in
                // Only update when actual change occurs
                if lastCenterIndex != newCenter {
                    lastCenterIndex = newCenter
                    updateOrderedIDs(spiralOffset: spiralOffset)
                }
            }
        }
    }

    // iOS 18 compatible and optimized: rotate a base array of IDs instead of sorting every time
    private func updateOrderedIDs(spiralOffset: CGFloat) {
        let n = numberOfItems
        guard n > 0 else {
            orderedIDS = []
            return
        }

        // Base order of IDs (stable)
        let baseIDs: [UUID] = generatedItems.map { $0.id }

        // Compute start index by modular arithmetic so that order matches the previous sort-by-s logic.
        // We normalize (total - offset) to [0, total), then take ceiling to pick the first index on the path,
        // and rotate the base array so the last element corresponds to the item at the path end (center).
        let total = CGFloat(n) * distanceBetweenItems
        var norm = (total - spiralOffset).truncatingRemainder(dividingBy: total)
        if norm < 0 { norm += total }

        let start = ((Int(ceil(norm / distanceBetweenItems)) % n) + n) % n

        // Rotate baseIDs so that the sequence starts at `start`
        let rotated: [UUID]
        if start == 0 {
            rotated = baseIDs
        } else {
            rotated = Array(baseIDs[start..<n]) + Array(baseIDs[0..<start])
        }

        // Assign on main thread to avoid SwiftUI warnings when called from view updates
        DispatchQueue.main.async {
            self.orderedIDS = rotated
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
