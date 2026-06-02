//
//  RegularPlaybackModifier.swift
//  ShelfPlayer
//
//  Created by Rasmus Krämer on 21.06.25.
//

import SwiftUI
import ShelfPlayback

struct RegularPlaybackBarModifier: ViewModifier {
    @Environment(\.playbackBottomOffset) private var playbackBottomOffset
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    @Environment(\.colorScheme) private var colorScheme

    @Environment(PlaybackViewModel.self) private var viewModel
    @Environment(Satellite.self) private var satellite

    @State private var didAppear = false

    var isPresented: Binding<Bool> {
        .init {
            viewModel.isExpanded
        } set: { _ in }
    }

    @ViewBuilder
    private func label(_ itemID: ItemIdentifier) -> some View {
        HStack(spacing: 8) {
            ItemImage(itemID: itemID, size: .small)
                .padding(.leading, 4)

            VStack(alignment: .leading, spacing: 2) {
                if let currentItem = satellite.nowPlayingItem {
                    Text(currentItem.name)
                        .lineLimit(1)
                        .font(.headline)

                    Text(currentItem.authors, format: .list(type: .and))
                        .lineLimit(1)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                } else {
                    Text("loading")
                        .foregroundStyle(.secondary)
                }
            }

            Spacer(minLength: 12)

            PlaybackRateButton()
                .font(.caption2.smallCaps())
                .foregroundStyle(.secondary)
                .padding(.trailing, 12)

            PlaybackBackwardButton()
                .font(.title3)

            ZStack {
                Group {
                    Image(systemName: "play")
                    Image(systemName: "pause")
                }
                .hidden()

                PlaybackTogglePlayButton()
            }
            .font(.title2)
            .padding(.horizontal, 8)

            PlaybackForwardButton()
                .font(.title3)

            PlaybackSleepTimerButton()
                .padding(.horizontal, 12)
                .labelStyle(.iconOnly)
                .font(.caption2)
                .foregroundStyle(.secondary)
        }
        .padding(8)
        .contentShape(.rect)
    }

    func body(content: Content) -> some View {
        if horizontalSizeClass == .regular {
            content
                .safeAreaInset(edge: .bottom) {
                    if let currentItemID = satellite.nowPlayingItemID {
                        GeometryReader { geometryProxy in
                            ZStack {
                                if #unavailable(iOS 26) {
                                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                                        .fill(.bar)
                                        .shadow(color: .black.opacity(0.4), radius: 8)
                                }

                                Button {
                                    viewModel.toggleExpanded()
                                } label: {
                                    label(currentItemID)
                                }
                                .buttonStyle(.plain)
                            }
                            .modify {
                                if #available(iOS 26 , *) {
                                    $0
                                        .universalContentShape(.capsule)
                                        .padding(.horizontal, 4)
                                        .glassEffect()
                                } else {
                                    $0
                                        .universalContentShape(.rect(cornerRadius: 12, style: .continuous))
                                }
                            }
                            .contextMenu {
                                PlaybackMenuActions()
                            } preview: {
                                if let currentItem = satellite.nowPlayingItem {
                                    PlayableItemContextMenuPreview(item: currentItem)
                                }
                            }
                            .padding(.horizontal, 20)
                            .animation(didAppear ? .smooth : .none, value: geometryProxy.size.width)
                        }
                        .frame(height: 56)
                        .task {
                            try? await Task.sleep(for: .seconds(0.4))
                            didAppear = true
                        }
                    }
                }
        } else {
            content
        }
    }
}

