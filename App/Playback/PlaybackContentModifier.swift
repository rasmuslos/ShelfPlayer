//
//  PlaybackContentModifier.swift
//  ShelfPlayer
//
//  Created by Rasmus Krämer on 25.02.25.
//

import SwiftUI
import ShelfPlayback

struct PlaybackTabContentModifier: ViewModifier {
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    @Environment(PlaybackViewModel.self) private var viewModel
    @Environment(Satellite.self) private var satellite

    func body(content: Content) -> some View {
        if #available(iOS 26, *) {
            content
                .modifier(RegularPlaybackBarModifier())
        } else {
            GeometryReader { geometryProxy in
                let additionalHeight: CGFloat = 44
                let height = geometryProxy.safeAreaInsets.bottom + additionalHeight
                let startPoint = (additionalHeight / height) / 2

                ZStack(alignment: .bottom) {
                    content

                    if satellite.isNowPlayingVisible && horizontalSizeClass == .compact {
                        Rectangle()
                            .fill(.bar)
                            .frame(height: height)
                            .mask {
                                LinearGradient(stops: [.init(color: .clear, location: 0),
                                                       .init(color: .black, location: startPoint),
                                                       .init(color: .black, location: 1)],
                                               startPoint: .top, endPoint: .bottom)
                            }
                            .toolbarBackgroundVisibility(satellite.isNowPlayingVisible ? .hidden : .automatic, for: .tabBar)
                    }
                }
                .ignoresSafeArea(edges: satellite.isNowPlayingVisible ? .bottom : [])
            }
            .modifier(RegularPlaybackBarModifier())
        }
    }
}

struct PlaybackSafeAreaPaddingModifier: ViewModifier {
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    @Environment(OfflineMode.self) private var offlineMode
    @Environment(Satellite.self) private var satellite

    private var padding: CGFloat {
        if #available(iOS 26, *), !offlineMode.isEnabled && horizontalSizeClass == .compact {
            0
        } else if satellite.isNowPlayingVisible {
            80
        } else {
            0
        }
    }

    func body(content: Content) -> some View {
        content
            .safeAreaPadding(.bottom, padding)
    }
}

struct PlaybackContentModifier: ViewModifier {
    @Environment(PlaybackViewModel.self) private var viewModel
    @Environment(BookmarkEditor.self) private var bookmarkEditor

    var isEditBookmarkAlertPresented: Binding<Bool> {
        .init {
            bookmarkEditor.isPresented
        } set: { _ in }
    }

    func body(content: Content) -> some View {
        @Bindable var viewModel = viewModel
        @Bindable var bookmarkEditor = bookmarkEditor

        content
            .alert("playback.alert.createBookmark", isPresented: $viewModel.isCreateBookmarkAlertVisible) {
                TextField("playback.alert.createBookmark.placeholder", text: $viewModel.bookmarkNote)

                if viewModel.isCreatingBookmark {
                    ProgressView()
                } else {
                    Button("action.cancel", role: .cancel) {
                        viewModel.cancelBookmarkCreation()
                    }
                    Button("playback.alert.createBookmark.action") {
                        viewModel.finalizeBookmarkCreation()
                    }
                    .keyboardShortcut(.defaultAction)
                }
            }
            .alert("playback.alert.editBookmark", isPresented: isEditBookmarkAlertPresented) {
                TextField("playback.alert.createBookmark.placeholder", text: $bookmarkEditor.note)

                if bookmarkEditor.isUpdating {
                    ProgressView()
                } else {
                    Button("action.cancel", role: .cancel) {
                        bookmarkEditor.abort()
                    }
                    Button("action.edit") {
                        bookmarkEditor.finalize()
                    }
                    .keyboardShortcut(.defaultAction)
                }
            }
    }
}
