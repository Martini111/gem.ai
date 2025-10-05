//
//  ContentView.swift
//  gem.ai
//
//  Created by Oleh Martyn on 04/10/2025.
//

import SwiftUI

struct ContentView: View {
    // Spiral configuration properties
    @State private var startingRadius: CGFloat = 80 // distance from center
    @State private var growthPerRadian: CGFloat = 10 // distance between curves
    @State private var numberOfTurns: CGFloat = 5 // number of curves
    @State private var centerRadius: CGFloat = 40 // center circle radius
    @State private var itemRadius: CGFloat = 20
    @State private var clockwisePositive: Bool = true
    @State private var itemSpacing: CGFloat = 1
    
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
                
                // Spiral items (drawn first, so they appear behind)
                ForEach(items) { item in
                    let position = SpiralItemGenerator.spiralPosition(
                        for: item,
                        center: center,
                        rotation: rotation,
                        startingRadius: startingRadius,
                        growthPerRadian: growthPerRadian,
                        clockwisePositive: clockwisePositive,
                        numberOfTurns: numberOfTurns
                    )
                    
                    let maxAngle = numberOfTurns * 2 * .pi
                    let effectiveProgress = item.progress + (rotation / maxAngle)
                    let itemColor = (effectiveProgress < 0.0) ? Color.black : item.color
                    let progressPercentage = Int(effectiveProgress * 100)
                    
                    ZStack {
                        Circle()
                            .fill(itemColor)
                            .frame(width: itemRadius * 2, height: itemRadius * 2)
                            .shadow(color: .black.opacity(0.2), radius: 4, x: 2, y: 2)
                        
                        Text("\(progressPercentage)%")
                            .font(.system(size: 10, weight: .bold))
                            .foregroundColor(.white)
                    }
                    .position(position)
                }
                
                // Center circle (drawn last, so it appears on top)
                Circle()
                    .fill(.red)
                    .frame(width: centerRadius * 2, height: centerRadius * 2)
                    .position(center)
                    .shadow(color: .black.opacity(0.2), radius: 4, x: 2, y: 2)
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
        items = SpiralItemGenerator.generateItems(
            numberOfTurns: numberOfTurns,
            itemSpacing: itemSpacing,
            startingRadius: startingRadius,
            growthPerRadian: growthPerRadian
        )
    }
}

#Preview {
    ContentView()
}
