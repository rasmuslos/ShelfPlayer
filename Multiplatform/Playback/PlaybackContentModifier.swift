//
//  TabValuePlaybackModifier.swift
//  Multiplatform
//
//  Created by Rasmus Krämer on 25.02.25.
//

import SwiftUI

struct PlaybackTabContentModifier: ViewModifier {
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    @Environment(PlaybackViewModel.self) private var viewModel
    @Environment(Satellite.self) private var satellite
    
    func body(content: Content) -> some View {
        if #available(iOS 26, *) {
            content
        } else {
            GeometryReader { geometryProxy in
                // 32 is at the middle axis of the pill
                let additionalHeight: CGFloat = 44
                let height = geometryProxy.safeAreaInsets.bottom + additionalHeight
                let startPoint = (additionalHeight / height) / 2
                
                ZStack(alignment: .bottom) {
                    content
                    
                    if satellite.isNowPlayingVisible {
                        Rectangle()
                            .fill(.bar)
                            .frame(height: height)
                            .mask {
                                LinearGradient(stops: [.init(color: .clear, location: 0),
                                                       .init(color: .black, location: startPoint),
                                                       .init(color: .black, location: 1)],
                                               startPoint: .top, endPoint: .bottom)
                            }
                    }
                }
                .toolbarBackgroundVisibility(satellite.isNowPlayingVisible ? .hidden : .automatic, for: .tabBar)
                .ignoresSafeArea(edges: satellite.isNowPlayingVisible ? .bottom : [])
                .modifier(RegularPlaybackModifier())
            }
        }
    }
}

struct PlaybackSafeAreaPaddingModifier: ViewModifier {
    @Environment(Satellite.self) private var satellite
    
    private var padding: CGFloat {
        if #available(iOS 26, *) {
            0
        } else if satellite.isNowPlayingVisible {
        // 56 (height) + 4
            60
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
    @Environment(Satellite.self) private var satellite
    
    func body(content: Content) -> some View {
        @Bindable var viewModel = viewModel
        @Bindable var satellite = satellite
        
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
    }
}
