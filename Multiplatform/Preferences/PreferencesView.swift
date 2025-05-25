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
    @State private var isLoading = false
    
    @State private var cacheDirectorySize: Int? = nil
    @State private var downloadDirectorySize: Int? = nil
    
    @State private var notifyError = false
    
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
                    
                    NavigationLink(destination: CarPlayPreferences()) {
                        Label("preferences.carPlay", systemImage: "car.badge.gearshape.fill")
                    }
                }
                
                Section {
                    Link(destination: URL(string: UIApplication.openSettingsURLString)!) {
                        Label("preferences.settings", systemImage: "gear")
                    }
                    NavigationLink(destination: DebugPreferences()) {
                        Label("preferences.debug", systemImage: "ladybug.fill")
                    }
                }
                
                Section {
                    Button {
                        clearCache()
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
                        removeDownloads()
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
                .disabled(isLoading)
                .foregroundStyle(.red)
            }
            .navigationTitle("preferences")
            .navigationBarTitleDisplayMode(.inline)
            .foregroundStyle(.primary)
        }
        .sensoryFeedback(.error, trigger: notifyError)
        .task {
            load()
        }
    }
    
    private nonisolated func load() {
        Task {
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
    private nonisolated func clearCache() {
        Task {
            await MainActor.withAnimation {
                isLoading = true
            }
            
            let success: Bool
            
            do {
                try await ShelfPlayer.invalidateCache()
                success = true
            } catch {
                success = false
            }
            
            load()
            
            await MainActor.withAnimation {
                isLoading = false
                
                if !success {
                    notifyError.toggle()
                }
            }
        }
    }
    private nonisolated func removeDownloads() {
        Task {
            await MainActor.withAnimation {
                isLoading = true
            }
            
            let success: Bool
            
            do {
                try await PersistenceManager.shared.download.removeAll()
                success = true
            } catch {
                success = false
            }
            
            load()
            
            await MainActor.withAnimation {
                isLoading = false
                
                if !success {
                    notifyError.toggle()
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
