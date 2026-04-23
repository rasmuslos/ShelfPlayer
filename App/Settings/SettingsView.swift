//
//  SettingsView.swift
//  ShelfPlayer
//

import SwiftUI
import ShelfPlayback

struct SettingsView: View {
    @Environment(OfflineMode.self) private var offlineMode
    @Bindable private var satellite = Satellite.shared

    @ViewBuilder
    private var connectionPreferences: some View {
        List {
            SettingsPageHeader(title: "connection.manage", systemImage: "server.rack", color: .teal)

            ConnectionManager()
        }
        .navigationTitle("connection.manage")
        .navigationBarTitleDisplayMode(.inline)
    }

    private func label(_ label: LocalizedStringKey, systemImage: String, color: Color) -> some View {
        HStack(spacing: 12) {
            Image(systemName: systemImage)
                .font(.body)
                .foregroundStyle(.white)
                .frame(width: 30, height: 30)
                .background(color.gradient, in: .rect(cornerRadius: 7))

            Text(label)
        }
    }

    var body: some View {
        NavigationStack(path: $satellite.settingsNavigationPath) {
            List {
                Section {
                    NavigationLink(value: SettingsPage.general) {
                        label("settings.general", systemImage: "slider.horizontal.3", color: .gray)
                    }
                    NavigationLink(value: SettingsPage.appearance) {
                        label("settings.appearance", systemImage: "paintbrush.fill", color: .purple)
                    }
                }

                Section("settings.section.playback") {
                    NavigationLink(value: SettingsPage.playback) {
                        label("settings.playback", systemImage: "play.circle.fill", color: .blue)
                    }
                    NavigationLink(value: SettingsPage.sleepTimer) {
                        label("settings.sleepTimer", systemImage: "moon.zzz.fill", color: .indigo)
                    }
                }

                Section("settings.section.content") {
                    NavigationLink(value: SettingsPage.connections) {
                        label("connection.manage", systemImage: "server.rack", color: .teal)
                    }
                    NavigationLink(value: SettingsPage.hiddenLibraries) {
                        label("preferences.hiddenLibraries", systemImage: "eye.slash.fill", color: .gray)
                    }
                    
                    NavigationLink(value: SettingsPage.downloads) {
                        label("settings.downloads", systemImage: "arrow.down.circle.fill", color: .green)
                    }
                    if !offlineMode.isEnabled {
                        PodcastSortOrderPreference {
                            label($0, systemImage: $1, color: .orange)
                        }
                    }
                }

                if !offlineMode.isEnabled {
                    Section("settings.section.integrations") {
                        NavigationLink(value: SettingsPage.carPlay) {
                            label("preferences.carPlay", systemImage: "car.fill", color: .green)
                        }
                        NavigationLink(value: SettingsPage.tabs) {
                            label("preferences.tabs", systemImage: "rectangle.2.swap", color: .purple)
                        }
                    }
                }

                Section {
                    NavigationLink(value: SettingsPage.advanced) {
                        label("settings.advanced", systemImage: "gearshape.2.fill", color: .gray)
                    }
                    
                    NavigationLink(value: SettingsPage.support) {
                        label("preferences.support", systemImage: "questionmark.circle.fill", color: .red)
                    }
                }

                #if DEBUG
                Section {
                    NavigationLink(value: SettingsPage.debug) {
                        label("settings.debug", systemImage: "ant.fill", color: .red)
                    }
                }
                #endif
            }
            .navigationTitle("preferences")
            .navigationBarTitleDisplayMode(.inline)
            .foregroundStyle(.primary)
            .navigationDestination(for: SettingsPage.self) { page in
                switch page {
                case .general:
                    GeneralSettingsView()
                case .appearance:
                    AppearanceSettingsView()
                case .playback:
                    PlaybackSettingsView()
                case .sleepTimer:
                    SleepTimerSettingsView()
                case .connections:
                    connectionPreferences
                case .downloads:
                    DownloadSettingsView()
                case .hiddenLibraries:
                    LibraryVisibilityPreferences()
                case .carPlay:
                    CarPlayPreferences()
                case .tabs:
                    TabValuePreferences()
                case .advanced:
                    AdvancedSettingsView()
                case .support:
                    DebugPreferences()
                #if DEBUG
                case .debug:
                    DebugSettingsView()
                #endif
                }
            }
        }
    }
}

