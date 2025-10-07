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
    enum HorizontalSwipeDirection {
        case leftToRight
        case rightToLeft
    }
    let swipeDirection: SwipeDirection = .topToBottom
    let horizontalSwipeDirection: HorizontalSwipeDirection = .leftToRight
    let numberOfItems: Int = 15
    let distanceBetweenCircles: CGFloat = 100
    let distanceToCenter: CGFloat = 80 // radius at which first circle is placed
    let circleSize: CGFloat = 90
    let centerCircleSize: CGFloat = 200
    // Maximum velocity (points per second) to cap fast swipes
    let maxVelocityMultiplier: CGFloat = 40
    // velocity decay (per second) for momentum
    let velocityDecayPerSecond: CGFloat = 8.0
    let distanceBetweenItems: CGFloat = 100
    let minCurves: Int = 3
    let swipeSensitivity: CGFloat = 0.1

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
                        distanceToCenter: distanceToCenter,
                        circleSize: circleSize,
                        centerCircleSize: centerCircleSize,
                        spiralOffset: spiralOffset + dragOffset,
                        distanceBetweenItems: distanceBetweenItems,
                        minCurves: minCurves
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
                        let isHorizontal = abs(value.translation.width) > abs(value.translation.height)
                        if isHorizontal {
                            let horizontalSign: CGFloat = (horizontalSwipeDirection == .leftToRight) ? 1.0 : -1.0
                            // live movement should follow finger directly
                            state = horizontalSign * value.translation.width * swipeSensitivity
                        } else {
                            let verticalSign: CGFloat = (swipeDirection == .bottomToTop) ? -1.0 : 1.0
                            // live movement should follow finger directly
                            state = verticalSign * value.translation.height * swipeSensitivity
                        }
                    }
                    .onEnded { value in
                        let rawWidth = value.predictedEndTranslation.width != 0 ? value.predictedEndTranslation.width : value.translation.width
                        let rawHeight = value.predictedEndTranslation.height != 0 ? value.predictedEndTranslation.height : value.translation.height
                        let isHorizontal = abs(rawWidth) > abs(rawHeight)
                        var delta: CGFloat = 0
                        if isHorizontal {
                            let horizontalSign: CGFloat = (horizontalSwipeDirection == .leftToRight) ? 1.0 : -1.0
                            // prefer predicted end translation for momentum feel
                            delta = horizontalSign * rawWidth * swipeSensitivity
                        } else {
                            let verticalSign: CGFloat = (swipeDirection == .bottomToTop) ? -1.0 : 1.0
                            // prefer predicted end translation for momentum feel
                            delta = verticalSign * rawHeight * swipeSensitivity
                        }

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
    }
}

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
                // Static spiral lines
                SpiralPath(
                    minCurves: minCurves,
                    distanceToCenter: distanceToCenter,
                    distanceBetweenCircles: distanceBetweenCircles,
                    numberOfItems: numberOfItems,
                    distanceBetweenItems: distanceBetweenItems
                )
                .stroke(Color.black.opacity(0.2), lineWidth: 2)
                
                
                
                // Moving circles
                ForEach(0..<numberOfItems, id: \.self) { index in
                    let position = spiralPosition(for: index, center: center)
                    
                    Circle()
                        .fill(Color.blue)
                        .frame(width: circleSize, height: circleSize)
                        .position(position)
                    
                // Center circle
                Circle()
                    .fill(Color.gray)
                    .frame(width: centerCircleSize, height: centerCircleSize)
                    .position(center)
                }
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
        let totalPoints = 100000 // More points for smoother spiral
        
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

#Preview {
    ContentView()
}
