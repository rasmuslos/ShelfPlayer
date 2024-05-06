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
    @State private var notificationPermission: UNAuthorizationStatus = .notDetermined
    
    var body: some View {
        NavigationStack {
            List {
                Section {
                    if let username = username {
                        Text(username)
                    } else {
                        ProgressIndicator()
                            .task {
                                username = try? await AudiobookshelfClient.shared.username()
                            }
                    }
                    
                    Button(role: .destructive) {
                        OfflineManager.shared.deleteProgressEntities()
                        AudiobookshelfClient.shared.logout()
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
                                Text("account.notifications.denied")
                                    .foregroundStyle(.red)
                            case .authorized:
                                Text("account.notifications.granted")
                                    .foregroundStyle(.secondary)
                            default:
                                Text("account.notifications.unknown")
                                    .foregroundStyle(.red)
                        }
                        
                        Button {
                            Task {
                                try? await BackgroundTaskHandler.runAutoDownload()
                            }
                        } label: {
                            Label("account.newEpisodes.check", systemImage: "antenna.radiowaves.left.and.right")
                        }
                    }
                    .foregroundStyle(.primary)
                } footer: {
                    Text("account.notifications.footer")
                }
                
                Downloads()
                
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
                    TintMenu()
                        .menuStyle(.borderlessButton)
                    NavigationLink(destination: CustomHeaderEditView()) {
                        Label("login.customHTTPHeaders", systemImage: "network.badge.shield.half.filled")
                    }
                }
                .foregroundStyle(.primary)
                
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
                
                Section {
                    Group {
                        Button(role: .destructive) {
                            OfflineManager.shared.deleteDownloads()
                        } label: {
                            Label("account.delete.downloads", systemImage: "slash.circle")
                        }
                        
                        Button(role: .destructive) {
                            ImagePipeline.shared.cache.removeAll()
                            OfflineManager.shared.deleteProgressEntities()
                            
                            NotificationCenter.default.post(name: Library.libraryChangedNotification, object: nil, userInfo: [
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
                
                Group {
                    Section("account.server") {
                        Text(AudiobookshelfClient.shared.serverUrl.absoluteString)
                        Text(AudiobookshelfClient.shared.clientId)
                    }
                    .fontDesign(.monospaced)
                    
                    Section {
                        Text("account.version \(AudiobookshelfClient.shared.clientVersion) (\(AudiobookshelfClient.shared.clientBuild))")
                    }
                }
                .font(.caption)
                .foregroundStyle(.secondary)
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
