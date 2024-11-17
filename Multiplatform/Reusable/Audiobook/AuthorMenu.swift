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
    let libraryID: String?
    
    @ViewBuilder
    private static func label(authorName: String?) -> some View {
        Label("author.view", systemImage: "person")
        
        if let authorName {
            Text(authorName)
        }
    }
    @ViewBuilder
    private static func button(authorName: String, libraryID: String?, @ViewBuilder buildLabel: (_ authorName: String) -> some View) -> some View {
        if let libraryID {
            Button {
                Navigation.navigate(authorName: authorName, libraryID: libraryID)
            } label: {
                buildLabel(authorName)
            }
        } else {
            NavigationLink(destination: AuthorLoadView(authorName: authorName)) {
                buildLabel(authorName)
            }
        }
    }
    
    var body: some View {
        if authors.count == 1, let authorName = authors.first {
            Self.button(authorName: authorName, libraryID: libraryID, buildLabel: Self.label)
        } else if !authors.isEmpty {
            Menu {
                AuthorsMenu(authors: authors, libraryID: libraryID)
            } label: {
                Self.label(authorName: nil)
            }
        }
    }
    
    internal struct AuthorsMenu: View {
        let authors: [String]
        let libraryID: String?
        
        var body: some View {
            ForEach(authors, id: \.self) { authorName in
                AuthorMenu.button(authorName: authorName, libraryID: libraryID) {
                    Text($0)
                }
            }
        }
    }
}
