//
//  AudiobookSeriesView.swift
//  Multiplatform
//
//  Created by Rasmus Krämer on 23.04.24.
//

import SwiftUI
import ShelfPlayerKit

struct AudiobookSeriesView: View {
    @Environment(\.libraryId) var libraryId
    
    @State var failed = false
    @State var series = [Series]()
    
    var body: some View {
        Group {
            if series.isEmpty {
                if failed {
                    ErrorView()
                } else {
                    LoadingView()
                        .task { await fetchItems() }
                }
            } else {
                ScrollView {
                    SeriesGrid(series: series)
                        .padding(20)
                }
                .modifier(NowPlaying.SafeAreaModifier())
            }
        }
        .navigationTitle("title.series")
        .navigationBarTitleDisplayMode(.large)
        .refreshable { await fetchItems() }
    }
}

extension AudiobookSeriesView {
    func fetchItems() async {
        failed = false
        
        if let series = try? await AudiobookshelfClient.shared.series(libraryId: libraryId) {
            self.series = series
        } else {
            failed = true
        }
    }
}

#Preview {
    AudiobookSeriesView()
}
