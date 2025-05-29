//
//  DebugPreferences.swift
//  Multiplatform
//
//  Created by Rasmus Krämer on 25.05.25.
//

import SwiftUI
import Nuke
import Defaults
import ShelfPlayerKit

struct DebugPreferences: View {
    #if DEBUG
    @State private var _itemID: String = "1::audiobook::Mn5Uwo+RZPPRUFZcewyMSWva5dUcftExIlOdw1ULo5o=::44e2d00a-402a-42ae-9bd3-3f339df44aef::75a7eaa0-0aed-46aa-8cb1-b5f43dbae985"
    
    private var itemID: ItemIdentifier {
        ItemIdentifier(_itemID)
    }
    #endif
    
    @Default(.spotlightIndexCompletionDate) private var spotlightIndexCompletionDate
    
    var body: some View {
        List {
            #if DEBUG
            Section(String("Item")) {
                TextField(String("ItemID"), text: $_itemID)
                
                Button(String("Navigate")) {
                    itemID.navigate()
                }
                Button(String("Create playback sessions")) {
                    Task {
                        await createDebugListeningSession(for: itemID)
                    }
                }
            }
            #endif
            
            Section {
                Link(destination: URL(string: "https://github.com/rasmuslos/ShelfPlayer")!) {
                    Label("preferences.github", systemImage: "chevron.left.forwardslash.chevron.right")
                }
                Link(destination: URL(string: "https://github.com/rasmuslos/ShelfPlayer/Support.md")!) {
                    Label("preferences.support", systemImage: "lifepreserver")
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
                
                Text("preferences.version \(ShelfPlayerKit.clientVersion) \(ShelfPlayerKit.clientBuild) \(ShelfPlayerKit.enableCentralized ? "C" : "L")")
                Text("preferences.version.database \(PersistenceManager.shared.modelContainer.schema.version.description) \(PersistenceManager.shared.modelContainer.configurations.map { $0.name }.joined(separator: ", "))")
            }
            .foregroundStyle(.secondary)
            .font(.caption)
        }
        .navigationTitle("preferences.debug")
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
            
            let success: Bool
            
            do {
                try await SpotlightIndexer.shared.reset()
                success = true
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
private func createDebugListeningSession(for itemID: ItemIdentifier) async {
    for i in 1..<50 {
        let i = Double(i)
        try! await ABSClient[itemID.connectionID].createListeningSession(itemID: itemID, timeListened: 400 + i, startTime: i * 4, currentTime: i * 5, started: .now, updated: .now)
    }
}

#Preview {
    NavigationStack {
        DebugPreferences()
    }
    .previewEnvironment()
}
#endif
