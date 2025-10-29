//
//  DownloadButton.swift
//  iOS
//
//  Created by Rasmus Krämer on 02.02.24.
//

import SwiftUI
import OSLog
import ShelfPlayback

struct DownloadButton: View {
    fileprivate static let logger = Logger(subsystem: "io.rfk.shelfPlayer", category: "DownloadButton")
    
    @Environment(Satellite.self) private var satellite
    
    @State private var viewModel: DownloadButtonViewModel
    
    init(itemID: ItemIdentifier, tint: Bool = false, progressVisibility: DownloadButtonViewModel.PresentationContext = .never, isPercentageTextVisible: Bool = false, initialStatus: DownloadStatus? = nil) {
        _viewModel = .init(initialValue: .init(itemID: itemID, tint: tint, progressVisibility: progressVisibility, isPercentageTextVisible: isPercentageTextVisible, initialStatus: initialStatus))
    }
    
    private var isLoading: Bool {
        if satellite.isLoading(observing: viewModel.itemID) {
            return true
        }
        
        guard let status = viewModel.status else {
            return true
        }
        
        if status == .downloading {
            return viewModel.baseProgress == nil
        }
        
        return false
    }
    
    @ViewBuilder
    private func circularProgressIndicator(current: Double) -> some View {
        CircularProgressIndicator(completed: current, background: viewModel.progressBackgroundColor, tint: viewModel.progressTintColor)
    }
    
    var body: some View {
        ZStack {
            if isLoading && viewModel.progressVisibility != .never {
                ProgressView()
            } else if let text = viewModel.text {
                Text(text, format: .percent.notation(.compactName))
                    .contentTransition(.numericText())
            } else {
                Button {
                    if viewModel.status == DownloadStatus.none {
                        satellite.download(itemID: viewModel.itemID)
                    } else {
                        satellite.removeDownload(itemID: viewModel.itemID, force: false)
                    }
                } label: {
                    if let current = viewModel.current {
                        CircularProgressIndicator(completed: current, background: viewModel.progressBackgroundColor, tint: viewModel.progressTintColor)
                            .modify {
                                switch viewModel.progressVisibility {
                                    case .never:
                                        EmptyView()
                                    case .toolbar:
                                        $0
                                            .frame(width: 18)
                                            .overlay {
                                                RoundedRectangle(cornerRadius: 1)
                                                    .aspectRatio(1, contentMode: .fit)
                                                    .frame(width: 6)
                                            }
                                    case .triangle:
                                        $0
                                    case .episode:
                                        $0
                                            .frame(width: 8)
                                    case .row:
                                        $0
                                            .frame(width: 14)
                                            .overlay {
                                                RoundedRectangle(cornerRadius: 1)
                                                    .aspectRatio(1, contentMode: .fit)
                                                    .frame(width: 5)
                                            }
                                            .foregroundStyle(Color.accentColor)
                                }
                            }
                    } else {
                        Label(viewModel.label, systemImage: viewModel.icon)
                            .modify(if: viewModel.tint) {
                                $0
                                    .tint(viewModel.status == .completed ? .red : .blue)
                            }
                    }
                }
            }
        }
        .disabled(viewModel.status == nil || satellite.isLoading(observing: viewModel.itemID))
        .animation(.smooth, value: viewModel.current)
        .task {
            viewModel.loadCurrent()
        }
    }
}

@MainActor @Observable
final class DownloadButtonViewModel {
    let itemID: ItemIdentifier
    
    let tint: Bool
    let progressVisibility: PresentationContext
    let isPercentageTextVisible: Bool
    
    var baseProgress: Percentage? = nil
    var status: DownloadStatus? {
        didSet {
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
    }
    
    var progress = [UUID: Int64]()
    var metadata = [UUID: (Percentage, Int64)]()
    
    var stash = RFNotification.MarkerStash()
    
    init(itemID: ItemIdentifier, tint: Bool, progressVisibility: PresentationContext, isPercentageTextVisible: Bool, initialStatus: DownloadStatus?) {
        self.itemID = itemID
        
        self.tint = tint
        self.progressVisibility = progressVisibility
        self.isPercentageTextVisible = isPercentageTextVisible
        
        status = initialStatus
        
        setupObservers()
        
        RFNotification[.scenePhaseDidChange].subscribe { [weak self] in
            if $0 {
                self?.setupObservers()
                self?.loadCurrent()
            } else {
                self?.stash.clear()
            }
        }
    }
    
    var progressBackgroundColor: Color {
        if progressVisibility == .triangle {
            .white.opacity(0.3)
        } else {
            .gray.opacity(0.5)
        }
    }
    var progressTintColor: Color {
        if progressVisibility == .triangle {
            .white
        } else {
            .accentColor
        }
    }
    
    var current: Percentage? {
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
    var text: Percentage? {
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
    
    var label: LocalizedStringKey {
        guard let status else {
            return "item.download.resolving"
        }
        
        switch status {
            case .none:
                return "item.download"
            case .downloading:
                return "item.download.abort"
            case .completed:
                return "item.download.remove"
        }
    }
    var icon: String {
        guard let status else {
            return "questionmark.circle.dashed"
        }
        
        switch status {
            case .none:
                return "arrow.down.circle"
            case .downloading:
                return "slash.circle"
            case .completed:
                return "trash.circle"
        }
    }
    
    nonisolated func loadCurrent() {
        Task {
            let status = await PersistenceManager.shared.download.status(of: itemID)
            
            await MainActor.withAnimation {
                self.status = status
            }
        }
    }
    nonisolated func loadProgress() {
        Task {
            let progress = await PersistenceManager.shared.download.downloadProgress(of: itemID)
            
            await MainActor.withAnimation {
                self.baseProgress = progress
            }
        }
    }
    
    private func setupObservers() {
        stash.clear()
        
        RFNotification[.downloadProgressChanged(itemID)].subscribe { [weak self] (assetID, weight, bytesWritten, totalBytesWritten, totalBytesExpectedToWrite) in
            guard let self, progressVisibility != .never else {
                return
            }
            
            metadata[assetID] = (weight, totalBytesExpectedToWrite)
            
            if progress[assetID] == nil {
                progress[assetID] = totalBytesWritten
            } else {
                progress[assetID]! += bytesWritten
            }
        }.store(in: &stash)
        
        RFNotification[.downloadStatusChanged].subscribe { [weak self] in
            guard let self else {
                return
            }
            
            guard let (itemID, status) = $0, self.itemID == itemID else {
                loadCurrent()
                return
            }
            
            self.status = status
        }.store(in: &stash)
    }
    
    enum PresentationContext {
        case never
        case toolbar
        case triangle
        case episode
        case row
    }
}

#if DEBUG
#Preview {
    DownloadButton(itemID: .fixture, tint: false, progressVisibility: .toolbar)
        .previewEnvironment()
}
#Preview {
    DownloadButton(itemID: .fixture, progressVisibility: .row)
        .previewEnvironment()
}
#Preview {
    DownloadButton(itemID: .fixture, tint: true)
        .previewEnvironment()
}
#Preview {
    NavigationStack {
        Text(verbatim: ":/")
            .toolbar {
                DownloadButton(itemID: .fixture, tint: true)
            }
    }
    .previewEnvironment()
}
#endif
