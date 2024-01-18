//
//  ProgressOverlay.swift
//  Audiobooks
//
//  Created by Rasmus Krämer on 04.10.23.
//

import SwiftUI
import SwiftData
import SPBaseKit
import SPOfflineKit
import SPOfflineExtendedKit

struct StatusOverlay: View {
    let item: Item
    let offlineTracker: ItemOfflineTracker?
    
    init(item: Item) {
        self.item = item
        
        if let playableItem = item as? PlayableItem {
            offlineTracker = playableItem.offlineTracker
        } else {
            offlineTracker = nil
        }
    }
    
    @State var progress: Double?
    
    // TODO: change color
    
    var body: some View {
        GeometryReader { geometry in
            let size = geometry.size.width / 3
            
            HStack(alignment: .top) {
                Color.clear
                    .onAppear(perform: fetchProgress)
                
                Spacer()
                
                if let progress = progress {
                    Triangle()
                        .frame(width: size, height: size)
                        .foregroundStyle(offlineTracker?.status == .downloaded ? Color.purple : Color.accentColor)
                        .reverseMask(alignment: .topTrailing) {
                            ZStack {
                                Circle()
                                    .stroke(Color.secondary.opacity(0.5), lineWidth: 3)
                                Circle()
                                    .trim(from: 0, to: CGFloat(progress))
                                    .stroke(Color.primary, lineWidth: 3)
                            }
                            .rotationEffect(.degrees(-90))
                            .frame(width: size / 3, height: size / 3)
                            .padding(size / 7)
                        }
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

extension StatusOverlay {
    func fetchProgress() {
        Task.detached {
            if let progress = await OfflineManager.shared.getProgressEntity(item: item) {
                if progress.progress > 0 && progress.progress < 1 {
                    self.progress = progress.progress
                }
            }
            
            progress = 0.5
        }
    }
}

// MARK: Progress image

struct ItemStatusImage: View {
    let item: Item
    
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
