//
//  AccountSheet.swift
//  Audiobooks
//
//  Created by Rasmus Krämer on 16.10.23.
//

import SwiftUI
import Defaults
import Nuke
import SPBase
import SPOffline
import SPOfflineExtended

struct AccountSheet: View {
    @Default(.customSleepTimer) private var customSleepTimer
    
    @State private var username: String?
    @State private var downloadStatus: OfflineManager.DownloadStatus?
    
    @State private var notificationPermission: UNAuthorizationStatus = .notDetermined
    
    var body: some View {
        NavigationStack {
            List {
                Section {
                    if let username = username {
                        Text(username)
                    } else {
                        ProgressView()
                            .task {
                                username = try? await AudiobookshelfClient.shared.username()
                            }
                    }
                    Button(role: .destructive) {
                        OfflineManager.shared.deleteProgressEntities()
                        AudiobookshelfClient.shared.logout()
                    } label: {
                        Text("account.logout")
                    }
                } header: {
                    Text("account.user")
                } footer: {
                    Text("account.logout.disclaimer")
                }
                
                Section {
                    Button {
                        UIApplication.shared.open(URL(string: UIApplication.openSettingsURLString)!)
                    } label: {
                        Text("account.settings")
                    }
                    
                    Button {
                        Task {
                            try? await BackgroundTaskHandler.runAutoDownload()
                        }
                    } label: {
                        Text("account.newEpisodes.check")
                    }
                    
                    switch notificationPermission {
                        case .notDetermined:
                            Button {
                                Task {
                                    try await UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .badge])
                                    notificationPermission = await UNUserNotificationCenter.current().notificationSettings().authorizationStatus
                                }
                            } label: {
                                Text("account.notifications.request")
                            }
                            .task {
                                notificationPermission = await UNUserNotificationCenter.current().notificationSettings().authorizationStatus
                            }
                        case .denied:
                            Text("account.notifications.denied")
                                .foregroundStyle(.red)
                        case .authorized:
                            Text("account.notifications.granted")
                                .foregroundStyle(.secondary)
                        default:
                            Text("account.notifications.unknown")
                                .foregroundStyle(.red)
                    }
                } footer: {
                    Text("account.notifications.footer")
                }
                
                Section {
                    Button(role: .destructive) {
                        OfflineManager.shared.deleteDownloads()
                    } label: {
                        Text("account.delete.downloads")
                    }
                    
                    Button(role: .destructive) {
                        ImagePipeline.shared.cache.removeAll()
                        OfflineManager.shared.deleteProgressEntities()
                        
                        NotificationCenter.default.post(name: Library.libraryChangedNotification, object: nil, userInfo: [
                            "offline": false,
                        ])
                    } label: {
                        Text("account.delete.cache")
                    }
                }
                
                Section("account.downloads") {
                    if let downloadStatus = downloadStatus, !(downloadStatus.0.isEmpty && downloadStatus.1.isEmpty) {
                        ForEach(Array(downloadStatus.0.keys).sorted { $0.name.localizedStandardCompare($1.name) == .orderedDescending }) { audiobook in
                            HStack {
                                ItemImage(image: audiobook.image)
                                    .frame(width: 55)
                                
                                VStack(alignment: .leading) {
                                    Text(audiobook.name)
                                        .fontDesign(.serif)
                                    if let author = audiobook.author {
                                        Text(author)
                                            .font(.subheadline)
                                            .foregroundStyle(.secondary)
                                    }
                                }
                                .lineLimit(1)
                                
                                Spacer()
                                
                                if let status = downloadStatus.0[audiobook] {
                                    if status.0 == 0 && status.1 == 1 {
                                        ProgressView()
                                    } else {
                                        Text(verbatim: "\(status.0)/\(status.1)")
                                            .fontDesign(.rounded)
                                            .foregroundStyle(.secondary)
                                    }
                                }
                            }
                            .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                                Button(role: .destructive) {
                                    OfflineManager.shared.delete(audiobookId: audiobook.id)
                                } label: {
                                    Image(systemName: "trash.fill")
                                }
                            }
                        }
                        
                        ForEach(Array(downloadStatus.1.keys).sorted { $0.name.localizedStandardCompare($1.name) == .orderedDescending }) { podcast in
                            HStack {
                                ItemImage(image: podcast.image)
                                    .frame(width: 55)
                                
                                VStack(alignment: .leading) {
                                    Text(podcast.name)
                                    
                                    if let author = podcast.author {
                                        Text(author)
                                            .font(.subheadline)
                                            .foregroundStyle(.secondary)
                                    }
                                }
                                .lineLimit(1)
                                
                                Spacer()
                                
                                if let status = downloadStatus.1[podcast] {
                                    Text(verbatim: "\(status.0)/\(status.1)")
                                        .fontDesign(.rounded)
                                        .foregroundStyle(.secondary)
                                }
                            }
                            .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                                Button(role: .destructive) {
                                    try! OfflineManager.shared.delete(podcastId: podcast.id)
                                } label: {
                                    Image(systemName: "trash.fill")
                                }
                            }
                        }
                    } else {
                        Text("accounts.downloads.empty")
                            .foregroundStyle(.secondary)
                    }
                }
                .task {
                    downloadStatus = try? await OfflineManager.shared.getDownloadStatus()
                }
                .onReceive(NotificationCenter.default.publisher(for: PlayableItem.downloadStatusUpdatedNotification)) { _ in
                    Task.detached { @MainActor in
                        downloadStatus = try? await OfflineManager.shared.getDownloadStatus()
                    }
                }
                
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
                    Text("account.sleepTimer")
                } footer: {
                    Text("account.sleepTimer.text")
                }
                
                Section {
                    NavigationLink(destination: CustomHeaderEditView()) {
                        Label("login.customHTTPHeaders", systemImage: "network.badge.shield.half.filled")
                    }
                    .foregroundStyle(.secondary)
                }
                
                Section {
                    Button {
                        UIApplication.shared.open(URL(string: "https://github.com/rasmuslos/ShelfPlayer")!)
                    } label: {
                        Text("account.github")
                    }
                    
                    Button {
                        UIApplication.shared.open(URL(string: "https://rfk.io/support.htm")!)
                    } label: {
                        Text("account.support")
                    }
                }
                
                Group {
                    Section("account.server") {
                        Text(AudiobookshelfClient.shared.token)
                        Text(AudiobookshelfClient.shared.serverUrl.absoluteString)
                    }
                    
                    Section {
                        Text("account.version \(AudiobookshelfClient.shared.clientVersion) (\(AudiobookshelfClient.shared.clientBuild))")
                    }
                }
                .font(.caption)
                .foregroundStyle(.secondary)
                
                #if !ENABLE_ALL_FEATURES
                Section {
                    HStack {
                        Spacer()
                        Text("developedBy")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        Spacer()
                    }
                }
                .listRowBackground(Color.clear)
                #endif
            }
            .navigationTitle("account.manage")
        }
    }
}

struct AccountSheetToolbarModifier: ViewModifier {
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    
    @State private var accountSheetPresented = false
    
    let requiredSize: UserInterfaceSizeClass?
    
    func body(content: Content) -> some View {
        content
            .sheet(isPresented: $accountSheetPresented) {
                AccountSheet()
            }
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        accountSheetPresented.toggle()
                    } label: {
                        Image(systemName: "person.crop.circle")
                    }
                }
            }
    }
}

#Preview {
    Text(":)")
        .sheet(isPresented: .constant(true)) {
            AccountSheet()
        }
}

#Preview {
    NavigationStack {
        Text(":)")
            .modifier(AccountSheetToolbarModifier(requiredSize: nil))
    }
}
