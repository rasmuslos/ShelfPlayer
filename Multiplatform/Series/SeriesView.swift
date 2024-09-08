//
//  SeriesView.swift
//  Audiobooks
//
//  Created by Rasmus Krämer on 05.10.23.
//

import SwiftUI
import Defaults
import ShelfPlayerKit

internal struct SeriesView: View {
    @Environment(\.libraryId) private var libraryId
    
    @State private var viewModel: SeriesViewModel
    
    init(_ series: Series) {
        viewModel = .init(series: series)
    }
    
    var body: some View {
        Group {
            switch viewModel.displayMode {
                case .grid:
                    ScrollView {
                        Header()
                        
                        HStack {
                            RowTitle(title: String(localized: "books"), fontDesign: .serif)
                            Spacer()
                        }
                        .padding(.horizontal, 20)
                        
                        AudiobookVGrid(audiobooks: viewModel.visible)
                            .padding(.horizontal, 20)
                    }
                case .list:
                    List {
                        Header()
                            .listRowSeparator(.hidden)
                            .listRowInsets(.init(top: 0, leading: 0, bottom: 0, trailing: 0))
                        
                        RowTitle(title: String(localized: "books"), fontDesign: .serif)
                            .listRowSeparator(.hidden, edges: .top)
                            .listRowInsets(.init(top: 0, leading: 20, bottom: 0, trailing: 20))
                        
                        AudiobookList(audiobooks: viewModel.visible)
                    }
                    .listStyle(.plain)
            }
        }
        .navigationTitle(viewModel.series.name)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                AudiobookSortFilter(displayType: $viewModel.displayMode, filter: $viewModel.filter, sortOrder: $viewModel.sortOrder, ascending: $viewModel.ascending)
            }
        }
        .environment(viewModel)
        .modifier(NowPlaying.SafeAreaModifier())
        .onAppear {
            viewModel.libraryID = libraryId
        }
        .task {
            await viewModel.load()
        }
        .refreshable {
            await viewModel.load()
        }
        .userActivity("io.rfk.shelfplayer.series") {
            $0.title = viewModel.series.name
            $0.isEligibleForHandoff = true
            $0.persistentIdentifier = viewModel.series.name
            $0.targetContentIdentifier = "series:\(viewModel.series.name)"
            $0.userInfo = [
                "seriesId": viewModel.series.id,
                "seriesName": viewModel.series.name,
            ]
            $0.webpageURL = AudiobookshelfClient.shared.serverUrl.appending(path: "library").appending(path: libraryId).appending(path: "series").appending(path: viewModel.series.id)
        }
    }
}

#if DEBUG
#Preview {
    NavigationStack {
        SeriesView(.fixture)
    }
}
#endif
