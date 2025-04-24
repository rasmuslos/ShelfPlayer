//
//  AudiobookSeriesView.swift
//  Multiplatform
//
//  Created by Rasmus Krämer on 23.04.24.
//

import SwiftUI
import Defaults
import ShelfPlayerKit

struct AudiobookSeriesPanel: View {
    @Environment(\.library) private var library
    
    @Default(.seriesAscending) private var seriesAscending
    @Default(.seriesSortOrder) private var seriesSortOrder
    @Default(.seriesDisplayType) private var seriesDisplayType
    
    @State private var lazyLoader = LazyLoadHelper<Series, Void>.series
    
    var body: some View {
        Group {
            if !lazyLoader.didLoad {
                Group {
                    if lazyLoader.failed {
                        ErrorView()
                    } else if lazyLoader.working {
                        LoadingView()
                            .onAppear {
                                lazyLoader.initialLoad()
                            }
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
                        }
                    case .list:
                        List {
                            SeriesList(series: lazyLoader.items) {
                                lazyLoader.performLoadIfRequired($0)
                            }
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
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Menu("item.options", systemImage: "ellipsis.circle") {
                    ItemDisplayTypePicker(displayType: $seriesDisplayType)
                    ItemSortOrderPicker(sortOrder: $seriesSortOrder, ascending: $seriesAscending)
                }
            }
        }
        .modifier(PlaybackSafeAreaPaddingModifier())
        .onAppear {
            lazyLoader.library = library
        }
        .onChange(of: seriesAscending) {
            lazyLoader.ascending = seriesAscending
        }
        .onChange(of: seriesSortOrder) {
            lazyLoader.sortOrder = seriesSortOrder
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
