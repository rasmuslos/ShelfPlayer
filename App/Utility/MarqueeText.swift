//
//  MarqueeText.swift
//  ShelfPlayer
//
//  Created by Rasmus Krämer on 19.04.26.
//

import SwiftUI

@Observable @MainActor
final class MarqueeController {
    private(set) var phase: MarqueePhase = .idle
    private var entries = [Entry]()

    private var animating = false

    var delay: TimeInterval = 2
    var speed: Double = 30

    enum MarqueePhase: Equatable {
        case idle
        case scrollingForward(duration: TimeInterval)
        case pausedAtEnd
        case scrollingBack(duration: TimeInterval)
    }

    struct Entry {
        let overflow: CGFloat
    }

    func register(overflow: CGFloat) -> Int {
        let id = entries.count
        entries.append(Entry(overflow: overflow))

        return id
    }

    func update(id: Int, overflow: CGFloat) {
        guard entries.indices.contains(id) else { return }
        entries[id] = Entry(overflow: overflow)
    }

    func startIfNeeded() {
        guard !animating else { return }

        let maxOverflow = entries.map(\.overflow).max() ?? 0
        guard maxOverflow > 0 else {
            phase = .idle
            return
        }

        animating = true
        phase = .idle

        Task { @MainActor in
            await animate()
        }
    }

    func stop() {
        animating = false
        phase = .idle
    }

    private func animate() async {
        while animating {
            let maxOverflow = entries.map(\.overflow).max() ?? 0
            guard maxOverflow > 0 else {
                phase = .idle
                return
            }

            // Pause at start
            try? await Task.sleep(for: .seconds(delay))
            guard animating else { return }

            // Scroll forward
            let duration = maxOverflow / speed
            phase = .scrollingForward(duration: duration)

            try? await Task.sleep(for: .seconds(duration))
            guard animating else { return }

            // Pause at end
            phase = .pausedAtEnd
            try? await Task.sleep(for: .seconds(delay))
            guard animating else { return }

            // Scroll back
            phase = .scrollingBack(duration: duration)
            try? await Task.sleep(for: .seconds(duration))
            guard animating else { return }

            phase = .idle
        }
    }
}

struct MarqueeText: View {
    let text: String
    var font: Font = .body
    var foregroundStyle: AnyShapeStyle = .init(.primary)
    var controller: MarqueeController?

    var delay: TimeInterval = 2
    var speed: Double = 30

    @State private var textWidth: CGFloat = 0
    @State private var containerWidth: CGFloat = 0
    @State private var offset: CGFloat = 0
    @State private var animating = false
    @State private var entryID: Int?

    private var overflow: CGFloat {
        max(0, textWidth - containerWidth)
    }

    private var needsMarquee: Bool {
        overflow > 0
    }

    private var fadeLeading: Bool {
        needsMarquee && offset < 0
    }

    private var fadeTrailing: Bool {
        needsMarquee && offset > -overflow
    }

    var body: some View {
        Text(text)
            .font(font)
            .lineLimit(1)
            .hidden()
            .overlay(alignment: .leading) {
                GeometryReader { containerGeo in
                    Text(text)
                        .font(font)
                        .foregroundStyle(foregroundStyle)
                        .fixedSize()
                        .background {
                            GeometryReader { textGeo in
                                Color.clear
                                    .preference(key: TextWidthKey.self, value: textGeo.size.width)
                            }
                        }
                        .offset(x: offset)
                        .onPreferenceChange(TextWidthKey.self) {
                            textWidth = $0
                            if let controller {
                                if let entryID {
                                    controller.update(id: entryID, overflow: max(0, $0 - containerWidth))
                                } else {
                                    entryID = controller.register(overflow: max(0, $0 - containerWidth))
                                }
                            }
                        }
                        .onChange(of: containerGeo.size.width, initial: true) {
                            containerWidth = containerGeo.size.width
                            if let controller, let entryID {
                                controller.update(id: entryID, overflow: max(0, textWidth - containerGeo.size.width))
                            }
                        }
                }
                .mask {
                    HStack(spacing: 0) {
                        LinearGradient(colors: [.clear, .black], startPoint: .leading, endPoint: .trailing)
                            .frame(width: fadeLeading ? 16 : 0)

                        Rectangle()

                        LinearGradient(colors: [.black, .clear], startPoint: .leading, endPoint: .trailing)
                            .frame(width: fadeTrailing ? 16 : 0)
                    }
                }
            }
            .onChange(of: controller?.phase, initial: true) { _, newPhase in
                guard controller != nil, let newPhase else { return }
                handlePhase(newPhase, maxOverflow: overflow)
            }
            .onChange(of: needsMarquee, initial: true) {
                guard controller == nil else {
                    controller?.startIfNeeded()
                    return
                }
                if needsMarquee {
                    startStandaloneAnimation()
                } else {
                    stopStandaloneAnimation()
                }
            }
            .onChange(of: text) {
                if let controller {
                    controller.stop()
                    Task { @MainActor in
                        try? await Task.sleep(for: .milliseconds(100))
                        controller.startIfNeeded()
                    }
                } else {
                    stopStandaloneAnimation()
                    Task { @MainActor in
                        try? await Task.sleep(for: .milliseconds(100))
                        if needsMarquee {
                            startStandaloneAnimation()
                        }
                    }
                }
            }
    }

    // MARK: - Controller-driven animation

    private func handlePhase(_ phase: MarqueeController.MarqueePhase, maxOverflow: CGFloat) {
        switch phase {
        case .idle:
            withAnimation(.easeOut(duration: 0.3)) {
                offset = 0
            }
        case .scrollingForward(let duration):
            guard overflow > 0 else { return }
            withAnimation(.linear(duration: duration)) {
                offset = -overflow
            }
        case .pausedAtEnd:
            break
        case .scrollingBack(let duration):
            withAnimation(.linear(duration: duration)) {
                offset = 0
            }
        }
    }

    // MARK: - Standalone animation (no controller)

    private func startStandaloneAnimation() {
        offset = 0
        animating = true

        Task { @MainActor in
            try? await Task.sleep(for: .seconds(delay))
            guard animating else { return }

            let duration = overflow / speed

            withAnimation(.linear(duration: duration)) {
                offset = -overflow
            }

            try? await Task.sleep(for: .seconds(duration + delay))
            guard animating else { return }

            withAnimation(.linear(duration: duration)) {
                offset = 0
            }

            try? await Task.sleep(for: .seconds(duration))
            guard animating else { return }

            startStandaloneAnimation()
        }
    }

    private func stopStandaloneAnimation() {
        animating = false
        withAnimation(.easeOut(duration: 0.3)) {
            offset = 0
        }
    }
}

private struct TextWidthKey: PreferenceKey {
    static let defaultValue: CGFloat = 0
    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        value = nextValue()
    }
}
