//
//  NowPlayingSheet+BottomButtons.swift
//  Audiobooks
//
//  Created by Rasmus Krämer on 11.10.23.
//

import SwiftUI

internal extension NowPlaying {
    struct CompactButtons: View {
        @Environment(NowPlaying.ViewModel.self) private var viewModel
        
        var body: some View {
            HStack {
                PlaybackSpeedButton()
                    .modifier(NowPlayingButtonModifier())
                
                Spacer()
                
                Label("sleep", systemImage: "moon.zzz.fill") // SleepTimerButton()
                    .labelStyle(.iconOnly)
                    .modifier(NowPlayingButtonModifier())
                
                Spacer()
                
                Button {
                    NowPlaying.presentPicker()
                } label: {
                    Label("output", systemImage: "airplay.audio")
                        .labelStyle(.iconOnly)
                        .modifier(NowPlayingButtonModifier())
                        .contentShape(.rect)
                }
                .buttonStyle(.plain)
                
                Spacer()
                
                Menu {
                    NowPlaying.ChapterMenu()
                } label: {
                    Label("nowPlaying.sheet.icon", systemImage: viewModel.sheetLabelIcon)
                        .labelStyle(.iconOnly)
                        .modifier(NowPlayingButtonModifier())
                        .contentShape(.rect)
                } primaryAction: {
                    viewModel.sheetPresented.toggle()
                }
                .buttonStyle(.plain)
            }
            .frame(height: 48)
        }
    }
}

private struct NowPlayingButtonModifier: ViewModifier {
    func body(content: Content) -> some View {
        content
            .bold()
            .font(.title3)
            .foregroundStyle(.secondary)
            .frame(width: 48)
    }
}
