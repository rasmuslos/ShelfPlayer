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
    private var entries = [UUID: CGFloat]()
    private var animationToken: UUID?

    var delay: TimeInterval = 2
    var speed: Double = 30

    enum MarqueePhase: Equatable {
        case idle
        case scrollingForward(duration: TimeInterval)
        case pausedAtEnd
        case scrollingBack(duration: TimeInterval)
    }

    private var maxOverflow: CGFloat {
        entries.values.max() ?? 0
    }

    func register() -> UUID {
        let id = UUID()
        entries[id] = 0
        return id
    }

    func update(id: UUID, overflow: CGFloat) {
        guard entries.keys.contains(id) else { return }
        entries[id] = max(0, overflow)
        startIfNeeded()
    }

    func unregister(id: UUID) {
        entries.removeValue(forKey: id)
        if maxOverflow <= 0 {
            stop()
        }
    }

    func startIfNeeded() {
        guard animationToken == nil else { return }
        guard maxOverflow > 0 else { return }

        let token = UUID()
        animationToken = token

        Task { @MainActor in
            await animate(token: token)
        }
    }

    func stop() {
        animationToken = nil
        phase = .idle
    }

    private func animate(token: UUID) async {
        defer {
            if animationToken == token {
                animationToken = nil
                phase = .idle
            }
        }

        while animationToken == token {
            let currentOverflow = maxOverflow
            guard currentOverflow > 0 else { return }

            phase = .idle
            try? await Task.sleep(for: .seconds(delay))
            guard animationToken == token else { return }

            let duration = currentOverflow / speed
            phase = .scrollingForward(duration: duration)
            try? await Task.sleep(for: .seconds(duration))
            guard animationToken == token else { return }

            phase = .pausedAtEnd
            try? await Task.sleep(for: .seconds(delay))
            guard animationToken == token else { return }

            phase = .scrollingBack(duration: duration)
            try? await Task.sleep(for: .seconds(duration))
            guard animationToken == token else { return }
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
    @State private var progress: Double = 0
    @State private var animating = false
    @State private var entryID: UUID?

    private var overflow: CGFloat {
        max(0, textWidth - containerWidth)
    }

    private var needsMarquee: Bool {
        overflow > 0
    }

    private var fadeLeading: Bool {
        needsMarquee && progress > 0
    }

    private var fadeTrailing: Bool {
        needsMarquee && progress < 1
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
                        .offset(x: -progress * overflow)
                        .onPreferenceChange(TextWidthKey.self) { newValue in
                            textWidth = newValue
                            syncEntry()
                        }
                        .onChange(of: containerGeo.size.width, initial: true) {
                            containerWidth = containerGeo.size.width
                            syncEntry()
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
                handlePhase(newPhase)
            }
            .onChange(of: needsMarquee, initial: true) {
                if let controller {
                    if needsMarquee {
                        controller.startIfNeeded()
                    }
                } else if needsMarquee {
                    startStandaloneAnimation()
                } else {
                    stopStandaloneAnimation()
                }
            }
            .onChange(of: text) {
                var transaction = Transaction()
                transaction.disablesAnimations = true
                withTransaction(transaction) {
                    progress = 0
                }

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
            .onDisappear {
                if let entryID, let controller {
                    controller.unregister(id: entryID)
                    self.entryID = nil
                }
                animating = false
            }
    }

    private func syncEntry() {
        guard let controller else { return }
        if let entryID {
            controller.update(id: entryID, overflow: overflow)
        } else if needsMarquee {
            let id = controller.register()
            entryID = id
            controller.update(id: id, overflow: overflow)
        }
    }

    // MARK: - Controller-driven animation

    private func handlePhase(_ phase: MarqueeController.MarqueePhase) {
        switch phase {
        case .idle:
            withAnimation(.easeOut(duration: 0.3)) {
                progress = 0
            }
        case .scrollingForward(let duration):
            withAnimation(.linear(duration: duration)) {
                progress = 1
            }
        case .pausedAtEnd:
            break
        case .scrollingBack(let duration):
            withAnimation(.linear(duration: duration)) {
                progress = 0
            }
        }
    }

    // MARK: - Standalone animation (no controller)

    private func startStandaloneAnimation() {
        guard !animating else { return }
        animating = true

        Task { @MainActor in
            while animating {
                guard needsMarquee else {
                    progress = 0
                    return
                }

                try? await Task.sleep(for: .seconds(delay))
                guard animating else { return }

                let duration = overflow / speed
                withAnimation(.linear(duration: duration)) {
                    progress = 1
                }
                try? await Task.sleep(for: .seconds(duration))
                guard animating else { return }

                try? await Task.sleep(for: .seconds(delay))
                guard animating else { return }

                withAnimation(.linear(duration: duration)) {
                    progress = 0
                }
                try? await Task.sleep(for: .seconds(duration))
                guard animating else { return }
            }
        }
    }

    private func stopStandaloneAnimation() {
        animating = false
        withAnimation(.easeOut(duration: 0.3)) {
            progress = 0
        }
    }
}

private struct TextWidthKey: PreferenceKey {
    static let defaultValue: CGFloat = 0
    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        value = nextValue()
    }
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
