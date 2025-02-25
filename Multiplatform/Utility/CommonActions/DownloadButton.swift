//
//  DownloadButton.swift
//  iOS
//
//  Created by Rasmus Krämer on 02.02.24.
//

import SwiftUI
import ShelfPlayerKit

struct DownloadButton: View {
    let item: PlayableItem
    
    var tint = false
    var progressVisibility = ProgressVisibility.never
    var isPercentageTextVisible = false
    
    @State private var isWorking = false
    
    @State private var baseProgress: Percentage? = nil
    @State private var status: PersistenceManager.DownloadSubsystem.DownloadStatus? = nil
    
    @State private var progress = [UUID: Int64]()
    @State private var metadata = [UUID: (Percentage, Int64)]()
    
    @State private var notifyError = false
    @State private var notifySuccess = false
    
    private var current: Percentage? {
        guard let baseProgress else {
            return nil
        }
        
        let assetIDs = metadata.keys
        var result = baseProgress
        
        for assetID in assetIDs {
            guard let (weight, total) = metadata[assetID], let current = progress[assetID] else {
                continue
            }
            
            guard total > 0 else {
                result += weight
                continue
            }
            
            let partialProgress: Percentage = Percentage(current) / Percentage(total)
            result += partialProgress * weight
        }
        
        return result
    }
    private var text: Percentage? {
        guard isPercentageTextVisible else {
            return nil
        }
        
        if let current {
            return current
        }
        if status == .completed {
            return 1
        }
        
        return 0
    }
    
    private var label: LocalizedStringKey {
        guard let status else {
            return "download.loading"
        }
        
        switch status {
        case .none:
            return "download"
        case .downloading:
            return "download.cancel"
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
            return "slash.circle"
        case .completed:
            return "xmark.circle"
        }
    }
    
    private var progressBackgroundColor: Color {
        if progressVisibility == .triangle {
            .white.opacity(0.3)
        } else {
            .gray.opacity(0.5)
        }
    }
    private var progressTintColor: Color {
        if progressVisibility == .triangle {
            .white
        } else {
            .accentColor
        }
    }
    
    private var isLoading: Bool {
        if isWorking {
            return true
        }
        
        guard let status else {
            return true
        }
        
        if status == .downloading {
            return baseProgress == nil
        }
        
        return false
    }
    
    var body: some View {
        Group {
            if isLoading && progressVisibility != .never {
                ProgressIndicator()
            } else if let text {
                Text(text, format: .percent.notation(.compactName))
                    .contentTransition(.numericText())
            } else {
                Button {
                    if status == PersistenceManager.DownloadSubsystem.DownloadStatus.none {
                        download()
                    } else {
                        remove()
                    }
                } label: {
                    if let current {
                        CircularProgressIndicator(completed: current, background: progressBackgroundColor, tint: progressTintColor)
                            .modify {
                                switch progressVisibility {
                                case .never:
                                    EmptyView()
                                case .toolbar:
                                    $0
                                        .frame(width: 18)
                                case .triangle:
                                    $0
                                case .episode:
                                    $0
                                        .frame(width: 8)
                                }
                            }
                    } else {
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
        }
        .animation(.smooth, value: current)
        .sensoryFeedback(.error, trigger: notifyError)
        .sensoryFeedback(.success, trigger: notifySuccess)
        .task {
            loadCurrent()
        }
        .onChange(of: status) {
            guard status == .downloading else {
                baseProgress = nil
                
                progress = [:]
                metadata = [:]
                
                return
            }
            
            if progressVisibility != .never {
                loadProgress()
            }
        }
        .onReceive(RFNotification[.downloadProgressChanged(item.id)].publisher()) { (assetID, weight, bytesWritten, totalBytesWritten, totalBytesExpectedToWrite) in
            guard progressVisibility != .never else {
                return
            }
            
            metadata[assetID] = (weight, totalBytesExpectedToWrite)
            
            if progress[assetID] == nil {
                progress[assetID] = totalBytesWritten
            } else {
                progress[assetID]! += bytesWritten
            }
        }
        .onReceive(RFNotification[.downloadStatusChanged].publisher()) { (itemID, status) in
            guard item.id == itemID else {
                return
            }
            
            self.status = status
        }
    }
    
    enum ProgressVisibility {
        case never
        case toolbar
        case triangle
        case episode
    }
}

private extension DownloadButton {
    nonisolated func loadCurrent() {
        Task {
            let status = await PersistenceManager.shared.download.status(of: item.id)
            
            await MainActor.withAnimation {
                self.status = status
            }
        }
    }
    nonisolated func loadProgress() {
        Task {
            let progress = await PersistenceManager.shared.download.downloadProgress(of: item.id)
            
            await MainActor.withAnimation {
                self.baseProgress = progress
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
            guard !(await isWorking), let status = await status, status != .none else {
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
