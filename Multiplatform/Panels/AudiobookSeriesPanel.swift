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
                if lazyLoader.failed {
                    ErrorView()
                        .refreshable {
                            lazyLoader.refresh()
                        }
                } else {
                    LoadingView()
                        .onAppear {
                            lazyLoader.initialLoad()
                        }
                        .refreshable {
                            lazyLoader.refresh()
                        }
                }
            } else {
                Group {
                    switch seriesDisplayType {
                        case .grid:
                            ScrollView {
                                SeriesGrid(series: lazyLoader.items) {
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
                Menu("options", systemImage: "ellipsis.circle") {
                    ItemDisplayTypePicker(displayType: $seriesDisplayType)
                    ItemSortOrderPicker(sortOrder: $seriesSortOrder, ascending: $seriesAscending)
                }
            }
        }
        // .modifier(NowPlaying.SafeAreaModifier())
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

#Preview {
    AudiobookSeriesPanel()
}
