//
//  AuthorMenu.swift
//  Multiplatform
//
//  Created by Rasmus Krämer on 31.10.24.
//

import Foundation
import SwiftUI
import ShelfPlayerKit

internal struct AuthorMenu: View {
    @Environment(\.library) private var library
    
    let authors: [String]
    @State private var authorIDs: [String: String] = [:]
    
    var body: some View {
        if !authors.isEmpty {
            if authorIDs.isEmpty {
                Button {
                    
                } label: {
                    Label {
                        Text(authors.joined(separator: ", "))
                    } icon: {
                        ProgressIndicator()
                    }
                }
                .disabled(true)
                .task {
                    authorIDs = await Self.mapAuthorIDs(authors, libraryID: library.id)
                }
            } else {
                if authorIDs.count == 1, let first = authorIDs.first {
                    NavigationLink(destination: AuthorLoadView(authorId: first.value)) {
                        Label("author.view", systemImage: "person")
                        Text(first.key)
                    }
                } else {
                    Menu {
                        AuthorsMenu(authorIDs: authorIDs)
                    } label: {
                        Label("author.view", systemImage: "person")
                    }
                }
            }
        }
    }
    
    internal struct AuthorsMenu: View {
        let authorIDs: [String: String]
        
        var body: some View {
            ForEach(Array(authorIDs.keys), id: \.self) { author in
                let authorID = authorIDs[author]!
                
                NavigationLink(destination: AuthorLoadView(authorId: authorID)) {
                    Label("author.view", systemImage: "person")
                    Text(author)
                }
            }
        }
    }
    
    /// Behold
    internal static func mapAuthorIDs(_ authors: [String], libraryID: String) async -> [String: String] {
        Dictionary(uniqueKeysWithValues: await authors.parallelMap { author -> (String, String)? in
            guard let authorID = try? await AudiobookshelfClient.shared.authorID(name: author, libraryID: libraryID) else {
                return nil
            }
            
            return (author, authorID)
        }.compactMap { $0 })
    }
}
