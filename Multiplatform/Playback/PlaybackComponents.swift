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
    @Environment(PlaybackViewModel.self) private var viewModel
    @Environment(Satellite.self) private var satellite
    
    var body: some View {
        HStack(spacing: 0) {
            Menu {
                PlaybackMenuActions()
            } label: {
                VStack(alignment: .leading, spacing: 4) {
                    if let currentItem = satellite.nowPlayingItem {
                        Text(currentItem.name)
                            .id(currentItem.name)
                            .lineLimit(2)
                            .font(.headline)
                            .modify {
                                if currentItem.id.type == .audiobook {
                                    $0
                                        .modifier(SerifModifier())
                                } else {
                                    $0
                                }
                            }
                        
                        Text(currentItem.authors, format: .list(type: .and, width: .short))
                            .id(currentItem.authors)
                            .lineLimit(1)
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    } else {
                        Text("loading")
                            .font(.headline)
                    }
                }
                .id(satellite.nowPlayingItem)
            }
            .buttonStyle(.plain)
            
            if satellite.nowPlayingItemID?.type == .audiobook {
                Spacer(minLength: 12)
                
                if viewModel.isCreatingBookmark {
                    ProgressView()
                } else {
                    Label("item.bookmarks", systemImage: "bookmark")
                        .labelStyle(.iconOnly)
                        .padding(4)
                        .contentShape(.rect)
                        .onTapGesture {
                            viewModel.presentCreateBookmarkAlert()
                        }
                        .onLongPressGesture {
                            viewModel.createQuickBookmark()
                        }
                }
            } else {
                Spacer(minLength: 0)
            }
        }
    }
}

struct PlaybackControls: View {
    @Environment(PlaybackViewModel.self) private var viewModel
    @Environment(Satellite.self) private var satellite
    
    private var isLoading: Bool {
        if let currentItemID = satellite.nowPlayingItemID {
            satellite.isBuffering || satellite.isLoading(observing: currentItemID)
        } else {
            true
        }
    }
    
    @ViewBuilder
    private func skipText(forwards: Bool) -> some View {
        if let skipCache = satellite.skipCache {
            if (Double(-viewModel.skipBackwardsInterval) > skipCache && !forwards) || (Double(viewModel.skipForwardsInterval) < skipCache && forwards) {
                Text(abs(skipCache) ,format: .duration(unitsStyle: .abbreviated, allowedUnits: [.second, .minute], maximumUnitCount: 1))
                    .font(.caption2)
                    .fontDesign(.monospaced)
                    .contentTransition(.numericText(value: skipCache))
                    .foregroundStyle(.secondary)
                    .animation(.snappy, value: skipCache)
            }
        }
    }
    
    @ViewBuilder
    private var backwardButton: some View {
        HStack(spacing: 0) {
            skipText(forwards: false)
            
            Spacer(minLength: 12)
            
            Label("playback.skip.backward", systemImage: "gobackward.\(viewModel.skipBackwardsInterval)")
                .labelStyle(.iconOnly)
                .font(.title)
                .foregroundStyle(isLoading ? .secondary : .primary)
                .padding(12)
                .contentShape(.rect)
                .onTapGesture {
                    satellite.skipPressed(forwards: false)
                }
                .onLongPressGesture {
                    satellite.seek(to: 0, insideChapter: true) {}
                }
                .padding(-12)
                .disabled(isLoading)
                .symbolEffect(.rotate.counterClockwise.byLayer, options: .speed(2), value: viewModel.notifySkipBackwards)
                .animation(.smooth, value: isLoading)
        }
    }
    @ViewBuilder
    private var togglePlayButton: some View {
        Button(satellite.isPlaying ? "playback.pause" : "playback.play", systemImage: satellite.isPlaying ? "pause" : "play") {
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
                Image(systemName: "dot.radiowaves.left.and.right")
                    .font(.title3)
                    .symbolRenderingMode(.multicolor)
                    .symbolEffect(.variableColor.iterative.dimInactiveLayers.nonReversing, isActive: isLoading)
            }
        }
    }
    @ViewBuilder
    private var forwardButton: some View {
        HStack(spacing: 0) {
            Label("playback.skip.forward", systemImage: "goforward.\(viewModel.skipForwardsInterval)")
                .labelStyle(.iconOnly)
                .font(.title)
                .foregroundStyle(isLoading ? .secondary : .primary)
                .padding(12)
                .contentShape(.rect)
                .onTapGesture {
                    satellite.skipPressed(forwards: true)
                }
                .onLongPressGesture {
                    satellite.seek(to: satellite.chapterDuration + 0.1, insideChapter: true) {}
                }
                .padding(-12)
                .disabled(isLoading)
                .symbolEffect(.rotate.clockwise.byLayer, options: .speed(2), value: viewModel.notifySkipForwards)
                .animation(.smooth, value: isLoading)
            
            Spacer(minLength: 12)
            
            skipText(forwards: true)
        }
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
                        .lineLimit(1)
                        .truncationMode(.middle)
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
        .compositingGroup()
        .drawingGroup()
    }
}

