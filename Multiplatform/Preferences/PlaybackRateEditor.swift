//
//  PlaybackRatesEditor.swift
//  Multiplatform
//
//  Created by Rasmus Krämer on 27.02.25.
//

import SwiftUI
import Defaults
import ShelfPlayerKit

struct PlaybackRateEditor: View {
    @Default(.playbackRates) private var playbackRates
    @Default(.defaultPlaybackRate) private var defaultPlaybackRate
    
    @State private var newValue: Percentage = 1
    
    @ViewBuilder
    func row(index: Int) -> some View {
        Text(playbackRates[index], format: .percent.notation(.compactName))
    }
    
    var body: some View {
        List {
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
                }
            }
            
            Section {
                Stepper(value: $newValue, in: 0.1...8, step: 0.05) {
                    Text(newValue, format: .percent.notation(.compactName))
                }
                
                Button("preferences.playbackRate.add", systemImage: "plus") {
                    guard !playbackRates.contains(newValue) else {
                        return
                    }
                    
                    playbackRates.append(newValue)
                    playbackRates.sort()
                }
                .labelStyle(.titleOnly)
            }
            
            Section {
                PlaybackRatePicker(label: "preferences.playbackRate.default", selection: $defaultPlaybackRate)
            }
            
            Section {
                Button("action.reset", role: .destructive) {
                    Defaults.reset([.playbackRates, .defaultPlaybackRate])
                }
            }
        }
        .environment(\.editMode, .constant(.active))
        .navigationTitle("preferences.playbackRate")
    }
}

struct PlaybackRatePicker: View {
    @Default(.playbackRates) private var playbackRates
    
    let label: LocalizedStringKey
    @Binding var selection: Percentage
    
    var body: some View {
        Picker(label, selection: $selection) {
            ForEach(playbackRates, id: \.hashValue) { value in
                Button {
                    selection = value
                } label: {
                    Text(value, format: .percent.notation(.compactName))
                }
                .tag(value)
            }
        }
    }
}

#Preview {
    PlaybackRateEditor()
}
