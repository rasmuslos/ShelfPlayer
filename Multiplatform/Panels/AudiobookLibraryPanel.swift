//
//  AudiobookLibraryView.swift
//  Multiplatform
//
//  Created by Rasmus Krämer on 23.04.24.
//

import SwiftUI
import ShelfPlayback

struct AudiobookLibraryPanel: View {
    @Environment(\.defaultMinListRowHeight) private var defaultMinListRowHeight
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    
    @Environment(Satellite.self) private var satellite
    @Environment(\.library) private var library
    
    @Default(.groupAudiobooksInSeries) private var groupAudiobooksInSeries
    
    @FocusState private var focused: Bool
    
    @State private var id = UUID()
    @State private var viewModel = LibraryViewModel()
    
    private var libraryRowCount: CGFloat {
        horizontalSizeClass == .compact && library != nil
        ? viewModel.tabs.isEmpty ? 0 : CGFloat(viewModel.tabs.count)
        : 0
    }
    @ViewBuilder
    private var libraryRows: some View {
        if horizontalSizeClass == .compact {
            if !viewModel.tabs.isEmpty {
                ForEach(Array(viewModel.tabs.enumerated()), id: \.element) { (index, row) in
                    NavigationLink(value: NavigationDestination.tabValue(row)) {
                        Label(row.label, systemImage: row.image)
                            .foregroundStyle(.primary)
                    }
                    .listRowSeparator(index == 0 ? .hidden : .automatic, edges: .top)
                }
            }
        }
    }
    @ViewBuilder
    private var libraryRowsList: some View {
        List {
            libraryRows
        }
        .frame(height: defaultMinListRowHeight * libraryRowCount)
    }
    
    @ViewBuilder
    private var listPresentation: some View {
        List {
            libraryRows
            
            AudiobookList(sections: viewModel.lazyLoader.items) {
                viewModel.lazyLoader.performLoadIfRequired($0)
            }
        }
        .id(id)
    }
    @ViewBuilder
    private var gridPresentation: some View {
        ScrollView {
            libraryRowsList
            
            AudiobookVGrid(sections: viewModel.lazyLoader.items) {
                viewModel.lazyLoader.performLoadIfRequired($0)
            }
            .id(id)
            .padding(.horizontal, 20)
        }
    }
    
    var body: some View {
        Group {
            if viewModel.showPlaceholders {
                ScrollView {
                    ZStack {
                        Spacer()
                            .containerRelativeFrame([.horizontal, .vertical])
                        
                        VStack(spacing: 0) {
                            libraryRowsList
                                .frame(alignment: .top)
                            
                            Group {
                                if viewModel.isLoading {
                                    LoadingView.Inner()
                                } else if viewModel.lazyLoader.failed {
                                    ErrorViewInner()
                                } else {
                                    EmptyCollectionView.Inner()
                                }
                            }
                            .frame(alignment: .center)
                        }
                    }
                }
            } else {
                switch viewModel.displayType {
                    case .grid:
                        gridPresentation
                    case .list:
                        listPresentation
                }
            }
        }
        .listStyle(.plain)
        .navigationTitle("panel.library")
        .largeTitleDisplayMode()
        .toolbar {
            ToolbarItemGroup(placement: .topBarTrailing) {
                if let genres = viewModel.genres, !genres.isEmpty {
                    Menu("item.genres", systemImage: "tag") {
                        ForEach(genres.sorted(by: <), id: \.hashValue) {
                            Toggle($0, isOn: viewModel.binding(for: $0))
                        }
                    }
                    .labelStyle(.iconOnly)
                    .symbolVariant(viewModel.lazyLoader.filteredGenre != nil ? .fill : .none)
                } else if viewModel.genres == nil {
                    ProgressView()
                }
                
                Menu("item.options", systemImage: viewModel.filter != .all ? "line.3.horizontal.decrease" : "line.3.horizontal") {
                    ItemDisplayTypePicker(displayType: $viewModel.displayType)
                    
                    Divider()
                    
                    Section("item.filter") {
                        ItemFilterPicker(filter: $viewModel.filter, restrictToPersisted: $viewModel.restrictToPersisted)
                    }
                    
                    Section("item.sort") {
                        ItemSortOrderPicker(sortOrder: $viewModel.sortOrder, ascending: $viewModel.ascending)
                    }
                    
                    Divider()
                    
                    Button("action.customize", systemImage: "list.bullet.badge.ellipsis") {
                        satellite.present(.customizeLibrary(viewModel.library, .library))
                    }
                    
                    Toggle("item.groupAudiobooksBySeries", systemImage: "square.3.layers.3d.down.forward", isOn: $groupAudiobooksInSeries)
                }
                .menuActionDismissBehavior(.disabled)
            }
        }
        .modifier(PlaybackSafeAreaPaddingModifier())
        .sensoryFeedback(.error, trigger: viewModel.notifyError)
        .onChange(of: viewModel.filter) {
            viewModel.lazyLoader.filter = viewModel.filter
        }
        .onChange(of: viewModel.restrictToPersisted) {
            viewModel.lazyLoader.restrictToPersisted = viewModel.restrictToPersisted
        }
        .onChange(of: viewModel.sortOrder) {
            viewModel.lazyLoader.sortOrder = viewModel.sortOrder
        }
        .onChange(of: viewModel.ascending) {
            viewModel.lazyLoader.ascending = viewModel.ascending
        }
        .task {
            viewModel.load()
        }
        .refreshable {
            viewModel.refresh()
        }
        .onAppear {
            viewModel.library = library
            viewModel.lazyLoader.initialLoad()
        }
        .onReceive(RFNotification[.invalidateTabs].publisher()) {
            viewModel.loadTabs()
        }
    }
}

