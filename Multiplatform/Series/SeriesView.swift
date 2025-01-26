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
            if !viewModel.lazyLoader.didLoad {
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
                            viewModel.lazyLoader.performLoadIfRequired($0, in: viewModel.sections)
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
                            viewModel.lazyLoader.performLoadIfRequired($0, in: viewModel.sections)
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
                Menu("options", systemImage: viewModel.filter != .all ? "line.3.horizontal.decrease.circle.fill" : "line.3.horizontal.decrease.circle") {
                    ItemDisplayTypePicker(displayType: $viewModel.displayType)
                    
                    Divider()
                    
                    Section("filter") {
                        ItemFilterPicker(filter: $viewModel.filter)
                    }
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
            viewModel.lazyLoader.refresh()
        }
        .onChange(of: viewModel.filter) {
            viewModel.lazyLoader.filter = viewModel.filter
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
