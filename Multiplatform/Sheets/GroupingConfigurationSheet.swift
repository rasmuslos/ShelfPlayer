//
//  CollectionConfiguration.swift
//  Multiplatform
//
//  Created by Rasmus Krämer on 09.05.25.
//

import SwiftUI
import ShelfPlayback

struct GroupingConfigurationSheet: View {
    @Environment(Satellite.self) private var satellite
    
    @Default(.generateUpNextQueue) private var generateUpNextQueue
    @Default(.enableConvenienceDownloads) private var enableConvenienceDownloads
    
    @Default(.sleepTimerIntervals) private var sleepTimerIntervals
    
    let itemID: ItemIdentifier
    
    @State private var viewModel: ViewModel?
    
    var body: some View {
        NavigationStack {
            List {
                if let viewModel {
                    @Bindable var viewModel = viewModel
                    
                    Section {
                        PlaybackRatePicker(label: "item.grouping.configure.playbackRate", selection: $viewModel.playbackRate)
                            .bold(viewModel.isPlaybackRateCustomized)
                        
                        Picker(selection: $viewModel.sleepTimer) {
                            Text("disabled")
                                .tag(Optional<SleepTimerConfiguration>.none)
                            
                            Divider()
                            
                            ForEach(sleepTimerIntervals, id: \.hashValue) {
                                Text($0.formatted(.duration(unitsStyle: .short, allowedUnits: [.hour, .minute])))
                                    .tag(SleepTimerConfiguration.interval($0))
                            }
                            
                            if viewModel.areSleepChaptersAvailable {
                                Divider()
                                
                                ForEach([1, 2, 3, 5, 7, 10], id: \.hashValue) {
                                    Text("item.chapters \($0)")
                                        .tag(SleepTimerConfiguration.chapters($0))
                                }
                            }
                        } label: {
                            Text("item.grouping.configure.sleepTimer")
                                .bold(viewModel.isSleepTimerCustomized)
                        }
                    } header: {
                        Text("item.grouping.configure.playback")
                    }
                    
                    Section {
                        if viewModel.isUpNextCustomizable {
                            Picker("item.grouping.configure.upNextStrategy", selection: $viewModel.upNextStrategy) {
                                ForEach(ConfigureableUpNextStrategy.allCases) {
                                    Text($0.label)
                                        .tag($0)
                                }
                            }
                            .bold(viewModel.isUpNextStrategyCustomized)
                            .disabled(!generateUpNextQueue)
                        }
                        
                        if viewModel.areSuggestionsAvailable {
                            Toggle("item.grouping.configure.allowSuggestions", isOn: $viewModel.allowSuggestions)
                                .bold(viewModel.isAllowSuggestionsCustomized)
                        }
                    } footer: {
                        if viewModel.areSuggestionsAvailable {
                            Text("item.grouping.configure.playback.description")
                        }
                    }
                    
                    if viewModel.areConvenienceDownloadsAvailable {
                        Section {
                            ConvenienceDownloadRetrievalPicker(itemType: itemID.type, retrieval: $viewModel.retrieval) {
                                Text("item.convenienceDownload.retrieval")
                            }
                        } header: {
                            Text("item.convenienceDownload")
                        } footer: {
                            Text("item.convenienceDownload.description")
                        }
                        .disabled(!enableConvenienceDownloads)
                    }
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
                
                if let viewModel {
                    ToolbarItem(placement: .confirmationAction) {
                        Button("action.save") {
                            viewModel.save() {
                                satellite.dismissSheet()
                            }
                        }
                        .sensoryFeedback(.error, trigger: viewModel.notifyError)
                    }
                }
            }
        }
        .presentationDetents([.medium, .large])
        .presentationDragIndicator(.visible)
        .interactiveDismissDisabled()
    }
    
    struct ConvenienceDownloadRetrievalPicker<Content: View>: View {
        let itemType: ItemIdentifier.ItemType
        @Binding var retrieval: ConvenienceDownloadRetrievalOption
        let content: () -> Content
        
        var body: some View {
            Picker(selection: $retrieval) {
                ForEach(ConvenienceDownloadRetrievalOption.options(for: itemType)) { strategy in
                    Text(strategy.label)
                        .tag(strategy)
                }
            } label: {
                content()
            }
            .bold(retrieval != .disabled)
        }
    }
}

@MainActor @Observable
private final class ViewModel {
    @ObservableDefault(.defaultPlaybackRate) @ObservationIgnored
    var defaultPlaybackRate: Percentage
    
    let itemID: ItemIdentifier
    
    var playbackRate: Percentage
    var sleepTimer: SleepTimerConfiguration?
    
    var upNextStrategy: ConfigureableUpNextStrategy
    var allowSuggestions: Bool
    
    var retrieval: ConvenienceDownloadRetrievalOption
    
    var notifyError = false
    
    init(itemID: ItemIdentifier) async {
        self.itemID = itemID
        
        playbackRate = await PersistenceManager.shared.item.playbackRate(for: itemID) ?? Defaults[.defaultPlaybackRate]
        upNextStrategy = await PersistenceManager.shared.item.upNextStrategy(for: itemID) ?? .default
        allowSuggestions = await PersistenceManager.shared.item.allowSuggestions(for: itemID) ?? true
        sleepTimer = await PersistenceManager.shared.item.sleepTimer(for: itemID)
        
        if let retrieval = await PersistenceManager.shared.convenienceDownload.retrieval(for: itemID), let parsed = ConvenienceDownloadRetrievalOption.parse(retrieval) {
            self.retrieval = parsed
        } else {
            retrieval = .disabled
        }
    }
    
