//
//  PlaybackPlaceholderBottomPill.swift
//  ShelfPlayer
//
//  Created by Rasmus Krämer on 08.11.25.
//

import SwiftUI
import ShelfPlayback

struct PlaybackPlaceholderBottomPill: View {
    @Environment(Satellite.self) private var satellite
    
    @Default(.lastPlayedItemID) private var lastPlayedItemID
    
    @State private var lastPlayedItemName: String?
    
    var body: some View {
        Button {
            if let lastPlayedItemID {
                satellite.start(lastPlayedItemID)
            }
        } label: {
            HStack(spacing: 8) {
                ItemImage(itemID: lastPlayedItemID, size: .small)
                    .padding(.vertical, 8)
                
                if let lastPlayedItemID {
                    VStack(alignment: .leading, spacing: 0) {
                        if let lastPlayedItemName {
                            Text(lastPlayedItemName)
                        } else {
                            ZStack(alignment: .leading) {
                                Text(verbatim: "PLACEHOLDER")
                                    .hidden()
                                
                                ProgressView()
                                    .scaleEffect(0.5)
                                    .frame(width: 10, height: 0)
                            }
                            .task {
                                loadItemName()
                            }
                        }
                        
                        Text("playback.placeholder.resume")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    
                    Spacer(minLength: 0)
                } else {
                    Text("playback.placeholder.inactive")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    
                    Spacer(minLength: 0)
                }
            }
            .contentShape(.rect)
            .padding(.horizontal, 16)
        }
        .buttonStyle(.plain)
        .onChange(of: lastPlayedItemID) {
            lastPlayedItemName = nil
        }
    }
    
    private nonisolated func loadItemName() {
        Task {
            do {
                let item = try await lastPlayedItemID?.resolved
                
                await MainActor.run {
                    lastPlayedItemName = item?.name
                }
            } catch {
                await MainActor.run {
                    lastPlayedItemID = nil
                }
            }
        }
    }
}

#if DEBUG
#Preview {
    if #available(iOS 26, *) {
        TabView {
            
        }
        .tabViewBottomAccessory {
            PlaybackPlaceholderBottomPill()
        }
        .previewEnvironment()
    }
}
#endif
