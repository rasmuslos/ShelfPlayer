//
//  AudioRoute.swift
//  ShelfPlayerKit
//
//  Created by Rasmus Krämer on 02.03.25.
//

import Foundation
import AVKit

public struct AudioRoute: Sendable {
    let name: String
    let port: AVAudioSession.Port
    
    init(name: String, port: AVAudioSession.Port) {
        self.name = name
        self.port = port
    }
    
    public var icon: String {
        if name.localizedStandardContains("AirPods Max") {
            "airpods.max"
        } else if name.localizedStandardContains("AirPods Pro") {
            "airpods.pro"
        } else if name.localizedStandardContains("AirPods") {
            "airpods.gen3"
        } else if name.localizedStandardContains("HomePod Mini") {
            "homepod.mini.fill"
        } else if name.localizedStandardContains("HomePod") {
            "homepod.fill"
        } else if name.localizedStandardContains("AppleTV") {
            "appletv.fill"
        } else if port == .HDMI || port == .displayPort {
            "tv.and.hifispeaker.fill"
        } else if port == .airPlay {
            "airPlay.audio"
        } else if port == .bluetoothA2DP || port == .bluetoothHFP || port == .bluetoothLE {
            "hifispeaker.fill"
        } else if port == .headphones {
            "headphones"
        } else if port == .lineOut {
            "cable.coaxial"
        } else if port == .thunderbolt || port == .usbAudio {
            "cable.connector"
        } else {
            "airPlay.audio"
        }
    }
    public var isHighlighted: Bool {
        switch port {
        case .AVB, .HDMI, .PCI, .airPlay, .bluetoothA2DP, .bluetoothHFP, .bluetoothLE, .displayPort, .fireWire, .headphones, .lineOut, .thunderbolt, .usbAudio:
            true
        case .carAudio:
            false
        default:
            false
        }
    }
}
