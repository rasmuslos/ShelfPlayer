//
//  AppDelegate.swift
//  iOS
//
//  Created by Rasmus Krämer on 07.01.24.
//

import UIKit
import Intents
import ShelfPlayback

// MARK: Background Downloads

final class AppDelegate: NSObject, UIApplicationDelegate {
    private var backgroundCompletionHandler: (() -> Void)? = nil
    
    func application(_ application: UIApplication, handleEventsForBackgroundURLSession identifier: String, completionHandler: @escaping () -> Void) {
        backgroundCompletionHandler = completionHandler
    }
    
    func application(_ application: UIApplication, handlerFor intent: INIntent) -> Any? {
        switch intent {
            case is INPlayMediaIntent:
                PlayMediaIntentHandler()
            default:
                nil
        }
    }
    
    func application(_ application: UIApplication, configurationForConnecting connectingSceneSession: UISceneSession, options: UIScene.ConnectionOptions) -> UISceneConfiguration {
        let configuration = UISceneConfiguration(name: "ShelfPlayer Configuration", sessionRole: connectingSceneSession.role)
        configuration.delegateClass = SceneDelegate.self
        
        return configuration
    }
    
    func applicationWillTerminate(_ application: UIApplication) {
        RFNotification[.finalizePlaybackReporting].send()
    }
    
    func urlSessionDidFinishEvents(forBackgroundURLSession session: URLSession) {
        guard let appDelegate = UIApplication.shared.delegate as? AppDelegate, let backgroundCompletionHandler = appDelegate.backgroundCompletionHandler else {
            return
        }
        
        DispatchQueue.main.async {
            backgroundCompletionHandler()
        }
    }
}

// MARK: Notification Handling

extension AppDelegate: UNUserNotificationCenterDelegate {
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil) -> Bool {
        UNUserNotificationCenter.current().delegate = self
        return true
    }
    
    /*
    internal func userNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification) async -> UNNotificationPresentationOptions {
        return [.banner]
    }
    
    internal func userNotificationCenter(_ center: UNUserNotificationCenter, didReceive response: UNNotificationResponse) async {
        let userInfo = response.notification.request.content.userInfo
        guard let libraryID = userInfo["libraryID"] as? String, let podcastID = userInfo["podcastID"] as? String else {
            return
        }
        
        if let episodeID = userInfo["episodeID"] as? String {
            Navigation.navigate(episodeID: episodeID, podcastID: podcastID, libraryID: libraryID)
        } else {
            Navigation.navigate(podcastID: podcastID, libraryID: libraryID)
     }
     }
     */
}

// MARK: Scene Delegate

private final class SceneDelegate: UIResponder, UIWindowSceneDelegate {
    func windowScene(_ windowScene: UIWindowScene, performActionFor shortcutItem: UIApplicationShortcutItem) async -> Bool {
        switch shortcutItem.type {
            case "search":
                await RFNotification[.setGlobalSearch].send(payload: ("", .global))
            case "play":
                guard let itemIDDescription = shortcutItem.userInfo?["itemID"] as? String else {
                    return false
                }
                
                let itemID = ItemIdentifier(itemIDDescription)
                
                do {
                    try await AudioPlayer.shared.start(.init(itemID: itemID, origin: .unknown))
                } catch {
                    return false
                }
            default:
                return false
        }
        
        return true
    }
}
