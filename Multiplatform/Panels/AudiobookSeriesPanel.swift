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
    
    @Default(.seriesDisplayType) private var seriesDisplayType
    
    @State private var lazyLoader = LazyLoadHelper<Series, Void>.series
    
    var body: some View {
        Group {
            if lazyLoader.items.isEmpty {
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
                .toolbar {
                    ToolbarItem(placement: .topBarTrailing) {
                        Button {
                            withAnimation {
                                seriesDisplayType = seriesDisplayType == .list ? .grid : .list
                            }
                        } label: {
                            Label(seriesDisplayType == .list ? "display.list" : "display.grid", systemImage: seriesDisplayType == .list ? "list.bullet" : "square.grid.2x2")
                        }
                    }
                }
                .refreshable {
                    lazyLoader.refresh()
                }
            }
        }
        .navigationTitle("panel.series")
        // .modifier(NowPlaying.SafeAreaModifier())
        .onAppear {
            lazyLoader.library = library
        }
    }
}

#Preview {
    AudiobookSeriesPanel()
}
