import SwiftUI
import OSLog
import ShelfPlayback

@MainActor @Observable
final class TabRouterViewModel: Sendable {
    private let logger = Logger(subsystem: "io.rfk.shelfPlayer", category: "TabRouterViewModel")
    
    // MARK: TabValue
    var tabValue: TabValue? = nil {
        willSet {
            applyLibraryTitleFont(type: newValue?.libraryID?.type ?? .podcasts)
            
            if let library = newValue?.libraryID {
                selectedLibraryID = library
            }
        }
        didSet {
            if let tab = tabValue, tab.isEligibleForSaving {
                Defaults[.lastTabValue] = tab
            }
        }
    }
    private(set) var selectedLibraryID: LibraryIdentifier?
    
    // MARK: Customization
    private(set) var tabBar = [LibraryIdentifier: [TabValue]]()
    private(set) var sideBar = [LibraryIdentifier: [TabValue]]()
    
    private(set) var libraryLookup = [LibraryIdentifier: Library]()
    private(set) var connectionLibraries = [ItemIdentifier.ConnectionID: [Library]]()
    
    @ObservableDefault(.pinnedTabValues) @ObservationIgnored
    private(set) var pinnedTabValues: [TabValue]
    
    // MARK: Synchronise

    private(set) var currentConnectionStatus = [ItemIdentifier.ConnectionID: Bool]()
    private(set) var activeUpdateTasks = [ItemIdentifier.ConnectionID: Task<Void, Never>]()
    private(set) var initialSyncCompleted = [ItemIdentifier.ConnectionID: Bool]()

    private(set) var isLoadingLibraries = false
    
    // MARK: Helper
    
    var navigateToWhenReady: ItemIdentifier?
    
    init() {
        RFNotification[.invalidateTabs].subscribe { [weak self] in
            self?.tabBar.removeAll()
            self?.sideBar.removeAll()
            
            self?.libraryLookup.removeAll()
            self?.connectionLibraries.removeAll()
        }
        RFNotification[.enablePinnedTabs].subscribe { [weak self] in
            guard self?.pinnedTabsActive == false else {
                return
            }
            
            self?.toggleCompactPinned()
        }
    }
    
    func refresh() {
        Task {
            await loadLibraries()
        }
    }
    nonisolated func loadLibraries() async {
        var shouldContinue = true

        await MainActor.run {
            isLoadingLibraries = true
        }

        logger.info("Loading online UI")

        let allConnectionsAvailable = await withTaskGroup {
            for connectionID in await PersistenceManager.shared.authorization.connectionIDs {
                logger.info("Loading connection: \(connectionID)")

                $0.addTask {
                    do {
                        let libraries = try await ABSClient[connectionID].libraries()
                        var results = [Library: ([TabValue], [TabValue])]()

                        self.logger.info("Got libraries for connection: \(connectionID)")

                        for library in libraries {
                            let (tabBar, sideBar) = (
                                await PersistenceManager.shared.customization.configuredTabs(for: library.id, scope: .tabBar),
                                await PersistenceManager.shared.customization.configuredTabs(for: library.id, scope: .sidebar),
                            )

                            results[library] = (tabBar, sideBar)
                        }

                        await self.synchronize(connectionID: connectionID)
                        self.logger.info("Syncrhonized connection: \(connectionID)")

                        await self.didLoad(connectionID: connectionID, libraries: results)
                        return true
                    } catch {
                        self.logger.info("Failed to load libraries for connection: \(connectionID)")

                        await self.synchronizeFailed(connectionID: connectionID)
                        return false
                    }
                }
            }

            return await $0.reduce(true) { $0 && $1 }
        }

        if !allConnectionsAvailable {
            await OfflineMode.shared.setEnabled(true)
        }

        await MainActor.run {
            isLoadingLibraries = false
        }
    }
}

// MARK: Navigation

extension TabRouterViewModel {
    var pinnedTabsActive: Bool {
        if case .custom = tabValue {
            true
        } else {
            false
        }
    }
    
    var libraries: [Library] {
        Array(connectionLibraries.flatMap { $1 })
    }
    var library: Library? {
        if let id = selectedLibraryID {
            libraryLookup[id]
        } else {
            nil
        }
    }
    
