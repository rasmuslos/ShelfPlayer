//
//  AudiobookListenNowView.swift
//  Multiplatform
//
//  Created by Rasmus Krämer on 23.04.24.
//

import SwiftUI
import ShelfPlayback

struct AudiobookHomePanel: View {
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    @Environment(\.library) private var library
    
    @Default(.showAuthorsRow) private var showAuthorsRow
    
    @State private var _authors = [HomeRow<Person>]()
    @State private var audiobooks = [HomeRow<Audiobook>]()
    
    @State private var downloaded = [Audiobook]()
    
    @State private var didFail = false
    @State private var isLoading = false
    @State private var notifyError = false
    
    private var authors: [HomeRow<Person>] {
        showAuthorsRow ? _authors : []
    }
    private var relevantItemIDs: [ItemIdentifier] {
        audiobooks.flatMap(\.itemIDs)
    }
    
    var body: some View {
        Group {
            if audiobooks.isEmpty && authors.isEmpty {
                Group {
                    if didFail {
                        ErrorView()
                    } else if isLoading {
                        LoadingView()
                    } else {
                        EmptyCollectionView()
                    }
                }
            } else {
                ScrollView {
                    LazyVStack(spacing: 16) {
                        ForEach(audiobooks) {
                            AudiobookRow(title: $0.localizedLabel, small: false, audiobooks: $0.entities)
                        }
                        
                        ForEach(authors) { row in
                            VStack(alignment: .leading, spacing: 0) {
                                RowTitle(title: row.localizedLabel)
                                    .padding(.bottom, 12)
                                    .padding(.horizontal, 20)
                                
                                PersonGrid(people: row.entities)
                            }
                        }
                        
                         if !downloaded.isEmpty {
                             AudiobookRow(title: String(localized: "row.downloaded"), small: false, audiobooks: downloaded)
                         }
                    }
                }
            }
        }
        .navigationTitle(library?.name ?? String(localized: "error.unavailable"))
        .modifier(PlaybackSafeAreaPaddingModifier())
        .sensoryFeedback(.error, trigger: notifyError)
        .toolbar {
            if horizontalSizeClass == .compact {
                ToolbarItemGroup(placement: .topBarTrailing) {
                    ListenNowSheetToggle()
                    
                    Menu("navigation.library.select", systemImage: "books.vertical.fill") {
                        LibraryPicker()
                    }
                }
            }
        }
        .task {
            fetchItems()
        }
        .refreshable {
            fetchItems(refresh: true)
            ListenedTodayTracker.shared.refresh()
        }
        .onReceive(RFNotification[.progressEntityUpdated].publisher()) { (connectionID, primaryID, groupingID, entity) in
            guard UIApplication.shared.applicationState == .active else {
                return
            }
            
            guard relevantItemIDs.contains(where: {
                $0.isEqual(primaryID: primaryID, groupingID: groupingID, connectionID: connectionID)
                || (entity?.progress ?? 0) > 0
            }) else {
                return
            }
            
            fetchItems()
        }
        .onReceive(RFNotification[.downloadStatusChanged].publisher()) {
            if let (itemID, _) = $0, itemID.libraryID != library?.id {
                return
            }
            
            Task {
                await fetchLocalItems()
            }
        }
    }
}

private extension AudiobookHomePanel {
    nonisolated func fetchItems(refresh: Bool = false) {
        Task {
            await MainActor.withAnimation {
                isLoading = true
                didFail = false
            }
            
            await withTaskGroup {
                $0.addTask { await fetchLocalItems() }
                $0.addTask { await fetchRemoteItems(refresh: refresh) }
            }
            
            await MainActor.withAnimation {
                isLoading = false
            }
        }
    }
    nonisolated func fetchLocalItems() async {
        guard let library = await library else {
            return
        }
        
        do {
            let audiobooks = try await PersistenceManager.shared.download.audiobooks(in: library.id)
            
            await MainActor.withAnimation {
                downloaded = audiobooks
            }
        } catch {
            await MainActor.withAnimation {
                notifyError.toggle()
            }
        }
    }
    nonisolated func fetchRemoteItems(refresh: Bool) async {
        guard let library = await library else {
            return
        }
        
        let discoverRow = refresh ? nil : await audiobooks.first { $0.id == "discover" }
        
        do {
            let home: ([HomeRow<Audiobook>], [HomeRow<Person>]) = try await ABSClient[library.connectionID].home(for: library.id)
            let audiobooks = await HomeRow.prepareForPresentation(home.0, connectionID: library.connectionID).map {
                if $0.id == "discover", let discoverRow {
                    discoverRow
                } else {
                    $0
                }
            }
            
            await MainActor.withAnimation {
                _authors = home.1
                self.audiobooks = audiobooks
            }
        } catch {
            await MainActor.withAnimation {
                didFail = true
                notifyError.toggle()
            }
        }
    }
}

#if DEBUG
#Preview {
    NavigationStack {
        AudiobookHomePanel()
    }
    .previewEnvironment()
}
#endif
