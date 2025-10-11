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

    // Removed horizontal swipe enums/flags — only vertical swipe is supported now.
    let swipeDirection: SwipeDirection = .topToBottom
    let numberOfItems: Int = 120
    let distanceBetweenItems: CGFloat = 120
    let distanceBetweenCircles: CGFloat = 120
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

    // Animation configuration: configure only these three values
    private let sensitivity: CGFloat = 0.3       // How much translation affects offset
    private let response: Double = 0.5           // Spring response (lower = faster)
    private let dampingFraction: Double = 0.7    // Spring damping (higher = less bounce)

    private var animation: Animation {
        .spring(response: response, dampingFraction: dampingFraction)
    }

    @State private var spiralOffset: CGFloat = 0

    // Track swipe session so movement is immediate and smooth
    @State private var swipeBegan: Bool = false
    @State private var swipeStartOffset: CGFloat = 0

    var body: some View {
        GeometryReader { geometry in
            ZStack {
                Color("BGColor").ignoresSafeArea()

                SpiralCarousel(
                    numberOfItems: numberOfItems,
                    distanceBetweenCircles: dynamicDistanceBetweenCircles,
                    distanceToCenter: dynamicDistanceToCenter,
                    circleSize: dynamicCircleSize,
                    centerCircleSize: dynamicCenterCircleSize,
                    distanceBetweenItems: dynamicDistanceBetweenItems,
                    minCurves: minCurves,
                    spiralOffset: $spiralOffset
                )
            }
            .simultaneousGesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { value in
                        // Lock the starting offset once
                        if (!swipeBegan) {
                            swipeBegan = true
                            swipeStartOffset = spiralOffset
                        }

                        // Always treat drag as vertical for offset calculation
                        let sign: CGFloat = swipeDirection == .bottomToTop ? -1.0 : 1.0
                        spiralOffset = swipeStartOffset + sign * value.translation.height * sensitivity
                    }
                    .onEnded { value in
                        let sign: CGFloat = swipeDirection == .bottomToTop ? -1.0 : 1.0
                        let velocity: CGFloat = value.velocity.height
                        let flick = sign * velocity * 0.1 * sensitivity
                        withAnimation(animation) {
                            spiralOffset += flick
                        }

                        // Reset transient state
                        swipeBegan = false
                    }
            )
            .simultaneousGesture(
                MagnificationGesture()
                    .onEnded { scale in
                        let pinchInThreshold: CGFloat = 0.95
                        let pinchOutThreshold: CGFloat = 1.05

                        if scale < pinchInThreshold {
                            withAnimation(.bouncy(duration: 0.2)) {
                                minCurves += 2
                                pinchLevel = max(-3, pinchLevel - 1)
                            }
                        } else if scale > pinchOutThreshold {
                            withAnimation(.bouncy(duration: 0.2)) {
                                minCurves = max(1, minCurves - 2)
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
