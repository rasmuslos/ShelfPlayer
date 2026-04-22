//
//  PlaybackAirPlayButton.swift
//  ShelfPlayer
//
//  Created by Rasmus Krämer on 26.02.25.
//

import SwiftUI
import AVKit
import ShelfPlayback

struct PlaybackAirPlayButton: View {
    @Environment(Satellite.self) private var satellite

    private var tintColor: TintColor { AppSettings.shared.tintColor }

    private let routePickerView = AVRoutePickerView()

    var body: some View {
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
                .symbolRenderingMode(.multicolor)
                .foregroundStyle(satellite.route?.isHighlighted == true ? tintColor.color : Color.primary)
                .contentTransition(.symbolEffect(.replace))
                .contentShape(.rect(cornerRadius: 4))
        }
        .hoverEffect(.highlight)
        .padding(-12)
    }
}
