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
                
                SleepTimerButton()
                    .labelStyle(.iconOnly)
                    .modifier(NowPlayingButtonModifier())
                
                Spacer()
                
                Button {
                    NowPlaying.presentPicker()
                } label: {
                    Label("route", systemImage: "airplayaudio")
                        .labelStyle(.iconOnly)
                        .modifier(NowPlayingButtonModifier())
                        .foregroundStyle(viewModel.isUsingExternalRoute ? Color.accentColor : .secondary)
                        .contentShape(.rect)
                }
                .buttonStyle(.plain)
                
                Spacer()
                
                Menu {
                    NowPlaying.ChapterMenu()
                } label: {
                    Label("nowPlaying.sheet", systemImage: viewModel.sheetLabelIcon)
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
