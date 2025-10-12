//
//  SpiralCenterItem.swift
//  gem.ai
//
//  Created by Oleh Martyn on 09/10/2025.
//

import SwiftUI

struct SpiralCenterItemView: View {
    let currentItem: SpiralItem?
    var centerCircleSize: CGFloat

    var body: some View {
        ZStack {
            Circle()
                .fill(currentItem?.color ?? Color.blue)
                .frame(width: centerCircleSize, height: centerCircleSize)
            Text(currentItem?.id.uuidString.prefix(4) ?? "")
                .foregroundColor(.white)
                .font(.system(size: centerCircleSize / 4))
        }
    }
}
