//
//  SpiralCenterItem.swift
//  gem.ai
//
//  Created by Oleh Martyn on 09/10/2025.
//

import SwiftUI
import UniformTypeIdentifiers

struct SpiralCenterItemView: View {
    @Binding var centerItem: SpiralItem?
    var orderedIDS: [UUID]
    var generatedItems: [SpiralItem]
    var centerCircleSize: CGFloat
    var onDropItem: ((SpiralItem) -> Void)? = nil

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
        .onDrop(of: [UTType.text], isTargeted: nil) { providers in
            guard let provider = providers.first else { return false }
            provider.loadObject(ofClass: NSString.self) { object, error in
                if let string = object as? String, let uuid = UUID(uuidString: string) {
                    DispatchQueue.main.async {
                        if let item = generatedItems.first(where: { $0.id == uuid }) {
                            centerItem = item
                            onDropItem?(item)
                        }
                    }
                }
            }
            return true
        }
    }
}
