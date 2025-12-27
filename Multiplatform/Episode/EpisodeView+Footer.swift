//
//  EpisodeView+Footer.swift
//  ShelfPlayer
//
//  Created by Rasmus Krämer on 27.12.25.
//

import SwiftUI
import ShelfPlayback

extension EpisodeView {
    struct Footer: View {
        @Environment(\.defaultMinListRowHeight) private var defaultMinListRowHeight
        @Environment(EpisodeViewModel.self) private var viewModel
        
        var height: CGFloat {
            defaultMinListRowHeight * 2 +
            defaultMinListRowHeight * CGFloat(viewModel.information.count)
        }
        
        var body: some View {
            List {
                InformationListTitle(title: "item.information")
                
                
                ForEach(viewModel.information, id: \.0.hashValue) {
                    InformationListRow(title: $0, value: $1)
                }
                
                InformationListRow.label(title: "item.episode.type") {
                    Menu {
                        ForEach(Episode.EpisodeType.allCases) { type in
                            if viewModel.episode.type == type {
                                Button(type.label, systemImage: "checkmark") {
                                    viewModel.changeEpisodeType(type)
                                }
                            } else {
                                Button(type.label) {
                                    viewModel.changeEpisodeType(type)
                                }
                            }
                        }
                    } label: {
                        if viewModel.isChangingEpisodeType {
                            ProgressView()
                        } else {
                            HStack(spacing: 4) {
                                Text(viewModel.episode.type.label)
                                
                                Image(systemName: "chevron.up.chevron.down")
                                    .imageScale(.small)
                            }
                            .contentShape(.rect)
                            .foregroundStyle(Color.accentColor)
                        }
                    }
                    .disabled(viewModel.isChangingEpisodeType)
                    .buttonStyle(.plain)
                }
            }
            .listStyle(.plain)
            .frame(height: height)
        }
    }
}
