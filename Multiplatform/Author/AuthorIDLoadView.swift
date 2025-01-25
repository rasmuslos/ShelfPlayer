//
//  AuthorLoadView.swift
//  Audiobooks
//
//  Created by Rasmus Krämer on 05.10.23.
//

import SwiftUI
import ShelfPlayerKit

struct AuthorIDLoadView: View {
    @Environment(\.library) private var library
    
    let authorName: String
    
    @State private var failed = false
    @State private var authorID: ItemIdentifier?
    
    var body: some View {
        if let authorID {
            ItemLoadView(authorID)
        } else if failed {
            ErrorView()
                .refreshable {
                    loadAuthor()
                }
        } else {
            LoadingView()
                .task {
                    loadAuthor()
                }
                .refreshable {
                    loadAuthor()
                }
        }
    }
    
    private nonisolated func loadAuthor() {
        Task {
            await MainActor.withAnimation {
                failed = false
            }
            
            do {
                guard let library = await library else { return }
                
                let authorID = try await ABSClient[library.connectionID].authorID(from: library.id, name: authorName)
                
                await MainActor.withAnimation {
                    self.authorID = authorID
                }
            } catch {
                await MainActor.withAnimation {
                    failed = true
                }
            }
        }
    }
}
