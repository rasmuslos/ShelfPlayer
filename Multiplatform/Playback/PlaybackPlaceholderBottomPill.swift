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
    
    let itemID: ItemIdentifier
    
    @State private var lastPlayedItemName: String?
    
    var body: some View {
        Button {
            satellite.start(itemID)
        } label: {
            HStack(spacing: 8) {
                Rectangle()
                    .fill(.clear)
                    .aspectRatio(1, contentMode: .fit)
                    .padding(.vertical, 8)
                    .overlay {
                        ItemImage(itemID: itemID, size: .small)
                    }
                
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
            }
            .contentShape(.rect)
            .padding(.horizontal, 16)
        }
        .buttonStyle(.plain)
        .onChange(of: itemID) {
            lastPlayedItemName = nil
        }
    }
    
    private func loadItemName() {
        Task {
            do {
                let item = try await itemID.resolved
                
                lastPlayedItemName = item.name
            } catch APIClientError.offline {
                return
            } catch {
                Defaults[.lastPlayedItemID] = nil
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
            PlaybackPlaceholderBottomPill(itemID: Audiobook.fixture.id)
        }
        .previewEnvironment()
    }
}
#endif
