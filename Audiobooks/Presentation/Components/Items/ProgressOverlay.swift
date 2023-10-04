//
//  ProgressOverlay.swift
//  Audiobooks
//
//  Created by Rasmus Krämer on 04.10.23.
//

import SwiftUI

struct ProgressOverlay: View {
    let item: Item
    
    @State var percentage: Double?
    
    var body: some View {
        GeometryReader { geometry in
            let size = geometry.size.width / 3
            
            if let percentage = percentage {
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
                                    .trim(from: 0, to: CGFloat(percentage))
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

// MARK: Helper

extension ProgressOverlay {
    func fetchProgress() {
        Task.detached {
            if let progress = await OfflineManager.shared.getProgress(item: item) {
                let percentage = progress.currentTime / progress.duration
                if percentage > 0 && percentage < 0.95 {
                    self.percentage = percentage
                }
            }
        }
    }
}

// MARK: Progress image

struct ItemProgressImage: View {
    let item: Item
    
    var body: some View {
        ItemImage(image: item.image)
            .overlay {
                ProgressOverlay(item: item)
            }
            .clipShape(RoundedRectangle(cornerRadius: 7))
    }
}

#Preview {
    ItemImage(image: Audiobook.fixture.image)
        .overlay {
            ProgressOverlay(item: Audiobook.fixture)
        }
        .frame(width: 200)
}
