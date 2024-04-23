//
//  ProgressOverlay.swift
//  Audiobooks
//
//  Created by Rasmus Krämer on 04.10.23.
//

import SwiftUI
import SwiftData
import Defaults
import SPBase
import SPOffline
import SPOfflineExtended

struct StatusOverlay: View {
    @Default(.itemImageStatusPercentageText) private var itemImageStatusPercentageText
    
    let item: Item
    let entity: ItemProgress
    let offlineTracker: ItemOfflineTracker?
    
    @MainActor
    init(item: PlayableItem) {
        self.item = item
        
        entity = OfflineManager.shared.requireProgressEntity(item: item)
        offlineTracker = item.offlineTracker
    }
    
    @State private var progress: Double?
    
    var body: some View {
        GeometryReader { geometry in
            let size = geometry.size.width / 2.5
            let fontSize = size * 0.23
            
            HStack(alignment: .top) {
                Spacer()
                
                if entity.progress > 0 {
                    ZStack {
                        Triangle()
                            .foregroundStyle(.black.opacity(0.2))
                        
                        Triangle()
                            .foregroundStyle(offlineTracker?.status == .downloaded ? Color.alternativeAccent : Color.accentColor)
                        /*
                            .overlay(alignment: .topTrailing) {
                                if entity.progress < 1 {
                                    Circle()
                                        .stroke(offlineTracker?.status == .downloaded ? Color.accentColor : Color.alternativeAccent, lineWidth: 3)
                                        .frame(width: size / 3, height: size / 3)
                                        .padding(size / 7)
                                }
                            }
                         */
                            .reverseMask(alignment: .topTrailing) {
                                Group {
                                    if entity.progress < 1 {
                                        if itemImageStatusPercentageText {
                                            Text(verbatim: "\(Int(entity.progress * 100))")
                                                .font(.system(size: fontSize))
                                                .fontWeight(.heavy)
                                        } else {
                                            ZStack {
                                                Circle()
                                                    .trim(from: CGFloat(entity.progress), to: 360 - CGFloat(entity.progress))
                                                    .stroke(Color.black.opacity(0.2), lineWidth: 3)
                                                
                                                Circle()
                                                    .trim(from: 0, to: CGFloat(entity.progress))
                                                    .stroke(Color.black, lineWidth: 3)
                                            }
                                            .rotationEffect(.degrees(-90))
                                        }
                                    } else {
                                        Image(systemName: "checkmark")
                                            .font(.system(size: fontSize))
                                            .fontWeight(.heavy)
                                    }
                                }
                                .frame(width: size / 3, height: size / 3)
                                .padding(size / 7)
                            }
                    }
                    .frame(width: size, height: size)
                } else {
                    if offlineTracker?.status == .downloaded {
                        Image(systemName: "arrow.down.circle.fill")
                            .font(.caption)
                            .foregroundStyle(.ultraThickMaterial)
                            .padding(4)
                    }
                }
            }
        }
    }
}

// MARK: Progress image

struct ItemStatusImage: View {
    let item: PlayableItem
    
    var body: some View {
        ItemImage(image: item.image)
            .overlay {
                StatusOverlay(item: item)
            }
            .clipShape(RoundedRectangle(cornerRadius: 7))
    }
}

#Preview {
    ItemStatusImage(item: Audiobook.fixture)
}
