//
//  SpiralCenterItem.swift
//  gem.ai
//
//  Created by Oleh Martyn on 09/10/2025.
//

import SwiftUI

struct SpiralCenterItemView: View {
    var orderedIDS: [UUID]
    var generatedItems: [SpiralItem]
    var centerCircleSize: CGFloat

    var body: some View {
        ZStack {
            let curIdx = orderedIDS.last
            let curItem = generatedItems.first(where: { $0.id == curIdx })
            Circle()
                .fill(curItem?.color ?? Color.blue)
                .frame(width: centerCircleSize, height: centerCircleSize)
            Text(curItem?.id.uuidString.prefix(4) ?? "")
                .foregroundColor(.white)
                .font(.system(size: centerCircleSize / 4))
        }
    }
}