struct RegularPlaybackModifier: ViewModifier {
    @Environment(\.playbackBottomOffset) private var playbackBottomOffset
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.namespace) private var namespace
    @Environment(\.scenePhase) private var scenePhase

    @Environment(PlaybackViewModel.self) private var viewModel
    @Environment(Satellite.self) private var satellite

    @Bindable private var settings = AppSettings.shared

    @State private var didAppear = false
    @State private var marqueeController = MarqueeController()

    var isPresented: Binding<Bool> {
        .init {
            viewModel.isExpanded
        } set: { _ in }
    }

    private var isMeshActive: Bool {
        settings.animatedNowPlayingBackground && viewModel.nowPlayingMeshColors != nil
    }

    /// Freeze the drift render loop while the scene is backgrounded or the user
    /// is interacting with a control on top of the gradient — seek/volume slider
    /// drags and the rate / sleep timer / queue cards — so the backdrop holds
    /// still during the adjustment.
    private var isMeshPaused: Bool {
        scenePhase != .active || viewModel.areSlidersInUse || viewModel.activeCard != nil
    }

    @ViewBuilder
    private func leftHandContent(height: CGFloat) -> some View {
        VStack(spacing: 0) {
            Spacer(minLength: 20)

            Rectangle()
                .fill(.clear)
                .aspectRatio(1, contentMode: .fit)
                .overlay {
                    ItemImage(itemID: satellite.nowPlayingItemID, size: .large, aspectRatio: .none, contrastConfiguration: nil)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                }
                .id(satellite.nowPlayingItemID)
                .shadow(color: .black.opacity(0.4), radius: 20)
                .scaleEffect(satellite.isPlaying ? 1 : 0.8)
                .animation(.spring(duration: 0.3, bounce: 0.6), value: satellite.isPlaying)
                .modifier(PlaybackDragGestureCatcher(height: height))

            Spacer(minLength: 20)

            PlaybackTitle(showTertiarySupplements: true)
                .padding(.bottom, 40)

            PlaybackControls()
        }
        .environment(\.playbackMarqueeController, marqueeController)
    }

    func body(content: Content) -> some View {
        if horizontalSizeClass == .regular {
            content
                .fullScreenCover(isPresented: isPresented) {
                    GeometryReader { geometryProxy in
                        Rectangle()
                            .fill(.background)
                            .overlay {
                                if isMeshActive, let meshColors = viewModel.nowPlayingMeshColors {
                                    NowPlayingMeshBackground(colors: meshColors, paused: isMeshPaused)
                                        .transition(.opacity)
                                }
                            }
                            .animation(.smooth(duration: 1.0), value: viewModel.nowPlayingMeshColors)
                            .contentShape(.rect)
                            .onTapGesture(count: 2) {
                                withAnimation(.smooth) {
                                    settings.animatedNowPlayingBackground.toggle()
                                }
                            }
                            .modifier(PlaybackDragGestureCatcher(height: geometryProxy.size.height))
                            .ignoresSafeArea()

                        Group {
                            if geometryProxy.size.width > geometryProxy.size.height {
                                VStack(spacing: 40) {
                                    HStack(spacing: 40) {
                                        leftHandContent(height: geometryProxy.size.height)
                                            .frame(maxWidth: 520)

                                        Group {
                                            switch viewModel.activeCard {
                                                case .ratePicker:
                                                    PlaybackRatePickerCard(onMeshBackground: isMeshActive)
                                                        .transition(.move(edge: .bottom).combined(with: .opacity))
                                                case .sleepTimerPicker:
                                                    PlaybackSleepTimerPickerCard(onMeshBackground: isMeshActive)
                                                        .transition(.move(edge: .bottom).combined(with: .opacity))
                                                case .queue, .none:
                                                    PlaybackQueue()
                                                        .transition(.move(edge: .bottom).combined(with: .opacity).animation(.snappy(duration: 0.1)))
                                            }
                                        }
                                        .frame(maxWidth: 720, maxHeight: .infinity)
                                    }
                                    .frame(maxWidth: .infinity)

                                    HStack(alignment: .bottom, spacing: 32) {
                                        PlaybackAirPlayButton()

                                        Spacer(minLength: 0)

                                        PlaybackRateButton(onMeshBackground: isMeshActive)
                                        PlaybackSleepTimerButton(onMeshBackground: isMeshActive)
                                    }
                                    .labelStyle(.iconOnly)
                                    .buttonStyle(.plain)
                                    .frame(maxWidth: .infinity)
                                }
                                .padding(.horizontal, 24)
                                .overlay(alignment: .top) {
                                    Button {
                                        viewModel.toggleExpanded()
                                    } label: {
                                        Rectangle()
                                            .foregroundStyle(.secondary)
                                            .opacity(0.62)
                                            .frame(width: 60, height: 4)
                                            .clipShape(.rect(cornerRadius: .infinity))
                                    }
                                    .buttonStyle(.plain)
                                    .padding(40)
                                    .contentShape(.rect)
                                    .modifier(PlaybackDragGestureCatcher(height: geometryProxy.size.height))
                                    .padding(-40)
                                    .accessibilityLabel("action.dismiss")
                                }
                                .modify(if: isMeshActive) {
                                    $0.foregroundStyle(.white)
                                }
                            } else {
                                HStack(spacing: 0) {
                                    Spacer(minLength: 0)

                                    VStack(spacing: 0) {
                                        PlaybackCompactExpandedForeground(height: geometryProxy.size.height, safeAreaTopInset: 0, safeAreaBottomInset: 0)
                                    }
                                    .frame(maxWidth: 600)

                                    Spacer(minLength: 0)
                                }
                            }
                        }
                        .safeAreaPadding(.bottom, geometryProxy.safeAreaInsets.bottom == 0 ? 40 : 0)
                    }
                    .environment(Satellite.shared)
                    .environment(PlaybackViewModel.shared)
                    .environment(SkipController.shared)
                    .environment(\.namespace, namespace)
                }
        } else {
            content
        }
    }
}

#if DEBUG
#Preview {
    TabView {
        Tab(role: .search) {
            ScrollView {
                ForEach(1..<1000) {
                    Text(verbatim: $0.formatted(.number))

                    Rectangle()
                        .fill(.blue)
                }
            }
            .modifier(RegularPlaybackModifier())
        }
    }
    .tabViewStyle(.sidebarAdaptable)
    .previewEnvironment()
}
#endif
