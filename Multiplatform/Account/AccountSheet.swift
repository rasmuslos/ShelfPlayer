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

struct AccountSheet: View {
    @Default(.customSleepTimer) private var customSleepTimer
    @Default(.customPlaybackSpeed) private var customPlaybackSpeed
    @Default(.defaultPlaybackSpeed) private var defaultPlaybackSpeed
    
    @State private var username: String?
    @State private var serverVersion: String?
    
    @State private var navigationPath = NavigationPath()
    @State private var notificationPermission: UNAuthorizationStatus = .notDetermined
    
    private var playbackSpeedText: String {
        let formatter = NumberFormatter()
        formatter.minimumFractionDigits = 2
        formatter.maximumFractionDigits = 2
        formatter.decimalSeparator = "."
        
        return formatter.string(from: NSNumber(value: customPlaybackSpeed))!
    }
    
    var body: some View {
        NavigationStack(path: $navigationPath) {
            List {
                Section {
                    if let username = username {
                        Text(username)
                    } else {
                        ProgressIndicator()
                    }
                    
                    Button(role: .destructive) {
                        try? OfflineManager.shared.deleteProgressEntities()
                        AudiobookshelfClient.shared.store(token: nil)
                    } label: {
                        Label("account.logout", systemImage: "person.crop.circle.badge.minus")
                            .foregroundStyle(.red)
                    }
                } header: {
                    Text("account.user")
                } footer: {
                    Text("account.logout.disclaimer")
                }
                
                Section {
                    Group {
                        Button {
                            UIApplication.shared.open(URL(string: UIApplication.openSettingsURLString)!)
                        } label: {
                            Label("account.settings", systemImage: "gear")
                        }
                        
                        switch notificationPermission {
                            case .notDetermined:
                                Button {
                                    Task {
                                        try await UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .badge])
                                        notificationPermission = await UNUserNotificationCenter.current().notificationSettings().authorizationStatus
                                    }
                                } label: {
                                    Label("account.notifications.request", systemImage: "bell.badge.waveform.fill")
                                }
                                .task {
                                    notificationPermission = await UNUserNotificationCenter.current().notificationSettings().authorizationStatus
                                }
                            case .denied:
                                Label("account.notifications.denied", systemImage: "bell.slash.fill")
                                    .foregroundStyle(.red)
                            case .authorized:
                                Label("account.notifications.granted", systemImage: "bell.badge.fill")
                                    .foregroundStyle(.secondary)
                            default:
                                Label("account.notifications.unknown", systemImage: "bell.and.waves.left.and.right.fill")
                                    .foregroundStyle(.red)
                        }
                        
                        Button {
                            Task {
                                try? await BackgroundTaskHandler.updateDownloads()
                            }
                        } label: {
                            Label("account.newEpisodes.check", systemImage: "antenna.radiowaves.left.and.right")
                        }
                    }
                    .foregroundStyle(.primary)
                } footer: {
                    Text("account.notifications.footer")
                }
                
                Section("account.defaults") {
                    Picker("account.defaultPlaybackSpeed", selection: $defaultPlaybackSpeed) {
                        PlaybackSpeedButton.Options(selected: $defaultPlaybackSpeed)
                    }
                    .tint(.primary)
                }
                
                Section {
                    Stepper("account.playbackSpeed \(playbackSpeedText)", value: $customPlaybackSpeed, in: 0.25...4, step: 0.05)
                    
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
                    Text("account.sleepTimer.text")
                }
                
                Section {
                    TintPicker()
                    
                    NavigationLink(value: "") {
                        Label("login.customHTTPHeaders", systemImage: "network.badge.shield.half.filled")
                    }
                }
                .foregroundStyle(.primary)
                
                Section {
                    Group {
                        Button(role: .destructive) {
                            OfflineManager.shared.removeAllDownloads()
                        } label: {
                            Label("account.delete.downloads", systemImage: "slash.circle")
                        }
                        
                        Button(role: .destructive) {
                            ImagePipeline.shared.cache.removeAll()
                            try? OfflineManager.shared.deleteProgressEntities()
                            
                            NotificationCenter.default.post(name: Library.changeLibraryNotification, object: nil, userInfo: [
                                "offline": false,
                            ])
                        } label: {
                            Label("account.delete.cache", systemImage: "square.stack.3d.up.slash")
                        }
                    }
                    .foregroundStyle(.red)
                } footer: {
                    Text("account.delete.footer")
                }
                
                Section {
                    Button {
                        UIApplication.shared.open(URL(string: "https://github.com/rasmuslos/ShelfPlayer")!)
                    } label: {
                        Label("account.github", systemImage: "chevron.left.forwardslash.chevron.right")
                    }
                    
                    Button {
                        UIApplication.shared.open(URL(string: "https://rfk.io/support.htm")!)
                    } label: {
                        Label("account.support", systemImage: "lifepreserver")
                    }
                }
                .foregroundStyle(.primary)
                
                Group {
                    Section("account.server") {
                        Group {
                            Text("account.server \(AudiobookshelfClient.shared.serverUrl.absoluteString) \(serverVersion ?? "?")")
                            Text(AudiobookshelfClient.shared.clientId)
                        }
                        .fontDesign(.monospaced)
                    }
                    
                    Section {
                        Text("account.version \(AudiobookshelfClient.shared.clientVersion) \(AudiobookshelfClient.shared.clientBuild)")
                        Text("account.version.database \(PersistenceManager.shared.modelContainer.schema.version.description) \(PersistenceManager.shared.modelContainer.configurations.map { $0.name }.joined(separator: ", "))")
                    }
                }
                .font(.caption)
                .foregroundStyle(.secondary)
            }
            .navigationTitle("account.manage")
            .navigationBarTitleDisplayMode(.inline)
            .navigationDestination(for: String.self) { _ in
                CustomHeaderEditView(backButtonVisible: false) {
                    navigationPath.removeLast()
                }
            }
            .task {
                username = try? await AudiobookshelfClient.shared.me().1
                serverVersion = try? await AudiobookshelfClient.shared.status().serverVersion
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
