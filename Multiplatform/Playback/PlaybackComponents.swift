//
//  PlaybackComponents.swift
//  Multiplatform
//
//  Created by Rasmus Krämer on 26.02.25.
//

import SwiftUI
import ShelfPlayerKit

struct PlaybackTitle: View {
    @Environment(Satellite.self) private var satellite
    
    var body: some View {
        HStack(spacing: 0) {
            Menu {
            } label: {
                VStack(alignment: .leading, spacing: 2) {
                    if let currentItem = satellite.currentItem {
                        Text(currentItem.name)
                            .lineLimit(2)
                            .font(.headline)
                        
                        Text(currentItem.authors, format: .list(type: .and, width: .short))
                            .font(.subheadline)
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
            
            HStack(spacing: 0) {
                Text(satellite.currentChapterTime, format: .duration(unitsStyle: .positional, allowedUnits: [.hour, .minute, .second], maximumUnitCount: 3))
                
                Spacer(minLength: 8)
                
                if let chapter = satellite.chapter {
                    Text(chapter.title)
                } else {
                    Text("ABC")
                }
                
                Spacer(minLength: 8)
                
                Text(satellite.chapterDuration, format: .duration(unitsStyle: .positional, allowedUnits: [.hour, .minute, .second], maximumUnitCount: 3))
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
            
            RoundedRectangle(cornerRadius: 8)
                .fill(.yellow)
                .frame(height: 8)
        }
        .aspectRatio(2, contentMode: .fit)
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
                    seeking = dragStartValue! + modifier
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
