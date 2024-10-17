//
//  FeedbackModifier.swift
//  Multiplatform
//
//  Created by Rasmus Krämer on 13.10.24.
//

import Foundation
import SwiftUI

internal extension NowPlaying {
    struct FeedbackModifier: ViewModifier {
        @Environment(NowPlaying.ViewModel.self) private var viewModel
        
        @State private var bookmarkEditingNote: String = ""
        
        func body(content: Content) -> some View {
            @Bindable var viewModel = viewModel
            
            content
                .sensoryFeedback(.selection, trigger: viewModel.notifyForwards)
                .sensoryFeedback(.selection, trigger: viewModel.notifyPlaying)
                .sensoryFeedback(.selection, trigger: viewModel.notifyBackwards)
                .sensoryFeedback(.error, trigger: viewModel.notifyError)
                .sensoryFeedback(.alignment, trigger: viewModel.notifyBookmark)
                .alert("bookmark.create.alert", isPresented: .init(get: { viewModel.bookmarkCapturedTime != nil }, set: { _ in } )) {
                    TextField("bookmark.create.prompt", text: $viewModel.bookmarkNote)
                    
                    Button {
                        viewModel.dismissBookmarkAlert()
                    } label: {
                        Text("bookmark.create.cancel")
                    }
                    .buttonStyle(.plain)
                    .tint(.red)
                    
                    Button {
                        viewModel.createBookmarkWithNote()
                    } label: {
                        Text("bookmark.create.finalize")
                    }
                    .buttonStyle(.plain)
                }
                .alert("bookmark.update.alert", isPresented: .init(get: { viewModel.bookmarkEditingIndex != nil }, set: { _ in } )) {
                    TextField("bookmark.update.prompt", text: $bookmarkEditingNote)
                    
                    Button {
                        viewModel.bookmarkEditingIndex = nil
                    } label: {
                        Text("bookmark.update.cancel")
                    }
                    .buttonStyle(.plain)
                    .tint(.red)
                    
                    Button {
                        viewModel.updateBookmark(note: bookmarkEditingNote)
                    } label: {
                        Text("bookmark.update.finalize")
                    }
                    .buttonStyle(.plain)
                }
                .onChange(of: viewModel.bookmarkEditingIndex) {
                    if let index = viewModel.bookmarkEditingIndex {
                        bookmarkEditingNote = viewModel.bookmarks[index].note
                    }
                }
        }
    }
}
