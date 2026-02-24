//
//  CarPlayTabBar.swift
//  Multiplatform
//
//  Created by Rasmus Krämer on 18.10.24.
//
import Foundation
@preconcurrency import CarPlay
import ShelfPlayback

final class CarPlayTabBar {
    private let interfaceController: CPInterfaceController
    
    private let listenNowController: CarPlayListenNowController
    
    private let librariesTemplate: CPListTemplate
    private var libraries = [Library]()
    private var libraryLookup = [LibraryIdentifier: Library]()
    private var libraryControllers = [LibraryIdentifier: CarPlayLibraryController]()
    
    private var defaultsTask: Task<Void, Never>?
    private var librariesTask: Task<Void, Never>?
    
    let template: CPTabBarTemplate
    
    init(interfaceController: CPInterfaceController) {
        self.interfaceController = interfaceController
        
        listenNowController = CarPlayListenNowController()
        
        librariesTemplate = CPListTemplate(
            title: String(localized: "carPlay.otherLibraries"),
            sections: [],
            assistantCellConfiguration: .none
        )
        librariesTemplate.tabTitle = String(localized: "carPlay.otherLibraries")
        librariesTemplate.tabImage = UIImage(systemName: "books.vertical.fill")
        librariesTemplate.applyCarPlayLoadingState()
        
        template = CPTabBarTemplate(templates: [])
        defaultsTask = Task { [weak self] in
            guard let self else {
                return
            }
            
            for await _ in Defaults.updates([.carPlayTabBarLibraries, .carPlayShowOtherLibraries], initial: false) {
                self.updateTemplate()
            }
        }
        
        RFNotification[.connectionsChanged].subscribe { [weak self] in
            self?.reloadLibraries()
        }
        RFNotification[.offlineModeChanged].subscribe { [weak self] _ in
            self?.reloadLibraries()
        }
        
        reloadLibraries()
        updateTemplate()
    }
    
    deinit {
        defaultsTask?.cancel()
        librariesTask?.cancel()
    }
}

private extension CarPlayTabBar {
    func reloadLibraries() {
        librariesTask?.cancel()
        librariesTemplate.applyCarPlayLoadingState()
        updateTemplate()
        
        librariesTask = Task { [weak self] in
            guard let self else {
                return
            }
            
            do {
                try await PersistenceManager.shared.authorization.waitForConnections()
            } catch {
                // Ignore; fallback to whatever connection state is currently available.
            }
            
            let connectionIDs = await PersistenceManager.shared.authorization.connectionIDs
            let fetched = await withTaskGroup(of: [Library].self, returning: [Library].self) { group in
                for connectionID in connectionIDs {
                    group.addTask {
                        (try? await ABSClient[connectionID].libraries()) ?? []
                    }
                }
                var combined = [Library]()
                for await result in group {
                    combined.append(contentsOf: result)
                }
                return combined
            }
            
            guard !Task.isCancelled else {
                return
            }
            
            self.applyLibraries(fetched)
        }
    }
    
    func applyLibraries(_ libraries: [Library]) {
        self.libraries = libraries.sorted(by: sortLibraries)
        libraryLookup = Dictionary(uniqueKeysWithValues: self.libraries.map { ($0.id, $0) })
        
        let validIDs = Set(self.libraries.map(\.id))
        libraryControllers = libraryControllers.filter { validIDs.contains($0.key) }
        
        refreshLibrariesTemplate()
        updateTemplate()
    }
    
    func sortLibraries(_ lhs: Library, _ rhs: Library) -> Bool {
        if lhs.id.connectionID != rhs.id.connectionID {
            return lhs.id.connectionID < rhs.id.connectionID
        }
        
        if lhs.index != rhs.index {
            return lhs.index < rhs.index
        }
        
        return lhs.name.localizedCaseInsensitiveCompare(rhs.name) == .orderedAscending
    }
    
    func refreshLibrariesTemplate() {
        guard !libraries.isEmpty else {
            librariesTemplate.updateSections([])
            librariesTemplate.applyCarPlayEmptyState()
            return
        }
        
        let rows = libraries.map(makeLibraryRow)
        
        librariesTemplate.updateSections([CPListSection(items: rows)])
        librariesTemplate.applyCarPlayEmptyState()
    }
    
    func makeLibraryRow(_ library: Library) -> CPListItem {
        let row = CPListItem(
            text: library.name,
            detailText: nil,
            image: UIImage(systemName: library.icon)
        )
        row.accessoryType = .disclosureIndicator
        row.handler = { [weak self] _, completion in
            guard let self else {
                completion()
                return
            }
            
            Task {
                await self.pushLibrary(library)
                completion()
            }
        }
        
        return row
    }
    
    func pushLibrary(_ library: Library) async {
        let controller = controller(for: library)
        _ = try? await interfaceController.pushTemplate(controller.template, animated: true)
    }
    
    func controller(for library: Library) -> CarPlayLibraryController {
        if let controller = libraryControllers[library.id] {
            return controller
        }
        
        let controller = CarPlayLibraryController(library: library)
        libraryControllers[library.id] = controller
        return controller
    }
    
    func selectedLibraryTemplates(limit: Int) -> [CPTemplate] {
        guard limit > 0 else {
            return []
        }
        
        guard let selected = Defaults[.carPlayTabBarLibraries] else {
            return []
        }
        
        return selected.prefix(limit)
            .compactMap { libraryLookup[$0.id] }
            .map { controller(for: $0).template }
    }
    
    func updateTemplate() {
        if OfflineMode.shared.isEnabled {
            template.updateTemplates([listenNowController.template])
            return
        }
        
        let showsLibraries = Defaults[.carPlayShowOtherLibraries]
        let reservedTabs = 1 + (showsLibraries ? 1 : 0)
        let customLimit = max(0, 5 - reservedTabs)
        
        var templates = [CPTemplate](arrayLiteral: listenNowController.template)
        
        templates.append(contentsOf: selectedLibraryTemplates(limit: customLimit))
        
        if showsLibraries {
            templates.append(librariesTemplate)
        }
        
        if templates.isEmpty {
            templates = [emptyTemplate]
        }
        
        template.updateTemplates(templates)
    }
    
    var emptyTemplate: CPListTemplate {
        let template = CPListTemplate(title: nil, sections: [], assistantCellConfiguration: .none)
        template.tabTitle = String(localized: "carPlay.tabBar.empty")
        template.tabImage = UIImage(systemName: "xmark")
        template.emptyViewTitleVariants = [String(localized: "carPlay.tabBar.empty")]
        template.emptyViewSubtitleVariants = [""]
        return template
    }
}
