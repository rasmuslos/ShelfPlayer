//
//  AudiobookListenNowView.swift
//  Multiplatform
//
//  Created by Rasmus Krämer on 23.04.24.
//

import SwiftUI
import Defaults
import ShelfPlayerKit
import SPPlayback

struct AudiobookHomePanel: View {
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    @Environment(\.library) private var library
    
    @Default(.showAuthorsRow) private var showAuthorsRow
    
    @State private var _authors = [HomeRow<Author>]()
    @State private var audiobooks = [HomeRow<Audiobook>]()
    
    @State private var downloaded = [Audiobook]()
    
    @State private var failed = false
    @State private var notifyError = false
    
    private var authors: [HomeRow<Author>] {
        showAuthorsRow ? _authors : []
    }
    private var relevantItemIDs: [ItemIdentifier] {
        audiobooks.flatMap(\.itemIDs)
    }
    
    var body: some View {
        Group {
            if audiobooks.isEmpty && authors.isEmpty {
                if failed {
                    ErrorView()
                        .refreshable {
                            fetchItems()
                        }
                } else {
                    LoadingView()
                        .task {
                            fetchItems()
                        }
                        .refreshable {
                            fetchItems()
                        }
                }
            } else {
                ScrollView {
                    LazyVStack(spacing: 12) {
                        ForEach(audiobooks) {
                            AudiobookRow(title: $0.localizedLabel, small: false, audiobooks: $0.entities)
                        }
                        
                        ForEach(authors) { row in
                            VStack(alignment: .leading, spacing: 0) {
                                RowTitle(title: row.localizedLabel)
                                    .padding(.bottom, 8)
                                    .padding(.horizontal, 20)
                                
                                AuthorGrid(authors: row.entities)
                            }
                        }
                        
                         if !downloaded.isEmpty {
                             AudiobookRow(title: String(localized: "row.downloaded"), small: false, audiobooks: downloaded)
                         }
                    }
                }
                .refreshable {
                    fetchItems()
                }
            }
        }
        .navigationTitle(library?.name ?? String(localized: "error.unavailable"))
        .modifier(PlaybackSafeAreaPaddingModifier())
        .sensoryFeedback(.error, trigger: notifyError)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Menu("navigation.library.select", systemImage: "books.vertical.fill") {
                    LibraryPicker()
                }
            }
        }
        .onReceive(RFNotification[.progressEntityUpdated].publisher()) { (connectionID, primaryID, groupingID, _) in
            guard relevantItemIDs.contains(where: { $0.connectionID == connectionID && $0.primaryID == primaryID && $0.groupingID == groupingID }) else {
                return
            }
            
            fetchItems()
        }
        .onReceive(RFNotification[.downloadStatusChanged].publisher()) { itemID, _ in
            guard itemID.libraryID == library?.id else {
                return
            }
            
            Task {
                await fetchLocalItems()
            }
        }
    }
}

private extension AudiobookHomePanel {
    nonisolated func fetchItems() {
        Task {
            await MainActor.withAnimation {
                failed = false
            }
            
            await withTaskGroup(of: Void.self) {
                $0.addTask { await fetchLocalItems() }
                $0.addTask { await fetchRemoteItems() }
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
    nonisolated func fetchRemoteItems() async {
        guard let library = await library else {
            return
        }
        
        do {
            let home: ([HomeRow<Audiobook>], [HomeRow<Author>]) = try await ABSClient[library.connectionID].home(for: library.id)
            let audiobooks = await HomeRow.prepareForPresentation(home.0, connectionID: library.connectionID)
            
            await MainActor.withAnimation {
                _authors = home.1
                self.audiobooks = audiobooks
            }
        } catch {
            await MainActor.withAnimation {
                failed = true
                notifyError.toggle()
            }
        }
    }
}

#if DEBUG
#Preview {
    AudiobookHomePanel()
        .previewEnvironment()
}
#endif
