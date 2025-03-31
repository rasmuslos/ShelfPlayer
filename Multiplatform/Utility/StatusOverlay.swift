//
//  ProgressOverlay.swift
//  Audiobooks
//
//  Created by Rasmus Krämer on 04.10.23.
//

import SwiftUI
import SwiftData
import Defaults
import ShelfPlayerKit

struct StatusOverlay: View {
    @Default(.tintColor) private var tintColor
    @Default(.itemImageStatusPercentageText) private var itemImageStatusPercentageText
    
    let itemID: ItemIdentifier
    
    @State private var progress: ProgressTracker
    @State private var download: DownloadStatusTracker
    
    init(itemID: ItemIdentifier) {
        self.itemID = itemID
        
        _progress = .init(initialValue: .init(itemID: itemID))
        _download = .init(initialValue: .init(itemID: itemID))
    }
    
    private var showTriangle: Bool {
        if download.status == .downloading {
            return true
        }
        
        if let progress = progress.progress {
            return progress > 0
        }
        
        return false
    }
    
    var body: some View {
        if let progress = progress.progress {
            GeometryReader { geometry in
                let size = geometry.size.width / 2.5
                let fontSize = size * 0.23
                
                HStack(alignment: .top, spacing: 0) {
                    Spacer()
                    
                    if showTriangle {
                        ZStack {
                            Triangle()
                                .foregroundStyle(download.status == PersistenceManager.DownloadSubsystem.DownloadStatus.none ? Defaults[.tintColor].color : Defaults[.tintColor].accent)
                                .overlay(alignment: .topTrailing) {
                                    Group {
                                        if download.status == .downloading {
                                            DownloadButton(itemID: itemID, progressVisibility: .triangle)
                                        } else if progress < 1 {
                                            if itemImageStatusPercentageText {
                                                Text(verbatim: "\(Int(progress * 100))")
                                                    .font(.system(size: fontSize))
                                                    .fontWeight(.heavy)
                                            } else {
                                                CircularProgressIndicator(completed: progress, background: .white.opacity(0.3), tint: .white)
                                            }
                                        } else {
                                            Image(systemName: "checkmark")
                                                .labelStyle(.iconOnly)
                                                .font(.system(size: fontSize))
                                                .fontWeight(.heavy)
                                        }
                                    }
                                    .frame(width: size / 3, height: size / 3)
                                    .foregroundStyle(.white)
                                    .padding(size / 7)
                                }
                        }
                        .frame(width: size, height: size)
                    } else if download.status == .completed {
                        Image(systemName: "arrow.down.circle.fill")
                            .labelStyle(.iconOnly)
                            .font(.system(size: fontSize))
                            .foregroundStyle(.ultraThickMaterial)
                            .padding(size / 7)
                    }
                }
            }
        } else {
            Color.clear
                .frame(width: 0, height: 0)
        }
    }
}

struct ItemProgressIndicatorImage: View {
    let itemID: ItemIdentifier
    let size: ItemIdentifier.CoverSize
    
    var aspectRatio = RequestImage.AspectRatioPolicy.square
    
    var body: some View {
        ItemImage(itemID: itemID, size: size, aspectRatio: aspectRatio)
            .overlay {
                StatusOverlay(itemID: itemID)
                    .clipShape(RoundedRectangle(cornerRadius: 8))
            }
    }
}

#if DEBUG
#Preview {
    ItemProgressIndicatorImage(itemID: .fixture, size: .large)
}
#endif
