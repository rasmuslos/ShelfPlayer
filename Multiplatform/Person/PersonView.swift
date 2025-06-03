//
//  PersonView.swift
//  Audiobooks
//
//  Created by Rasmus Krämer on 05.10.23.
//

import SwiftUI
import ShelfPlayback

struct PersonView: View {
    @Environment(\.library) private var library
    
    @State private var viewModel: PersonViewModel
    
    init(_ person: Person) {
        viewModel = .init(person: person)
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
    
    private var audiobooksRowTitle: String? {
        if viewModel.person.id.type == .author {
            String(localized: "item.related.author.audiobooks")
        } else {
            nil
        }
    }
    
    @ViewBuilder
    private var gridPresentation: some View {
        ScrollView {
            Header()
            
            if let seriesLoader = viewModel.seriesLoader, !seriesLoader.items.isEmpty {
                gridTitle(.init(localized: "item.related.author.series"), count: seriesLoader.totalCount)
                
                SeriesGrid(series: seriesLoader.items, showName: true) {
                    seriesLoader.performLoadIfRequired($0)
                }
                .padding(.horizontal, 20)
            }
            
            if !viewModel.sections.isEmpty {
                if let audiobooksRowTitle {
                    gridTitle(audiobooksRowTitle, count: viewModel.audiobooksLoader.totalCount)
                }
                
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
            
            if let seriesLoader = viewModel.seriesLoader, !seriesLoader.items.isEmpty {
                listTitle(.init(localized: "item.related.author.series"), count: seriesLoader.totalCount)
                
                SeriesList(series: seriesLoader.items) {
                    seriesLoader.performLoadIfRequired($0)
                }
            }
            
            if !viewModel.sections.isEmpty {
                if let audiobooksRowTitle {
                    listTitle(audiobooksRowTitle, count: viewModel.audiobooksLoader.totalCount)
                }
                
                AudiobookList(sections: viewModel.sections) {
                    viewModel.audiobooksLoader.performLoadIfRequired($0, in: viewModel.sections)
                }
            }
        }
        .listStyle(.plain)
    }
    
    @ViewBuilder
    private func gridTitle(_ title: String, count: Int) -> some View {
        HStack(spacing: 0) {
            RowTitle(title: title, fontDesign: .serif)
            
            Spacer()
            
            if count > 0 {
                Text(count, format: .number)
                    .font(.caption)
                    .fontDesign(.rounded)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(.top, 16)
        .padding(.horizontal, 20)
    }
    @ViewBuilder
    private func listTitle(_ title: String, count: Int) -> some View {
        HStack(alignment: .firstTextBaseline, spacing: 0) {
            RowTitle(title: title, fontDesign: .serif)
            
            Spacer()
            
            if count > 0 {
                Text(count, format: .number)
                    .font(.caption)
                    .fontDesign(.rounded)
                    .foregroundStyle(.secondary)
            }
        }
        .listRowSeparator(.hidden, edges: .top)
        .listRowInsets(.init(top: 16, leading: 20, bottom: 0, trailing: 20))
    }
    
    var body: some View {
        Group {
            if !viewModel.audiobooksLoader.didLoad && viewModel.seriesLoader?.didLoad == false {
                loadingPresentation
            } else if viewModel.sections.isEmpty && viewModel.seriesLoader?.items.isEmpty == true {
                UnavailableWrapper {
                    VStack(spacing: 0) {
                        Header()
                        EmptyCollectionView()
                    }
                }
            } else {
                switch viewModel.displayType {
                case .grid:
                    gridPresentation
                case .list:
                    listPresentation
                }
            }
        }
        .navigationTitle(viewModel.person.name)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Menu("item.options", systemImage: viewModel.filter != .all ? "line.3.horizontal.decrease.circle.fill" : "line.3.horizontal.decrease.circle") {
                    ItemDisplayTypePicker(displayType: $viewModel.displayType)
                    
                    Divider()
                    
                    Section("item.filter") {
                        ItemFilterPicker(filter: $viewModel.filter, restrictToPersisted: $viewModel.restrictToPersisted)
                    }
                }
                .menuActionDismissBehavior(.disabled)
            }
        }
        .modifier(PlaybackSafeAreaPaddingModifier())
        .sensoryFeedback(.error, trigger: viewModel.notifyError)
        .sensoryFeedback(.error, trigger: viewModel.seriesLoader?.notifyError)
        .sensoryFeedback(.error, trigger: viewModel.audiobooksLoader.notifyError)
        .environment(viewModel)
        .environment(\.displayContext, .person(person: viewModel.person))
        .onAppear {
            viewModel.library = library
        }
        .task {
            viewModel.load(refresh: false)
        }
        .refreshable {
            viewModel.load(refresh: true)
        }
        .onChange(of: viewModel.filter) {
            viewModel.seriesLoader?.filter = viewModel.filter
            viewModel.audiobooksLoader.filter = viewModel.filter
        }
        .onChange(of: viewModel.restrictToPersisted) {
            viewModel.seriesLoader?.restrictToPersisted = viewModel.restrictToPersisted
            viewModel.audiobooksLoader.restrictToPersisted = viewModel.restrictToPersisted
        }
        .userActivity("io.rfk.shelfplayer.item") { activity in
            activity.title = viewModel.person.name
            activity.isEligibleForHandoff = true
            activity.persistentIdentifier = viewModel.person.description
            
            Task {
                activity.webpageURL = try await viewModel.person.id.url
            }
        }
    }
}

#if DEBUG
#Preview {
    NavigationStack {
        PersonView(.authorFixture)
    }
    .previewEnvironment()
}
#endif
