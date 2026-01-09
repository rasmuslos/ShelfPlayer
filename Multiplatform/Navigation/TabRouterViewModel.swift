import SwiftUI
import OSLog
import ShelfPlayback

@MainActor @Observable
final class TabRouterViewModel {
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
    func loadLibraries() async {
        var results = [ItemIdentifier.ConnectionID: [Library: ([TabValue], [TabValue])]]()
                       
        await withTaskGroup { group in
            for connectionID in await PersistenceManager.shared.authorization.connectionIDs {
                group.addTask {
                    do {
                        let libraries = try await ABSClient[connectionID].libraries()
                        var results = [Library: ([TabValue], [TabValue])]()
                        
                        for library in libraries {
                            let (tabBar, sideBar) = (
                                await PersistenceManager.shared.customization.configuredTabs(for: library.id, scope: .tabBar),
                                await PersistenceManager.shared.customization.configuredTabs(for: library.id, scope: .sidebar),
                            )
                            
                            results[library] = (tabBar, sideBar)
                        }
                        
                        return (connectionID, results)
                    } catch {
                        return (connectionID, [:])
                    }
                }
                
                for await (connectionID, result) in group {
                    results[connectionID] = result
                }
            }
        }
        
        // i will go to hell for this
        
        let successMapped = results.mapValues { !$0.isEmpty }
        
        for (connectionID, isSuccessful) in successMapped {
            if isSuccessful {
                synchronize(connectionID: connectionID)
            } else {
                synchronizeFailed(connectionID: connectionID)
            }
        }
        
        if !successMapped.reduce(true, { $0 && $1.value }) {
            OfflineMode.shared.setEnabled(true)
        }
        
        let libraryTabMapped = results.values.flatMap { $0.map { ($0.id, $1.0, $1.1) } }
        
        tabBar = Dictionary(uniqueKeysWithValues: libraryTabMapped.map { ($0.0, $0.1) })
        sideBar = Dictionary(uniqueKeysWithValues: libraryTabMapped.map { ($0, $2) })
        
        let libraries = results.values.flatMap(\.keys).sorted {
            $0.name < $1.name
        }
        
        connectionLibraries = Dictionary(grouping: libraries, by: \.id.connectionID)
        libraryLookup = Dictionary(uniqueKeysWithValues: libraries.map { ($0.id, $0) })
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
        
        guard let lastTabValue = Defaults[.lastTabValue] else {
            return false
        }
        
        if let libraryID = lastTabValue.libraryID {
            guard libraries.contains(where: { $0.id == libraryID }) else {
                return false
            }
        } else {
            selectedLibraryID = libraries.first?.id
        }
        
        tabValue = lastTabValue
        return true
    }
}

// MARK: Sync

extension TabRouterViewModel {
    func synchronize(connectionID: ItemIdentifier.ConnectionID) {
        guard activeUpdateTasks[connectionID] == nil else {
            logger.warning("Tried to start sync for \(connectionID) while it is already running")
            return
        }
        
        activeUpdateTasks[connectionID] = .init { [weak self] in
            let success: Bool
            let task = UIApplication.shared.beginBackgroundTask(withName: "synchronizeUserData")
            
            do {
                let (sessions, bookmarks) = try await ABSClient[connectionID].authorize()
                
                try await withThrowingTaskGroup(of: Void.self) {
                    $0.addTask { try await PersistenceManager.shared.progress.compareDatabase(against: sessions, connectionID: connectionID) }
                    $0.addTask { try await PersistenceManager.shared.bookmark.sync(bookmarks: bookmarks, connectionID: connectionID) }
                    
                    try await $0.waitForAll()
                }
                
                success = true
            } catch {
                self?.logger.error("Failed to synchronize \(connectionID, privacy: .public): \(error, privacy: .public)")
                success = false
            }
            
            UIApplication.shared.endBackgroundTask(task)
            
            guard !Task.isCancelled, let self else {
                return
            }
            
            await MainActor.withAnimation {
                currentConnectionStatus[connectionID] = success
                activeUpdateTasks[connectionID] = nil
            }
        }
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
