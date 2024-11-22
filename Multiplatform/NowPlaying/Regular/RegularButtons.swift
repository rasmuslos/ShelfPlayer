//
//  Regular+Buttons.swift
//  Multiplatform
//
//  Created by Rasmus Krämer on 23.04.24.
//

import SwiftUI
import SPFoundation
import SPPlayback

extension NowPlaying {
    internal struct RegularButtons: View {
        @Environment(NowPlaying.ViewModel.self) private var viewModel
        
        var body: some View {
            HStack(spacing: 0) {
                PlaybackSpeedButton()
                    .modifier(NowPlayingButtonModifier())
                
                SleepTimerButton()
                    .labelStyle(.iconOnly)
                    .modifier(NowPlayingButtonModifier())
                
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
                
                Button {
                    withAnimation {
                        viewModel.sheetTab = viewModel.sheetTab?.next
                    }
                } label: {
                    Text(viewModel.sheetTab?.label ?? "loading")
                        .foregroundStyle(.secondary)
                        .animation(.smooth, value: viewModel.sheetTab)
                }
                .buttonStyle(.plain)
                .padding(.trailing, 8)
                .modifier(NowPlayingButtonModifier(fixedWidth: false))
                
                if viewModel.sheetTab == .queue {
                    Button {
                        AudioPlayer.shared.clear()
                    } label: {
                        Label("queue.clear", systemImage: "xmark.square.fill")
                            .labelStyle(.iconOnly)
                            .contentTransition(.opacity)
                            .animation(.smooth, value: viewModel.sheetTab)
                    }
                    .modifier(NowPlayingButtonModifier(fixedWidth: false))
                    .padding(.trailing, 8)
                }
                
                Menu {
                    ForEach(NowPlaying.ViewModel.SheetTab.allCases) { tab in
                        Button {
                            withAnimation {
                                viewModel.sheetTab = tab
                            }
                        } label: {
                            Label(tab.label, systemImage: tab.icon)
                        }
                    }
                } label: {
                    Label(viewModel.sheetTab?.label ?? "loading", systemImage: viewModel.sheetTab?.icon ?? "command")
                        .labelStyle(.iconOnly)
                        .contentTransition(.symbolEffect(.replace.upUp.wholeSymbol))
                        .animation(.smooth, value: viewModel.sheetTab)
                } primaryAction: {
                    withAnimation {
                        viewModel.sheetTab = viewModel.sheetTab?.next
                    }
                }
                .menuStyle(.button)
                .buttonStyle(.plain)
                .menuActionDismissBehavior(.disabled)
                .modifier(NowPlayingButtonModifier(fixedWidth: false))
            }
            .frame(height: 48)
        }
    }
}
