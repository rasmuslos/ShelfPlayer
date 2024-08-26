//
//  NowPlayingSheet+BottomButtons.swift
//  Audiobooks
//
//  Created by Rasmus Krämer on 11.10.23.
//

import SwiftUI

extension NowPlaying.CompactViewModifier {
    struct Buttons: View {
        @State private var bookmarksActive = false
        @State private var notableMomentSheetPresented = false
        
        var body: some View {
            HStack {
                PlaybackSpeedButton()
                    .frame(width: 45)
                    .font(.system(size: 21))
                    .foregroundStyle(.secondary)
                
                Spacer()
                
                Text("sleep") // SleepTimerButton()
                    .frame(width: 45)
                    .labelStyle(.iconOnly)
                    .font(.system(size: 19))
                    .foregroundStyle(.secondary)
                
                Spacer()
                
                NowPlaying.AirPlayPicker()
                    .frame(width: 45)
                
                Spacer()
                
                Menu {
                    NowPlaying.ChapterMenu()
                } label: {
                    Label("notableMoments", systemImage: "list.dash")
                        .labelStyle(.iconOnly)
                } primaryAction: {
                    notableMomentSheetPresented.toggle()
                }
                .frame(width: 45)
                .foregroundStyle(.secondary)
            }
            .bold()
            .font(.system(size: 20))
            .frame(height: 45)
            .sheet(isPresented: $notableMomentSheetPresented, content: {
                NowPlaying.NotableMomentsView(includeHeader: true, bookmarksActive: $bookmarksActive)
                    .presentationDragIndicator(.visible)
                    .presentationDetents([.large, .medium])
            })
        }
    }
}
