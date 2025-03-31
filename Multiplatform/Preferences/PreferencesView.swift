//
//  PreferencesView.swift
//  Multiplatform
//
//  Created by Rasmus Krämer on 01.03.25.
//

import SwiftUI
import Nuke
import ShelfPlayerKit

struct PreferencesView: View {
    @State private var cacheDirectorySize: Int? = nil
    @State private var downloadDirectorySize: Int? = nil
    
    @State private var notificationPermission: UNAuthorizationStatus = .notDetermined
    
    var body: some View {
        List {
            Section {
                NavigationLink {
                    ConnectionPreferences()
                } label: {
                    Label("connection.manage", systemImage: "server.rack")
                }
                
                NavigationLink {
                    PlaybackRateEditor()
                } label: {
                    Label("preferences.playbackRate", systemImage: "percent")
                }
                NavigationLink {
                    SleepTimerEditor()
                } label: {
                    Label("preferences.sleepTimer", systemImage: "clock")
                }
                
                TintPicker()
            }
            
            Section {
                Link(destination: URL(string: UIApplication.openSettingsURLString)!) {
                    Label("preferences.settings", systemImage: "gear")
                }
                
                switch notificationPermission {
                case .notDetermined:
                    Button {
                        Task {
                            try await UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .badge])
                            notificationPermission = await UNUserNotificationCenter.current().notificationSettings().authorizationStatus
                        }
                    } label: {
                        Label("notification.permission.request", systemImage: "bell.badge.waveform.fill")
                    }
                    .task {
                        notificationPermission = await UNUserNotificationCenter.current().notificationSettings().authorizationStatus
                    }
                case .denied:
                    Link(destination: URL(string: UIApplication.openNotificationSettingsURLString)!) {
                        Label("notification.permission.denied", systemImage: "bell.slash.fill")
                    }
                    .foregroundStyle(.red)
                case .authorized:
                    Label("notification.permission.granted", systemImage: "bell.badge.fill")
                        .foregroundStyle(.secondary)
                default:
                    ProgressIndicator()
                }
            } footer: {
                Text("notification.permission.footer")
                    .foregroundStyle(.secondary)
            }
            
            Section {
                Button {
                    ShelfPlayer.clearCache()
                } label: {
                    Label {
                        HStack(spacing: 0) {
                            Text("preferences.purge.cache")
                            
                            if let cacheDirectorySize {
                                Spacer(minLength: 8)
                                Text(cacheDirectorySize.formatted(.byteCount(style: .file)))
                                    .foregroundStyle(.gray)
                            }
                        }
                    } icon: {
                        Image(systemName: "square.stack.3d.up.slash")
                    }
                }
                
                Button {
                    
                } label: {
                    Label {
                        HStack(spacing: 0) {
                            Text("preferences.purge.downloads")
                            
                            if let downloadDirectorySize {
                                Spacer(minLength: 8)
                                Text(downloadDirectorySize.formatted(.byteCount(style: .file)))
                                    .foregroundStyle(.gray)
                            }
                        }
                    } icon: {
                        Image(systemName: "slash.circle")
                    }
                }
            }
            .foregroundStyle(.red)
            
            Section {
                Link(destination: URL(string: "https://github.com/rasmuslos/ShelfPlayer")!) {
                    Label("preferences.github", systemImage: "chevron.left.forwardslash.chevron.right")
                }
                Link(destination: URL(string: "https://github.com/rasmuslos/ShelfPlayer/Support.md")!) {
                    Label("preferences.support", systemImage: "lifepreserver")
                }
                
                CreateLogArchiveButton()
            }
            
            Section {
                Text("preferences.version \(ShelfPlayerKit.clientVersion) \(ShelfPlayerKit.clientBuild) \(ShelfPlayerKit.enableCentralized ? "C" : "L")")
                Text("preferences.version.database \(PersistenceManager.shared.modelContainer.schema.version.description) \(PersistenceManager.shared.modelContainer.configurations.map { $0.name }.joined(separator: ", "))")
            }
            .foregroundStyle(.secondary)
            .font(.caption)
        }
        .navigationTitle("preferences")
        .navigationBarTitleDisplayMode(.inline)
        .foregroundStyle(.primary)
        .task {
            load()
        }
    }
    
    private nonisolated func load() {
        Task.detached {
            let (cacheSize, downloadsSize) = ((ImagePipeline.shared.configuration.dataCache as? DataCache)?.totalAllocatedSize, try? ShelfPlayerKit.downloadDirectoryURL.directoryTotalAllocatedSize())
            
            await MainActor.withAnimation {
                if let cacheSize, cacheSize > 0 {
                    cacheDirectorySize = cacheSize
                } else {
                    cacheDirectorySize = nil
                }
                
                if let downloadsSize, downloadsSize > 0 {
                    downloadDirectorySize = downloadsSize
                } else {
                    downloadDirectorySize = nil
                }
            }
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
                            Button("preferences", systemImage: "gearshape.circle") {
                                satellite.present(.preferences)
                            }
                            .labelStyle(.iconOnly)
                        }
                } else {
                    $0
                }
            }
    }
}

private struct ConnectionPreferences: View {
    var body: some View {
        List {
            ConnectionManager()
        }
        .navigationTitle("connection.manage")
        .navigationBarTitleDisplayMode(.inline)
    }
}

#if DEBUG
#Preview {
    NavigationStack {
        PreferencesView()
    }
    .previewEnvironment()
}
#endif

/*
 
 guard let size = try? (ImagePipeline.shared.configuration.dataCache as? DataCache)?.path.directoryTotalAllocatedSize() else {
     return
 }
 */
