//
//  AudiobookSeriesPanel.swift
//  ShelfPlayer
//
//  Created by Rasmus Krämer on 23.04.24.
//

import SwiftUI
import ShelfPlayback

struct AudiobookSeriesPanel: View {
    @Environment(\.library) private var library

    @State private var seriesAscending = AppSettings.shared.seriesAscending
    @State private var seriesSortOrder = AppSettings.shared.seriesSortOrder
    @State private var seriesDisplayType = AppSettings.shared.seriesDisplayType

    @State private var lazyLoader = LazyLoadHelper<Series, Void>.series

    var body: some View {
        Group {
            if !lazyLoader.didLoad {
                Group {
                    if lazyLoader.failed {
                        ErrorView()
                    } else if lazyLoader.working {
                        LoadingView()
                    } else {
                        EmptyCollectionView()
                    }
                }
                .refreshable {
                    lazyLoader.refresh()
                }
            } else {
                Group {
                    switch seriesDisplayType {
                    case .grid:
                        ScrollView {
                            SeriesGrid(series: lazyLoader.items, showName: true) {
                                lazyLoader.performLoadIfRequired($0)
                            }
                            .padding(20)

                            PanelItemCountLabel(total: lazyLoader.totalCount, type: .series, isLoading: lazyLoader.isLoading)
                        }
                    case .list:
                        List {
                            SeriesList(series: lazyLoader.items) {
                                lazyLoader.performLoadIfRequired($0)
                            }

                            PanelItemCountLabel(total: lazyLoader.totalCount, type: .series, isLoading: lazyLoader.isLoading)
                        }
                        .listStyle(.plain)
                    }
                }
                .refreshable {
                    lazyLoader.refresh()
                }
            }
        }
        .navigationTitle("panel.series")
        .largeTitleDisplayMode()
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Menu("item.options", systemImage: "ellipsis") {
                    ItemDisplayTypePicker(displayType: $seriesDisplayType)
                    Section("item.sort") {
                        ItemSortOrderPicker(sortOrder: $seriesSortOrder, ascending: $seriesAscending)
                    }
                }
                .menuActionDismissBehavior(.disabled)
            }
        }
        .modifier(PlaybackSafeAreaPaddingModifier())
        .onAppear {
            lazyLoader.library = library
            lazyLoader.initialLoad()
        }
        .onChange(of: seriesAscending) {
            AppSettings.shared.seriesAscending = seriesAscending
            lazyLoader.ascending = seriesAscending
        }
        .onChange(of: seriesSortOrder) {
            AppSettings.shared.seriesSortOrder = seriesSortOrder
            lazyLoader.sortOrder = seriesSortOrder
        }
        .onChange(of: seriesDisplayType) {
            AppSettings.shared.seriesDisplayType = seriesDisplayType
        }
    }
}

#if DEBUG
#Preview {
    NavigationStack {
        AudiobookSeriesPanel()
            .previewEnvironment()
    }
}
#endif