    func selectCompact(libraryID: LibraryIdentifier) {
        guard libraryLookup.keys.contains(libraryID) else {
            logger.warning("Tried to select a library that doesn't exist: \(libraryID.id) \(libraryID.connectionID) \(libraryID.type.rawValue)")
            return
        }
        
        if case .search = tabValue {
            selectedLibraryID = libraryID
        } else {
            selectFirstCompactTab(for: libraryID, allowPinned: false)
        }
    }
    func selectFirstCompactTab(for library: LibraryIdentifier, allowPinned: Bool) {
        if allowPinned, let pinnedTabValue = pinnedTabValues.compactMap({ $0 }).first(where: { $0.libraryID == library }) {
            tabValue = pinnedTabValue
        } else {
            tabValue = tabBar.first { $0.key == library }?.value.first
        }
    }
    
    func toggleCompactPinned() {
        if pinnedTabsActive {
            enableFirstLibrary()
        } else {
            enableFirstPinnedTab()
        }
    }
    func enableFirstPinnedTab() {
        if let first = pinnedTabValues.first {
            tabValue = first
        } else {
            Satellite.shared.present(.customTabValuePreferences)
        }
    }
    func enableFirstLibrary() {
        guard let library = libraries.first else {
            logger.warning("Requested to enable first library, but there are no libraries")
            return
        }
        
        selectFirstCompactTab(for: library.id, allowPinned: false)
    }
    
    func selectLastOrFirstCompactLibrary() {
        guard !restoreLastTabValue() else {
            return
        }
        
        if let first = pinnedTabValues.first {
            tabValue = first
            return
        }
        
        guard let first = connectionLibraries.first(where: { !$1.isEmpty })?.value.first else {
            return
        }
        
        selectFirstCompactTab(for: first.id, allowPinned: true)
    }
    
    func navigate(to itemID: ItemIdentifier) {
        self.navigateToWhenReady = itemID
    }
}

private extension TabRouterViewModel {
    func restoreLastTabValue() -> Bool {
        if let navigateToWhenReady {
            selectFirstCompactTab(for: .convertItemIdentifierToLibraryIdentifier(navigateToWhenReady), allowPinned: true)
            return true
        }

        // Prioritize lastPlayedItemID (show the library where the pill item belongs)
        if let lastPlayedItemID = Defaults[.lastPlayedItemID] {
            let targetLibraryID = LibraryIdentifier.convertItemIdentifierToLibraryIdentifier(lastPlayedItemID)

            if libraries.contains(where: { $0.id == targetLibraryID }) {
                logger.info("Restoring library from lastPlayedItemID: \(targetLibraryID.connectionID)")

                // Check if lastTabValue exists and matches the same library - use the specific tab
                if let lastTabValue = Defaults[.lastTabValue],
                   lastTabValue.libraryID == targetLibraryID {
                    logger.info("Restoring specific tab within same library from lastTabValue")
                    tabValue = lastTabValue
                } else {
                    // Use first tab of the library where the played item belongs
                    logger.info("Selecting first tab of library where played item belongs")
                    selectFirstCompactTab(for: targetLibraryID, allowPinned: true)
                }
                return true
            } else {
                logger.info("Library for lastPlayedItemID not available: \(targetLibraryID.connectionID)")
            }
        }

        // Fall back to lastTabValue if no lastPlayedItemID
        if let lastTabValue = Defaults[.lastTabValue] {
            if let libraryID = lastTabValue.libraryID {
                guard libraries.contains(where: { $0.id == libraryID }) else {
                    logger.info("Library for lastTabValue not available: \(libraryID.id)")
                    return false
                }
            } else {
                selectedLibraryID = libraries.first?.id
            }

            logger.info("Restoring from lastTabValue as fallback")
            tabValue = lastTabValue
            return true
        }

        return false
    }
    
    func didLoad(connectionID: ItemIdentifier.ConnectionID, libraries: [Library: ([TabValue], [TabValue])]) {
        for (library, (tabBar, sideBar)) in libraries {
            self.tabBar[library.id] = tabBar
            self.sideBar[library.id] = sideBar
        }
        
        let libraries = libraries.map(\.key)
        
        connectionLibraries[connectionID] = libraries.sorted { $0.name < $1.name }
        libraryLookup.merge(libraries.map { ($0.id, $0) }) {
            $1
        }
    }
}

// MARK: Sync