    var isPlaybackRateCustomized: Bool {
        playbackRate != defaultPlaybackRate
    }
    var isSleepTimerCustomized: Bool {
        sleepTimer != nil
    }
    var areSleepChaptersAvailable: Bool {
        itemID.type == .series || itemID.type == .collection || itemID.type == .audiobook
    }
    
    var isUpNextCustomizable: Bool {
        itemID.type == .series || itemID.type == .podcast
    }
    var isUpNextStrategyCustomized: Bool {
        upNextStrategy != .default
    }
    
    var areSuggestionsAvailable: Bool {
        itemID.type == .series || itemID.type == .podcast
    }
    var isAllowSuggestionsCustomized: Bool {
        allowSuggestions != true
    }
    
    var areConvenienceDownloadsAvailable: Bool {
        itemID.type == .series || itemID.type == .podcast || itemID.type == .collection || itemID.type == .playlist
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
                try await PersistenceManager.shared.item.setSleepTimer(sleepTimer, for: itemID)
            } catch {
                failedCount += 1
            }
            
            do {
                if await isUpNextCustomizable, await isUpNextStrategyCustomized {
                    try await PersistenceManager.shared.item.setUpNextStrategy(upNextStrategy, for: itemID)
                } else {
                    try await PersistenceManager.shared.item.setUpNextStrategy(nil, for: itemID)
                }
            } catch {
                failedCount += 1
            }
            
            do {
                if await areSuggestionsAvailable, await isAllowSuggestionsCustomized {
                    try await PersistenceManager.shared.item.setAllowSuggestions(allowSuggestions, for: itemID)
                } else {
                    try await PersistenceManager.shared.item.setAllowSuggestions(nil, for: itemID)
                }
            } catch {
                failedCount += 1
            }
            
            do {
                try await PersistenceManager.shared.convenienceDownload.setRetrieval(for: itemID, retrieval: retrieval.resolved)
            } catch {
                failedCount += 1
            }
            
            if failedCount > 0 {
                await MainActor.run {
                    notifyError.toggle()
                }
            }
            
            await RFNotification[.invalidateProgressEntities].send(payload: nil)
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
            "disabled"
        }
    }
}

enum ConvenienceDownloadRetrievalOption: String, Identifiable {
    case disabled
    
    case one
    case two
    case three
    case four
    case five
    case ten
    
    case oneDay
    case oneWeek
    case twoWeeks
    case oneMonth
    
    case all
    
    var id: String {
        rawValue
    }
    var label: LocalizedStringKey {
        switch self {
        case .disabled:
            "disabled"
        case .one:
            "item.convenienceDownload.one"
        case .two:
            "item.convenienceDownload.two"
        case .three:
            "item.convenienceDownload.three"
        case .four:
            "item.convenienceDownload.four"
        case .five:
            "item.convenienceDownload.five"
        case .ten:
            "item.convenienceDownload.ten"
        case .oneDay:
            "item.convenienceDownload.oneDay"
        case .oneWeek:
            "item.convenienceDownload.oneWeek"
        case .twoWeeks:
            "item.convenienceDownload.twoWeeks"
        case .oneMonth:
            "item.convenienceDownload.oneMonth"
        case .all:
            "item.convenienceDownload.all"
        }
    }
    
    var resolved: PersistenceManager.ConvenienceDownloadSubsystem.GroupingRetrieval? {
        switch self {
        case .disabled:
            nil
        case .one:
                .amount(1)
        case .two:
                .amount(2)
        case .three:
                .amount(3)
            case .four:
                    .amount(4)
            case .five:
                    .amount(5)
            case .ten:
                    .amount(10)
            case .oneDay:
                    .cutoff(24)
            case .oneWeek:
                    .cutoff(168)
            case .twoWeeks:
                    .cutoff(336)
            case .oneMonth:
                    .cutoff(672)
            case .all:
                    .all
        }
    }
    
    static func options(for itemType: ItemIdentifier.ItemType) -> [Self] {
        switch itemType {
            case .podcast:
                [.disabled,
                 .one, .two, .three, .four, .five, .ten,
                 .oneDay, .oneWeek, .twoWeeks, .oneMonth,
                 .all
                ]
            case .series, .collection, .playlist:
                [.disabled,
                 .one, .two, .three, .four, .five, .ten,
                 .all
                ]
            default:
                [.disabled]
        }
    }
    static func parse(_ retrieval: PersistenceManager.ConvenienceDownloadSubsystem.GroupingRetrieval) -> Self? {
        switch retrieval {
            case .amount(let amount):
                switch amount {
                    case 1: return .one
                    case 2: return .two
                    case 3: return .three
                    case 4: return .four
                    case 5: return .five
                    case 10: return .ten
                        
                    default:
                        return nil
                }
            case .cutoff(let cutoff):
                switch cutoff {
                    case 24: return .oneDay
                    case 168: return .oneWeek
                    case 336: return .twoWeeks
                    case 672: return .oneMonth
                        
                    default:
                        return nil
                }
            case .all:
                return .all
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
#Preview {
    Text(verbatim: ":)")
        .sheet(isPresented: .constant(true)) {
            GroupingConfigurationSheet(itemID: Audiobook.fixture.id)
        }
        .previewEnvironment()
}
#endif
