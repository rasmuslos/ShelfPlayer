//
//  PlaybackComponents.swift
//  Multiplatform
//
//  Created by Rasmus Krämer on 26.02.25.
//

import SwiftUI
import AVKit
import Defaults
import ShelfPlayerKit
import SPPlayback

struct PlaybackTitle: View {
    @Environment(Satellite.self) private var satellite
    
    var body: some View {
        HStack(spacing: 0) {
            Menu {
                if let currentItem = satellite.currentItem {
                    if let audiobook = currentItem as? Audiobook {
                        ItemMenu(authors: audiobook.authors)
                        ItemMenu(series: audiobook.series)
                    } else if let episode = currentItem as? Episode {
                        ItemLoadLink(itemID: episode.id)
                        ItemLoadLink(itemID: episode.podcastID)
                    }
                    
                    Divider()
                    
                    ProgressButton(item: currentItem)
                    StopPlaybackButton()
                }
            } label: {
                VStack(alignment: .leading, spacing: 4) {
                    if let currentItem = satellite.currentItem {
                        Text(currentItem.name)
                            .lineLimit(2)
                            .font(.headline)
                        
                        Text(currentItem.authors, format: .list(type: .and, width: .short))
                            .lineLimit(1)
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    } else {
                        Text("loading")
                            .font(.headline)
                        
                        Text(String("PLACEHOLDER"))
                            .font(.subheadline)
                            .hidden()
                            .overlay(alignment: .leading) {
                                ProgressIndicator()
                                    .scaleEffect(0.5)
                            }
                    }
                }
            }
            .buttonStyle(.plain)
            
            Spacer(minLength: 12)
        }
    }
}

struct PlaybackControls: View {
    @Environment(PlaybackViewModel.self) private var viewModel
    @Environment(Satellite.self) private var satellite
    
    private var isLoading: Bool {
        if let currentItemID = satellite.currentItemID {
            satellite.isBuffering || satellite.isLoading(observing: currentItemID)
        } else {
            true
        }
    }
    
    @ViewBuilder
    private var backwardButton: some View {
        Button("backwards", systemImage: "gobackward.\(viewModel.skipBackwardsInterval)") {
            satellite.skip(forwards: false)
        }
        .buttonStyle(.plain)
        .labelStyle(.iconOnly)
        .disabled(isLoading)
        .font(.title)
        .symbolEffect(.rotate.counterClockwise.byLayer, value: viewModel.notifySkipBackwards)
    }
    @ViewBuilder
    private var togglePlayButton: some View {
        Button("backwards", systemImage: satellite.isPlaying ? "pause" : "play") {
            satellite.togglePlaying()
        }
        .contentShape(.rect)
        .buttonStyle(.plain)
        .labelStyle(.iconOnly)
        .font(.largeTitle)
        .imageScale(.large)
        .symbolVariant(.fill)
        .symbolEffect(.rotate.counterClockwise.byLayer, value: viewModel.notifySkipBackwards)
        .contentTransition(.symbolEffect(.replace.byLayer.downUp))
        .opacity(isLoading ? 0 : 1)
        .overlay {
            if isLoading {
                ProgressIndicator()
                    .scaleEffect(1.5)
            }
        }
    }
    @ViewBuilder
    private var forwardButton: some View {
        Button("forwards", systemImage: "goforward.\(viewModel.skipBackwardsInterval)") {
            satellite.skip(forwards: true)
        }
        .buttonStyle(.plain)
        .labelStyle(.iconOnly)
        .disabled(isLoading)
        .font(.title)
        .symbolEffect(.rotate.clockwise.byLayer, value: viewModel.notifySkipForwards)
    }
    
    private var currentTime: TimeInterval {
        if let seeking = viewModel.seeking {
            satellite.chapterDuration * seeking
        } else {
            satellite.currentChapterTime
        }
    }
    private var duration: TimeInterval {
        if viewModel.seeking != nil {
            satellite.chapterDuration - currentTime
        } else {
            satellite.chapterDuration
        }
    }
    
    private var remaining: TimeInterval {
        if viewModel.seeking != nil {
            duration * (1 / satellite.playbackRate)
        } else {
            (satellite.chapterDuration - satellite.currentChapterTime) * (1 / satellite.playbackRate)
        }
    }
    
    var body: some View {
        @Bindable var viewModel = viewModel
        
        VStack(spacing: 0) {
            PlaybackSlider(percentage: satellite.played, seeking: $viewModel.seeking) {
                satellite.seek(to: satellite.chapterDuration * $0, insideChapter: true) {
                    Task { @MainActor in
                        viewModel.seeking = nil
                    }
                }
            }
            
            LazyVGrid(columns: [.init(alignment: .leading), .init(alignment: .center), .init(alignment: .trailing)]) {
                Text(currentTime, format: .duration(unitsStyle: .positional, allowedUnits: [.hour, .minute, .second], maximumUnitCount: 3))
                
                if viewModel.seeking == nil, let chapter = satellite.chapter {
                    Text(chapter.title)
                } else {
                    Text(remaining, format: .duration(unitsStyle: .abbreviated, allowedUnits: [.hour, .minute, .second], maximumUnitCount: 1))
                        .contentTransition(.numericText())
                }
                
                Text(duration, format: .duration(unitsStyle: .positional, allowedUnits: [.hour, .minute, .second], maximumUnitCount: 3))
            }
            .font(.caption2)
            .foregroundStyle(.secondary)
            .padding(.top, 6)
            
            Spacer(minLength: 8)
            
            LazyVGrid(columns: [.init(alignment: .trailing), .init(alignment: .center), .init(alignment: .leading)]) {
                backwardButton
                togglePlayButton
                forwardButton
            }
            Spacer(minLength: 8)
            
            Text(String("PLACEHOLDER"))
                .font(.caption2)
                .padding(.bottom, 6)
                .hidden()
            
            PlaybackSlider(percentage: satellite.volume, seeking: $viewModel.volumePreview) { _ in
                viewModel.volumePreview = nil
            }
            .onChange(of: viewModel.volumePreview) {
                if let volume = viewModel.volumePreview {
                    Task {
                        await AudioPlayer.shared.setVolume(volume)
                    }
                }
            }
        }
        .aspectRatio(2, contentMode: .fit)
    }
}

