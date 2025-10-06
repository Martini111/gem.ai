//
//  ContentView.swift
//  gem.ai
//
//  Created by Oleh Martyn on 04/10/2025.
//

import SwiftUI

struct ContentView: View {
    // Configuration variables
    enum SwipeDirection {
        case bottomToTop
        case topToBottom
    }
    let swipeDirection: SwipeDirection = .bottomToTop
    let numberOfItems: Int = 20
    let distanceBetweenCircles: CGFloat = 5
    let numberOfSpiralCurves: Int = 3
    let distanceToCenter: CGFloat = 60 // radius at which first circle is placed
    let circleSize: CGFloat = 30
    let centerCircleSize: CGFloat = 60
    // Maximum velocity (points per second) to cap fast swipes
    let maxVelocityMultiplier: CGFloat = 40 // multiplied by distanceBetweenCircles
    // velocity decay (per second) for momentum
    let velocityDecayPerSecond: CGFloat = 6.0

    @State private var spiralOffset: CGFloat = 0
    @GestureState private var dragOffset: CGFloat = 0

    // Momentum state
    @State private var velocity: CGFloat = 0
    @State private var lastUpdateDate: Date? = nil

    var body: some View {
        GeometryReader { geometry in
            ZStack {
                Color.gray.opacity(0.3).ignoresSafeArea()
                // Use TimelineView to drive momentum and smooth updates
                TimelineView(.animation) { timeline in
                    // Spiral carousel - properly centered
                    SpiralCarousel(
                        numberOfItems: numberOfItems,
                        distanceBetweenCircles: distanceBetweenCircles,
                        numberOfSpiralCurves: numberOfSpiralCurves,
                        distanceToCenter: distanceToCenter,
                        circleSize: circleSize,
                        centerCircleSize: centerCircleSize,
                        spiralOffset: spiralOffset + dragOffset
                    )
                    // Update momentum on each timeline tick
                    .onChange(of: timeline.date) { _, now in
                        if let last = lastUpdateDate {
                            let dt = now.timeIntervalSince(last)
                            if dt > 0 {
                                if velocity != 0 {
                                    spiralOffset += velocity * CGFloat(dt)
                                    let decay = exp(-velocityDecayPerSecond * CGFloat(dt))
                                    velocity *= decay
                                    if abs(velocity) < 1 {
                                        velocity = 0
                                    }
                                }
                            }
                        }
                        lastUpdateDate = now
                    }
                }
            }.gesture(
                DragGesture()
                    .updating($dragOffset) { value, state, _ in
                        // Stop any ongoing momentum while user is dragging
                        velocity = 0
                        let verticalSign: CGFloat = (swipeDirection == .bottomToTop) ? -1.0 : 1.0
                        // live movement should follow finger directly
                        state = verticalSign * value.translation.height * 3.0
                    }
                    .onEnded { value in
                        let verticalSign: CGFloat = (swipeDirection == .bottomToTop) ? -1.0 : 1.0
                        // prefer predicted end translation for momentum feel
                        let rawTranslation = value.predictedEndTranslation.height != 0 ? value.predictedEndTranslation.height : value.translation.height
                        let delta = verticalSign * rawTranslation * 3.0

                        // Convert delta into a starting velocity (points/sec). Use a short predicted timeframe
                        // predictedEndTranslation often represents displacement over ~0.1-0.2s, but to be safe we scale
                        var initialVelocity = delta * 10.0

                        // Clamp velocity so very quick swipes won't move items too fast
                        let maxVel = maxVelocityMultiplier * distanceBetweenCircles
                        if initialVelocity > maxVel { initialVelocity = maxVel }
                        if initialVelocity < -maxVel { initialVelocity = -maxVel }

                        // If velocity is very small, just apply delta immediately and don't start momentum
                        if abs(initialVelocity) < 5 {
                            spiralOffset += delta
                            velocity = 0
                        } else {
                            // start momentum
                            velocity = initialVelocity
                        }
                    }
            )
        }
        .ignoresSafeArea()
    }
}

struct SpiralCarousel: View {
    let numberOfItems: Int
    let distanceBetweenCircles: CGFloat
    let numberOfSpiralCurves: Int
    let distanceToCenter: CGFloat
    let circleSize: CGFloat
    let centerCircleSize: CGFloat
    let spiralOffset: CGFloat
    
    var body: some View {
        GeometryReader { geometry in
            let center = CGPoint(x: geometry.size.width / 2, y: geometry.size.height / 2)
            
            ZStack {
                // Static spiral lines
                SpiralPath(
                    numberOfCurves: numberOfSpiralCurves,
                    distanceToCenter: distanceToCenter,
                    distanceBetweenCircles: distanceBetweenCircles,
                    numberOfItems: numberOfItems
                )
                .stroke(Color.black.opacity(0.2), lineWidth: 2)
                
                // Center circle
                Circle()
                    .fill(Color.red)
                    .frame(width: centerCircleSize, height: centerCircleSize)
                    .position(center)
                
                // Moving circles
                ForEach(0..<numberOfItems, id: \.self) { index in
                    let position = spiralPosition(for: index, center: center)
                    
                    Circle()
                        .fill(Color.blue)
                        .frame(width: circleSize, height: circleSize)
                        .position(position)
                }
            }
        }
    }
    
    private func spiralPosition(for index: Int, center: CGPoint) -> CGPoint {
        // Calculate the total path length for infinite looping
        let totalPathLength = CGFloat(numberOfItems) * distanceBetweenCircles
        
        // Apply offset and ensure infinite looping
        let adjustedPosition = (CGFloat(index) * distanceBetweenCircles + spiralOffset)
            .truncatingRemainder(dividingBy: totalPathLength)
        let normalizedPosition = adjustedPosition < 0 ? adjustedPosition + totalPathLength : adjustedPosition
        
        // Calculate progress from 0 to 1
        let progress = normalizedPosition / totalPathLength
        
        // Archimedean spiral: r = a + b*θ
        let rotationsPerSpiral = CGFloat(numberOfSpiralCurves)
        let angle = progress * rotationsPerSpiral * 2 * .pi
        
        // Fixed radius calculation for better centering
        let maxRadius: CGFloat = 150
        let radius = distanceToCenter + (progress * maxRadius)
        
        let x = center.x + radius * cos(angle)
        let y = center.y + radius * sin(angle)
        
        return CGPoint(x: x, y: y)
    }
}

struct SpiralPath: Shape {
    let numberOfCurves: Int
    let distanceToCenter: CGFloat
    let distanceBetweenCircles: CGFloat
    let numberOfItems: Int
    
    func path(in rect: CGRect) -> Path {
        var path = Path()
        let center = CGPoint(x: rect.width / 2, y: rect.height / 2)
        
        // Create smooth spiral path with many points
        let totalPoints = 300 // More points for smoother spiral
        let rotationsPerSpiral = CGFloat(numberOfCurves)
        let maxRadius: CGFloat = 150 // Match the circle positioning
        
        for i in 0..<totalPoints {
            let progress = CGFloat(i) / CGFloat(totalPoints - 1)
            
            // Archimedean spiral formula
            let angle = progress * rotationsPerSpiral * 2 * .pi
            let radius = distanceToCenter + (progress * maxRadius)
            
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

#Preview {
    ContentView()
}
