//
//  SpiralItemGenerator.swift
//  gem.ai
//
//  Created by Oleh Martyn on 04/10/2025.
//

import SwiftUI

struct SpiralItem: Identifiable {
    let id = UUID()
    let angle: Double
    let index: Int
    let bgImage: String
    let color: Color
}

class SpiralItemGenerator {
    static let maxItemCount: Int = 5 // Control the maximum number of items
    
    static func generateItems(
        numberOfTurns: CGFloat,
        itemSpacing: CGFloat,
        startingRadius: CGFloat,
        growthPerRadian: CGFloat
    ) -> [SpiralItem] {
        var items: [SpiralItem] = []
        let maxAngle = numberOfTurns * 2 * .pi
        let targetArcDistance = itemSpacing * 50
        
        var currentAngle: Double = 0
        var itemIndex = 0
        
        while currentAngle <= maxAngle && itemIndex < maxItemCount {
            let currentRadius = startingRadius + growthPerRadian * currentAngle
            let angleIncrement = targetArcDistance / currentRadius
            
            let colors: [Color] = [.blue, .green, .purple, .orange, .pink, .cyan, .yellow, .mint, .indigo]
            let bgImages = ["star.fill", "heart.fill", "diamond.fill", "circle.fill", "square.fill", "triangle.fill"]
            
            let item = SpiralItem(
                angle: currentAngle,
                index: itemIndex,
                bgImage: bgImages.randomElement() ?? "circle.fill",
                color: colors.randomElement() ?? .blue
            )
            
            items.append(item)
            currentAngle += angleIncrement
            itemIndex += 1
        }
        
        return items
    }
    
    static func spiralPosition(
        for item: SpiralItem,
        center: CGPoint,
        rotation: Double,
        startingRadius: CGFloat,
        growthPerRadian: CGFloat,
        clockwisePositive: Bool
    ) -> CGPoint {
        let adjustedAngle = item.angle + rotation
        let radius = startingRadius + growthPerRadian * item.angle
        let direction: CGFloat = clockwisePositive ? 1 : -1
        
        let x = center.x + radius * cos(adjustedAngle * direction)
        let y = center.y + radius * sin(adjustedAngle * direction)
        
        return CGPoint(x: x, y: y)
    }
}
