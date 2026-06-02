//
//  MarqueeText.swift
//  ShelfPlayer
//
//  Created by Rasmus Krämer on 19.04.26.
//

import SwiftUI

@Observable @MainActor
final class MarqueeController {
    private var entries = [UUID: CGFloat]()
    /// Wall-clock start of the current scroll cycle. `nil` while nothing overflows.
    /// `progress(at:)` is a pure function of `Date.timeIntervalSince(cycleStart)`, so
    /// every text on the controller derives the same offset from one clock — no
    /// per-text animation timers to drift, and a text that mounts mid-cycle simply
    /// reads the current position instead of restarting.
    private(set) var cycleStart: Date?

    var delay: TimeInterval = 2
    var speed: Double = 30

    /// The widest overflow across all registered texts. It sets the scroll pace, so
    /// shorter texts (smaller overflow) traverse less distance over the same cycle and
    /// the whole group starts and stops together.
    var maxOverflow: CGFloat {
        entries.values.max() ?? 0
    }
    var isActive: Bool {
        maxOverflow > 0
    }

    func register() -> UUID {
        let id = UUID()
        entries[id] = 0
        return id
    }

    func update(id: UUID, overflow: CGFloat) {
        guard entries.keys.contains(id) else { return }
        entries[id] = max(0, overflow)

        if isActive {
            if cycleStart == nil { cycleStart = Date() }
        } else {
            cycleStart = nil
        }
    }

    func unregister(id: UUID) {
        entries.removeValue(forKey: id)
        if !isActive {
            cycleStart = nil
        }
    }

    /// Restart the cycle from the leading edge. Called on a genuine content change so
    /// the whole synced group resets together and the new text reads from its start.
    func restart() {
        guard isActive else { return }
        cycleStart = Date()
    }

    /// Normalized scroll position in `0...1` for the given instant. The cycle is
    /// `delay` (rest at start) → scroll forward → `delay` (rest at end) → scroll back.
    func progress(at date: Date) -> Double {
        guard isActive, let cycleStart else { return 0 }

        let scroll = Double(maxOverflow) / speed
        guard scroll > 0 else { return 0 }

        let cycle = 2 * delay + 2 * scroll
        var t = date.timeIntervalSince(cycleStart).truncatingRemainder(dividingBy: cycle)
        if t < 0 { t += cycle }

        if t < delay { return 0 }
        t -= delay
        if t < scroll { return t / scroll }
        t -= scroll
        if t < delay { return 1 }
        t -= delay
        return 1 - t / scroll
    }
}

struct MarqueeText: View {
    let text: String
    var font: Font = .body
    var foregroundStyle: AnyShapeStyle = .init(.primary)
    /// Horizontal alignment of the text while it fits the container (no marquee needed).
    /// Once the text overflows it always scrolls from the leading edge, so this only
    /// affects the resting position of short strings — e.g. centering the chapter title
    /// in the wide center slot of the iPad scrubber.
    var alignment: HorizontalAlignment = .leading
    var controller: MarqueeController?

    var delay: TimeInterval = 2
    var speed: Double = 30

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    @State private var textWidth: CGFloat = 0
    @State private var containerWidth: CGFloat = 0
    @State private var entryID: UUID?
    /// Used when no `controller` is injected, so the standalone and shared paths are
    /// identical — a lone text is just a one-entry group driving its own clock.
    @State private var localController = MarqueeController()

    private var activeController: MarqueeController {
        controller ?? localController
    }

    private var overflow: CGFloat {
        max(0, textWidth - containerWidth)
    }

    /// Where the text rests when it fits. The overlay is pinned leading, so a non-leading
    /// alignment is expressed as a positive offset into the slack. When the text overflows
    /// `slack` is zero, so this collapses to leading and the marquee scroll is unaffected.
    private var restingOffset: CGFloat {
        let slack = max(0, containerWidth - textWidth)
        if alignment == .center { return slack / 2 }
        if alignment == .trailing { return slack }
        return 0
    }

    private var needsMarquee: Bool {
        !reduceMotion && overflow > 0
    }