extension TabRouterViewModel {
    func synchronize(connectionID: ItemIdentifier.ConnectionID) async {
        // Atomically check for existing task or create new one on MainActor
        let task = await MainActor.run { () -> Task<Void, Never> in
            // If there's already a task running, return it
            if let existingTask = activeUpdateTasks[connectionID] {
                logger.info("Sync already running for \(connectionID), awaiting existing task")
                return existingTask
            }

            let isInitialSync = initialSyncCompleted[connectionID] != true

            // Create the task
            let newTask: Task<Void, Never> = .init { [weak self] in
                let success: Bool
                let backgroundTask = UIApplication.shared.beginBackgroundTask(withName: "synchronizeUserData")

                do {
                    let (sessions, bookmarks) = try await ABSClient[connectionID].authorize()

                    try await withThrowingTaskGroup(of: Void.self) {
                        $0.addTask {
                            try await PersistenceManager.shared.progress.compareDatabase(
                                against: sessions,
                                connectionID: connectionID,
                                isInitialSync: isInitialSync
                            )
                        }
                        $0.addTask { try await PersistenceManager.shared.bookmark.sync(bookmarks: bookmarks, connectionID: connectionID) }

                        try await $0.waitForAll()
                    }

                    success = true
                } catch {
                    self?.logger.error("Failed to synchronize \(connectionID, privacy: .public): \(error, privacy: .public)")
                    success = false
                }

                UIApplication.shared.endBackgroundTask(backgroundTask)

                guard !Task.isCancelled, let self else {
                    return
                }

                await MainActor.withAnimation {
                    currentConnectionStatus[connectionID] = success
                    activeUpdateTasks[connectionID] = nil

                    // Mark initial sync as complete
                    if success && isInitialSync {
                        initialSyncCompleted[connectionID] = true
                    }
                }
            }

            // Store the task atomically
            activeUpdateTasks[connectionID] = newTask
            return newTask
        }

        // Await the task (either existing or newly created)
        await task.value
    }
    func synchronizeFailed(connectionID: ItemIdentifier.ConnectionID) {
        currentConnectionStatus[connectionID] = false
        
        activeUpdateTasks[connectionID]?.cancel()
        activeUpdateTasks[connectionID] = nil
    }
}

// MARK: Helper

private extension TabRouterViewModel {
    func applyLibraryTitleFont(type: LibraryMediaType) {
        let appearance = UINavigationBarAppearance()
        
        if type == .audiobooks && Defaults[.enableSerifFont] {
            appearance.titleTextAttributes = [.font: UIFont(descriptor: UIFont.systemFont(ofSize: 17, weight: .bold).fontDescriptor.withDesign(.serif)!, size: 0)]
            appearance.largeTitleTextAttributes = [.font: UIFont(descriptor: UIFont.systemFont(ofSize: 34, weight: .bold).fontDescriptor.withDesign(.serif)!, size: 0)]
        }
        
        appearance.configureWithTransparentBackground()
        UINavigationBar.appearance().standardAppearance = appearance
        
        appearance.configureWithDefaultBackground()
        UINavigationBar.appearance().compactAppearance = appearance
    }
}

#if DEBUG
extension TabRouterViewModel {
    func previewEnvironment() -> Self {
        let library = Library.fixture
        
        tabBar[library.id] = [
            .audiobookHome(library.id),
            .audiobookLibrary(library.id),
        ]
        sideBar[library.id] = tabBar[library.id]
        
        libraryLookup[library.id] = library
        connectionLibraries[library.id.connectionID] = [library]
        
        return self
    }
}
#endif
        
//    func navigateIfRequired(withDelay: Bool) {
//        if let navigateToWhenReadyTab {
//            print(navigateToWhenReadyTab)
//        }
//        
//        guard let to = navigateToWhenReady else { return }
//
//        let targetTab: TabValue
//        switch library.type {
//        case .audiobooks:
//            targetTab = .audiobookHome(library)
//        case .podcasts:
//            targetTab = .podcastHome(library)
//        }
//
//        let customWrapped: TabValue = .custom(targetTab)
//        if tabValue != targetTab && tabValue != customWrapped {
//            if customTabValues.contains(customWrapped) {
//                tabValue = customWrapped
//            } else {
//                setCustomTabsActive(false)
//                tabValue = targetTab
//            }
//            
//            return
//        }
//
//        guard ProgressViewModel.shared.importedConnectionIDs.contains(library.connectionID) else {
//            if ProgressViewModel.shared.importFailedConnectionIDs.contains(library.id) {
//                navigateToWhenReady = nil
//            }
//            return
//        }
//
//        let payload = to
//        Task {
//            if withDelay {
//                try? await Task.sleep(for: .seconds(0.5))
//            }
//            await RFNotification[._navigate].send(payload: payload)
//        }
//
//        navigateToWhenReady = nil
//    }
