//
//  PlaybackCompactExpandedForeground.swift
//  ShelfPlayer
//
//  Created by Rasmus Krämer on 14.09.25.
//

import SwiftUI
import ShelfPlayback

struct PlaybackCompactExpandedForeground: View {
    @Environment(PlaybackViewModel.self) private var viewModel
    @Environment(Satellite.self) private var satellite

    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.namespace) private var namespace

    @Bindable private var settings = AppSettings.shared

    @State private var marqueeController = MarqueeController()

    let height: CGFloat
    let safeAreaTopInset: CGFloat
    let safeAreaBottomInset: CGFloat

    private var isMeshActive: Bool {
        settings.animatedNowPlayingBackground && viewModel.nowPlayingMeshColors != nil
    }

    var body: some View {
        VStack(spacing: 0) {
            Rectangle()
                .frame(height: safeAreaTopInset)
                .hidden()

            Spacer(minLength: 12)

            if viewModel.activeCard == nil {
                Rectangle()
                    .fill(.clear)
                    .aspectRatio(1, contentMode: .fit)
                    .overlay {
                        GeometryReader { imageGeometryProxy in
                            let x = imageGeometryProxy.frame(in: .global).minX
                            let y = imageGeometryProxy.frame(in: .global).minY

                            let size = imageGeometryProxy.size.width

                            Rectangle()
                                .fill(.clear)
                                .onChange(of: x, initial: true) { viewModel.expandedImageX = x }
                                .onChange(of: y, initial: true) { viewModel.expandedImageY = y }
                                .onChange(of: size, initial: true) { viewModel.expandedImageSize = size }

                            ItemImage(itemID: satellite.nowPlayingItemID, size: .large, cornerRadius: viewModel.EXPANDED_IMAGE_CORNER_RADIUS, aspectRatio: .none, contrastConfiguration: nil)
                                .frame(maxWidth: .infinity, maxHeight: .infinity)
                                .opacity(viewModel.isExpanded && viewModel.expansionAnimationCount <= 0 ? 1 : 0)
                        }
                        .aspectRatio(1, contentMode: .fit)
                        .id((satellite.nowPlayingItemID?.description ?? "placeholder") + "_nowPlaying_image_expanded_large")
                        .shadow(color: .black.opacity(0.4), radius: 20)
                        .matchedGeometryEffect(id: "image", in: namespace!, properties: .frame, anchor: viewModel.isExpanded ? .topLeading : .topTrailing)
                        .padding(.horizontal, satellite.isPlaying ? 0 : 40)
                        .animation(.spring(duration: 0.3, bounce: 0.6), value: satellite.isPlaying)
                        .modifier(PlaybackDragGestureCatcher(height: height))
                    }

                Spacer(minLength: 12)

                Group {
                    PlaybackTitle(showTertiarySupplements: true)
                        .matchedGeometryEffect(id: "text", in: namespace!, properties: .frame, anchor: .center)

                    Spacer(minLength: 12)

                    PlaybackControls()
                        .transition(.asymmetric(insertion: .move(edge: .bottom), removal: .move(edge: .bottom).combined(with: .opacity)))
                }
                .offset(y: viewModel.controlTranslationY)

                Spacer(minLength: 12)
            } else {
                HStack(spacing: 12) {
                    Button {
                        withAnimation(.snappy) {
                            viewModel.activeCard = nil
                        }
                    } label: {
                        GeometryReader { imageGeometryProxy in
                            let x = imageGeometryProxy.frame(in: .global).minX
                            let y = imageGeometryProxy.frame(in: .global).minY

                            let size = imageGeometryProxy.size.width

                            Rectangle()
                                .fill(.clear)
                                .onChange(of: x, initial: true) { viewModel.cardThumbnailImageX = x }
                                .onChange(of: y, initial: true) { viewModel.cardThumbnailImageY = y }
                                .onChange(of: size, initial: true) { viewModel.cardThumbnailImageSize = size }

                            ItemImage(itemID: satellite.nowPlayingItemID, size: .regular, cornerRadius: viewModel.CARD_THUMBNAIL_IMAGE_CORNER_RADIUS, aspectRatio: .none, contrastConfiguration: nil)
                                .frame(maxWidth: .infinity, maxHeight: .infinity)
                                .opacity(viewModel.isExpanded && viewModel.expansionAnimationCount <= 0 ? 1 : 0)
                        }
                        .aspectRatio(1, contentMode: .fit)
                        .frame(width: 72)
                        .shadow(color: .black.opacity(0.32), radius: 12)
                        .id((satellite.nowPlayingItemID?.description ?? "placeholder") + "_nowPlaying_image_expanded_small")
                    }
                    .buttonStyle(.plain)
                    .matchedGeometryEffect(id: "image", in: namespace!, properties: .frame, anchor: viewModel.isExpanded ? .topLeading : .topTrailing)

                    PlaybackTitle(showTertiarySupplements: false)
                        .matchedGeometryEffect(id: "text", in: namespace!, properties: .frame, anchor: .center)
                }
                .padding(.top, 20)
                .modifier(PlaybackDragGestureCatcher(height: height))

                Group {
                    switch viewModel.activeCard {
                        case .ratePicker:
                            PlaybackRatePickerCard(onMeshBackground: isMeshActive)
                                .frame(maxWidth: .infinity, maxHeight: .infinity)
                                .transition(.asymmetric(insertion: .move(edge: .bottom), removal: .move(edge: .bottom).combined(with: .opacity)))
                        case .sleepTimerPicker:
                            PlaybackSleepTimerPickerCard(onMeshBackground: isMeshActive)
                                .frame(maxWidth: .infinity, maxHeight: .infinity)
                                .transition(.asymmetric(insertion: .move(edge: .bottom), removal: .move(edge: .bottom).combined(with: .opacity)))
                        case .queue, .none:
                            PlaybackQueue()
                                .frame(maxHeight: height - 140)
                                .transition(.asymmetric(insertion: .move(edge: .bottom), removal: .move(edge: .bottom).combined(with: .opacity)))
                    }
                }
                .padding(.vertical, 12)
                .offset(y: viewModel.controlTranslationY * 2)
            }

            PlaybackActions(onMeshBackground: isMeshActive)
                .transition(.move(edge: .bottom).combined(with: .opacity).animation(.snappy(duration: 0.1)))
                .padding(.bottom, safeAreaBottomInset + 12)
                .offset(y: viewModel.controlTranslationY)
        }
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
            .modifier(PlaybackDragGestureCatcher(height: height))
            .padding(-40)
            .offset(y: safeAreaTopInset)
            .accessibilityLabel("action.dismiss")
        }
        .padding(.horizontal, 28)
        .modify(if: isMeshActive) {
            $0.foregroundStyle(.white)
        }
        .environment(\.playbackMarqueeController, marqueeController)
    }
}

#if DEBUG
#Preview {
    GeometryReader { geometryProxy in
        PlaybackCompactExpandedForeground(height: geometryProxy.size.height, safeAreaTopInset: geometryProxy.safeAreaInsets.top, safeAreaBottomInset: geometryProxy.safeAreaInsets.bottom)
            .ignoresSafeArea()
    }
    .previewEnvironment()
}
#endif
