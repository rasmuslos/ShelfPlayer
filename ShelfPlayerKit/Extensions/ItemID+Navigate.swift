//
//  ItemID+Navigate.swift
//  ShelfPlayerKit
//
//  Created by Rasmus Krämer on 04.03.25.
//

import Foundation

public extension ItemIdentifier {
    @MainActor
    func navigateIsolated() {
        NavigationEventSource.shared.navigate.send(self)
    }

    func navigate() {
        Task {
            await navigateIsolated()
        }
    }

    func navigate() async {
        await navigateIsolated()
    }
}
