//
//  AppDelegate.swift
//  iOS
//
//  Created by Rasmus Krämer on 07.01.24.
//

import UIKit

class AppDelegate: NSObject, UIApplicationDelegate {
    private var backgroundCompletionHandler: (() -> Void)? = nil
    
    func application(_ application: UIApplication, handleEventsForBackgroundURLSession identifier: String, completionHandler: @escaping () -> Void) {
        backgroundCompletionHandler = completionHandler
    }
    
    func urlSessionDidFinishEvents(forBackgroundURLSession session: URLSession) {
        Task { @MainActor in
            guard let appDelegate = UIApplication.shared.delegate as? AppDelegate, let backgroundCompletionHandler = appDelegate.backgroundCompletionHandler else {
                return
            }
            
            backgroundCompletionHandler()
        }
    }
}
