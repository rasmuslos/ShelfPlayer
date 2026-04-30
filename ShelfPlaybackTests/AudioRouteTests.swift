//
//  AudioRouteTests.swift
//  ShelfPlaybackTests
//

import Testing
import Foundation
import AVFoundation
@testable import ShelfPlayback

struct AudioRouteTests {
    // MARK: - Name-based icon resolution

    @Test func airPodsMaxIconByName() {
        let route = AudioRoute(name: "Rasmus' AirPods Max", port: .bluetoothA2DP)
        #expect(route.icon == "airpods.max")
    }

    @Test func airPodsProIconByName() {
        let route = AudioRoute(name: "AirPods Pro", port: .bluetoothA2DP)
        #expect(route.icon == "airpods.pro")
    }

    @Test func airPodsGenericIconByName() {
        let route = AudioRoute(name: "AirPods", port: .bluetoothA2DP)
        #expect(route.icon == "airpods.gen3")
    }

    @Test func airPodsMaxBeatsAirPods() {
        // The most specific match must win — "AirPods Max" should not fall
        // through to the generic "AirPods" branch.
        let route = AudioRoute(name: "AirPods Max", port: .bluetoothA2DP)
        #expect(route.icon == "airpods.max")
    }

    @Test func airPodsProBeatsAirPods() {
        let route = AudioRoute(name: "AirPods Pro", port: .bluetoothA2DP)
        #expect(route.icon == "airpods.pro")
    }

    @Test func homePodMiniIconByName() {
        let route = AudioRoute(name: "Living Room HomePod Mini", port: .airPlay)
        #expect(route.icon == "homepod.mini.fill")
    }

    @Test func homePodIconByName() {
        let route = AudioRoute(name: "HomePod", port: .airPlay)
        #expect(route.icon == "homepod.fill")
    }

    @Test func homePodMiniBeatsHomePod() {
        let route = AudioRoute(name: "HomePod Mini", port: .airPlay)
        #expect(route.icon == "homepod.mini.fill")
    }

    @Test func appleTVIconByName() {
        let route = AudioRoute(name: "Living Room AppleTV", port: .airPlay)
        #expect(route.icon == "appletv.fill")
    }

    // MARK: - Port-based icon resolution

    @Test func hdmiIcon() {
        let route = AudioRoute(name: "External Display", port: .HDMI)
        #expect(route.icon == "tv.and.hifispeaker.fill")
    }

    @Test func displayPortIcon() {
        let route = AudioRoute(name: "Monitor", port: .displayPort)
        #expect(route.icon == "tv.and.hifispeaker.fill")
    }

    @Test func airPlayIcon() {
        let route = AudioRoute(name: "Generic Speaker", port: .airPlay)
        #expect(route.icon == "airplay.audio")
    }

    @Test func bluetoothA2DPIcon() {
        let route = AudioRoute(name: "Some Speaker", port: .bluetoothA2DP)
        #expect(route.icon == "hifispeaker.fill")
    }

    @Test func bluetoothHFPIcon() {
        let route = AudioRoute(name: "Some Headset", port: .bluetoothHFP)
        #expect(route.icon == "hifispeaker.fill")
    }

    @Test func bluetoothLEIcon() {
        let route = AudioRoute(name: "BLE Speaker", port: .bluetoothLE)
        #expect(route.icon == "hifispeaker.fill")
    }

    @Test func headphonesIcon() {
        let route = AudioRoute(name: "Wired Headphones", port: .headphones)
        #expect(route.icon == "headphones")
    }

    @Test func lineOutIcon() {
        let route = AudioRoute(name: "Line Out", port: .lineOut)
        #expect(route.icon == "cable.coaxial")
    }

    @Test func thunderboltIcon() {
        let route = AudioRoute(name: "Thunderbolt Audio", port: .thunderbolt)
        #expect(route.icon == "cable.connector")
    }

    @Test func usbAudioIcon() {
        let route = AudioRoute(name: "USB DAC", port: .usbAudio)
        #expect(route.icon == "cable.connector")
    }

    @Test func carAudioIcon() {
        let route = AudioRoute(name: "My Car", port: .carAudio)
        #expect(route.icon == "car.fill")
    }

    @Test func builtInSpeakerFallsBackToAirPlay() {
        // Any port not explicitly handled falls through to the airplay default.
        let route = AudioRoute(name: "iPhone Speaker", port: .builtInSpeaker)
        #expect(route.icon == "airplay.audio")
    }

    @Test func builtInReceiverFallsBackToAirPlay() {
        let route = AudioRoute(name: "Receiver", port: .builtInReceiver)
        #expect(route.icon == "airplay.audio")
    }

    // MARK: - isHighlighted

    @Test func avbIsHighlighted() {
        #expect(AudioRoute(name: "AVB", port: .AVB).isHighlighted)
    }

    @Test func hdmiIsHighlighted() {
        #expect(AudioRoute(name: "HDMI", port: .HDMI).isHighlighted)
    }

    @Test func pciIsHighlighted() {
        #expect(AudioRoute(name: "PCI", port: .PCI).isHighlighted)
    }

    @Test func airPlayIsHighlighted() {
        #expect(AudioRoute(name: "AirPlay", port: .airPlay).isHighlighted)
    }

    @Test func bluetoothA2DPIsHighlighted() {
        #expect(AudioRoute(name: "BT A2DP", port: .bluetoothA2DP).isHighlighted)
    }

    @Test func bluetoothHFPIsHighlighted() {
        #expect(AudioRoute(name: "BT HFP", port: .bluetoothHFP).isHighlighted)
    }

    @Test func bluetoothLEIsHighlighted() {
        #expect(AudioRoute(name: "BT LE", port: .bluetoothLE).isHighlighted)
    }

    @Test func displayPortIsHighlighted() {
        #expect(AudioRoute(name: "DP", port: .displayPort).isHighlighted)
    }

    @Test func fireWireIsHighlighted() {
        #expect(AudioRoute(name: "FireWire", port: .fireWire).isHighlighted)
    }

    @Test func headphonesIsHighlighted() {
        #expect(AudioRoute(name: "Headphones", port: .headphones).isHighlighted)
    }

    @Test func lineOutIsHighlighted() {
        #expect(AudioRoute(name: "Line Out", port: .lineOut).isHighlighted)
    }

    @Test func thunderboltIsHighlighted() {
        #expect(AudioRoute(name: "Thunderbolt", port: .thunderbolt).isHighlighted)
    }

    @Test func usbAudioIsHighlighted() {
        #expect(AudioRoute(name: "USB Audio", port: .usbAudio).isHighlighted)
    }

    @Test func carAudioIsHighlighted() {
        #expect(AudioRoute(name: "Car", port: .carAudio).isHighlighted)
    }

    @Test func builtInSpeakerIsNotHighlighted() {
        #expect(!AudioRoute(name: "Speaker", port: .builtInSpeaker).isHighlighted)
    }

    @Test func builtInReceiverIsNotHighlighted() {
        #expect(!AudioRoute(name: "Receiver", port: .builtInReceiver).isHighlighted)
    }

    @Test func builtInMicIsNotHighlighted() {
        #expect(!AudioRoute(name: "Built-in Mic", port: .builtInMic).isHighlighted)
    }
}
