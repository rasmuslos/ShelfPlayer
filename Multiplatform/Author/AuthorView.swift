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
    
    init(_ author: Author) {
        viewModel = .init(author: author)
    }
    
    private var loadingPresentation: some View {
        UnavailableWrapper {
            VStack(spacing: 0) {
                Header()
                LoadingView.Inner()
            }
        }
    }
    
    private var gridPresentation: some View {
        ScrollView {
            Header()
            
            if !viewModel.seriesLoader.items.isEmpty {
                HStack(spacing: 0) {
                    RowTitle(title: String(localized: "series"), fontDesign: .serif)
                    Spacer()
                }
                .padding(.top, 16)
                .padding(.horizontal, 20)
                
                SeriesGrid(series: viewModel.seriesLoader.items) {
                    if $0 == viewModel.seriesLoader.items.last {
                        viewModel.seriesLoader.didReachEndOfLoadedContent()
                    }
                }
                .padding(.horizontal, 20)
            }
            
            if !viewModel.sections.isEmpty || !viewModel.seriesLoader.items.isEmpty {
                HStack(spacing: 0) {
                    RowTitle(title: String(localized: "books"), fontDesign: .serif)
                    Spacer()
                }
                .padding(.top, 16)
                .padding(.horizontal, 20)
                
                AudiobookVGrid(sections: viewModel.sections) {
                    if $0 == viewModel.sections.last {
                        viewModel.audiobooksLoader.didReachEndOfLoadedContent()
                    }
                }
                .padding(.horizontal, 20)
            }
        }
    }
    private var listPresentation: some View {
        List {
            Header()
                .listRowSeparator(.hidden)
                .listRowInsets(.init(top: 0, leading: 0, bottom: 0, trailing: 0))
            
            if !viewModel.seriesLoader.items.isEmpty {
                RowTitle(title: String(localized: "series"), fontDesign: .serif)
                    .listRowSeparator(.hidden, edges: .top)
                    .listRowInsets(.init(top: 16, leading: 20, bottom: 0, trailing: 20))
                
                SeriesList(series: viewModel.seriesLoader.items) {
                    if $0 == viewModel.seriesLoader.items[max(0, viewModel.seriesLoader.items.endIndex - 4)] {
                        viewModel.seriesLoader.didReachEndOfLoadedContent()
                    }
                }
            }
            
            if !viewModel.sections.isEmpty {
                RowTitle(title: String(localized: "books"), fontDesign: .serif)
                    .listRowSeparator(.hidden, edges: .top)
                    .listRowInsets(.init(top: 16, leading: 20, bottom: 0, trailing: 20))
                
                AudiobookList(sections: viewModel.sections) {
                    if $0 == viewModel.sections[max(0, viewModel.sections.endIndex - 4)] {
                        viewModel.audiobooksLoader.didReachEndOfLoadedContent()
                    }
                }
            }
        }
        .listStyle(.plain)
    }
    
    var body: some View {
        Group {
            if viewModel.audiobooksLoader.items.isEmpty {
                loadingPresentation
            } else {
                switch viewModel.displayType {
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
                Button {
                    withAnimation(.snappy) {
                        viewModel.displayType = viewModel.displayType.next
                    }
                } label: {
                    Label(viewModel.displayType == .list ? "display.list" : "display.grid", systemImage: viewModel.displayType == .list ? "list.bullet" : "square.grid.2x2")
                }
            }
        }
        // .modifier(NowPlaying.SafeAreaModifier())
        .sensoryFeedback(.error, trigger: viewModel.notifyError)
        .environment(viewModel)
        .environment(\.displayContext, .author(author: viewModel.author))
        .onAppear {
            viewModel.library = library
        }
        .task {
            viewModel.load()
        }
        .refreshable {
            viewModel.load()
        }
        .sheet(isPresented: $viewModel.isDescriptionSheetVisible) {
            NavigationStack {
                ScrollView {
                    HStack(spacing: 0) {
                        if let description = viewModel.author.description {
                            Text(description)
                        } else {
                            Text("description.unavailable")
                        }
                        
                        Spacer(minLength: 0)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.horizontal, 20)
                }
                .navigationTitle(viewModel.author.name)
                .presentationDragIndicator(.visible)
            }
        }
        .userActivity("io.rfk.shelfplayer.item") { activity in
            activity.title = viewModel.author.name
            activity.isEligibleForHandoff = true
            activity.persistentIdentifier = viewModel.author.description
            
            Task {
                activity.webpageURL = try await viewModel.author.id.url
            }
        }
    }
}

#if DEBUG
#Preview {
    NavigationStack {
        AuthorView(.fixture)
    }
}
#endif
