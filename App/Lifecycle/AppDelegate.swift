//
//  AppDelegate.swift
//  ShelfPlayer
//
//  Created by Rasmus Krämer on 07.01.24.
//

@preconcurrency import UIKit
import Intents
import ShelfPlayback

// MARK: Background Downloads

final class AppDelegate: NSObject, UIApplicationDelegate {
    private var backgroundCompletionHandler: (() -> Void)? = nil

    func application(_ application: UIApplication, handleEventsForBackgroundURLSession identifier: String, completionHandler: @escaping () -> Void) {
        backgroundCompletionHandler = completionHandler
    }

    func application(_ application: UIApplication, handlerFor intent: INIntent) -> Any? {
        return switch intent {
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
        PlaybackLifecycleEventSource.shared.finalizeReporting.send()
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
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil) -> Bool {
        UNUserNotificationCenter.current().delegate = self
        return true
    }
}

// MARK: Scene Delegate

private final class SceneDelegate: UIResponder, UIWindowSceneDelegate {
    func windowScene(_ windowScene: UIWindowScene, performActionFor shortcutItem: UIApplicationShortcutItem, completionHandler: @escaping (Bool) -> Void) {
        switch shortcutItem.type {
            case "search":
                NavigationEventSource.shared.setGlobalSearch.send(("", .global))
            case "play":
                guard let itemIDDescription = shortcutItem.userInfo?["itemID"] as? String else {
                    completionHandler(false)
                    return
                }

                let itemID = ItemIdentifier(itemIDDescription)

                Task {
                    try await Task.sleep(for: .seconds(4))
                    NavigationEventSource.shared.navigate.send(itemID)
                }
            default:
                completionHandler(false)
                return
        }

        completionHandler(true)
    }
}
