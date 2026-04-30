//
//  DownloadButton.swift
//  ShelfPlayer
//
//  Created by Rasmus Krämer on 02.02.24.
//

import SwiftUI
import Combine
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

    var body: some View {
        Group {
            if viewModel.isVisible {
                content
                    .disabled(viewModel.status == nil || satellite.isLoading(observing: viewModel.itemID))
                    .animation(.smooth, value: viewModel.current)
            }
        }
        .task {
            viewModel.loadCurrent()
            viewModel.loadCanDownload()
        }
    }

    @ViewBuilder
    private var content: some View {
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
            .accessibilityLabel(Text(viewModel.label))
        }
    }
}

@MainActor @Observable
final class DownloadButtonViewModel {
    private var observerSubscriptions = Set<AnyCancellable>()
    private var scenePhaseSubscription: AnyCancellable?

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

    var canDownload: Bool? = nil

    var isVisible: Bool {
        if status == .completed || status == .downloading {
            return true
        }

        return canDownload == true
    }

    init(itemID: ItemIdentifier, tint: Bool, progressVisibility: PresentationContext, isPercentageTextVisible: Bool, initialStatus: DownloadStatus?) {
        self.itemID = itemID

        self.tint = tint
        self.progressVisibility = progressVisibility
        self.isPercentageTextVisible = isPercentageTextVisible

        status = initialStatus

        setupObservers()
        loadCanDownload()

        scenePhaseSubscription = AppEventSource.shared.scenePhaseDidChange
            .sink { [weak self] isActive in
                Task { @MainActor [weak self] in
                    guard let self else {
                        return
                    }

                    if isActive {
                        self.setupObservers()
                        self.loadCurrent()
                    } else {
                        self.observerSubscriptions.removeAll(keepingCapacity: true)
                    }
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
            return "questionmark"
        }

        switch status {
            case .none:
                return "arrow.down"
            case .downloading:
                return "slash.circle"
            case .completed:
                return "trash"
        }
    }

    func loadCurrent() {
        Task {
            let status = await PersistenceManager.shared.download.status(of: itemID)

            withAnimation {
                self.status = status
            }
        }
    }
    func loadProgress() {
        Task {
            let progress = await PersistenceManager.shared.download.downloadProgress(of: itemID)

            withAnimation {
                self.baseProgress = progress
            }
        }
    }
    func loadCanDownload() {
        Task {
            let resolved = await PersistenceManager.shared.authorization.canDownload(for: itemID.connectionID)

            guard resolved != canDownload else {
                return
            }

            withAnimation {
                self.canDownload = resolved
            }
        }
    }

    private func setupObservers() {
        observerSubscriptions.removeAll(keepingCapacity: true)

        PersistenceManager.shared.download.events.progressChanged
            .sink { [weak self] eventItemID, assetID, weight, bytesWritten, totalBytesWritten, totalBytesExpectedToWrite in
                Task { @MainActor [weak self] in
                    guard let self, progressVisibility != .never, self.itemID == eventItemID else {
                        return
                    }

                    metadata[assetID] = (weight, totalBytesExpectedToWrite)

                    if progress[assetID] == nil {
                        progress[assetID] = totalBytesWritten
                    } else {
                        progress[assetID]! += bytesWritten
                    }
                }
            }
            .store(in: &observerSubscriptions)

        PersistenceManager.shared.download.events.statusChanged
            .sink { [weak self] payload in
                Task { @MainActor [weak self] in
                    guard let self else {
                        return
                    }

                    guard let (itemID, status) = payload, self.itemID == itemID else {
                        self.loadCurrent()
                        return
                    }

                    self.status = status
                }
            }
            .store(in: &observerSubscriptions)

        PersistenceManager.shared.authorization.events.permissionsChanged
            .sink { [weak self] connectionID in
                Task { @MainActor [weak self] in
                    guard let self, self.itemID.connectionID == connectionID else {
                        return
                    }

                    self.loadCanDownload()
                }
            }
            .store(in: &observerSubscriptions)
    }

    enum PresentationContext {
        case never
        case toolbar
        case triangle
        case episode
        case row
    }
}
