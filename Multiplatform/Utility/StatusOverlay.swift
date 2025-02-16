//
//  ProgressOverlay.swift
//  Audiobooks
//
//  Created by Rasmus Krämer on 04.10.23.
//

import SwiftUI
import SwiftData
import Defaults
import RFNotifications
import SPFoundation
import SPPersistence

struct StatusOverlay: View {
    @Default(.tintColor) private var tintColor
    @Default(.itemImageStatusPercentageText) private var itemImageStatusPercentageText
    
    let item: PlayableItem
    
    @State private var progressEntity: ProgressEntity.UpdatingProgressEntity? = nil
    @State private var downloadStatus: PersistenceManager.DownloadSubsystem.DownloadStatus? = nil
    
    private var showTriangle: Bool {
        if downloadStatus == .downloading {
            return true
        }
        
        if let progressEntity {
            return progressEntity.progress > 0
        }
        
        return false
    }
    
    var body: some View {
        if let progressEntity {
            GeometryReader { geometry in
                let size = geometry.size.width / 2.5
                let fontSize = size * 0.23
                
                HStack(alignment: .top, spacing: 0) {
                    Spacer()
                    
                    if showTriangle {
                        ZStack {
                            Triangle()
                                .foregroundStyle(downloadStatus == PersistenceManager.DownloadSubsystem.DownloadStatus.none ? Defaults[.tintColor].color : Defaults[.tintColor].accent)
                                .overlay(alignment: .topTrailing) {
                                    Group {
                                        if downloadStatus == .downloading {
                                            DownloadButton(item: item, progressVisibility: .triangle)
                                        } else if progressEntity.progress < 1 {
                                            if itemImageStatusPercentageText {
                                                Text(verbatim: "\(Int(progressEntity.progress * 100))")
                                                    .font(.system(size: fontSize))
                                                    .fontWeight(.heavy)
                                            } else {
                                                CircularProgressIndicator(completed: progressEntity.progress, background: .white.opacity(0.3), tint: .white)
                                            }
                                        } else {
                                            Label("finished", systemImage: "checkmark")
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
                    } else if downloadStatus == .completed {
                        Label("downloaded", systemImage: "arrow.down.circle.fill")
                            .labelStyle(.iconOnly)
                            .font(.system(size: fontSize))
                            .foregroundStyle(.ultraThickMaterial)
                            .padding(size / 7)
                    }
                }
            }
            .onReceive(RFNotification[.downloadStatusChanged].publisher()) { (itemID, status) in
                guard itemID == item.id else {
                    return
                }
                
                self.downloadStatus = status
            }
        } else {
            Color.clear
                .frame(width: 0, height: 0)
                .onAppear {
                    load()
                }
        }
    }
    
    private nonisolated func load() {
        Task {
            let progressEntity = await PersistenceManager.shared.progress[item.id]
            let downloadStatus = await PersistenceManager.shared.download.status(of: item.id)
            
            await MainActor.withAnimation {
                self.progressEntity = progressEntity.updating
                self.downloadStatus = downloadStatus
            }
        }
    }
}

struct ItemProgressIndicatorImage: View {
    let item: PlayableItem
    let size: ItemIdentifier.CoverSize
    
    var aspectRatio = RequestImage.AspectRatioPolicy.square
    
    var body: some View {
        ItemImage(item: item, size: size, aspectRatio: aspectRatio)
            .overlay {
                StatusOverlay(item: item)
                    .clipShape(RoundedRectangle(cornerRadius: 8))
            }
    }
}

#if DEBUG
#Preview {
    ItemProgressIndicatorImage(item: Audiobook.fixture, size: .large)
}
#endif
