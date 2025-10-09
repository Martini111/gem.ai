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
        spiralOffset: CGFloat,
        distanceBetweenItems: CGFloat,
        minCurves: Int
    ) {
        self.numberOfItems = numberOfItems
        self.distanceBetweenCircles = distanceBetweenCircles
        self.distanceToCenter = distanceToCenter
        self.circleSize = circleSize
        self.centerCircleSize = centerCircleSize
        self.spiralOffset = spiralOffset
        self.distanceBetweenItems = distanceBetweenItems
        self.minCurves = minCurves

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

                // Кружечки на спіралі
                ForEach($generatedItems, id: \.id) { $item in
                    let item = $item.wrappedValue
                    let index = generatedItems.firstIndex(where: { $0.id == item.id })!
                    let position = spiralPosition(for: index, center: center)
                    
                    let isEndEdge = (orderedIDS.last == item.id)
                    let isStartEdge = (orderedIDS.first == item.id)

                    let opacity = isStartEdge ? 0.8 : isEndEdge ? 0.0 : 1.0

                    return SpiralItemView(item: item, circleSize: circleSize)
                    .position(position)
                    .opacity(opacity)
                    .animation(.easeInOut(duration: 0), value: orderedIDS)
                }

                // Center circle
                ZStack {
                    let curIdx = orderedIDS.last
                    let curItem = generatedItems.first(where: { $0.id == curIdx })
                    Circle()
                        .fill(curItem?.color ?? Color.blue)
                        .frame(width: centerCircleSize, height: centerCircleSize)
                    Text(curItem?.id.uuidString.prefix(4) ?? "")
                        .foregroundColor(.white)
                        .font(.system(size: centerCircleSize / 4))
                }
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

    private func updateOrderedIDs(spiralOffset: CGFloat) {
        // Compute the path position 's' for each item index, then sort by it so first element
        // corresponds to the start of the spiral and last is the center.
        let totalPathLength = CGFloat(numberOfItems) * distanceBetweenItems

        var indexedS: [(index: Int, s: CGFloat)] = []
        for i in 0..<numberOfItems {
            let adjustedPosition = (CGFloat(i) * distanceBetweenItems + spiralOffset)
                .truncatingRemainder(dividingBy: totalPathLength)
            let s = adjustedPosition < 0 ? adjustedPosition + totalPathLength : adjustedPosition
            indexedS.append((index: i, s: s))
        }

        // Sort by s ascending. This yields order along the spiral path. The last element will be
        // the one closest to the end of the path (center).
        indexedS.sort { $0.s < $1.s }

        // Map to IDs. If generatedItems changed size for any reason, guard indexes.
        let ids: [UUID] = indexedS.compactMap { pair in
            guard pair.index >= 0 && pair.index < generatedItems.count else { return nil }
            return generatedItems[pair.index].id
        }

        // Assign on main thread to avoid SwiftUI warnings when called from view updates
        DispatchQueue.main.async {
            self.orderedIDS = ids
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
