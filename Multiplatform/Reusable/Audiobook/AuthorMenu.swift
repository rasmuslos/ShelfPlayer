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
    
    var body: some View {
        if authors.count == 1, let authorName = authors.first {
            NavigationLink(destination: AuthorLoadView(authorName: authorName)) {
                Label("author.view", systemImage: "person")
                Text(authorName)
            }
        } else if !authors.isEmpty {
            Menu {
                AuthorsMenu(authors: authors)
            } label: {
                Label("author.view", systemImage: "person")
            }
        }
    }
    
    internal struct AuthorsMenu: View {
        let authors: [String]
        
        var body: some View {
            ForEach(Array(authors), id: \.self) { authorName in
                NavigationLink(destination: AuthorLoadView(authorName: authorName)) {
                    Label("author.view", systemImage: "person")
                    Text(authorName)
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
