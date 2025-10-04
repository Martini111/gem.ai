//
//  ContentView.swift
//  gem.ai
//
//  Created by Oleh Martyn on 04/10/2025.
//

import SwiftUI

struct SpiralItem: Identifiable {
    let id = UUID()
    let angle: Double
    let index: Int
}

struct ContentView: View {
    // Spiral configuration properties
    @State private var startingRadius: CGFloat = 80 // distance from center
    @State private var growthPerRadian: CGFloat = 30
    @State private var numberOfTurns: CGFloat = 5 // number if curves
    @State private var centerRadius: CGFloat = 50
    @State private var itemRadius: CGFloat = 20
    @State private var clockwisePositive: Bool = true
    @State private var itemSpacing: CGFloat = 1.2
    
    // Animation state
    @State private var rotation: Double = 0
    @State private var items: [SpiralItem] = []
    
    var body: some View {
        GeometryReader { geometry in
            let center = CGPoint(
                x: geometry.size.width / 2,
                y: geometry.size.height / 2
            )
            
            ZStack {
                Color.white
                    .ignoresSafeArea()
                
                // Center circle
                Circle()
                    .fill(.red)
                    .frame(width: centerRadius * 2, height: centerRadius * 2)
                    .position(center)
                    .shadow(color: .black.opacity(0.2), radius: 4, x: 2, y: 2)
                
                // Spiral items
                ForEach(items) { item in
                    let position = spiralPosition(
                        for: item,
                        center: center,
                        rotation: rotation
                    )
                    
                    Circle()
                        .fill(.blue)
                        .frame(width: itemRadius * 2, height: itemRadius * 2)
                        .position(position)
                        .shadow(color: .black.opacity(0.2), radius: 4, x: 2, y: 2)
                }
            }
            .gesture(
                DragGesture()
                    .onChanged { value in
                        let rotationSpeed: Double = 0.005
                        let direction: Double = clockwisePositive ? 1 : -1
                        rotation += value.translation.width * rotationSpeed * direction
                    }
            )
        }
        .onAppear {
            generateSpiralItems()
        }
    }
    
    private func generateSpiralItems() {
        items.removeAll()
        
        let totalAngle = numberOfTurns * 2 * .pi
        let targetArcDistance: Double = Double(itemSpacing * 50) // Convert spacing to actual distance
        var currentAngle: Double = 0
        var itemIndex = 0
        
        while currentAngle <= totalAngle {
            items.append(SpiralItem(angle: currentAngle, index: itemIndex))
            
            // Calculate the next angle to maintain equal arc distance
            let currentRadius = Double(startingRadius + growthPerRadian * CGFloat(currentAngle))
            let angleIncrement = targetArcDistance / currentRadius
            
            currentAngle += angleIncrement
            itemIndex += 1
        }
    }
    
    private func spiralPosition(for item: SpiralItem, center: CGPoint, rotation: Double) -> CGPoint {
        let adjustedAngle = item.angle + rotation
        let direction: Double = clockwisePositive ? 1 : -1
        
        // Archimedean spiral formula: r = startingRadius + growthPerRadian * θ
        let radius = startingRadius + growthPerRadian * CGFloat(item.angle)
        
        // Convert polar coordinates to Cartesian
        let x = center.x + CGFloat(radius * cos(adjustedAngle * direction))
        let y = center.y + CGFloat(radius * sin(adjustedAngle * direction))
        
        return CGPoint(x: x, y: y)
    }
}

#Preview {
    ContentView()
}
