//
//  PodcastLibraryView.swift
//  Multiplatform
//
//  Created by Rasmus Krämer on 23.04.24.
//

import SwiftUI
import ShelfPlayback

struct PodcastLibraryPanel: View {
    @Environment(\.defaultMinListRowHeight) private var defaultMinListRowHeight
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    @Environment(\.library) private var library
    
    @Environment(Satellite.self) private var satellite

    @Default(.podcastsAscending) private var podcastsAscending
    @Default(.podcastsSortOrder) private var podcastsSortOrder
    @Default(.podcastsDisplayType) private var podcastsDisplayType

    @State private var id = UUID()
    @State private var tabs = [TabValue]()
    @State private var lazyLoader = LazyLoadHelper<Podcast, PodcastSortOrder>.podcasts

    private var showPlaceholders: Bool {
        !lazyLoader.didLoad
    }
    private var isLoading: Bool {
        lazyLoader.working && !lazyLoader.failed
    }

    private var libraryRowCount: CGFloat {
        horizontalSizeClass == .compact && library != nil
        ? (tabs.isEmpty ? 0 : CGFloat(tabs.count))
        : 0
    }

    @ViewBuilder
    private var libraryRows: some View {
        if horizontalSizeClass == .compact {
            if !tabs.isEmpty {
                ForEach(Array(tabs.enumerated()), id: \.element) { (index, row) in
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

            PodcastList(podcasts: lazyLoader.items) {
                lazyLoader.performLoadIfRequired($0)
            }
            
            PanelItemCountLabel(total: lazyLoader.totalCount, type: .podcast, isLoading: lazyLoader.isLoading)
            
        }
        .id(id)
        .listStyle(.plain)
    }

    @ViewBuilder
    private var gridPresentation: some View {
        ScrollView {
            libraryRowsList

            PodcastVGrid(podcasts: lazyLoader.items) {
                lazyLoader.performLoadIfRequired($0)
            }
            .id(id)
            .padding(.horizontal, 20)
            
            PanelItemCountLabel(total: lazyLoader.totalCount, type: .podcast, isLoading: lazyLoader.isLoading)
        }
    }

    var body: some View {
        Group {
            if showPlaceholders {
                ScrollView {
                    ZStack {
                        Spacer()
                            .containerRelativeFrame([.horizontal, .vertical])

                        VStack(spacing: 0) {
                            libraryRowsList
                                .frame(alignment: .top)

                            Group {
                                if isLoading {
                                    LoadingView.Inner()
                                } else if lazyLoader.failed {
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
                switch podcastsDisplayType {
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
            ToolbarItem(placement: .topBarTrailing) {
                Menu("item.options", systemImage: "ellipsis") {
                    ItemDisplayTypePicker(displayType: $podcastsDisplayType)
                    
                    Section("item.sort") {
                        ItemSortOrderPicker(sortOrder: $podcastsSortOrder, ascending: $podcastsAscending)
                    }
                    
                    if let library {
                        Divider()
                        
                        Button("action.customize", systemImage: "list.bullet.badge.ellipsis") {
                            satellite.present(.customizeLibrary(library, .library))
                        }
                    }
                }
                .menuActionDismissBehavior(.disabled)
            }
        }
        .modifier(PlaybackSafeAreaPaddingModifier())
        .onChange(of: podcastsAscending) {
            lazyLoader.ascending = podcastsAscending
        }
        .onChange(of: podcastsSortOrder) {
            lazyLoader.sortOrder = podcastsSortOrder
        }
        .refreshable {
            lazyLoader.refresh()
            loadTabs()
        }
        .onAppear {
            lazyLoader.library = library
            lazyLoader.initialLoad()
            loadTabs()
        }
        .onReceive(RFNotification[.invalidateTabs].publisher()) { _ in
            loadTabs()
        }
    }
}

private extension PodcastLibraryPanel {
    func loadTabs() {
        Task {
            guard let library else {
                return
            }
            
            tabs = await PersistenceManager.shared.customization.configuredTabs(for: library.id, scope: .library)
        }
    }
}

#if DEBUG
#Preview {
    NavigationStack {
        PodcastLibraryPanel()
    }
    .previewEnvironment()
}
#endif

