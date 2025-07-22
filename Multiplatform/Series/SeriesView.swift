//
//  SeriesView.swift
//  Audiobooks
//
//  Created by Rasmus Krämer on 05.10.23.
//

import SwiftUI
import ShelfPlayback

struct SeriesView: View {
    @Environment(Satellite.self) private var satellite
    @Environment(\.library) private var library
    
    @State private var viewModel: SeriesViewModel
    
    init(_ series: Series) {
        viewModel = .init(series: series)
    }
    
    @ViewBuilder
    private var rowTitle: some View {
        HStack(spacing: 0) {
            RowTitle(title: String(localized: "item.related.series.audiobooks"), fontDesign: .serif)
            
            Spacer(minLength: 0)
            
            if viewModel.lazyLoader.totalCount > 0 {
                Text(viewModel.lazyLoader.totalCount, format: .number)
                    .font(.caption)
                    .fontDesign(.rounded)
                    .foregroundStyle(.secondary)
            }
        }
        .accessibilityElement(children: .ignore)
        .accessibilityAddTraits(.isHeader)
        .accessibilityLabel(Text("item.related.series.audiobooks"))
        .accessibilityValue(Text(verbatim: "\(viewModel.lazyLoader.totalCount)"))
    }
    
    var body: some View {
        Group {
            if !viewModel.lazyLoader.didLoad {
                if viewModel.lazyLoader.failed {
                    ErrorView()
                } else {
                    LoadingView()
                }
            } else if viewModel.sections.isEmpty {
                EmptyCollectionView()
            } else {
                switch viewModel.displayType {
                case .grid:
                    ScrollView {
                        Header()
                            .padding(.bottom, 12)
                        
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
        .sensoryFeedback(.error, trigger: viewModel.lazyLoader.notifyError)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Menu("item.options", systemImage: viewModel.filter != .all ? "line.3.horizontal.decrease.circle.fill" : "line.3.horizontal.decrease.circle") {
                    ItemDisplayTypePicker(displayType: $viewModel.displayType)
                    
                    Divider()
                    
                    Section("item.filter") {
                        ItemFilterPicker(filter: $viewModel.filter, restrictToPersisted: $viewModel.restrictToPersisted)
                    }
                    
                    Divider()
                    
                    Button("item.configure", systemImage: "gearshape") {
                        satellite.present(.configureGrouping(viewModel.series.id))
                    }
                }
                .menuActionDismissBehavior(.disabled)
            }
        }
        .environment(viewModel)
        .environment(\.displayContext, .series(viewModel.series))
        .modifier(PlaybackSafeAreaPaddingModifier())
        .onAppear {
            viewModel.library = library
            viewModel.lazyLoader.initialLoad()
        }
        .refreshable {
            viewModel.refresh()
        }
        .onChange(of: viewModel.filter) {
            viewModel.lazyLoader.filter = viewModel.filter
        }
        .onChange(of: viewModel.restrictToPersisted) {
            viewModel.lazyLoader.restrictToPersisted = viewModel.restrictToPersisted
        }
        .userActivity("io.rfk.shelfplayer.item") { activity in
            activity.title = viewModel.series.name
            activity.isEligibleForHandoff = true
            activity.isEligibleForPrediction = true
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
    .previewEnvironment()
}
#endif