// MARK: - Settings Page

enum SettingsPage: Hashable {
    case general
    case appearance
    case playback
    case sleepTimer
    case connections
    case downloads
    case hiddenLibraries
    case carPlay
    case tabs
    case advanced
    case support

    #if DEBUG
    case debug
    #endif
}

// MARK: - Header

/// Hero header used at the top of every settings sub-page — a large rounded
/// icon badge. The page title lives in the navigation bar.
struct SettingsPageHeader: View {
    let title: LocalizedStringKey
    let systemImage: String
    let color: Color

    var body: some View {
        Section {
            ZStack {
                RoundedRectangle(cornerRadius: 22, style: .continuous)
                    .fill(color.gradient)
                    .frame(width: 88, height: 88)
                    .shadow(color: color.opacity(0.25), radius: 12, y: 4)
                Image(systemName: systemImage)
                    .font(.system(size: 46, weight: .regular))
                    .foregroundStyle(.white)
                    .accessibilityLabel(Text(title))
            }
            .frame(maxWidth: .infinity)
            .listRowBackground(Color.clear)
            .listRowInsets(EdgeInsets(top: 24, leading: 20, bottom: 24, trailing: 20))
        }
        .listSectionSpacing(.compact)
    }
}

// MARK: - General

private struct GeneralSettingsView: View {
    @Bindable private var settings = AppSettings.shared

    var body: some View {
        List {
            SettingsPageHeader(title: "settings.general", systemImage: "slider.horizontal.3", color: .gray)

            Section {
                Toggle("settings.groupAudiobooksInSeries", isOn: $settings.groupAudiobooksInSeries)
                Toggle("settings.forceAspectRatio", isOn: $settings.forceAspectRatio)
                Toggle("settings.showSingleEntryGroupedSeries", isOn: $settings.showSingleEntryGroupedSeries)
                Toggle("settings.enableSerifFont", isOn: $settings.enableSerifFont)
            }

}
        .navigationTitle("settings.general")
        .navigationBarTitleDisplayMode(.inline)
    }
}

// MARK: - Appearance

private struct AppearanceSettingsView: View {
    @State private var activeTintColor: TintColor = AppSettings.shared.tintColor
    @Bindable private var settings = AppSettings.shared

    var body: some View {
        List {
            SettingsPageHeader(title: "settings.appearance", systemImage: "paintbrush.fill", color: .purple)

            Section {
                TintPicker(onChanged: { activeTintColor = $0 }) { title, _ in
                    Label(title, systemImage: activeTintColor == .shelfPlayer ? "circle.dashed" : "circle.fill")
                        .modify(if: activeTintColor != .shelfPlayer) {
                            $0.foregroundStyle(activeTintColor.color)
                        }
                }
                ColorSchemePreference { title, icon in
                    Label(title, systemImage: icon)
                }
            }

            Section {
                Toggle("settings.animatedNowPlayingBackground", isOn: $settings.animatedNowPlayingBackground)
            }
        }
        .navigationTitle("settings.appearance")
        .navigationBarTitleDisplayMode(.inline)
    }
}

// MARK: - Playback

private struct PlaybackSettingsView: View {
    @Bindable private var settings = AppSettings.shared

    private let skipIntervals = [5, 10, 15, 30, 45, 60, 75, 90]

    var body: some View {
        List {
            SettingsPageHeader(title: "settings.playback", systemImage: "play.circle.fill", color: .blue)

            Section {
                Toggle("settings.enableChapterTrack", isOn: $settings.enableChapterTrack)
                Toggle("settings.replaceVolumeWithTotalProgress", isOn: $settings.replaceVolumeWithTotalProgress)
            }

            Section {
                Toggle("settings.generateUpNextQueue", isOn: $settings.generateUpNextQueue)
                Toggle("settings.enableSmartRewind", isOn: $settings.enableSmartRewind)
            } footer: {
                Text("settings.smartRewind.footer")
            }

            Section("settings.skipIntervals") {
                Picker("settings.skipBackwardsInterval", selection: $settings.skipBackwardsInterval) {
                    ForEach(skipIntervals, id: \.self) { interval in
                        Text("settings.skipInterval.seconds \(interval)")
                            .tag(interval)
                    }
                }

                Picker("settings.skipForwardsInterval", selection: $settings.skipForwardsInterval) {
                    ForEach(skipIntervals, id: \.self) { interval in
                        Text("settings.skipInterval.seconds \(interval)")
                            .tag(interval)
                    }
                }
            }

            Section {
                NavigationLink(destination: PlaybackRateEditor()) {
                    Label("preferences.playbackRate", systemImage: "gauge.with.needle")
                }
            }
        }
        .navigationTitle("settings.playback")
        .navigationBarTitleDisplayMode(.inline)
    }
}

