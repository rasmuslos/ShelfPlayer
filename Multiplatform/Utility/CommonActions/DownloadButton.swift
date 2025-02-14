//
//  DownloadButton.swift
//  iOS
//
//  Created by Rasmus Krämer on 02.02.24.
//

import SwiftUI
import RFNotifications
import ShelfPlayerKit

struct DownloadButton: View {
    let item: PlayableItem
    let tint: Bool
    
    @State private var isWorking = false
    
    @State private var progress: Percentage? = nil
    @State private var status: PersistenceManager.DownloadSubsystem.DownloadStatus? = nil
    
    @State private var notifyError = false
    @State private var notifySuccess = false
    
    private var isLoading: Bool {
        if isWorking {
            return true
        }
        
        guard let status else {
            return true
        }
        
        if status == .downloading {
            return progress == nil
        }
        
        return false
    }
    
    private var label: LocalizedStringKey {
        guard let status else {
            return "download.loading"
        }
        
        switch status {
        case .none:
            return "download"
        case .downloading:
            return "download.working"
        case .completed:
            return "download.remove"
        }
    }
    private var icon: String {
        guard let status else {
            return "command"
        }
        
        switch status {
        case .none:
            return "arrow.down.circle"
        case .downloading:
            return "command"
        case .completed:
            return "xmark.circle"
        }
    }
    
    var body: some View {
        Group {
            if isLoading {
                ProgressIndicator()
            } else {
                Button {
                    if status == .completed {
                        remove()
                    } else if status == PersistenceManager.DownloadSubsystem.DownloadStatus.none {
                        download()
                    }
                } label: {
                    Label(label, systemImage: icon)
                        .modify {
                            if tint {
                                $0
                                    .tint(status == .completed ? .red : .blue)
                            } else {
                                $0
                            }
                        }
                }
            }
        }
        .sensoryFeedback(.error, trigger: notifyError)
        .sensoryFeedback(.success, trigger: notifySuccess)
        .task {
            loadCurrent()
        }
        .onReceive(RFNotification[.downloadStatusChanged].publisher()) { (itemID, status) in
            guard item.id == itemID else {
                return
            }
            
            self.status = status
            if status != .downloading {
                progress = nil
            }
        }
    }
}

private extension DownloadButton {
    nonisolated func loadCurrent() {
        Task {
            let status = await PersistenceManager.shared.download.status(of: item.id)
            
            await MainActor.withAnimation {
                self.status = status
                
                if status != .downloading {
                    progress = nil
                }
            }
        }
    }
    
    nonisolated func download() {
        Task {
            guard !(await isWorking), let status = await status, status == .none else {
                return
            }
            
            await MainActor.withAnimation {
                isWorking = true
            }
            
            do {
                try await PersistenceManager.shared.download.download(item.id)
                
                await MainActor.withAnimation {
                    isWorking = false
                    notifySuccess.toggle()
                }
            } catch {
                await MainActor.withAnimation {
                    isWorking = false
                    notifyError.toggle()
                }
            }
        }
    }
    
    nonisolated func remove() {
        Task {
            guard !(await isWorking), let status = await status, status == .completed else {
                return
            }
            
            await MainActor.withAnimation {
                isWorking = true
            }
            
            do {
                try await PersistenceManager.shared.download.remove(item.id)
                
                await MainActor.withAnimation {
                    isWorking = false
                    notifySuccess.toggle()
                }
            } catch {
                await MainActor.withAnimation {
                    isWorking = false
                    notifyError.toggle()
                }
            }
        }
    }
}

#if DEBUG
#Preview {
    DownloadButton(item: Audiobook.fixture, tint: false)
}
#Preview {
    DownloadButton(item: Audiobook.fixture, tint: true)
}
#endif