struct PlaybackMenuActions: View {
    @Environment(PlaybackViewModel.self) private var viewModel
    @Environment(Satellite.self) private var satellite
    
    var body: some View {
        if let currentItem = satellite.nowPlayingItem {
            if let audiobook = currentItem as? Audiobook {
                Button(ItemIdentifier.ItemType.audiobook.viewLabel, systemImage: "book") {
                    audiobook.id.navigateIsolated()
                }
                
                ItemMenu(authors: viewModel.authorIDs)
                ItemMenu(narrators: viewModel.narratorIDs)
                ItemMenu(series: viewModel.seriesIDs)
            } else if let episode = currentItem as? Episode {
                ItemLoadLink(itemID: episode.id)
                ItemLoadLink(itemID: episode.podcastID)
            }
            
            Divider()
            
            ProgressButton(itemID: currentItem.id)
            StopPlaybackButton()
        }
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
                .padding(12)
                .contentShape(.rect)
                .contentTransition(.numericText())
                .animation(.smooth, value: satellite.playbackRate)
        } primaryAction: {
            viewModel.cyclePlaybackSpeed()
        }
        .padding(-12)
    }
    
    @ViewBuilder
    private var sleepTimerButton: some View {
        Menu {
            if let sleepTimer = satellite.sleepTimer {
                switch sleepTimer {
                case .chapters(let amount):
                    ControlGroup {
                        Button("action.decrease", systemImage: "minus") {
                            if amount > 1 {
                                satellite.setSleepTimer(.chapters(amount - 1))
                            } else {
                                satellite.setSleepTimer(nil)
                            }
                        }
                        
                        Text(amount, format: .number)
                        
                        Button("action.increase", systemImage: "plus") {
                            satellite.setSleepTimer(.chapters(amount + 1))
                        }
                    }
                case .interval(let expiresAt):
                    if let remainingSleepTime = satellite.remainingSleepTime {
                        ControlGroup {
                            Button("action.decrease", systemImage: "minus") {
                                if remainingSleepTime > 60 {
                                    satellite.setSleepTimer(.interval(expiresAt.advanced(by: -60)))
                                } else {
                                    satellite.setSleepTimer(nil)
                                }
                            }
                            
                            Button("action.increase", systemImage: "plus") {
                                satellite.setSleepTimer(.interval(expiresAt.advanced(by: 60)))
                            }
                        }
                    }
                }
                
                Divider()
                
                Button("playback.sleepTimer.extend", systemImage: "plus") {
                    satellite.extendSleepTimer()
                }
                
                Button("playback.sleepTimer.cancel", systemImage: "alarm") {
                    satellite.setSleepTimer(nil)
                }
            } else {
                if satellite.chapter != nil {
                    Button("playback.sleepTimer.chapter", systemImage: "append.page") {
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
            ZStack {
                Group {
                    Image(systemName: "append.page")
                    Image(systemName: "moon.zzz.fill")
                }
                .hidden()
                
                if let sleepTimer = satellite.sleepTimer {
                    switch sleepTimer {
                    case .chapters(_):
                        Label("sleepTimer.chapter", systemImage: "append.page")
                    case .interval(_):
                        if let remainingSleepTime = satellite.remainingSleepTime {
                            Text(remainingSleepTime, format: .duration(unitsStyle: .abbreviated, allowedUnits: [.minute, .second], maximumUnitCount: 1))
                                .contentTransition(.numericText())
                                .animation(.smooth, value: remainingSleepTime)
                        } else {
                            ProgressView()
                                .scaleEffect(0.5)
                        }
                    }
                } else {
                    Label("playback.sleepTimer", systemImage: "moon.zzz.fill")
                }
            }
            .padding(12)
            .contentShape(.rect)
        }
        .menuActionDismissBehavior(.disabled)
        .padding(-12)
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
                .symbolRenderingMode(.palette)
                .foregroundStyle(satellite.route?.isHighlighted == true ? Color.accentColor : Color.primary)
                .contentTransition(.symbolEffect(.replace))
        }
        .padding(-12)
    }
    
    @ViewBuilder
    private var queueButton: some View {
        Button {
            withAnimation(.snappy) {
                viewModel.isQueueVisible.toggle()
            }
        } label: {
            Label("playback.queue", systemImage: "list.number")
                .padding(12)
                .contentShape(.rect)
        }
        .padding(-6)
        .background(.gray.opacity(viewModel.isQueueVisible ? 0.2 : 0), in: .rect(cornerRadius: 4))
        .padding(-6)
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
        .geometryGroup()
        .compositingGroup()
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
    @State private var lastDragVelocity: CGFloat? = nil
    
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
                        
                        lastDragVelocity = velocity
                        
                        if velocity < 600 {
                            acceleration = 1
                        } else if velocity < 1000 {
                            acceleration = 2
                        } else {
                            acceleration = 3
                        }
                        
                        let modifier = moved * acceleration
                        seeking = min(1, max(0, dragStartValue! + modifier))
                    }
                    .onEnded {
                        if let lastDragVelocity, lastDragVelocity > 1000, let seeking {
                            let modifier = $0.translation.width < 0 ? -1.1 : 1.1
                            self.seeking = min(1, seeking * modifier)
                        }
                        
                        if let seeking {
                            complete(seeking)
                        }
                        
                        dragStartValue = nil
                        lastDragVelocity = nil
                    })
            }
            .frame(height: hitTargetPadding * 2 + adjustedHeight)
            .padding(.vertical, -hitTargetPadding)
            
            if !textFirst {
                text
            }
        }
        .frame(height: height * 2 + activeHeight + 6)
        .compositingGroup()
        .animation(.smooth, value: seeking)
    }
}
private struct BottomSlider: View {
    @Environment(PlaybackViewModel.self) private var viewModel
    @Environment(Satellite.self) private var satellite
    
    @Default(.replaceVolumeWithTotalProgress) private var replaceVolumeWithTotalProgress
    
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
        
        if replaceVolumeWithTotalProgress, satellite.chapter != nil {
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

#if DEBUG
#Preview {
    @Previewable @State var percentage: Percentage = 0.5
    @Previewable @State var seeking: Percentage? = nil
    
    VStack(spacing: 20) {
        PlaybackSlider(percentage: percentage, seeking: $seeking, currentTime: 10, duration: 20, textFirst: false) {
            Text("ABC")
        } complete: { _ in
            seeking = nil
        }
        
        PlaybackSlider(percentage: percentage, seeking: $seeking, currentTime: nil, duration: nil, textFirst: true) {
            Spacer()
        } complete: { _ in
            seeking = nil
        }
    }
}

#Preview {
    PlaybackControls()
        .previewEnvironment()
}

#Preview {
    PlaybackActions()
        .previewEnvironment()
}
#endif
