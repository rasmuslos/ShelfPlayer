//
//  PlaybackRateEditor.swift
//  ShelfPlayer
//
//  Created by Rasmus Krämer on 27.02.25.
//

import SwiftUI
import ShelfPlayback

struct PlaybackRateEditor: View {
    private var settings: AppSettings { .shared }

    @State private var playbackRates: [Double] = AppSettings.shared.playbackRates
    @State private var defaultPlaybackRate: Double = AppSettings.shared.defaultPlaybackRate

    @State private var playbackRateAdjustmentUp: Double = AppSettings.shared.playbackRateAdjustmentUp
    @State private var playbackRateAdjustmentDown: Double = AppSettings.shared.playbackRateAdjustmentDown

    @State private var newValue: Percentage = 1

    @ViewBuilder
    func row(index: Int) -> some View {
        Text(playbackRates[index], format: .playbackRate)
    }

    var body: some View {
        List {
            SettingsPageHeader(title: "preferences.playbackRate", systemImage: "gauge.with.needle", color: .blue)

            Section {
                ForEach(Array(playbackRates.enumerated()), id: \.element.hashValue) {
                    row(index: $0.offset)
                }
                .onDelete {
                    for index in $0 {
                        if defaultPlaybackRate == playbackRates[index] {
                            defaultPlaybackRate = playbackRates.first ?? 1
                        }

                        playbackRates.remove(at: index)

                        if playbackRates.isEmpty {
                            playbackRates.append(1)
                        }
                    }
                    save()
                }
            }

            Section {
                Stepper(value: $newValue, in: 0.1...8, step: 0.05) {
                    Text(newValue, format: .playbackRate)
                }

                Button("preferences.playbackRate.add", systemImage: "plus") {
                    guard !playbackRates.contains(newValue) else {
                        return
                    }

                    playbackRates.append(newValue)
                    playbackRates.sort()
                    save()
                }
                .labelStyle(.titleOnly)
            }

            Section {
                Stepper(value: $playbackRateAdjustmentUp, in: 0.05...0.5, step: 0.05) {
                    Text("preferences.playbackRate.adjust.up \(playbackRateAdjustmentUp.formatted(.playbackRate))")
                }
                .onChange(of: playbackRateAdjustmentUp) { settings.playbackRateAdjustmentUp = playbackRateAdjustmentUp }

                Stepper(value: $playbackRateAdjustmentDown, in: 0.05...0.5, step: 0.05) {
                    Text("preferences.playbackRate.adjust.down \(playbackRateAdjustmentDown.formatted(.playbackRate))")
                }
                .onChange(of: playbackRateAdjustmentDown) { settings.playbackRateAdjustmentDown = playbackRateAdjustmentDown }
            }

            Section {
                PlaybackRatePicker(label: "preferences.playbackRate.default", selection: $defaultPlaybackRate)
                    .onChange(of: defaultPlaybackRate) { settings.defaultPlaybackRate = defaultPlaybackRate }
            }

            Section {
                Button("action.reset", role: .destructive) {
                    playbackRates = [0.9, 1, 1.3, 1.6, 2]
                    defaultPlaybackRate = 1
                    playbackRateAdjustmentUp = 0.1
                    playbackRateAdjustmentDown = 0.1

                    settings.playbackRates = playbackRates
                    settings.defaultPlaybackRate = defaultPlaybackRate
                    settings.playbackRateAdjustmentUp = playbackRateAdjustmentUp
                    settings.playbackRateAdjustmentDown = playbackRateAdjustmentDown
                }
            }
        }
        .environment(\.editMode, .constant(.active))
        .navigationTitle("preferences.playbackRate")
        .navigationBarTitleDisplayMode(.inline)
    }

    private func save() {
        settings.playbackRates = playbackRates
        settings.defaultPlaybackRate = defaultPlaybackRate
    }
}

struct PlaybackRatePicker: View {
    private var playbackRates: [Double] { AppSettings.shared.playbackRates }

    let label: LocalizedStringKey
    @Binding var selection: Percentage

    var body: some View {
        Picker(label, selection: $selection) {
            ForEach(playbackRates, id: \.hashValue) { value in
                Button {
                    selection = value
                } label: {
                    Text(value, format: .playbackRate)
                }
                .tag(value)
            }
        }
    }
}

#Preview {
    PlaybackRateEditor()
}