// MARK: View Model

@MainActor @Observable
private final class LibraryViewModel {
    @ObservableDefault(.audiobooksFilter) @ObservationIgnored
    var filter: ItemFilter
    @ObservableDefault(.audiobooksRestrictToPersisted) @ObservationIgnored
    var restrictToPersisted: Bool
    @ObservableDefault(.audiobooksDisplayType) @ObservationIgnored
    var displayType: ItemDisplayType
    
    @ObservableDefault(.audiobooksSortOrder) @ObservationIgnored
    var sortOrder: AudiobookSortOrder
    @ObservableDefault(.audiobooksAscending) @ObservationIgnored
    var ascending: Bool
    
    var tabs = [TabValue]()
    
    private(set) var genres: [String]? = nil
    var isGenreFilterPresented = false
    
    let lazyLoader = LazyLoadHelper<Audiobook, AudiobookSortOrder>.audiobooks
    
    var library: Library! {
        didSet {
            lazyLoader.library = library
        }
    }
    
    private(set) var notifyError = false
    
    // MARK: Helper
    
    var showPlaceholders: Bool {
        !lazyLoader.didLoad
    }
    var isLoading: Bool {
        lazyLoader.working && !lazyLoader.failed
    }
    
    nonisolated func load() {
        loadTabs()
        loadGenres()
    }
    nonisolated func refresh() {
        lazyLoader.refresh()
        
        loadTabs()
        loadGenres()
    }
    
    nonisolated func loadTabs() {
        Task {
            let tabs = await PersistenceManager.shared.customization.configuredTabs(for: library, scope: .library)
            
            await MainActor.withAnimation {
                self.tabs = tabs
            }
        }
    }
}

// MARK: Genres

extension LibraryViewModel {
    func binding(for genre: String) -> Binding<Bool> {
        .init { self.lazyLoader.filteredGenre == genre } set: {
            if $0 {
                self.lazyLoader.filteredGenre = genre
            } else {
                self.lazyLoader.filteredGenre = nil
            }
        }
    }
    
    private nonisolated func loadGenres() {
        Task {
            guard let library = await library else {
                return
            }
            
            do {
                let genres = try await ABSClient[library.connectionID].genres(from: library.id)
                
                await MainActor.withAnimation {
                    self.genres = genres
                }
            } catch {
                await MainActor.withAnimation {
                    notifyError.toggle()
                    genres = []
                }
            }
        }
    }
}

// MARK: Scopes

private enum SearchScope: Int, Hashable, Identifiable, CaseIterable {
    case all
    case series
    case authors
    case narrators
    case audiobooks
    
    var id: Int {
        rawValue
    }
    var label: LocalizedStringKey {
        switch self {
            case .all:
                "filter.all"
            case .series:
                "item.series"
            case .authors:
                "item.author"
            case .narrators:
                "item.narrator"
            case .audiobooks:
                "item.audiobook"
        }
    }
    
    func shouldShow(_ other: SearchScope) -> Bool {
        if self == other {
            return true
        } else {
            return self == .all
        }
    }
}

#if DEBUG
#Preview {
    NavigationStack {
        AudiobookLibraryPanel()
    }
    .previewEnvironment()
    .environment(\.library, .init(id: "fixture", connectionID: "fixture", name: "Fixture", type: "book", index: 0))
}
#endif
