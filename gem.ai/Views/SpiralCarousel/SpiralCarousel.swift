import SwiftUI
import UniformTypeIdentifiers

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

    // Dropped item for center circle
    @State private var centerItem: SpiralItem? = nil

    // Popup state: show transient popup when centerItem changes
    @State private var showCenterPopup: Bool = false
    @State private var popupMessage: String = ""

    // --- Drag & drop state ---
    @State private var draggingItem: SpiralItem? = nil
    @State private var dragStartPosition: CGPoint = .zero
    @State private var dragLocation: CGPoint = .zero
    @State private var showPreview: Bool = false

    // Optional callback to notify parent when an item was dropped into center
    var onItemDropped: ((SpiralItem) -> Void)? = nil

    init(
        numberOfItems: Int,
        distanceBetweenCircles: CGFloat,
        distanceToCenter: CGFloat,
        circleSize: CGFloat,
        centerCircleSize: CGFloat,
        effectiveSpiralOffset: CGFloat,
        distanceBetweenItems: CGFloat,
        minCurves: Int,
        spiralOffset: Binding<CGFloat>,
        onItemDropped: ((SpiralItem) -> Void)? = nil
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

        self.onItemDropped = onItemDropped
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

                    // Pass position and drag callbacks to the item view. The item view will not move;
                    // we create a separate preview that follows the finger.
                    SpiralItemView(
                        item: item,
                        circleSize: circleSize,
                        centerPosition: position,
                        onDragStart: { start in
                            // start is the item's center position in this coordinate space
                            draggingItem = item
                            dragStartPosition = start
                            dragLocation = start
                            // Inform parent that DnD started via notification
                            NotificationCenter.default.post(name: .spiralDragDidStart, object: nil)
                            withAnimation(.easeIn(duration: 0.12)) {
                                showPreview = true
                            }
                        },
                        onDragChanged: { translation in
                            // Update preview location relative to drag start
                            dragLocation = CGPoint(x: dragStartPosition.x + translation.width,
                                                   y: dragStartPosition.y + translation.height)
                        },
                        onDragEnd: { translation in
                            let final = CGPoint(x: dragStartPosition.x + translation.width,
                                                y: dragStartPosition.y + translation.height)
                            // Check if final point is inside center circle
                            let distanceToCenter = hypot(final.x - center.x, final.y - center.y)
                            if distanceToCenter <= centerCircleSize / 2 {
                                // Dropped on center
                                centerItem = item
                                onItemDropped?(item)
                            }
                            // Hide preview and clear state
                            withAnimation(.easeOut(duration: 0.18)) {
                                showPreview = false
                            }
                            // Delay clearing to allow fade-out animation
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.18) {
                                draggingItem = nil
                                // Inform parent that DnD ended via notification
                                NotificationCenter.default.post(name: .spiralDragDidEnd, object: nil)
                            }
                        }
                    )
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
                .onDrop(of: [UTType.text], isTargeted: nil) { providers in
                    guard let provider = providers.first else { return false }
                    provider.loadObject(ofClass: NSString.self) { object, error in
                        if let string = object as? String, let uuid = UUID(uuidString: string) {
                            DispatchQueue.main.async {
                                if let item = generatedItems.first(where: { $0.id == uuid }) {
                                    centerItem = item
                                }
                            }
                        }
                    }
                    return true
                }

                // Floating drag preview (renders above everything)
                if let dragging = draggingItem, showPreview {
                    SpiralItemPreviewView(item: dragging, size: circleSize * 0.95)
                        .position(dragLocation)
                        .shadow(radius: 6)
                        .transition(.opacity)
                        .animation(.easeInOut(duration: 0.12), value: showPreview)
                }

                // Popup that appears when an item is dropped to center
                if showCenterPopup {
                    VStack(spacing: 6) {
                        Text("Item dropped")
                            .font(.headline)
                            .foregroundColor(.white)
                        Text(popupMessage)
                            .font(.subheadline)
                            .foregroundColor(.white)
                            .multilineTextAlignment(.center)
                    }
                    .padding(12)
                    .background(Color.black.opacity(0.8))
                    .cornerRadius(10)
                    .shadow(radius: 6)
                    .position(x: center.x, y: 80)
                    .transition(.move(edge: .top).combined(with: .opacity))
                    .animation(.easeInOut(duration: 0.2), value: showCenterPopup)
                }
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
            // Show popup when centerItem changes (observe id to avoid requiring Equatable on SpiralItem)
            .onChange(of: centerItem?.id) { (_: UUID?, newID: UUID?) in
                guard let id = newID, let item = generatedItems.first(where: { $0.id == id }) else {
                    // hide if centerItem became nil
                    withAnimation {
                        showCenterPopup = false
                    }
                    return
                }

                // Build message with short id and type
                let shortID = String(item.id.uuidString.prefix(8))
                popupMessage = "ID: \(shortID)\nType: \(item.type.rawValue)"

                withAnimation {
                    showCenterPopup = true
                }

                // Auto-hide after a short delay
                DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) {
                    withAnimation {
                        showCenterPopup = false
                    }
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

extension Notification.Name {
    static let spiralDragDidStart = Notification.Name("SpiralCarousel.DragDidStart")
    static let spiralDragDidEnd = Notification.Name("SpiralCarousel.DragDidEnd")
}