// MARK: - Sleep Timer

private struct SleepTimerSettingsView: View {
    @Bindable private var settings = AppSettings.shared

    var body: some View {
        List {
            SettingsPageHeader(title: "settings.sleepTimer", systemImage: "moon.zzz.fill", color: .indigo)

            Section(footer: Text("settings.sleepTimer.footer")) {
                Toggle("settings.sleepTimerFadeOut", isOn: $settings.sleepTimerFadeOut)
                Toggle("settings.shakeExtendsSleepTimer", isOn: $settings.shakeExtendsSleepTimer)
                Toggle("settings.extendSleepTimerOnPlay", isOn: $settings.extendSleepTimerOnPlay)
            }

            Section {
                NavigationLink(destination: SleepTimerEditor()) {
                    Label("settings.sleepTimer.intervals", systemImage: "clock.fill")
                }
            }
        }
        .navigationTitle("settings.sleepTimer")
        .navigationBarTitleDisplayMode(.inline)
    }
}

// MARK: - Downloads

private struct DownloadSettingsView: View {
    @Bindable private var settings = AppSettings.shared

    var body: some View {
        List {
            SettingsPageHeader(title: "settings.downloads", systemImage: "arrow.down.circle.fill", color: .green)

            Section {
                Toggle("settings.allowCellularDownloads", isOn: $settings.allowCellularDownloads)
                Toggle("settings.removeFinishedDownloads", isOn: $settings.removeFinishedDownloads)
            }

            Section {
                NavigationLink(destination: ConvenienceDownloadPreferences()) {
                    Text("preferences.convenienceDownload")
                }
            }
        }
        .navigationTitle("settings.downloads")
        .navigationBarTitleDisplayMode(.inline)
    }
}

// MARK: - Advanced

private struct AdvancedSettingsView: View {
    @Bindable private var settings = AppSettings.shared

    var body: some View {
        List {
            SettingsPageHeader(title: "settings.advanced", systemImage: "gearshape.2.fill", color: .gray)

            Section {
                Toggle("settings.lockSeekBar", isOn: $settings.lockSeekBar)
                Toggle("settings.ultraHighQuality", isOn: $settings.ultraHighQuality)
                Toggle("settings.enableHapticFeedback", isOn: $settings.enableHapticFeedback)
                Toggle("settings.itemImageStatusPercentageText", isOn: $settings.itemImageStatusPercentageText)
            }
        }
        .navigationTitle("settings.advanced")
        .navigationBarTitleDisplayMode(.inline)
    }
}

// MARK: - Debug

#if DEBUG
private struct DebugSettingsView: View {
    @State private var general = [String: String]()

    @AppStorage("io.rfk.shelfPlayer.debug.forceImagePlaceholder") private var forceImagePlaceholder = false

    var body: some View {
        List {
            Section {
                ForEach(Array(general.keys).sorted(), id: \.hashValue) { key in
                    LabeledContent(key, value: general[key]!)
                }
            }

            Section("Rendering") {
                Toggle("Force image placeholder", isOn: $forceImagePlaceholder)
            }

            Button("Reconnect sockets") {
                PersistenceManager.shared.webSocket.reconnect()
            }
        }
        .navigationTitle("settings.debug")
        .navigationBarTitleDisplayMode(.inline)
        .task {
            general.removeAll()

            general["offline"] = OfflineMode.shared.isEnabled.description
            general["socketCount"] = PersistenceManager.shared.webSocket.connected.description
        }
    }
}
#endif

#if DEBUG
#Preview {
    SettingsView()
        .previewEnvironment()
}
#endif
