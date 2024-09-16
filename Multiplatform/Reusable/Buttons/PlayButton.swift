//
//  PlayButton.swift
//  Audiobooks
//
//  Created by Rasmus Krämer on 09.10.23.
//

import Foundation
import SwiftUI
import TipKit
import RFKVisuals
import ShelfPlayerKit
import SPPlayback

internal struct PlayButton: View {
    @Environment(NowPlaying.ViewModel.self) private var nowPlayingViewModel
    @Environment(\.playButtonStyle) private var playButtonStyle
    @Environment(\.colorScheme) private var colorScheme
    
    let item: PlayableItem
    
    let color: Color?
    
    @State private var error = false
    @State private var loading = false
    
    @State private var progressEntity: ItemProgress
    
    @MainActor
    init(item: PlayableItem, color: Color?) {
        self.item = item
        self.color = color
        
        _progressEntity = .init(initialValue: OfflineManager.shared.progressEntity(item: item))
        progressEntity.beginReceivingUpdates()
    }
    
    private var background: Color {
        if let color {
            return color
        }
        
        return colorScheme == .dark ? .white : .black
    }
    
    private var remaining: TimeInterval {
        if nowPlayingViewModel.item == item && nowPlayingViewModel.itemDuration > 0 {
            return nowPlayingViewModel.itemDuration - nowPlayingViewModel.itemCurrentTime
        } else if progressEntity.duration <= 0 {
            return item.duration
        }
        
        return progressEntity.duration - progressEntity.currentTime
    }
    
    private var label: String {
        if progressEntity.progress >= 1 {
            return String(localized: "listen.again")
        }
        
        if progressEntity.progress > 0 {
            return String(localized: "resume")
        }
        
        if item.type == .audiobook {
            return String(localized: "listen")
        }
        
        return String(localized: "play")
    }
    private var icon: String {
        if item == nowPlayingViewModel.item {
            return nowPlayingViewModel.playing ? "waveform" : "pause.fill"
        } else {
            return "play.fill"
        }
    }
    
    @ViewBuilder
    var labelContent: some View {
        ZStack {
            Label(String("FFS"), systemImage: "waveform")
                .hidden()
            
            HStack(spacing: 8) {
                if loading {
                    ProgressIndicator()
                        .padding(.trailing, 4)
                } else {
                    ZStack {
                        Group {
                            Image(systemName: "waveform")
                            Image(systemName: "play.fill")
                            Image(systemName: "pause.fill")
                        }
                        .hidden()
                        
                        Label("playing", systemImage: icon)
                            .labelStyle(.iconOnly)
                            .contentTransition(.symbolEffect(.replace.downUp.byLayer))
                            .symbolEffect(.variableColor.iterative, isActive: icon == "waveform")
                    }
                }
                
                Text(label)
                + Text(verbatim: " • ")
                + Text(remaining, format: .duration(unitsStyle: .short, allowedUnits: [.hour, .minute, .second], maximumUnitCount: 2))
            }
        }
        .contentShape(.rect)
        .transition(.opacity)
        .animation(.smooth, value: progressEntity.progress)
    }
    
    @ViewBuilder
    var menuContent: some View {
        Menu {
            ControlGroup {
                Button {
                    play()
                } label: {
                    Label("queue.play", systemImage: "play.fill")
                }
                
                QueueButton(item: item)
            }
            
            Divider()
            
            ProgressButton(item: item)
            
            if progressEntity.startedAt != nil {
                Button(role: .destructive) {
                    Task {
                        loading = true
                        
                        do {
                            try await item.resetProgress()
                        } catch {
                            self.error.toggle()
                        }
                        
                        loading = false
                    }
                } label: {
                    Label("progress.reset", systemImage: "xmark")
                }
            }
        } label: {
            playButtonStyle.makeLabel(configuration: .init(progress: progressEntity.progress, background: background, content: .init(content: labelContent)))
        } primaryAction: {
            if nowPlayingViewModel.item == item {
                AudioPlayer.shared.playing.toggle()
                return
            }
            
            play()
        }
        .foregroundColor(background.isLight ? .black : .white)
        .animation(.smooth, value: color)
        .popoverTip(PlayButtonTip())
    }
    
    var body: some View {
        Group {
            playButtonStyle.makeMenu(configuration: .init(progress: progressEntity.progress, background: background, content: .init(content: menuContent)))
                .clipShape(.rect(cornerRadius: playButtonStyle.cornerRadius))
                .modifier(ButtonHoverEffectModifier(cornerRadius: playButtonStyle.cornerRadius, hoverEffect: .lift))
        }
    }
    
