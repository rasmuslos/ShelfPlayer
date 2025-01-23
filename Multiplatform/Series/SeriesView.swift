//
//  SeriesView.swift
//  Audiobooks
//
//  Created by Rasmus Krämer on 05.10.23.
//

import SwiftUI
import Defaults
import ShelfPlayerKit

struct SeriesView: View {
    @Environment(\.library) private var library
    
    @State private var viewModel: SeriesViewModel
    
    init(_ series: Series) {
        viewModel = .init(series: series)
    }
    
    @ViewBuilder
    private var rowTitle: some View {
        HStack(spacing: 0) {
            RowTitle(title: String(localized: "books"), fontDesign: .serif)
            Spacer(minLength: 0)
        }
    }
    
    var body: some View {
        Group {
            if viewModel.lazyLoader.items.isEmpty {
                if viewModel.lazyLoader.failed {
                    ErrorView()
                } else {
                    LoadingView()
                }
            } else {
                switch viewModel.displayType {
                case .grid:
                    ScrollView {
                        Header()
                        
                        rowTitle
                            .padding(.horizontal, 20)
                        
                        AudiobookVGrid(sections: viewModel.sections) {
                            if $0 == viewModel.sections.last {
                                viewModel.lazyLoader.didReachEndOfLoadedContent()
                            }
                        }
                        .padding(.horizontal, 20)
                    }
                case .list:
                    List {
                        Header()
                            .listRowSeparator(.hidden)
                            .listRowInsets(.init(top: 0, leading: 0, bottom: 0, trailing: 0))
                        
                        rowTitle
                            .listRowSeparator(.hidden, edges: .top)
                            .listRowInsets(.init(top: 16, leading: 20, bottom: 0, trailing: 20))
                        
                        AudiobookList(sections: viewModel.sections) {
                            if $0 == viewModel.sections[max(0, viewModel.sections.endIndex - 4)] {
                                viewModel.lazyLoader.didReachEndOfLoadedContent()
                            }
                        }
                    }
                    .listStyle(.plain)
                }
            }
        }
        .navigationTitle(viewModel.series.name)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    withAnimation(.snappy) {
                        viewModel.displayType = viewModel.displayType.next
                    }
                } label: {
                    Label(viewModel.displayType == .list ? "display.list" : "display.grid", systemImage: viewModel.displayType == .list ? "list.bullet" : "square.grid.2x2")
                }
            }
        }
        .environment(viewModel)
        .environment(\.displayContext, .series(series: viewModel.series))
        // .modifier(NowPlaying.SafeAreaModifier())
        .onAppear {
            viewModel.library = library
            viewModel.lazyLoader.initialLoad()
        }
        .refreshable {
            await viewModel.lazyLoader.refresh()
        }
        .userActivity("io.rfk.shelfplayer.item") { activity in
            activity.title = viewModel.series.name
            activity.isEligibleForHandoff = true
            activity.persistentIdentifier = viewModel.series.id.description
            
            Task {
                try await activity.webpageURL = viewModel.series.id.url
            }
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
