//
//  CarPlayLibraryController.swift
//  Multiplatform
//
//  Created by Rasmus Krämer on 19.10.24.
//
import Foundation
@preconcurrency import CarPlay
import ShelfPlayback
final class CarPlayLibraryController {
    private let interfaceController: CPInterfaceController
    private let library: Library
    let template: CPListTemplate
    private var itemControllers = [CarPlayItemController]()
    private var refreshTask: Task<Void, Never>?
    init(interfaceController: CPInterfaceController, library: Library) {
        self.interfaceController = interfaceController
        self.library = library
        template = CPListTemplate(title: library.name, sections: [], assistantCellConfiguration: .none)
        template.tabTitle = library.name
        template.tabImage = UIImage(systemName: library.icon)
        template.applyCarPlayLoadingState()
        RFNotification[.connectionsChanged].subscribe { [weak self] in
            self?.reload()
        }
        RFNotification[.offlineModeChanged].subscribe { [weak self] _ in
            self?.reload()
        }
        reload()
    }
    deinit {
        refreshTask?.cancel()
    }
}
private extension CarPlayLibraryController {
    func reload() {
        refreshTask?.cancel()
        template.applyCarPlayLoadingState()
        refreshTask = Task { [weak self] in
            guard let self else {
                return
            }

            guard library.id.type == .audiobooks else {
                itemControllers = []
                template.updateSections([])
                template.applyCarPlayEmptyState()
                return
            }

            await self.loadAudiobookHome()
        }
    }
    func loadAudiobookHome() async {
        do {
            let rows: ([HomeRow<Audiobook>], [HomeRow<Person>]) = try await ABSClient[library.id.connectionID].home(for: library.id.libraryID)
            let prepared = await HomeRow.prepareForPresentation(rows.0, connectionID: library.id.connectionID)
            var sections = [CPListSection]()
            var retainedControllers = [CarPlayItemController]()
            for row in prepared {
                let controllers = row.entities.map {
                    CarPlayPlayableItemController(item: $0, displayCover: true)
                }
                retainedControllers.append(contentsOf: controllers)
                sections.append(
                    CPListSection(
                        items: controllers.map(\.row),
                        header: row.localizedLabel,
                        sectionIndexTitle: nil
                    )
                )
            }
            itemControllers = retainedControllers
            template.updateSections(sections)
            template.applyCarPlayEmptyState()
        } catch {
            itemControllers = []
            template.updateSections([])
            template.applyCarPlayEmptyState()
        }
    }
}
