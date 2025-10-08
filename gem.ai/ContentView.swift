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
    let numberOfItems: Int = 200
    let distanceBetweenItems: CGFloat = 100
    let distanceBetweenCircles: CGFloat = 100
    let distanceToCenter: CGFloat = 80
    let circleSize: CGFloat = 90
    let centerCircleSize: CGFloat = 200
    @State private var minCurves: Int = 1
    @State private var pinchLevel: Int = 0

    // Computed dynamic values that change with pinchLevel
    private var dynamicCircleSize: CGFloat { circleSize + CGFloat(pinchLevel) * 10.0 }
    private var dynamicCenterCircleSize: CGFloat { centerCircleSize + CGFloat(pinchLevel) * 10.0 }
    private var dynamicDistanceToCenter: CGFloat { distanceToCenter + CGFloat(pinchLevel) * 10.0 }
    private var dynamicDistanceBetweenCircles: CGFloat { distanceBetweenCircles + CGFloat(pinchLevel) * 10.0 }
    private var dynamicDistanceBetweenItems: CGFloat { distanceBetweenItems + CGFloat(pinchLevel) * 10.0 }

    // Simplified Animation Presets
    enum AnimationPreset {
        case fast, medium, smooth, slow, highSensitivity
        
        var config: AnimationConfig {
            switch self {
            case .fast:
                return AnimationConfig(
                    sensitivity: 0.55,
                    response: 0.3,
                    dampingFraction: 0.7
                )
            case .medium:
                return AnimationConfig(
                    sensitivity: 0.4,
                    response: 0.4,
                    dampingFraction: 0.75
                )
            case .smooth:
                return AnimationConfig(
                    sensitivity: 0.35,
                    response: 0.5,
                    dampingFraction: 0.85
                )
            case .slow:
                return AnimationConfig(
                    sensitivity: 0.25,
                    response: 0.6,
                    dampingFraction: 0.9
                )
            case .highSensitivity:
                return AnimationConfig(
                    sensitivity: 0.7,
                    response: 0.25,
                    dampingFraction: 0.65
                )
            }
        }
    }
    
    struct AnimationConfig {
        let sensitivity: CGFloat      // How much translation affects offset
        let response: Double           // Spring response (lower = faster)
        let dampingFraction: Double    // Spring damping (higher = less bounce)
        
        var animation: Animation {
            .spring(response: response, dampingFraction: dampingFraction)
        }
    }

    private let animationPreset: AnimationPreset = .fast
    private var config: AnimationConfig { animationPreset.config }

    @State private var spiralOffset: CGFloat = 0
    @State private var dragTranslation: CGFloat = 0

    var body: some View {
        GeometryReader { geometry in
            ZStack {
                Color.gray.opacity(0.3).ignoresSafeArea()
                
                SpiralCarousel(
                    numberOfItems: numberOfItems,
                    distanceBetweenCircles: dynamicDistanceBetweenCircles,
                    distanceToCenter: dynamicDistanceToCenter,
                    circleSize: dynamicCircleSize,
                    centerCircleSize: dynamicCenterCircleSize,
                    spiralOffset: spiralOffset + dragTranslation,
                    distanceBetweenItems: dynamicDistanceBetweenItems,
                    minCurves: minCurves
                )
            }
            .gesture(
                DragGesture()
                    .onChanged { value in
                        let isHorizontal = abs(value.translation.width) > abs(value.translation.height)
                        
                        if isHorizontal && !disableHorizontalSwipe {
                            let sign: CGFloat = horizontalSwipeDirection == .leftToRight ? 1.0 : -1.0
                            dragTranslation = sign * value.translation.width * config.sensitivity
                        } else if !isHorizontal {
                            let sign: CGFloat = swipeDirection == .bottomToTop ? -1.0 : 1.0
                            dragTranslation = sign * value.translation.height * config.sensitivity
                        }
                    }
                    .onEnded { value in
                        let isHorizontal = abs(value.translation.width) > abs(value.translation.height)
                        let velocity: CGFloat
                        let translation: CGFloat
                        
                        if isHorizontal && !disableHorizontalSwipe {
                            let sign: CGFloat = horizontalSwipeDirection == .leftToRight ? 1.0 : -1.0
                            translation = value.translation.width
                            velocity = value.velocity.width
                            
                            let finalOffset = sign * (translation + velocity * 0.1) * config.sensitivity
                            
//                            withAnimation(config.animation) {
                                spiralOffset += finalOffset
                                dragTranslation = 0
//                            }
                        } else if !isHorizontal {
                            let sign: CGFloat = swipeDirection == .bottomToTop ? -1.0 : 1.0
                            translation = value.translation.height
                            velocity = value.velocity.height
                            
                            let finalOffset = sign * (translation + velocity * 0.1) * config.sensitivity
                            
//                            withAnimation(config.animation) {
                                spiralOffset += finalOffset
                                dragTranslation = 0
//                            }
                        } else {
                            dragTranslation = 0
                        }
                    }
            )
            .simultaneousGesture(
                MagnificationGesture()
                    .onEnded { scale in
                        let pinchInThreshold: CGFloat = 0.95
                        let pinchOutThreshold: CGFloat = 1.05
                        
                        if scale < pinchInThreshold {
//                            withAnimation(.bouncy) {
                                minCurves += 2
                                pinchLevel = max(-3, pinchLevel - 1)
//                            }
                        } else if scale > pinchOutThreshold {
//                            withAnimation(.bouncy) {
                                minCurves = max(1, minCurves - 2)
                                pinchLevel = min(3, pinchLevel + 1)
//                            }
                        }
                    }
            )
        }
    }
}

#Preview {
    ContentView()
}