    public func playButtonSize(_ playButtonStyle: any PlayButtonStyle) -> some View {
        self
            .environment(\.playButtonStyle, .init(style: playButtonStyle))
    }
    
    private func play() {
        if loading {
            return
        }
        
        Task {
            loading = true
            
            do {
                try await AudioPlayer.shared.play(item)
            } catch {
                self.error.toggle()
                loading = false
            }
            
            loading = false
        }
    }
}

internal protocol PlayButtonStyle {
    associatedtype MenuBody: View
    associatedtype LabelBody: View
    
    typealias Configuration = PlayButtonConfiguration
    
    func makeMenu(configuration: Self.Configuration) -> Self.MenuBody
    func makeLabel(configuration: Self.Configuration) -> Self.LabelBody
    
    var cornerRadius: CGFloat { get }
}
extension PlayButtonStyle where Self == LargePlayButtonStyle {
    static var large: LargePlayButtonStyle { .init() }
}
extension PlayButtonStyle where Self == MediumPlayButtonStyle {
    static var medium: MediumPlayButtonStyle { .init() }
}

private struct AnyLargePlayButtonStyle: PlayButtonStyle {
    private var _makeMenu: (Configuration) -> AnyView
    private var _makeLabel: (Configuration) -> AnyView
    
    private var _cornerRadius: CGFloat
    
    init<S: PlayButtonStyle>(style: S) {
        _makeMenu = { configuration in
            AnyView(style.makeMenu(configuration: configuration))
        }
        _makeLabel = { configuration in
            AnyView(style.makeLabel(configuration: configuration))
        }
        
        _cornerRadius = style.cornerRadius
    }
    
    func makeMenu(configuration: Configuration) -> some View {
        _makeMenu(configuration)
    }
    func makeLabel(configuration: Configuration) -> some View {
        _makeLabel(configuration)
    }
    
    var cornerRadius: CGFloat {
        _cornerRadius
    }
}

internal struct LargePlayButtonStyle: PlayButtonStyle {
    func makeMenu(configuration: Configuration) -> some View {
        configuration.content
            .background {
                ZStack {
                    RFKVisuals.adjust(configuration.background, saturation: 0, brightness: -0.8)
                        .animation(.smooth, value: configuration.background)
                    
                    GeometryReader { geometry in
                        Rectangle()
                            .fill(configuration.background.isLight ? .white : .black)
                            .opacity(0.2)
                            .frame(width: geometry.size.width * configuration.progress)
                            .animation(.smooth, value: configuration.progress)
                    }
                }
            }
    }
    
    func makeLabel(configuration: Configuration) -> some View {
        configuration.content
            .font(.headline)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
    }
    
    var cornerRadius: CGFloat {
        8
    }
}
internal struct MediumPlayButtonStyle: PlayButtonStyle {
    func makeMenu(configuration: Configuration) -> some View {
        configuration.content
            .imageScale(.small)
            .bold()
            .font(.footnote)
            .frame(maxWidth: 240)
            .background(configuration.background.isLight ? .black : .white)
    }
    
    func makeLabel(configuration: Configuration) -> some View {
        configuration.content
            .foregroundStyle(configuration.background.isLight ? .white : .black)
            .padding(.vertical, 12)
            .frame(maxWidth: .infinity)
    }
    
    var cornerRadius: CGFloat {
        12
    }
}

internal struct PlayButtonConfiguration {
    let progress: Percentage
    let background: Color
    
    struct Content: View {
        init<Content: View>(content: Content) {
            body = AnyView(content)
        }
        
        var body: AnyView
    }
    
    let content: PlayButtonConfiguration.Content
}
private extension EnvironmentValues {
    @Entry var playButtonStyle: AnyLargePlayButtonStyle = .init(style: LargePlayButtonStyle())
}

private struct PlayButtonTip: Tip {
    var title: Text {
        Text("queue.tip.title")
    }
    
    var message: Text? {
        Text("queue.tip.message")
    }
    
    var icon: Image? {
        Image(systemName: "text.line.last.and.arrowtriangle.forward")
    }
    
    var options: [any TipOption] {[
        MaxDisplayCount(3)
    ]}
}

#if DEBUG
#Preview {
    VStack {
        PlayButton(item: Audiobook.fixture, color: .accent)
            .playButtonSize(.medium)
    }
    .frame(maxWidth: .infinity, maxHeight: .infinity)
    .background(.accent)
}
#Preview {
    PlayButton(item: Audiobook.fixture, color: .accent)
        .playButtonSize(.large)
}
#endif
