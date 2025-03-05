//
//  AccountSheet.swift
//  Audiobooks
//
//  Created by Rasmus Krämer on 16.10.23.
//

import SwiftUI
import Defaults
import Nuke
import ShelfPlayerKit

internal struct AccountSheet: View {
    @Environment(\.dismiss) private var dismiss
    
    @Default(.lastSpotlightIndex) private var lastSpotlightIndex
    
    @State private var username: String?
    @State private var serverVersion: String?
    
    @State private var serverInfoToggled = false
    
    @State private var cacheSize: Int? = nil
    @State private var downloadsSize: Int? = nil
    
    @State private var notificationPermission: UNAuthorizationStatus = .notDetermined
    
    var body: some View {
        NavigationStack {
            List {
                Section {
                    if let username {
                        Text(username)
                    } else {
                        ProgressIndicator()
                    }
                    
                    Button(role: .destructive) {
                        /*
                        try? OfflineManager.shared.deleteProgressEntities()
                        
                        OfflineManager.shared.removeAllDownloads()
                        SpotlightIndexer.deleteIndex()
                        
                        AudiobookshelfClient.shared.store(token: nil)
                         */
                        
                        dismiss()
                    } label: {
                        Label("account.logout", systemImage: "person.crop.circle.badge.minus")
                            .foregroundStyle(.red)
                    }
                }
                
                Section {
                    Group {
                        Button {
                            Task {
                                // try? await BackgroundTaskHandler.updateDownloads()
                            }
                        } label: {
                            Label("account.newEpisodes.check", systemImage: "antenna.radiowaves.left.and.right")
                        }
                    }
                    .foregroundStyle(.primary)
                } footer: {
                    Text("account.notifications.text")
                }
                
                DownloadQueue()
                
                /*
                Section {
                    let hours = customSleepTimer / 60
                    let minutes = customSleepTimer % 60
                    
                    Stepper("\(hours) account.sleepTimer.hours", value: .init(get: { hours }, set: {
                        customSleepTimer -= hours * 60
                        customSleepTimer += $0 * 60
                    }), in: 0...12)
                    
                    Stepper("\(minutes) account.sleepTimer.minutes", value: .init(get: { minutes }, set: {
                        customSleepTimer -= minutes
                        customSleepTimer += $0
                    }), in: 0...60)
                } header: {
                    Text("account.custom")
                } footer: {
                    Text("account.custom.text")
                }
                 */
                
                Section {
                    TintPicker()
                }
                .foregroundStyle(.primary)
                
                Section {
                    Group {
                        Button(role: .destructive) {
                            downloadsSize = nil
                            // OfflineManager.shared.removeAllDownloads()
                            
                            Task {
                                await update()
                            }
                        } label: {
                            Label {
                                let text = Text("account.delete.downloads")
                                
                                if let downloadsSize {
                                    text
                                    + Text(verbatim: " (\(downloadsSize.formatted(.byteCount(style: .file))))")
                                } else {
                                    text
                                }
                            } icon: {
                                Image(systemName: "slash.circle")
                            }
                        }
                        
                        Button(role: .destructive) {
                            cacheSize = nil
                            
                            ImagePipeline.shared.cache.removeAll()
                            // try? OfflineManager.shared.deleteProgressEntities()
                            
                            /*
                            NotificationCenter.default.post(name: SelectLibraryModifier.changeLibraryNotification, object: nil, userInfo: [
                                "offline": false,
                            ])
                             */
                            
                            Task {
                                await update()
                            }
                        } label: {
                            Label {
                                let text = Text("account.delete.cache")
                                
                                if let cacheSize {
                                    text
                                    + Text(verbatim: " (\(cacheSize.formatted(.byteCount(style: .file))))")
                                } else {
                                    text
                                }
                            } icon: {
                                Image(systemName: "square.stack.3d.up.slash")
                            }
                        }
                        
                        Button(role: .destructive) {
                            SpotlightIndexer.deleteIndex()
                        } label: {
                            Label("account.delete.spotlight", systemImage: "minus.magnifyingglass")
                        }
                    }
                    .foregroundStyle(.red)
                } footer: {
                    Text("account.delete.footer")
                }
                
                Group {
                    Section {
                        Button {
                            serverInfoToggled.toggle()
                        } label: {
                            /*
                            Text(serverInfoToggled
                                 ? AudiobookshelfClient.shared.clientID
                                 : String(localized: "account.connection \(AudiobookshelfClient.shared.serverURL.absoluteString) \(serverVersion ?? "?")"))
                            .animation(.smooth, value: serverInfoToggled)
                            .fontDesign(.monospaced)
                             */
                        }
                        .buttonStyle(.plain)
                        
                        // Text("account.version \(AudiobookshelfClient.shared.clientVersion) \(AudiobookshelfClient.shared.clientBuild)")
                        // Text("account.version.database \(PersistenceManager.shared.modelContainer.schema.version.description) \(PersistenceManager.shared.modelContainer.configurations.map { $0.name }.joined(separator: ", "))")
                        
                        /*
                        if let lastSpotlightIndex {
                            Text("account.spotlight.lastIndex \(lastSpotlightIndex.formatted(date: .abbreviated, time: .shortened))")
                        } else {
                            Text("account.spotlight.pending")
                        }
                         */
                    }
                }
                .font(.caption)
                .foregroundStyle(.secondary)
            }
            .navigationTitle("account.title")
            .navigationBarTitleDisplayMode(.inline)
            .task {
                await update()
            }
        }
    }
    
    private nonisolated func update() async {
        await withTaskGroup(of: Void.self) {
            $0.addTask {
                /*
                guard let username = try? await AudiobookshelfClient.shared.me().1 else {
                    return
                }
                
                await MainActor.withAnimation {
                    self.username = username
                }
                 */
            }
            $0.addTask {
                /*
                guard let serverVersion = try? await AudiobookshelfClient.shared.status().serverVersion else {
                    return
                }
                
                await MainActor.withAnimation {
                    self.serverVersion = serverVersion
                }
                 */
            }
            $0.addTask {
                /*
                guard let size = try? (ImagePipeline.shared.configuration.dataCache as? DataCache)?.path.directoryTotalAllocatedSize() else {
                    return
                }
                
                await MainActor.withAnimation {
                    self.cacheSize = size
                }
                 */
            }
            $0.addTask {
                /*
                guard let size = try? DownloadManager.shared.documentsURL.directoryTotalAllocatedSize() else {
                    return
                }
                
                await MainActor.withAnimation {
                    self.downloadsSize = size
                }
                 */
            }
        }
    }
}

internal struct AccountSheetToolbarModifier: ViewModifier {
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    
    @State private var accountSheetPresented = false
    
    let requiredSize: UserInterfaceSizeClass?
    
    func body(content: Content) -> some View {
        if requiredSize == nil || horizontalSizeClass == requiredSize {
            content
                .sheet(isPresented: $accountSheetPresented) {
                    AccountSheet()
                }
                .toolbar {
                    ToolbarItem(placement: .topBarTrailing) {
                        Button {
                            accountSheetPresented.toggle()
                        } label: {
                            Label("account", systemImage: "person.crop.circle")
                                .labelStyle(.iconOnly)
                        }
                    }
                }
        } else {
            content
        }
    }
}

#Preview {
    Text(verbatim: ":)")
        .sheet(isPresented: .constant(true)) {
            AccountSheet()
        }
}

#Preview {
    NavigationStack {
        Text(verbatim: ":)")
            .modifier(AccountSheetToolbarModifier(requiredSize: nil))
    }
}
