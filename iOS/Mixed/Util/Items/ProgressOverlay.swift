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
    
    @State var progress: Double?
    
    var body: some View {
        GeometryReader { geometry in
            let size = geometry.size.width / 3
            
            if let progress = progress {
                HStack {
                    Spacer()
                    
                    Triangle()
                        .frame(width: size, height: size)
                        .foregroundStyle(Color.accentColor)
                        .overlay(alignment: .topTrailing) {
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
                            .opacity(0.8)
                        }
                }
            } else {
                Color.clear.onAppear {
                    fetchProgress()
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
        }
    }
}

// MARK: Progress image

struct ItemStatusImage: View {
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
    
    var body: some View {
        ItemImage(image: item.image)
            .overlay {
                StatusOverlay(item: item)
            }
            .overlay(alignment: .topLeading) {
                if let offlineTracker = offlineTracker {
                    if offlineTracker.status == .working {
                        ProgressView()
                    } else if offlineTracker.status == .downloaded {
                        Image(systemName: "arrow.down.circle.fill")
                            .padding(3)
                            .font(.caption)
                            .foregroundStyle(.ultraThickMaterial)
                    }
                }
            }
            .clipShape(RoundedRectangle(cornerRadius: 7))
    }
}

#Preview {
    ItemStatusImage(item: Audiobook.fixture)
}
