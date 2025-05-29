//
//  CollectionConfiguration.swift
//  Multiplatform
//
//  Created by Rasmus Krämer on 09.05.25.
//

import SwiftUI
import Defaults
import DefaultsMacros
import ShelfPlayerKit
import SPPlayback

struct GroupingConfigurationSheet: View {
    @Environment(Satellite.self) private var satellite
    
    let itemID: ItemIdentifier
    
    @State private var viewModel: ViewModel?
    
    var body: some View {
        NavigationStack {
            List {
                if let viewModel {
                    @Bindable var viewModel = viewModel
                    
                    Section("item.grouping.configure.playback") {
                        PlaybackRatePicker(label: "item.grouping.configure.playbackRate", selection: $viewModel.playbackRate)
                            .bold(viewModel.isPlaybackRateCustomized)
                        
                        Picker("item.grouping.configure.upNextStrategy", selection: $viewModel.upNextStrategy) {
                            ForEach(ConfigureableUpNextStrategy.allCases) { strategy in
                                Text(strategy.label)
                                    .tag(strategy)
                            }
                        }
                        .bold(viewModel.isUpNextStrategyCustomized)
                    }
                    
                    Color.clear
                        .listRowBackground(Color.clear)
                        .toolbar {
                            ToolbarItem(placement: .confirmationAction) {
                                Button("action.save") {
                                    viewModel.save() {
                                        satellite.dismissSheet()
                                    }
                                }
                            }
                        }
                        .sensoryFeedback(.error, trigger: viewModel.notifyError)
                } else {
                    LoadingView.Inner()
                        .task {
                            viewModel = await .init(itemID: itemID)
                        }
                }
            }
            .navigationTitle("item.grouping.configure")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("action.cancel") {
                        satellite.dismissSheet()
                    }
                }
            }
        }
        .presentationDetents([.medium, .large])
        .presentationDragIndicator(.visible)
        .interactiveDismissDisabled()
    }
}

@MainActor @Observable
private final class ViewModel {
    @ObservableDefault(.defaultPlaybackRate) @ObservationIgnored
    var defaultPlaybackRate: Percentage
    
    @ObservableDefault(.upNextStrategy) @ObservationIgnored
    var globalUpNextStrategy: ConfigureableUpNextStrategy
    
    let itemID: ItemIdentifier
    
    var playbackRate: Percentage
    var upNextStrategy: ConfigureableUpNextStrategy
    
    var notifyError = false
    
    init(itemID: ItemIdentifier) async {
        self.itemID = itemID
        
        playbackRate = await PersistenceManager.shared.item.playbackRate(for: itemID) ?? Defaults[.defaultPlaybackRate]
        upNextStrategy = await PersistenceManager.shared.item.upNextStrategy(for: itemID) ?? Defaults[.upNextStrategy]
    }
    
    var isPlaybackRateCustomized: Bool {
        playbackRate != defaultPlaybackRate
    }
    var isUpNextStrategyCustomized: Bool {
        upNextStrategy != globalUpNextStrategy
    }
    
    nonisolated func save(callback: @MainActor @escaping () -> Void) {
        Task {
            var failedCount = 0
            
            do {
                if await isPlaybackRateCustomized {
                    try await PersistenceManager.shared.item.setPlaybackRate(playbackRate, for: itemID)
                } else {
                    try await PersistenceManager.shared.item.setPlaybackRate(nil, for: itemID)
                }
            } catch {
                failedCount += 1
            }
            
            do {
                if await isUpNextStrategyCustomized {
                    try await PersistenceManager.shared.item.setUpNextStrategy(upNextStrategy, for: itemID)
                } else {
                    try await PersistenceManager.shared.item.setUpNextStrategy(nil, for: itemID)
                }
            } catch {
                failedCount += 1
            }
            
            if failedCount > 0 {
                await MainActor.run {
                    notifyError.toggle()
                }
            }
            
            await callback()
        }
    }
}

private extension ConfigureableUpNextStrategy {
    var label: LocalizedStringKey {
        switch self {
            case .default:
                "upNextStrategy.default"
            case .listenNow:
                "upNextStrategy.listenNow"
            case .disabled:
                "upNextStrategy.disabled"
        }
    }
}

#if DEBUG
#Preview {
    Text(verbatim: ":)")
        .sheet(isPresented: .constant(true)) {
            GroupingConfigurationSheet(itemID: Podcast.fixture.id)
        }
        .previewEnvironment()
}
#endif