struct PlaybackActions: View {
    @Environment(Satellite.self) private var satellite
    @Default(.playbackRates) private var playbackRates
    
    private let routePickerView = AVRoutePickerView()
    
    @ViewBuilder
    private var playbackSpeedButton: some View {
        Menu {
            ForEach(playbackRates, id: \.hashValue) { value in
                Toggle(isOn: .init { satellite.playbackRate == value } set: {
                    if $0 {
                        satellite.setPlaybackRate(value)
                    }
                    
                }) {
                    Text(value, format: .percent.notation(.compactName))
                }
            }
        } label: {
            Text(satellite.playbackRate, format: .percent.notation(.compactName))
                .contentTransition(.numericText())
                .padding(12)
                .contentShape(.rect)
                .padding(-12)
        } primaryAction: {
            guard let index = playbackRates.firstIndex(of: satellite.playbackRate) else {
                if let rate = playbackRates.first {
                    satellite.setPlaybackRate(rate)
                }
                
                return
            }
            
            if index + 1 < playbackRates.count {
                satellite.setPlaybackRate(playbackRates[index + 1])
            } else if let rate = playbackRates.first {
                satellite.setPlaybackRate(rate)
            }
        }
    }
    
    @ViewBuilder
    private var sleepTimerButton: some View {
        Button("sleepTimer", systemImage: "moon.zzz.fill") {
            
        }
    }
    
    @ViewBuilder
    private var airPlayButton: some View {
        Button("airPlay", systemImage: "airplay.audio") {
            for view in routePickerView.subviews {
                guard let button = view as? UIButton else {
                    continue
                }
                
                button.sendActions(for: .touchUpInside)
                break
            }
        }
    }
    
    @ViewBuilder
    private var queueButton: some View {
        Button("queue", systemImage: "list.number") {
            
        }
    }
    
    var body: some View {
        LazyVGrid(columns: .init(repeating: .init(alignment: .centerFirstTextBaseline), count: 4)) {
            playbackSpeedButton
            sleepTimerButton
            airPlayButton
            queueButton
        }
        .buttonStyle(.plain)
        .labelStyle(.iconOnly)
        .font(.system(size: 17, weight: .bold, design: .rounded))
    }
}

private struct PlaybackSlider: View {
    @Environment(\.colorScheme) private var colorScheme
    
    let percentage: Percentage
    @Binding var seeking: Percentage?
    
    let complete: (_: Percentage) -> Void
    
    @State private var dragStartValue: Percentage?
    
    private let height: CGFloat = 6
    private let hitTargetPadding: CGFloat = 12
    
    var body: some View {
        GeometryReader { geometry in
            let width = geometry.size.width * min(1, max(0, CGFloat(seeking ?? percentage)))
            
            ZStack(alignment: .leading) {
                if colorScheme == .dark {
                    Rectangle()
                        .fill(.background.tertiary)
                        .saturation(1.6)
                } else {
                    Rectangle()
                        .fill(.background.secondary)
                        .saturation(1.6)
                }
                
                Rectangle()
                    .frame(width: width)
                    .foregroundStyle(.primary)
                    .animation(.smooth, value: width)
            }
            .frame(height: height)
            .clipShape(.rect(cornerRadius: 8))
            .padding(.vertical, hitTargetPadding)
            .contentShape(.rect)
            .highPriorityGesture(DragGesture(minimumDistance: 0.0, coordinateSpace: .global)
                .onChanged {
                    if dragStartValue == nil {
                        dragStartValue = percentage
                    }
                    
                    let width = geometry.size.width
                    let offset = min(width, max(-width, $0.translation.width))
                    
                    let moved: Percentage = .init(offset / width)
                    let velocity = abs($0.velocity.width)
                    let acceleration: Percentage
                    
                    if velocity < 500 {
                        acceleration = 0.8
                    } else if velocity < 1000 {
                        acceleration = 1
                    } else {
                        acceleration = 1.2
                    }
                    
                    let modifier = moved * acceleration
                    seeking = min(1, max(0, dragStartValue! + modifier))
                }
                .onEnded { _ in
                    if let seeking {
                        complete(seeking)
                    }
                    
                    dragStartValue = nil
                })
        }
        .frame(height: hitTargetPadding * 2 + height)
        .padding(.vertical, -hitTargetPadding)
    }
}
private struct StopPlaybackButton: View {
    @Environment(Satellite.self) private var satellite
    
    var body: some View {
        Button("playback.stop", systemImage: "stop.fill") {
            satellite.stop()
        }
    }
}
