//
//  AudiobookSeriesView.swift
//  Multiplatform
//
//  Created by Rasmus Krämer on 23.04.24.
//

import SwiftUI
import Defaults
import ShelfPlayerKit

internal struct AudiobookSeriesPanel: View {
    @Environment(\.libraryId) private var libraryId
    @Default(.seriesDisplay) private var seriesDisplay
    
    @State private var failed = false
    @State private var series = [Series]()
    
    var body: some View {
        Group {
            if series.isEmpty {
                if failed {
                    ErrorView()
                        .refreshable {
                            await fetchItems()
                        }
                } else {
                    LoadingView()
                        .task {
                            await fetchItems()
                        }
                }
            } else {
                Group {
                    switch seriesDisplay {
                        case .grid:
                            ScrollView {
                                SeriesGrid(series: series)
                                    .padding(20)
                            }
                        case .list:
                            List {
                                SeriesList(series: series)
                            }
                            .listStyle(.plain)
                    }
                }
                .toolbar {
                    ToolbarItem(placement: .topBarTrailing) {
                        Button {
                            withAnimation {
                                seriesDisplay = seriesDisplay == .list ? .grid : .list
                            }
                        } label: {
                            Label("sort.\(seriesDisplay == .list ? "list" : "grid")", systemImage: seriesDisplay == .list ? "list.bullet" : "square.grid.2x2")
                        }
                    }
                }
                .refreshable {
                    await fetchItems()
                }
            }
        }
        .navigationTitle("title.series")
        .modifier(NowPlaying.SafeAreaModifier())
    }
    
    private nonisolated func fetchItems() async {
        await MainActor.run {
            failed = false
        }
        
        guard let series = try? await AudiobookshelfClient.shared.series(libraryId: libraryId) else {
            await MainActor.run {
                failed = true
            }
            
            return
        }
        
        await MainActor.run {
            self.series = series
        }
    }
}

#Preview {
    AudiobookSeriesPanel()
}
