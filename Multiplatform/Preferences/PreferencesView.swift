//
//  PreferencesView.swift
//  Multiplatform
//
//  Created by Rasmus Krämer on 01.03.25.
//

import SwiftUI
import ShelfPlayback

struct PreferencesView: View {
    @Environment(\.colorScheme) private var colorScheme
    @Default(.tintColor) private var tintColor
    
    @ViewBuilder
    private var connectionPreferences: some View {
        List {
            ConnectionManager()
        }
        .navigationTitle("connection.manage")
        .navigationBarTitleDisplayMode(.inline)
    }
    
    private func label(_ label: LocalizedStringKey, systemImage: String, color: Color, lightIcon: Bool, largeIcon: Bool = false) -> some View {
        HStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(color.gradient)
                    .aspectRatio(1, contentMode: .fit)
                    .frame(width: 36)
                
                Image(systemName: systemImage)
                    .modify {
                        if largeIcon {
                            $0
                                .resizable()
                                .aspectRatio(contentMode: .fit)
                                .frame(width: 20)
                        } else {
                            $0
                                .dynamicTypeSize(.small)
                        }
                    }
                    .shadow(color: .black.opacity(0.8), radius: 12)
                    .foregroundStyle(lightIcon ? .white : .black)
            }
            
            Text(label)
        }
    }
    
    var body: some View {
        NavigationStack {
            List {
                Section {
                    NavigationLink(destination: PlaybackRateEditor()) {
                        label("preferences.playbackRate", systemImage: "percent", color: .blue, lightIcon: true)
                    }
                    NavigationLink(destination: SleepTimerEditor()) {
                        label("preferences.sleepTimer", systemImage: "clock", color: .orange, lightIcon: true)
                    }
                }
                
                Section {
                    TintPicker {
                        label($0, systemImage: $1, color: tintColor.color, lightIcon: tintColor == .black, largeIcon: true)
                    }
                    ColorSchemePreference {
                        label($0, systemImage: $1, color: colorScheme == .dark ? .white : .black, lightIcon: colorScheme != .dark, largeIcon: true)
                    }
                }
                
                Section {
                    NavigationLink(destination: connectionPreferences) {
                        label("connection.manage", systemImage: "server.rack", color: .teal, lightIcon: true)
                    }
                    
                    NavigationLink(destination: ConvenienceDownloadPreferences()) {
                        label("preferences.convenienceDownload", systemImage: "arrow.down", color: .indigo, lightIcon: true)
                    }
                }
                
                Section {
                    NavigationLink(destination: CarPlayPreferences()) {
                        label("preferences.carPlay", systemImage: "car", color: .green, lightIcon: false)
                    }
                    NavigationLink(destination: TabValuePreferences()) {
                        label("preferences.tabs", systemImage: "rectangle.2.swap", color: .purple, lightIcon: false)
                    }
                }
                
                PodcastSortOrderPreference {
                    label($0, systemImage: $1, color: .orange, lightIcon: true)
                }
                
                Section {
                    Link(destination: URL(string: UIApplication.openSettingsURLString)!) {
                        label("preferences.settings", systemImage: "gear", color: .gray, lightIcon: true)
                    }
                    NavigationLink(destination: DebugPreferences()) {
                        label("preferences.support", systemImage: "lifepreserver", color: .red, lightIcon: true)
                    }
                }
            }
            .navigationTitle("preferences")
            .navigationBarTitleDisplayMode(.inline)
            .foregroundStyle(.primary)
        }
    }
}

#if DEBUG
#Preview {
    PreferencesView()
        .previewEnvironment()
}
#endif

