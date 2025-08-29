//
//  DebugPreferences.swift
//  Multiplatform
//
//  Created by Rasmus Krämer on 25.05.25.
//

import SwiftUI
import ShelfPlayback

struct DebugPreferences: View {
    @Default(.spotlightIndexCompletionDate) private var spotlightIndexCompletionDate
    @Default(.lastConvenienceDownloadRun) private var lastConvenienceDownloadRun
    
    @State private var downloadRunsInExtendedBackgroundTask: Bool? = nil
    
    var body: some View {
        List {
            Section {
                VStack(spacing: 12) {
                    HStack(spacing: 0) {
                        Spacer(minLength: 0)
                        
                        Image(systemName: "lifepreserver")
                            .font(.system(size: 92))
                        
                        Spacer(minLength: 0)
                    }
                    
                    Text("preferences.support")
                        .bold()
                }
                .listRowBackground(Color.clear)
            }
            
            Section {
                Link(destination: URL(string: "https://github.com/rasmuslos/ShelfPlayer")!) {
                    Label("preferences.github", systemImage: "chevron.left.forwardslash.chevron.right")
                }
                
                CreateLogArchiveButton()
            }
            .foregroundStyle(.primary)
            
            FlushButtons()
            
            Section {
                if let spotlightIndexCompletionDate {
                    Text("preferences.spotlightIndex \(spotlightIndexCompletionDate.formatted(.relative(presentation: .named)))")
                } else {
                    Text("preferences.spotlightIndex.pending")
                }
                
                if let lastConvenienceDownloadRun {
                    Text("preferences.lastConvenienceDownload \(lastConvenienceDownloadRun.formatted(.relative(presentation: .named))) \(downloadRunsInExtendedBackgroundTask == nil ? "?" : downloadRunsInExtendedBackgroundTask == true ? "E" : "R")")
                }
                
                Text("preferences.version \(ShelfPlayerKit.clientVersion) \(ShelfPlayerKit.clientBuild) \(ShelfPlayerKit.enableCentralized ? "C" : "L")")
                Text("preferences.version.database \(PersistenceManager.shared.modelContainer.schema.version.description) \(PersistenceManager.shared.modelContainer.configurations.map { $0.name }.joined(separator: ", "))")
            }
            .foregroundStyle(.secondary)
            .font(.caption)
            
            Section {
                Link(destination: URL(string: "https://github.com/rasmuslos/ShelfPlayer/blob/main/Privacy.md")!) {
                    Text(verbatim: "Privacy")
                }
                Link(destination: URL(string: "https://github.com/rasmuslos/ShelfPlayer/blob/main/LICENSE")!) {
                    Text(verbatim: "License")
                }
                Link(destination: URL(string: "https://github.com/rasmuslos/ShelfPlayer/blob/main/ToS.md")!) {
                    Text(verbatim: "Terms of Service")
                }
            }
            .font(.caption)
        }
        .task {
            downloadRunsInExtendedBackgroundTask = await PersistenceManager.shared.convenienceDownload.runsInExtendedBackgroundTask
        }
    }
}

private struct FlushButtons: View {
    @State private var isLoading = false
    
    @State private var cacheDirectorySize: Int? = nil
    @State private var downloadDirectorySize: Int? = nil
    
    @State private var notifyError = false
    
    var body: some View {
        Section {
            Button {
                clearSpotlightIndex()
            } label: {
                Label("preferences.purge.spotlight", systemImage: "sparkle.magnifyingglass")
            }
            
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
        .sensoryFeedback(.error, trigger: notifyError)
        .foregroundStyle(.red)
        .task {
            load()
        }
    }
    
    nonisolated func load() {
        Task {
            let (imageSize, cacheSize, downloadsSize) = (
                await ImageLoader.shared.currentDiskUsage,
                try? ShelfPlayerKit.cacheDirectoryURL.directoryTotalAllocatedSize(),
                try? ShelfPlayerKit.downloadDirectoryURL.directoryTotalAllocatedSize()
            )
            let totalCacheSize = imageSize + (cacheSize ?? 0)
            
            await MainActor.withAnimation {
                if totalCacheSize > 0 {
                    cacheDirectorySize = totalCacheSize
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
    nonisolated func clearCache() {
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
            
            try? await Task.sleep(for: .seconds(4))
            
            load()
            
            await MainActor.withAnimation {
                isLoading = false
                
                if !success {
                    notifyError.toggle()
                }
            }
        }
    }
    nonisolated func removeDownloads() {
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
            
            try? await Task.sleep(for: .seconds(1))
            
            load()
            
            await MainActor.withAnimation {
                isLoading = false
                
                if !success {
                    notifyError.toggle()
                }
            }
        }
    }
    
    nonisolated func clearSpotlightIndex() {
        Task {
            await MainActor.withAnimation {
                isLoading = true
            }
            
            var success = true
            
            do {
                try await PersistenceManager.shared.convenienceDownload.resetRunsInExtendedBackgroundTask()
            } catch {
                success = false
            }
            
            do {
                try await SpotlightIndexer.shared.reset()
            } catch {
                success = false
            }
            
            await MainActor.withAnimation {
                isLoading = false
                
                if !success {
                    notifyError.toggle()
                }
            }
        }
    }
}


#if DEBUG
#Preview {
    NavigationStack {
        DebugPreferences()
    }
    .previewEnvironment()
}
#endif
