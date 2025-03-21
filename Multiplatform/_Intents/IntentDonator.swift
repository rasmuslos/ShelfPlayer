//
//  IntentDonator.swift
//  Multiplatform
//
//  Created by Rasmus Krämer on 01.10.24.
//

import Foundation
import Intents
import ShelfPlayerKit
import SPPlayback
import OSLog

final class IntentDonator: Sendable {
    // bound to the notification queue
    // nonisolated(unsafe) var lastDonatedItem: Item?
    
    let logger = Logger(subsystem: "USerContext", category: "Intents")
    
    private init() {
        // lastDonatedItem = nil
        setupObservers()
    }
    
    public func ping() {
        logger.debug("Pong from IntentDonator")
    }
    
    static let shared = IntentDonator()
}

private extension IntentDonator {
    func setupObservers() {
        /*
        NotificationCenter.default.addObserver(forName: AudioPlayer.itemDidChangeNotification, object: nil, queue: nil) { [unowned self] _ in
            Task {
                guard AudioPlayer.shared.item != self.lastDonatedItem else {
                    return
                }
                
                guard let item = AudioPlayer.shared.item else {
                    return
                }
                
                guard let intent = await IntentHelper.createIntent(item: item) else {
                    return
                }
                
                let response = INPlayMediaIntentResponse(code: .success, userActivity: nil)
                
                let interaction = INInteraction(intent: intent, response: response)
                try await interaction.donate()
                
                UserContext.logger.info("Donated INPlayMediaIntent for \(item.name)")
                
                lastDonatedItem = AudioPlayer.shared.item
            }
        }
         */
    }
}
