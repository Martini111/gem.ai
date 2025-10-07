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
    let disableHorizontalSwipe: Bool = false
    let numberOfItems: Int = 15
    let distanceBetweenItems: CGFloat = 100
    let distanceBetweenCircles: CGFloat = 100
    let distanceToCenter: CGFloat = 80 // radius at which first circle is placed
    let circleSize: CGFloat = 90
    let centerCircleSize: CGFloat = 200
    let minCurves: Int = 3
    
    // Animation and gesture tuning
    // Maximum velocity (points per second) to cap fast swipes
    let maxVelocityMultiplier: CGFloat = 40
    // velocity decay (per second) for momentum
    let velocityDecayPerSecond: CGFloat = 8.0
    let swipeSensitivity: CGFloat = 0.3

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
                        if isHorizontal && !disableHorizontalSwipe {
                            let horizontalSign: CGFloat = (horizontalSwipeDirection == .leftToRight) ? 1.0 : -1.0
                            // live movement should follow finger directly
                            state = horizontalSign * value.translation.width * swipeSensitivity
                        } else if !isHorizontal {
                            let verticalSign: CGFloat = (swipeDirection == .bottomToTop) ? -1.0 : 1.0
                            // live movement should follow finger directly
                            state = verticalSign * value.translation.height * swipeSensitivity
                        } else {
                            // Horizontal swipe disabled, no movement
                            state = 0
                        }
                    }
                    .onEnded { value in
                        let rawWidth = value.predictedEndTranslation.width != 0 ? value.predictedEndTranslation.width : value.translation.width
                        let rawHeight = value.predictedEndTranslation.height != 0 ? value.predictedEndTranslation.height : value.translation.height
                        let isHorizontal = abs(rawWidth) > abs(rawHeight)
                        var delta: CGFloat = 0
                        if isHorizontal && !disableHorizontalSwipe {
                            let horizontalSign: CGFloat = (horizontalSwipeDirection == .leftToRight) ? 1.0 : -1.0
                            // prefer predicted end translation for momentum feel
                            delta = horizontalSign * rawWidth * swipeSensitivity
                        } else if !isHorizontal {
                            let verticalSign: CGFloat = (swipeDirection == .bottomToTop) ? -1.0 : 1.0
                            // prefer predicted end translation for momentum feel
                            delta = verticalSign * rawHeight * swipeSensitivity
                        } else {
                            // Horizontal swipe disabled, no delta
                            delta = 0
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

#Preview {
    ContentView()
}
