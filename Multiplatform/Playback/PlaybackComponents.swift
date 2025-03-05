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
    @Environment(PlaybackViewModel.self) private var playbackViewModel
    @Environment(Satellite.self) private var satellite
    
    var body: some View {
        HStack(spacing: 0) {
            Menu {
                if let currentItem = satellite.currentItem {
                    if currentItem as? Audiobook != nil {
                        ItemMenu(authors: playbackViewModel.authorIDs)
                        ItemMenu(series: playbackViewModel.seriesIDs)
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
        Label("backwards", systemImage: "gobackward.\(viewModel.skipBackwardsInterval)")
            .labelStyle(.iconOnly)
            .font(.title)
            .padding(12)
            .contentShape(.rect)
            .onTapGesture {
                satellite.skip(forwards: false)
            }
            .onLongPressGesture {
                satellite.seek(to: 0, insideChapter: true) {}
            }
            .padding(-12)
            .disabled(isLoading)
            .symbolEffect(.rotate.counterClockwise.byLayer, value: viewModel.notifySkipBackwards)
    }
    @ViewBuilder
    private var togglePlayButton: some View {
        Button(satellite.isPlaying ? "pause" : "play", systemImage: satellite.isPlaying ? "pause" : "play") {
            satellite.togglePlaying()
        }
        .contentShape(.rect)
        .buttonStyle(.plain)
        .labelStyle(.iconOnly)
        .font(.largeTitle)
        .imageScale(.large)
        .symbolVariant(.fill)
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
        Label("forwards", systemImage: "goforward.\(viewModel.skipBackwardsInterval)")
            .labelStyle(.iconOnly)
            .font(.title)
            .padding(12)
            .contentShape(.rect)
            .onTapGesture {
                satellite.skip(forwards: true)
            }
            .onLongPressGesture {
                satellite.seek(to: satellite.chapterDuration + 0.1, insideChapter: true) {}
            }
            .padding(-12)
            .disabled(isLoading)
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
            PlaybackSlider(percentage: satellite.played, seeking: $viewModel.seeking, currentTime: currentTime, duration: duration, textFirst: false) {
                if let chapter = satellite.chapter, viewModel.seeking == nil {
                    Text(chapter.title)
                } else {
                    Text(remaining, format: .duration(unitsStyle: .abbreviated, allowedUnits: [.hour, .minute, .second], maximumUnitCount: 1))
                        .contentTransition(.numericText())
                        .animation(.smooth, value: remaining)
                }
            } complete: {
                satellite.seek(to: satellite.chapterDuration * $0, insideChapter: true) {
                    Task { @MainActor in
                        viewModel.seeking = nil
                    }
                }
            }
            
            Spacer(minLength: 8)
            
            LazyVGrid(columns: [.init(alignment: .trailing), .init(alignment: .center), .init(alignment: .leading)]) {
                backwardButton
                togglePlayButton
                forwardButton
            }
            Spacer(minLength: 8)
            
            BottomSlider()
        }
        .aspectRatio(2, contentMode: .fit)
    }
}

struct PlaybackActions: View {
    @Environment(PlaybackViewModel.self) private var viewModel
    @Environment(Satellite.self) private var satellite
    
    @Default(.sleepTimerIntervals) private var sleepTimerIntervals
    @Default(.sleepTimerExtendInterval) private var sleepTimerExtendInterval
    
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
        Menu {
            if let sleepTimer = satellite.sleepTimer {
                switch sleepTimer {
                case .chapters(let amount):
                    ControlGroup {
                        Button("decrease", systemImage: "minus") {
                            if amount > 1 {
                                satellite.setSleepTimer(.chapters(amount - 1))
                            } else {
                                satellite.setSleepTimer(nil)
                            }
                        }
                        
                        Text(amount.description)
                        
                        Button("increase", systemImage: "plus") {
                            satellite.setSleepTimer(.chapters(amount + 1))
                        }
                    }
                case .interval(_):
                    EmptyView()
                }
                
                Divider()
                
                Button("sleep.extend", systemImage: "plus") {
                    satellite.extendSleepTimer()
                }
                
                Button("sleep.cancel", systemImage: "alarm") {
                    satellite.setSleepTimer(nil)
                }
            } else {
                if satellite.chapter != nil {
                    Button("sleepTimer.chapter", systemImage: "append.page") {
                        satellite.setSleepTimer(.chapters(1))
                    }
                    
                    Divider()
                }
                
                ForEach(sleepTimerIntervals, id: \.hashValue) { interval in
                    Button {
                        satellite.setSleepTimer(.interval(.now.advanced(by: interval)))
                    } label: {
                        Text(interval, format: .duration(unitsStyle: .full, allowedUnits: [.minute, .hour]))
                    }
                }
            }
        } label: {
            Group {
                if let sleepTimer = satellite.sleepTimer {
                    switch sleepTimer {
                    case .chapters(_):
                        Label("sleepTimer.chapter", systemImage: "append.page")
                    case .interval(_):
                        if let remainingSleepTime = satellite.remainingSleepTime {
                            Text(remainingSleepTime, format: .duration(unitsStyle: .abbreviated, allowedUnits: [.minute, .second], maximumUnitCount: 1))
                        } else {
                            ProgressView()
                                .scaleEffect(0.5)
                        }
                    }
                } else {
                    Label("sleepTimer", systemImage: "moon.zzz.fill")
                }
            }
            .padding(12)
            .contentShape(.rect)
            .padding(-12)
        }
        .menuActionDismissBehavior(.disabled)
    }
    
    @ViewBuilder
    private var airPlayButton: some View {
        Button {
            for view in routePickerView.subviews {
                guard let button = view as? UIButton else {
                    continue
                }
                
                button.sendActions(for: .touchUpInside)
                break
            }
        } label: {
            Label("airPlay", systemImage: satellite.route?.icon ?? "airplay.audio")
                .padding(12)
                .contentShape(.rect)
                .padding(-12)
                .foregroundStyle(satellite.route?.isHighlighted == true ? Color.accentColor : Color.primary)
                .contentTransition(.symbolEffect(.replace))
        }
        .symbolRenderingMode(.palette)
    }
    
    @ViewBuilder
    private var queueButton: some View {
        Button {
            withAnimation(.snappy(extraBounce: 0.1)) {
                viewModel.isQueueVisible.toggle()
            }
        } label: {
            Label("queue", systemImage: "list.number")
                .padding(12)
                .contentShape(.rect)
                .padding(-12)
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

private struct PlaybackSlider<MiddleContent: View>: View {
    @Environment(\.colorScheme) private var colorScheme
    @Default(.lockSeekBar) private var lockSeekBar
    
    let percentage: Percentage
    @Binding var seeking: Percentage?
    
    let currentTime: TimeInterval?
    let duration: TimeInterval?
    
    let textFirst: Bool
    
    @ViewBuilder let middleContent: () -> MiddleContent
    let complete: (_: Percentage) -> Void
    
    @State private var dragStartValue: Percentage?
    
    @ScaledMetric private var mutedHeight = 11
    @ScaledMetric private var activeHeight = 14
    
    private let height: CGFloat = 6
    private let hitTargetPadding: CGFloat = 12
    
    @ViewBuilder
    private var text: some View {
        Group {
            if let currentTime, let duration {
                LazyVGrid(columns: [.init(alignment: .leading), .init(alignment: .center), .init(alignment: .trailing)]) {
                    Text(currentTime, format: .duration(unitsStyle: .positional, allowedUnits: [.hour, .minute, .second], maximumUnitCount: 3))
                    
                    middleContent()
                    
                    Text(duration, format: .duration(unitsStyle: .positional, allowedUnits: [.hour, .minute, .second], maximumUnitCount: 3))
                }
            } else {
                Text(String("PLACEHOLDER"))
                    .hidden()
            }
        }
        .font(seeking == nil ? .system(size: mutedHeight, design: .rounded) : .system(size: activeHeight, design: .rounded))
        .foregroundStyle(seeking == nil ? .secondary : .primary)
    }
    
    private var adjustedHeight: CGFloat {
        height * (seeking == nil ? 1 : 2)
    }
    
    var body: some View {
        VStack(spacing: 6) {
            if textFirst {
                text
            }
            
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
                .frame(height: adjustedHeight, alignment: textFirst ? .bottom : .top)
                .clipShape(.rect(cornerRadius: 8))
                .padding(.vertical, hitTargetPadding)
                .contentShape(.rect)
                .highPriorityGesture(DragGesture(minimumDistance: 0.0, coordinateSpace: .global)
                    .onChanged {
                        guard !lockSeekBar else {
                            return
                        }
                        
                        if dragStartValue == nil {
                            dragStartValue = percentage
                        }
                        
                        let width = geometry.size.width
                        let offset = min(width, max(-width, $0.translation.width))
                        
                        let moved: Percentage = .init(offset / width)
                        let velocity = abs($0.velocity.width)
                        let acceleration: Percentage
                        
                        if velocity < 500 {
                            acceleration = 0.7
                        } else if velocity < 1000 {
                            acceleration = 1
                        } else {
                            acceleration = 1.3
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
            .frame(height: hitTargetPadding * 2 + adjustedHeight)
            .padding(.vertical, -hitTargetPadding)
            
            if !textFirst {
                text
            }
        }
        .frame(height: height * 2 + activeHeight + 6)
        .animation(.smooth, value: seeking)
    }
}
private struct BottomSlider: View {
    @Environment(PlaybackViewModel.self) private var viewModel
    @Environment(Satellite.self) private var satellite
    
    @Default(.replaceVolumeWithTotalProgresss) private var replaceVolumeWithTotalProgresss
    
    private var currentTime: TimeInterval {
        if let seekingTotal = viewModel.seekingTotal {
            satellite.duration * seekingTotal
        } else {
            satellite.currentTime
        }
    }
    private var duration: TimeInterval {
        if viewModel.seekingTotal != nil {
            satellite.duration - currentTime
        } else {
            satellite.duration
        }
    }
    
    private var remaining: TimeInterval {
        if viewModel.seekingTotal != nil {
            duration * (1 / satellite.playbackRate)
        } else {
            (satellite.duration - satellite.currentTime) * (1 / satellite.playbackRate)
        }
    }
    
    var body: some View {
        @Bindable var viewModel = viewModel
        
        if true, satellite.chapter != nil {
            PlaybackSlider(percentage: satellite.playedTotal, seeking: $viewModel.seekingTotal, currentTime: currentTime, duration: duration, textFirst: true) {
                Text(remaining, format: .duration(unitsStyle: .abbreviated, allowedUnits: [.hour, .minute, .second], maximumUnitCount: 1))
                    .contentTransition(.numericText())
                    .transition(.opacity)
                    .animation(.smooth, value: remaining)
            } complete: {
                satellite.seek(to: satellite.duration * $0, insideChapter: false) {
                    Task { @MainActor in
                        viewModel.seekingTotal = nil
                    }
                }
            }
        } else {
            PlaybackSlider(percentage: satellite.volume, seeking: $viewModel.volumePreview, currentTime: nil, duration: nil, textFirst: true) {
                Spacer()
            } complete: { _ in
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

#Preview {
    @Previewable @State var seeking: Percentage? = nil
    
    VStack(spacing: 20) {
        PlaybackSlider(percentage: 0.5, seeking: $seeking, currentTime: 10, duration: 20, textFirst: false) {
            Text("ABC")
        } complete: { _ in
            seeking = nil
        }
        
        PlaybackSlider(percentage: 0.5, seeking: $seeking, currentTime: nil, duration: nil, textFirst: true) {
            Spacer()
        } complete: { _ in
            seeking = nil
        }
    }
}
