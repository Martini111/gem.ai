//
//  ContentView.swift
//  gem.ai
//
//  Created by Oleh Martyn on 04/10/2025.
//

import SwiftUI

struct ContentView: View {
    // Configuration variables
    let numberOfItems: Int = 5
    let distanceBetweenCircles: CGFloat = 15
    let numberOfSpiralCurves: Int = 3
    let distanceToCenter: CGFloat = 60
    let circleSize: CGFloat = 20
    let centerCircleSize: CGFloat = 60
    let animationSpeed: CGFloat = 1.0
    
    @State private var spiralOffset: CGFloat = 0
    @GestureState private var dragOffset: CGFloat = 0
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                Color.clear
                
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
                .frame(width: geometry.size.width, height: geometry.size.height - 150)
                .position(x: geometry.size.width / 2, y: (geometry.size.height - 150) / 2)
                
                // Ruler dragger at bottom
                VStack {
                    Spacer()
                    RulerDragger(dragOffset: dragOffset)
                        .gesture(
                            DragGesture()
                                .updating($dragOffset) { value, state, _ in
                                    // Increase sensitivity for smoother control
                                    state = value.translation.width * 3.0
                                }
                                .onEnded { value in
                                    spiralOffset += value.translation.width * 3.0
                                }
                        )
                        .padding(.bottom, 50)
                }
            }
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
                .stroke(Color.black.opacity(0.3), lineWidth: 2)
                
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

struct RulerDragger: View {
    let dragOffset: CGFloat
    
    var body: some View {
        VStack(spacing: 10) {
            // Ruler marks
            HStack(spacing: 0) {
                ForEach(0..<21, id: \.self) { index in
                    VStack {
                        Rectangle()
                            .fill(Color.gray)
                            .frame(width: 1, height: index % 5 == 0 ? 20 : 10)
                        
                        if index % 5 == 0 {
                            Text("\(index - 10)")
                                .font(.caption2)
                                .foregroundColor(.gray)
                        }
                    }
                    .frame(width: 20)
                }
            }
            .offset(x: dragOffset * 4)
            
            // Dragger handle
            RoundedRectangle(cornerRadius: 15)
                .fill(Color.blue)
                .frame(width: 60, height: 30)
                .overlay(
                    RoundedRectangle(cornerRadius: 15)
                        .stroke(Color.white, lineWidth: 2)
                )
                .scaleEffect(1.0)
                .offset(x: dragOffset)
        }
        .padding(.horizontal, 40)
    }
}

#Preview {
    ContentView()
}
