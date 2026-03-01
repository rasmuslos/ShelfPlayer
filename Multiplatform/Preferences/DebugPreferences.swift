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
            
            CacheSection()
            
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

private struct CacheSection: View {
    @State private var downloadCount = 0
    @State private var imageCount = 0
    @State private var itemCount = 0
    @State private var progressCount = 0
    
    @State private var isLoading = true
    
    var body: some View {
        Section("preferences.cache") {
            Group {
                InformationListRow(title: String(localized: "preferences.cache.downloads"), value: downloadCount.formatted(.number))
                InformationListRow(title: String(localized: "preferences.cache.images"), value: imageCount.formatted(.number))
                InformationListRow(title: String(localized: "preferences.cache.items"), value: itemCount.formatted(.number))
                InformationListRow(title: String(localized: "preferences.cache.progress"), value: progressCount.formatted(.number))
            }
            .modify(if: isLoading) {
                $0
                    .redacted(reason: .placeholder)
            }
        }
        .task {
            await load()
        }
    }
    
    private func load() async {
        isLoading = true
        
        downloadCount = await PersistenceManager.shared.download.totalCount
        imageCount = await recursiveFileCount(in: ImageLoader.shared.cachePath)
        itemCount = await recursiveFileCount(in: ResolveCache.shared.cachePath)
        progressCount = await PersistenceManager.shared.progress.totalCount
        
        isLoading = false
    }
    
    private nonisolated func recursiveFileCount(in directoryURL: URL) -> Int {
        let keys: Set<URLResourceKey> = [.isRegularFileKey]
        
        guard let enumerator = FileManager.default.enumerator(
            at: directoryURL,
            includingPropertiesForKeys: Array(keys),
            options: [.skipsPackageDescendants],
            errorHandler: nil
        ) else {
            return 0
        }
        
        var count = 0
        for case let fileURL as URL in enumerator {
            do {
                let values = try fileURL.resourceValues(forKeys: keys)
                if values.isRegularFile == true {
                    count += 1
                }
            } catch {
                // If we can't read resource values for a URL, skip it and continue.
                continue
            }
        }
        
        return count
    }
}

private struct FlushButtons: View {
    @Environment(OfflineMode.self) private var offlineMode
    
    @State private var isLoading = false
    @State private var isProgressWarningPresented = false
    
    @State private var cacheDirectorySize: Int? = nil
    @State private var downloadDirectorySize: Int? = nil
    
    @State private var notifyError = false
    
    var body: some View {
        Section {
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
            
            Button("preferences.purge.progress", systemImage: "trash.square") {
                isProgressWarningPresented = true
            }
            .disabled(offlineMode.isEnabled)
        }
        .alert("preferences.purge.progress", isPresented: $isProgressWarningPresented) {
            Button("action.cancel", role: .cancel) {}
            
            Button("action.proceed") {
                flushProgres()
            }
        } message: {
            Text("preferences.purge.progress.warning")
        }
        .disabled(isLoading)
        .hapticFeedback(.error, trigger: notifyError)
        .foregroundStyle(.red)
        .task {
            load()
        }
    }
    
    func load() {
        Task {
            let (cacheSize, downloadsSize) = (
                (try? ShelfPlayerKit.cacheDirectoryURL.directoryTotalAllocatedSize()) ?? 0,
                try? ShelfPlayerKit.downloadDirectoryURL.directoryTotalAllocatedSize()
            )
            
            withAnimation {
                if cacheSize > 0 {
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
    func clearCache() {
        Task {
            withAnimation {
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
            
            withAnimation {
                isLoading = false
                
                if !success {
                    notifyError.toggle()
                }
            }
        }
    }
    func removeDownloads() {
        Task {
            withAnimation {
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
            
            withAnimation {
                isLoading = false
                
                if !success {
                    notifyError.toggle()
                }
            }
        }
    }
    func flushProgres() {
        Task {
            withAnimation {
                isLoading = true
            }
            
            let success: Bool
            
            do {
                try await PersistenceManager.shared.progress.flush()
                success = true
            } catch {
                success = false
            }
            
            try? await Task.sleep(for: .seconds(1))
            
            load()
            
            withAnimation {
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
