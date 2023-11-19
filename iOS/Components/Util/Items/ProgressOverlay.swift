//
//  ProgressOverlay.swift
//  Audiobooks
//
//  Created by Rasmus Krämer on 04.10.23.
//

import SwiftUI
import SwiftData
import AudiobooksKit

struct ProgressOverlay: View {
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

// MARK: Helper

extension ProgressOverlay {
    func fetchProgress() {
        Task.detached {
            if let progress = await OfflineManager.shared.getProgress(item: item) {
                if progress.progress > 0 && progress.progress < 1 {
                    self.progress = progress.progress
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
    ItemProgressImage(item: Audiobook.fixture)
}
