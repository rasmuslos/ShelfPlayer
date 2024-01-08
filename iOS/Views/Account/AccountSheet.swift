//
//  AccountSheet.swift
//  Audiobooks
//
//  Created by Rasmus Krämer on 16.10.23.
//

import SwiftUI
import ShelfPlayerKit

struct AccountSheet: View {
    @State var username: String?
    
    @State var downloadingAudiobooks: [Audiobook: (Int, Int)]?
    @State var downloadingPodcasts: [Podcast: (Int, Int)]?
    
    var body: some View {
        List {
            Section {
                if let username = username {
                    Text(username)
                } else {
                    ProgressView()
                        .onAppear {
                            Task.detached {
                                username = try? await AudiobookshelfClient.shared.getUsername()
                            }
                        }
                }
                Button(role: .destructive) {
                    OfflineManager.shared.deleteStoredProgress()
                    AudiobookshelfClient.shared.logout()
                } label: {
                    Text("account.logout")
                }
            } header: {
                Text("account.user")
            } footer: {
                Text("account.logout.disclaimer")
            }
            
            Section("account.downloads") {
                if let downloadingAudiobooks = downloadingAudiobooks, !downloadingAudiobooks.isEmpty {
                    ForEach(Array(downloadingAudiobooks.keys).sorted { $0.name < $1.name }) { audiobook in
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
                            
                            Spacer()
                            
                            if let downloadStatus = downloadingAudiobooks[audiobook] {
                                if downloadStatus.0 == 0 && downloadStatus.1 == 1 {
                                    ProgressView()
                                } else {
                                    Text(verbatim: "\(downloadStatus.0)/\(downloadStatus.1)")
                                        .fontDesign(.rounded)
                                        .foregroundStyle(.secondary)
                                }
                            }
                        }
                        .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                            Button(role: .destructive) {
                                try! OfflineManager.shared.delete(audiobookId: audiobook.id)
                            } label: {
                                Image(systemName: "trash.fill")
                            }
                        }
                    }
                }
                
                if let downloadingPodcasts = downloadingPodcasts, !downloadingPodcasts.isEmpty {
                    ForEach(Array(downloadingPodcasts.keys).sorted { $0.name < $1.name }) { podcast in
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
                            
                            Spacer()
                            
                            if let downloadStatus = downloadingPodcasts[podcast] {
                                Text(verbatim: "\(downloadStatus.0)/\(downloadStatus.1)")
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
                }
            }
            .onReceive(NotificationCenter.default.publisher(for: PlayableItem.downloadStatusUpdatedNotification)) { _ in
                downloadingAudiobooks = try? OfflineManager.shared.getAudiobookDownloadData()
                downloadingPodcasts = try? OfflineManager.shared.getPodcastDownloadData()
            }
            .task {
                downloadingAudiobooks = try? OfflineManager.shared.getAudiobookDownloadData()
                downloadingPodcasts = try? OfflineManager.shared.getPodcastDownloadData()
            }
            
            Section {
                Button {
                    UIApplication.shared.open(URL(string: UIApplication.openSettingsURLString)!)
                } label: {
                    Text("account.settings")
                }
                
                Button(role: .destructive) {
                    OfflineManager.shared.deleteStoredProgress()
                    NotificationCenter.default.post(name: Library.libraryChangedNotification, object: nil, userInfo: [
                        "offline": false,
                    ])
                } label: {
                    Text("account.delete.cache")
                }
                Button(role: .destructive) {
                    OfflineManager.shared.deleteAllDownloads()
                } label: {
                    Text("account.delete.downloads")
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
            
            #if DEBUG
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
    }
}

struct AccountSheetToolbarModifier: ViewModifier {
    @State var accountSheetPresented = false
    
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
                        Image(systemName: "server.rack")
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
            .modifier(AccountSheetToolbarModifier())
    }
}
