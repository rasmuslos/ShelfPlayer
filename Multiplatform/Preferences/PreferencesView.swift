//
//  PreferencesView.swift
//  Multiplatform
//
//  Created by Rasmus Krämer on 01.03.25.
//

import SwiftUI
import ShelfPlayback

struct PreferencesView: View {
    @ViewBuilder
    private var connectionPreferences: some View {
        List {
            ConnectionManager()
        }
        .navigationTitle("connection.manage")
        .navigationBarTitleDisplayMode(.inline)
    }
    
    var body: some View {
        NavigationStack {
            List {
                Section {
                    NavigationLink(destination: PlaybackRateEditor()) {
                        Label("preferences.playbackRate", systemImage: "percent")
                    }
                    NavigationLink(destination: SleepTimerEditor()) {
                        Label("preferences.sleepTimer", systemImage: "clock")
                    }
                    
                    TintPicker()
                }
                
                Section {
                    NavigationLink(destination: connectionPreferences) {
                        Label("connection.manage", systemImage: "server.rack")
                    }
                    
                    NavigationLink(destination: ConvenienceDownloadPreferences()) {
                        Label("preferences.convenienceDownload", systemImage: "arrow.down.circle")
                    }
                    
                    NavigationLink(destination: CarPlayPreferences()) {
                        Label("preferences.carPlay", systemImage: "car.badge.gearshape")
                    }
                }
                
                PodcastSortOrderPreferences()
                
                Section {
                    Link(destination: URL(string: UIApplication.openSettingsURLString)!) {
                        Label("preferences.settings", systemImage: "gear")
                    }
                    NavigationLink(destination: DebugPreferences()) {
                        Label("preferences.support", systemImage: "lifepreserver")
                    }
                }
            }
            .navigationTitle("preferences")
            .navigationBarTitleDisplayMode(.inline)
            .foregroundStyle(.primary)
        }
    }
}

struct CompactPreferencesToolbarModifier: ViewModifier {
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    @Environment(Satellite.self) private var satellite
    
    func body(content: Content) -> some View {
        content
            .modify {
                if horizontalSizeClass == .compact {
                    $0
                        .toolbar {
                            ToolbarItem(placement: .topBarLeading) {
                                Button("preferences", systemImage: "gearshape.circle") {
                                    satellite.present(.preferences)
                                }
                                .labelStyle(.iconOnly)
                            }
                        }
                } else {
                    $0
                }
            }
    }
}

#if DEBUG
#Preview {
    PreferencesView()
        .previewEnvironment()
}
#endif
