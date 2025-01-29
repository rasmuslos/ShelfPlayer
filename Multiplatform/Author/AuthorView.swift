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
    
    @ViewBuilder
    private var loadingPresentation: some View {
        UnavailableWrapper {
            VStack(spacing: 0) {
                Header()
                LoadingView.Inner()
            }
        }
    }
    
    @ViewBuilder
    private var gridPresentation: some View {
        ScrollView {
            Header()
            
            if !viewModel.seriesLoader.items.isEmpty {
                gridTitle(.init(localized: "series"))
                
                SeriesGrid(series: viewModel.seriesLoader.items) {
                    viewModel.seriesLoader.performLoadIfRequired($0)
                }
                .padding(.horizontal, 20)
            }
            
            if !viewModel.sections.isEmpty || !viewModel.seriesLoader.items.isEmpty {
                gridTitle(.init(localized: "books"))
                
                AudiobookVGrid(sections: viewModel.sections) {
                    viewModel.audiobooksLoader.performLoadIfRequired($0, in: viewModel.sections)
                }
                .padding(.horizontal, 20)
            }
        }
    }
    @ViewBuilder
    private var listPresentation: some View {
        List {
            Header()
                .listRowSeparator(.hidden)
                .listRowInsets(.init(top: 0, leading: 0, bottom: 0, trailing: 0))
            
            if !viewModel.seriesLoader.items.isEmpty {
                listTitle(.init(localized: "series"))
                
                SeriesList(series: viewModel.seriesLoader.items) {
                    viewModel.seriesLoader.performLoadIfRequired($0)
                }
            }
            
            if !viewModel.sections.isEmpty {
                listTitle(.init(localized: "books"))
                
                AudiobookList(sections: viewModel.sections) {
                    viewModel.audiobooksLoader.performLoadIfRequired($0, in: viewModel.sections)
                }
            }
        }
        .listStyle(.plain)
    }
    
    @ViewBuilder
    private func gridTitle(_ title: String) -> some View {
        HStack(spacing: 0) {
            RowTitle(title: title, fontDesign: .serif)
            Spacer()
        }
        .padding(.top, 16)
        .padding(.horizontal, 20)
    }
    @ViewBuilder
    private func listTitle(_ title: String) -> some View {
        RowTitle(title: title, fontDesign: .serif)
            .listRowSeparator(.hidden, edges: .top)
            .listRowInsets(.init(top: 16, leading: 20, bottom: 0, trailing: 20))
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
                Menu("options", systemImage: "ellipsis.circle") {
                    ItemDisplayTypePicker(displayType: $viewModel.displayType)
                    
                    Divider()
                    
                    Section("filter") {
                        ItemFilterPicker(filter: $viewModel.filter)
                    }
                }
            }
        }
        // .modifier(NowPlaying.SafeAreaModifier())
        .sensoryFeedback(.error, trigger: viewModel.notifyError)
        .sensoryFeedback(.error, trigger: viewModel.seriesLoader.notifyError)
        .sensoryFeedback(.error, trigger: viewModel.audiobooksLoader.notifyError)
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
