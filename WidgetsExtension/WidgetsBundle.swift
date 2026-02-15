//
//  WidgetsBundle.swift
//  Widgets
//
//  Created by Rasmus Krämer on 29.05.25.
//

import WidgetKit
import SwiftUI
import AppIntents
import ShelfPlayerKit

@main
struct WidgetsBundle: WidgetBundle {
    init() {
        let semaphore = DispatchSemaphore(value: 0)
        
        Task {
            try? await PersistenceManager.shared.authorization.waitForConnections()
            semaphore.signal()
        }
    }
    
    var body: some Widget {
        StartWidget()
        
        ListenedTodayWidget()
        ListenNowWidget()
        
        SleepTimerLiveActivity()
    }
}

struct ShelfPlayerWidgetPackage: AppIntentsPackage {
    static let includedPackages: [any AppIntentsPackage.Type] = [
        ShelfPlayerKitPackage.self,
    ]
}