    var body: some View {
        Text(text)
            .font(font)
            .lineLimit(1)
            .hidden()
            .frame(maxWidth: .infinity, alignment: .leading)
            .overlay(alignment: .leading) {
                GeometryReader { containerGeo in
                    TimelineView(.animation(paused: !needsMarquee)) { context in
                        let progress = needsMarquee ? activeController.progress(at: context.date) : 0
                        let fadeLeading = needsMarquee && progress > 0
                        let fadeTrailing = needsMarquee && progress < 1

                        Color.clear
                            .overlay(alignment: .leading) {
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
                                    .offset(x: restingOffset - progress * overflow)
                            }
                            .mask {
                                HStack(spacing: 0) {
                                    LinearGradient(colors: [fadeLeading ? .clear : .black, .black], startPoint: .leading, endPoint: .trailing)
                                        .frame(width: 16)

                                    Rectangle()

                                    LinearGradient(colors: [.black, fadeTrailing ? .clear : .black], startPoint: .leading, endPoint: .trailing)
                                        .frame(width: 16)
                                }
                            }
                    }
                    .onPreferenceChange(TextWidthKey.self) { newValue in
                        textWidth = newValue
                        syncEntry()
                    }
                    .onChange(of: containerGeo.size.width, initial: true) {
                        containerWidth = containerGeo.size.width
                        syncEntry()
                    }
                }
            }
            .onChange(of: text) {
                // A genuine content change resyncs the whole group from the leading
                // edge so the new text reads from its start.
                activeController.restart()
            }
            .onAppear {
                // Configure the standalone fallback to mirror the explicit knobs.
                // No-op when an external controller is injected.
                localController.delay = delay
                localController.speed = speed
            }
            .onDisappear {
                if let entryID {
                    activeController.unregister(id: entryID)
                    self.entryID = nil
                }
            }
    }

    private func syncEntry() {
        if let entryID {
            activeController.update(id: entryID, overflow: overflow)
        } else if needsMarquee {
            let id = activeController.register()
            entryID = id
            activeController.update(id: id, overflow: overflow)
        }
    }
}

private struct TextWidthKey: PreferenceKey {
    static let defaultValue: CGFloat = 0
    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        value = nextValue()
    }
}

extension EnvironmentValues {
    /// A `MarqueeController` shared across the now playing UI so the title, authors
    /// and chapter title scroll in lockstep. Injected at the layout root; `nil` when
    /// a `MarqueeText` lives outside that context (it then animates standalone).
    @Entry var playbackMarqueeController: MarqueeController?
}

#if DEBUG
private struct MarqueePreviewHost: View {
    @State private var controller = MarqueeController()
    @State private var containerWidth: CGFloat = 200
    @State private var title: String = "Lorem ipsum dolor sit amet, consectetur adipiscing elit, sed do eiusmod tempor incididunt ut labore et dolore magna aliqua."

    var body: some View {
        VStack(alignment: .leading, spacing: 24) {
            VStack(alignment: .leading, spacing: 12) {
                Text("Controller-driven (synced)")
                    .font(.caption).foregroundStyle(.secondary)

                VStack(alignment: .leading, spacing: 4) {
                    MarqueeText(text: title, font: .headline, controller: controller)
                    MarqueeText(text: "Ut enim ad minim veniam, quis nostrud exercitation ullamco laboris nisi ut aliquip ex ea commodo consequat.",
                                font: .subheadline,
                                foregroundStyle: .init(.secondary),
                                controller: controller)
                }
                .frame(width: containerWidth, alignment: .leading)
                .padding(8)
                .background(.quaternary, in: .rect(cornerRadius: 8))
            }

            VStack(alignment: .leading, spacing: 12) {
                Text("Standalone (no controller)")
                    .font(.caption).foregroundStyle(.secondary)

                MarqueeText(text: title, font: .headline)
                    .frame(width: containerWidth, alignment: .leading)
                    .padding(8)
                    .background(.quaternary, in: .rect(cornerRadius: 8))
            }

            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text("Container width")
                    Spacer()
                    Text("\(Int(containerWidth)) pt").monospacedDigit().foregroundStyle(.secondary)
                }
                .font(.caption)

                Slider(value: $containerWidth, in: 80...360)
            }

            VStack(alignment: .leading, spacing: 8) {
                Text("Title").font(.caption)
                TextField("Title", text: $title, axis: .vertical)
                    .textFieldStyle(.roundedBorder)
                    .lineLimit(1...4)
            }

            Spacer()
        }
        .padding()
    }
}

#Preview("Playground") {
    MarqueePreviewHost()
}

#Preview("Fits") {
    MarqueeText(text: "Lorem ipsum", font: .headline)
        .frame(width: 200, alignment: .leading)
        .padding()
}

#Preview("Overflows (standalone)") {
    MarqueeText(text: "Lorem ipsum dolor sit amet, consectetur adipiscing elit, sed do eiusmod tempor incididunt.", font: .headline)
        .frame(width: 200, alignment: .leading)
        .padding()
}

#Preview("Overflows (controller, 2 rows)") {
    @Previewable @State var controller = MarqueeController()
    VStack(alignment: .leading, spacing: 4) {
        MarqueeText(text: "Lorem ipsum dolor sit amet, consectetur adipiscing elit.",
                    font: .headline,
                    controller: controller)
        MarqueeText(text: "Sed do eiusmod tempor incididunt ut labore et dolore magna aliqua.",
                    font: .subheadline,
                    foregroundStyle: .init(.secondary),
                    controller: controller)
    }
    .frame(width: 220, alignment: .leading)
    .padding()
}
#endif
