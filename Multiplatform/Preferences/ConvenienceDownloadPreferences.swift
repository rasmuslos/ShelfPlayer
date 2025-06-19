//
//  ConvenienceDownloadPreferences.swift
//  Multiplatform
//
//  Created by Rasmus Krämer on 09.05.25.
//

import SwiftUI
import ShelfPlayback

struct ConvenienceDownloadPreferences: View {
    @Default(.enableConvenienceDownloads) private var enableConvenienceDownloads
    @Default(.enableListenNowDownloads) private var enableListenNowDownloads
    
    @State private var totalDownloaded = 0
    
    @State private var configurations = [PersistenceManager.ConvenienceDownloadSubsystem.ConvenienceDownloadConfiguration]()
    @State private var loading = [ItemIdentifier: Bool]()
    
    @State private var notifyError = false
    
    var body: some View {
        List {
            Toggle("preferences.convenienceDownload.enable", isOn: $enableConvenienceDownloads)
            Toggle("preferences.convenienceDownload.enableListenNowDownloads", isOn: $enableListenNowDownloads)
            
            Section("preferences.convenienceDownload.configurations") {
                ForEach(configurations) { configuration in
                    switch configuration {
                        case .listenNow:
                            EmptyView()
                        case .grouping(let itemID, let retrieval):
                            ItemCompactRow(itemID: itemID) {
                                if loading[itemID] == true {
                                    ProgressView()
                                } else if let parsed = ConvenienceDownloadRetrievalOption.parse(retrieval) {
                                    GroupingConfigurationSheet.ConvenienceDownloadRetrievalPicker(retrieval: .init() {
                                        parsed
                                    } set: {
                                        updateConfiguration(itemID: itemID, retrieval: $0.resolved)
                                    })
                                    .labelsHidden()
                                }
                            } callback: {}
                    }
                }
                .onDelete {
                    for index in $0 {
                        guard let itemID = PersistenceManager.shared.convenienceDownload.resolveItemID(from: configurations[index].id) else {
                            continue
                        }
                        
                        removeConfiguration(itemID: itemID)
                    }
                }
            }
            
            if totalDownloaded > 0 {
                Text("preferences.convenienceDownload.downloadedTotal \(totalDownloaded)")
                    .foregroundStyle(.secondary)
            }
        }
        .navigationTitle("preferences.convenienceDownload")
        .sensoryFeedback(.error, trigger: notifyError)
        .task {
            loadConfigurations()
        }
        .refreshable {
            loadConfigurations()
        }
        .onReceive(RFNotification[.convenienceDownloadConfigurationsChanged].publisher()) {
            loadConfigurations()
        }
    }
    
    private func removeConfiguration(itemID: ItemIdentifier) {
        Task {
            loading[itemID] = true
            
            do {
                try await PersistenceManager.shared.convenienceDownload.setRetrieval(for: itemID, retrieval: nil)
            } catch {
                notifyError.toggle()
            }
            
            loading[itemID] = false
        }
    }
    private func updateConfiguration(itemID: ItemIdentifier, retrieval: PersistenceManager.ConvenienceDownloadSubsystem.GroupingRetrieval?) {
        Task {
            loading[itemID] = true
            
            do {
                try await PersistenceManager.shared.convenienceDownload.setRetrieval(for: itemID, retrieval: retrieval)
            } catch {
                notifyError.toggle()
            }
            
            loading[itemID] = false
        }
    }
    
    private nonisolated func loadConfigurations() {
        Task {
            await withTaskGroup {
                $0.addTask {
                    let configurations = await PersistenceManager.shared.convenienceDownload.activeConfigurations.sorted {
                        $0.id < $1.id
                    }
                    
                    await MainActor.withAnimation {
                        self.configurations = configurations
                    }
                }
                $0.addTask {
                    let count = await PersistenceManager.shared.convenienceDownload.totalDownloadCount
                    
                    await MainActor.withAnimation {
                        self.totalDownloaded = count
                    }
                }
            }
        }
    }
}

#Preview {
    ConvenienceDownloadPreferences()
}
