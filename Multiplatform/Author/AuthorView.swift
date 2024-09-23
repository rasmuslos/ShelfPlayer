//
//  AuthorView.swift
//  Audiobooks
//
//  Created by Rasmus Krämer on 05.10.23.
//

import SwiftUI
import Defaults
import ShelfPlayerKit

struct AuthorView: View {
    @Environment(\.library) private var library
    
    @State private var viewModel: AuthorViewModel
    
    init(_ author: Author, series: [Series] = [], audiobooks: [Audiobook] = []) {
        viewModel = .init(author: author, series: series, audiobooks: audiobooks)
    }
    
    var loadingPresentation: some View {
        VStack(spacing: 0) {
            Header()
            LoadingView()
        }
    }
    
    var gridPresentation: some View {
        ScrollView {
            Header()
            
            if !viewModel.audiobooks.isEmpty {
                HStack(spacing: 0) {
                    RowTitle(title: String(localized: "books"), fontDesign: .serif)
                    Spacer()
                }
                .padding(.top, 16)
                .padding(.horizontal, 20)
                
                AudiobookVGrid(audiobooks: viewModel.visible)
                    .padding(.horizontal, 20)
            }
            
            if !viewModel.series.isEmpty {
                HStack(spacing: 0) {
                    RowTitle(title: String(localized: "series"), fontDesign: .serif)
                    Spacer()
                }
                .padding(.top, 16)
                .padding(.horizontal, 20)
                
                SeriesGrid(series: viewModel.series)
                    .padding(.horizontal, 20)
            }
        }
    }
    var listPresentation: some View {
        List {
            Header()
                .listRowSeparator(.hidden)
                .listRowInsets(.init(top: 0, leading: 0, bottom: 0, trailing: 0))
            
            RowTitle(title: String(localized: "books"), fontDesign: .serif)
                .listRowSeparator(.hidden, edges: .top)
                .listRowInsets(.init(top: 16, leading: 20, bottom: 0, trailing: 20))
            
            AudiobookList(audiobooks: viewModel.visible)
            
            RowTitle(title: String(localized: "series"), fontDesign: .serif)
                .listRowSeparator(.hidden, edges: .top)
                .listRowInsets(.init(top: 16, leading: 20, bottom: 0, trailing: 20))
            
            SeriesList(series: viewModel.series)
        }
        .listStyle(.plain)
    }
    
    var body: some View {
        Group {
            if viewModel.audiobooks.isEmpty {
                loadingPresentation
            } else {
                switch viewModel.displayMode {
                    case .grid:
                        gridPresentation
                    case .list:
                        listPresentation
                }
            }
        }
        .navigationTitle(viewModel.author.name)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                AudiobookSortFilter(displayType: $viewModel.displayMode, filter: $viewModel.filter, sortOrder: $viewModel.sortOrder, ascending: $viewModel.ascending)
            }
        }
        .modifier(NowPlaying.SafeAreaModifier())
        .sensoryFeedback(.error, trigger: viewModel.errorNotify)
        .environment(viewModel)
        .onAppear {
            viewModel.library = library
        }
        .task {
            await viewModel.load()
        }
        .refreshable {
            await viewModel.load()
        }
        .sheet(isPresented: $viewModel.descriptionSheetVisible) {
            if let description = viewModel.author.description {
                NavigationStack {
                    Text(description)
                        .navigationTitle(viewModel.author.name)
                        .padding(20)
                    
                    Spacer()
                }
                .presentationDragIndicator(.visible)
            }
        }
        .userActivity("io.rfk.shelfplayer.author") {
            $0.title = viewModel.author.name
            $0.isEligibleForHandoff = true
            $0.persistentIdentifier = viewModel.author.id
            $0.targetContentIdentifier = "author:\(viewModel.author.id)"
            $0.userInfo = [
                "authorId": viewModel.author.id,
            ]
            $0.webpageURL = AudiobookshelfClient.shared.serverUrl.appending(path: "author").appending(path: viewModel.author.id)
        }
    }
}

#if DEBUG
#Preview {
    NavigationStack {
        AuthorView(.fixture)
    }
    .environment(NowPlaying.ViewModel())
}
#endif
