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
    let numberOfItems: Int = 50
    let distanceBetweenItems: CGFloat = 100
    let distanceBetweenCircles: CGFloat = 100
    let distanceToCenter: CGFloat = 80 // radius at which first circle is placed
    let circleSize: CGFloat = 90
    let centerCircleSize: CGFloat = 200
    @State private var minCurves: Int = 1
    // Pinch/zoom levels: -3..3. Each level adjusts sizes by 10 points.
    @State private var pinchLevel: Int = 0

    // Computed dynamic values that change with pinchLevel
    private var dynamicCircleSize: CGFloat { circleSize + CGFloat(pinchLevel) * 10.0 }
    private var dynamicCenterCircleSize: CGFloat { centerCircleSize + CGFloat(pinchLevel) * 10.0 }
    private var dynamicDistanceToCenter: CGFloat { distanceToCenter + CGFloat(pinchLevel) * 10.0 }
    private var dynamicDistanceBetweenCircles: CGFloat { distanceBetweenCircles + CGFloat(pinchLevel) * 10.0 }
    private var dynamicDistanceBetweenItems: CGFloat { distanceBetweenItems + CGFloat(pinchLevel) * 10.0 }

    // Animation and gesture tuning
    // Animation presets — pick one by changing `animationPreset`
    enum AnimationPreset {
        case fast, medium, smooth, slow, highSensitivity
    }

    // Choose active preset here (no UI control added per request)
    private let animationPreset: AnimationPreset = .fast

    // Preset values (tweak these if you want different defaults)
    struct PresetConfig {
        let maxVelocityMultiplier: CGFloat
        let velocityDecayPerSecond: CGFloat
        let swipeSensitivity: CGFloat

        static let fast = PresetConfig(maxVelocityMultiplier: 24.0, velocityDecayPerSecond: 6.0, swipeSensitivity: 0.42)
        static let medium = PresetConfig(maxVelocityMultiplier: 12.0, velocityDecayPerSecond: 3.0, swipeSensitivity: 0.25)
        static let smooth = PresetConfig(maxVelocityMultiplier: 10.0, velocityDecayPerSecond: 0.8, swipeSensitivity: 0.22)
        static let slow = PresetConfig(maxVelocityMultiplier: 6.0, velocityDecayPerSecond: 8.0, swipeSensitivity: 0.16)
        static let highSensitivity = PresetConfig(maxVelocityMultiplier: 32.0, velocityDecayPerSecond: 2.0, swipeSensitivity: 0.6)
    }

    private var currentPreset: PresetConfig {
        switch animationPreset {
        case .fast: return .fast
        case .medium: return .medium
        case .smooth: return .smooth
        case .slow: return .slow
        case .highSensitivity: return .highSensitivity
        }
    }

    // Expose the actual tuning values used by the logic below
    var maxVelocityMultiplier: CGFloat { currentPreset.maxVelocityMultiplier }
    var velocityDecayPerSecond: CGFloat { currentPreset.velocityDecayPerSecond }
    var swipeSensitivity: CGFloat { currentPreset.swipeSensitivity }

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
                        distanceBetweenCircles: dynamicDistanceBetweenCircles,
                        distanceToCenter: dynamicDistanceToCenter,
                        circleSize: dynamicCircleSize,
                        centerCircleSize: dynamicCenterCircleSize,
                        spiralOffset: spiralOffset + dragOffset,
                        distanceBetweenItems: dynamicDistanceBetweenItems,
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
                        let maxVel = maxVelocityMultiplier * dynamicDistanceBetweenItems
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
            // Add pinch (magnification) gesture alongside drag. Pinch IN (scale < 1) -> increase minCurves by 2.
            // Pinch OUT (scale > 1) -> decrease minCurves by 2. Use thresholds to avoid tiny accidental changes.
            .simultaneousGesture(
                MagnificationGesture()
                    .onEnded { scale in
                        let pinchInThreshold: CGFloat = 0.95
                        let pinchOutThreshold: CGFloat = 1.05
                        if scale < pinchInThreshold {
                            // Pinch in (fingers together) -> increase curves and reduce sizes
                            withAnimation(.bouncy) {
                                minCurves += 2
                                // decrease pinch level (more negative), clamp to -3
                                pinchLevel = max(-3, pinchLevel - 1)
                            }
                        } else if scale > pinchOutThreshold {
                            // Pinch out (fingers apart) -> decrease curves and increase sizes
                            withAnimation(.bouncy) {
                                minCurves = max(1, minCurves - 2)
                                // increase pinch level, clamp to +3
                                pinchLevel = min(3, pinchLevel + 1)
                            }
                        }
                    }
            )
        }
    }
}

#Preview {
    ContentView()
}
