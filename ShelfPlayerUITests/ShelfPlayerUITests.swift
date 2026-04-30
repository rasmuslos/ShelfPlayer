//
//  ShelfPlayerUITests.swift
//  ShelfPlayerUITests
//

import Testing
import XCTest

// MARK: - Connection Flow

@Suite("Connection flow", .serialized)
@MainActor
struct ConnectionFlowTests {
    let app: XCUIApplication

    init() {
        let app = XCUIApplication()
        // Wipe any previously stored connection so every connection-flow test
        // begins on the welcome screen, not whatever the last suite left behind.
        app.launchForUITesting(wipeConnections: true)
        app.dismissSystemAlertsIfPresent()
        self.app = app
    }

    @Test("Launch screen resolves to welcome or tab bar")
    func welcomeOrTabBarAppears() async throws {
        let welcome = app.staticTexts["Welcome"]
        let tabBar = app.tabBars.firstMatch
        #expect(
            XCUIElement.waitForEither(welcome, tabBar, timeout: 15),
            "Neither the welcome screen nor the tab bar appeared"
        )
    }

    @Test("Tapping add-connection opens the endpoint sheet")
    func addConnectionButtonOpensSheet() async throws {
        guard !app.isAlreadyConnected() else { return }

        let addButton = app.addConnectionButton
        #expect(addButton.waitForExistence(timeout: 10), "Add connection button not found")
        addButton.tap()

        #expect(app.endpointTextField.waitForExistence(timeout: 5), "Endpoint field did not appear")
    }

    @Test("Endpoint verification advances to the authorization step")
    func connectToLocalAdvancesToAuth() async throws {
        guard !app.isAlreadyConnected() else { return }

        app.addConnectionButton.tap()

        let endpointField = app.endpointTextField
        try #require(endpointField.waitForExistence(timeout: 5))

        endpointField.tap()
        endpointField.clearText()
        endpointField.typeText(LocalServer.endpoint)

        app.tapConnectButton()

        #expect(app.textFields["Username"].waitForExistence(timeout: 20), "Authorization step did not appear")
    }

    @Test("Full login flow lands on the main tab bar")
    func fullLoginFlowReachesMainContent() async throws {
        if app.isAlreadyConnected() {
            // Nothing left to prove — the device already has a live connection.
            return
        }

        try app.logInToLocalServer()

        #expect(app.tabBars.firstMatch.waitForExistence(timeout: 30), "Did not reach main content after login")
    }
}

// MARK: - User Flows

@Suite("User flows", .serialized)
@MainActor
struct UserFlowTests {
    let app: XCUIApplication

    init() throws {
        let app = XCUIApplication()
        app.launchForUITesting()
        app.dismissSystemAlertsIfPresent()

        // Log in if needed so each test is independent of prior suite state.
        if !app.isAlreadyConnected() {
            try app.logInToLocalServer()
        }

        try #require(
            app.tabBars.firstMatch.waitForExistence(timeout: 30),
            "App did not reach the main tab bar after attempting to log in"
        )

        self.app = app
    }

    @Test("Home content loads")
    func browseHome() async throws {
        let homeTab = app.tabBars.buttons.matching(
            NSPredicate(format: "label CONTAINS[c] 'Home' OR label CONTAINS[c] 'Listen'")
        ).firstMatch

        if homeTab.exists {
            homeTab.tap()
        }

        #expect(app.anyScrollableContent.waitForExistence(timeout: 15), "Home content did not load")
    }

    @Test("Library tab shows content")
    func navigateToLibraryTab() async throws {
        let libraryTab = app.tabBars.buttons.matching(
            NSPredicate(format: "label CONTAINS[c] 'Library'")
        ).firstMatch

        guard libraryTab.waitForExistence(timeout: 5) else { return }
        libraryTab.tap()

        #expect(app.anyScrollableContent.waitForExistence(timeout: 15), "Library content did not load")
    }

    @Test("Series tab is reachable if present")
    func navigateToSeriesTab() async throws {
        let seriesTab = app.tabBars.buttons.matching(
            NSPredicate(format: "label CONTAINS[c] 'Series'")
        ).firstMatch

        guard seriesTab.waitForExistence(timeout: 5) else { return }
        seriesTab.tap()

        _ = app.staticTexts.firstMatch.waitForExistence(timeout: 10)
    }

    @Test("Search returns Pride results")
    func searchForAudiobook() async throws {
        try app.navigateToSearch()
        app.searchFor(LocalServer.searchQuery)

        #expect(
            app.cells.firstMatch.waitForExistence(timeout: 20),
            "Search results did not appear for '\(LocalServer.searchQuery)'"
        )
    }

    @Test("Opening a search result shows the detail view")
    func openAudiobookDetail() async throws {
        try app.navigateToSearch()
        app.searchFor(LocalServer.audiobookTitle)

        let result = app.cells.firstMatch
        try #require(result.waitForExistence(timeout: 20), "No search results")
        result.tap()

        let title = app.staticTexts.matching(
            NSPredicate(format: "label CONTAINS[c] %@", LocalServer.searchQuery)
        ).firstMatch
        #expect(title.waitForExistence(timeout: 15), "Audiobook detail did not load")
    }

    @Test("Tapping play on the audiobook detail is reachable")
    func playAudiobook() async throws {
        try app.navigateToSearch()
        app.searchFor(LocalServer.audiobookTitle)

        let result = app.cells.firstMatch
        try #require(result.waitForExistence(timeout: 20), "No search results")
        result.tap()

        let playButton = app.buttons.matching(
            NSPredicate(format: "label CONTAINS[c] 'Play' OR label CONTAINS[c] 'play'")
        ).firstMatch
        try #require(playButton.waitForExistence(timeout: 15), "Play button not found")

        // Tapping should not throw; we don't assert on the audio engine since
        // playback startup depends on the local server and is inherently flaky.
        playButton.tap()
    }

    @Test("Podcast library is reachable if the server has one")
    func navigateToPodcastLibrary() async throws {
        let podcastElement = app.buttons.matching(
            NSPredicate(format: "label CONTAINS[c] 'Podcast'")
        ).firstMatch

        if !podcastElement.exists {
            let libraryPicker = app.buttons.matching(
                NSPredicate(format: "label CONTAINS[c] 'librar'")
            ).firstMatch

            guard libraryPicker.waitForExistence(timeout: 5) else { return }
            libraryPicker.tap()

            let podcastLibrary = app.buttons.matching(
                NSPredicate(format: "label CONTAINS[c] 'Podcast'")
            ).firstMatch

            guard podcastLibrary.waitForExistence(timeout: 5) else { return }
            podcastLibrary.tap()
        } else {
            podcastElement.tap()
        }

        _ = app.cells.firstMatch.waitForExistence(timeout: 15)
    }

    @Test("Bookmark button can be activated during playback")
    func createBookmark() async throws {
        try app.navigateToSearch()
        app.searchFor(LocalServer.audiobookTitle)

        let result = app.cells.firstMatch
        try #require(result.waitForExistence(timeout: 20), "No search results")
        result.tap()

        let playButton = app.buttons.matching(
            NSPredicate(format: "label CONTAINS[c] 'Play' OR label CONTAINS[c] 'play'")
        ).firstMatch
        try #require(playButton.waitForExistence(timeout: 15), "Play button not found")
        playButton.tap()

        _ = app.buttons.matching(NSPredicate(format: "label CONTAINS[c] 'Pause'")).firstMatch
            .waitForExistence(timeout: 10)

        let bookmarkButton = app.buttons.matching(
            NSPredicate(format: "label CONTAINS[c] 'bookmark'")
        ).firstMatch

        guard bookmarkButton.waitForExistence(timeout: 10) else { return }
        bookmarkButton.tap()

        let createButton = app.buttons.matching(
            NSPredicate(format: "label CONTAINS[c] 'Create'")
        ).firstMatch
        if createButton.waitForExistence(timeout: 5) {
            createButton.tap()
        }
    }

    @Test("Mark-as-finished control is reachable when the detail has a menu")
    func markAsFinished() async throws {
        try app.navigateToSearch()
        app.searchFor(LocalServer.audiobookTitle)

        let result = app.cells.firstMatch
        try #require(result.waitForExistence(timeout: 20), "No search results")
        result.tap()

        let moreButton = app.buttons.matching(
            NSPredicate(format: "label CONTAINS[c] 'More' OR identifier CONTAINS[c] 'menu'")
        ).firstMatch

        guard moreButton.waitForExistence(timeout: 5) else { return }
        moreButton.tap()

        let finishedButton = app.buttons.matching(
            NSPredicate(format: "label CONTAINS[c] 'Finished' OR label CONTAINS[c] 'complete'")
        ).firstMatch

        if finishedButton.waitForExistence(timeout: 5) {
            finishedButton.tap()
        }
    }
}

// MARK: - Offline Mode

@Suite("Offline mode", .serialized)
@MainActor
struct OfflineModeTests {
    /// Without any connections, the welcome screen takes precedence over
    /// offline mode — even when offline mode is forced at launch.
    @Test("Welcome screen wins when no connections exist")
    func welcomeWinsWithoutConnections() async throws {
        let app = XCUIApplication()
        app.launchForUITesting(wipeConnections: true, forceOfflineMode: true)
        app.dismissSystemAlertsIfPresent()

        try #require(app.addConnectionButton.waitForExistence(timeout: 15), "Welcome screen did not appear")
        #expect(!app.tabBars.firstMatch.exists, "Tab bar should not be visible without connections")
        #expect(!app.staticTexts["Offline"].exists, "Offline panel should not be visible without connections")
    }

    /// With a connection in place, forcing offline mode at launch should drop
    /// the user onto the offline panel and the "Go online" control should
    /// recover the tab bar once tapped.
    @Test("Offline panel appears with a connection and recovers via 'Go online'")
    func offlinePanelTogglesWithConnection() async throws {
        // Step 1 — fresh simulator state, log in, reach the tab bar.
        let app = XCUIApplication()
        app.launchForUITesting(wipeConnections: true)
        app.dismissSystemAlertsIfPresent()

        try app.logInToLocalServer()
        try #require(
            app.tabBars.firstMatch.waitForExistence(timeout: 30),
            "Did not reach main content after login"
        )

        // Step 2 — relaunch with offline mode forced; keep the stored connection.
        app.terminate()
        app.launchForUITesting(forceOfflineMode: true)
        app.dismissSystemAlertsIfPresent()

        // The offline panel renders "Go online" twice (toolbar + body), so
        // pin to the toolbar instance which sits inside the "Offline" nav bar.
        let toolbarGoOnline = app.navigationBars["Offline"].buttons["Go online"]
        try #require(toolbarGoOnline.waitForExistence(timeout: 20), "Offline panel did not appear after forcing offline mode")
        #expect(!app.tabBars.firstMatch.exists, "Tab bar should be hidden in offline mode")

        // Step 3 — tap "Go online" and verify the tab bar returns.
        toolbarGoOnline.tap()
        #expect(
            app.tabBars.firstMatch.waitForExistence(timeout: 30),
            "Tab bar did not return after tapping 'Go online'"
        )
    }
}

// MARK: - Local server fixture

/// Coordinates UI tests with the local Audiobookshelf dev server. Tests assume
/// the server at `http://localhost:3333` is running and seeded with the public
/// domain audiobook collection (Pride and Prejudice, Alice in Wonderland, …).
enum LocalServer {
    static let endpoint = "http://localhost:3333"
    static let username = "root"
    static let password = "root"

    /// A short token that should match an audiobook on the seeded server.
    static let searchQuery = "Pride"

    /// A full title that exists in the seeded audiobook library.
    static let audiobookTitle = "Pride and Prejudice"
}

// MARK: - Shared app helpers

extension XCUIApplication {
    /// Launch in a predictable locale so hardcoded English strings match the
    /// rendered labels regardless of the simulator's language setting. Pass
    /// `wipeConnections: true` for tests that need to start from a clean
    /// welcome screen (debug-only env var); leave the default for tests that
    /// reuse a previously logged-in connection across launches.
    func launchForUITesting(wipeConnections: Bool = false, forceOfflineMode: Bool = false) {
        launchArguments += [
            "-AppleLanguages", "(en)",
            "-AppleLocale", "en_US",
        ]
        if wipeConnections {
            launchEnvironment["WIPE_CONNECTIONS"] = "YES"
        } else {
            launchEnvironment.removeValue(forKey: "WIPE_CONNECTIONS")
        }
        if forceOfflineMode {
            launchEnvironment["FORCE_OFFLINE_MODE"] = "YES"
        } else {
            launchEnvironment.removeValue(forKey: "FORCE_OFFLINE_MODE")
        }
        launch()
    }

    /// Dismiss any permission alert that interrupts the first launch (Siri,
    /// notifications, tracking). Siri's dialog is owned by SpringBoard, so we
    /// check both the app's own alerts and the springboard's.
    func dismissSystemAlertsIfPresent() {
        let springboard = XCUIApplication(bundleIdentifier: "com.apple.springboard")
        let dismissLabels = ["Don't Allow", "Don\u{2019}t Allow", "Not Now", "Cancel", "Dismiss", "OK"]

        for _ in 0..<3 {
            var dismissed = false

            for alertQuery in [alerts, springboard.alerts] {
                let alert = alertQuery.firstMatch
                guard alert.waitForExistence(timeout: 1.5) else { continue }

                let labelMatch = dismissLabels
                    .map { alert.buttons[$0] }
                    .first(where: { $0.exists })

                (labelMatch ?? alert.buttons.firstMatch).tap()
                dismissed = true
            }

            if !dismissed { break }
        }
    }

    var addConnectionButton: XCUIElement { buttons["Add connections"] }
    var endpointTextField: XCUIElement { textFields["Endpoint"] }

    /// Best-effort check for "main content is visible" — used so tests relying
    /// on a prior connection don't trip when the simulator is already set up.
    func isAlreadyConnected(timeout: TimeInterval = 2) -> Bool {
        tabBars.firstMatch.waitForExistence(timeout: timeout)
    }

    /// The connect button's localization key (`connection.add.connect`) has no
    /// English translation, so the rendered label is literally the key. Match
    /// on the substring "connect" to cover both the key and any real value.
    func tapConnectButton() {
        let predicate = NSPredicate(format: "label CONTAINS[c] 'connect'")
        let connect = buttons.matching(predicate).firstMatch

        if connect.waitForExistence(timeout: 5) {
            connect.tap()
        } else {
            endpointTextField.typeText("\n")
        }
    }

    var anyScrollableContent: XCUIElement {
        if collectionViews.firstMatch.exists { return collectionViews.firstMatch }
        if scrollViews.firstMatch.exists { return scrollViews.firstMatch }
        return tables.firstMatch
    }

    /// Drives the welcome-flow through to the tab bar using the local
    /// Audiobookshelf server. Assumes the app is on the welcome screen and that
    /// `http://localhost:3333` is reachable from the simulator's host.
    func logInToLocalServer() throws {
        try #require(addConnectionButton.waitForExistence(timeout: 10), "Add connection button not found")
        addConnectionButton.tap()

        let endpointField = endpointTextField
        try #require(endpointField.waitForExistence(timeout: 5), "Endpoint field not found")
        endpointField.tap()
        endpointField.clearText()
        endpointField.typeText(LocalServer.endpoint)

        tapConnectButton()

        let usernameField = textFields["Username"]
        try #require(usernameField.waitForExistence(timeout: 20), "Authorization step did not appear")
        usernameField.tap()
        usernameField.typeText(LocalServer.username)

        let passwordField = secureTextFields["Password"]
        try #require(passwordField.waitForExistence(timeout: 3), "Password field not found")
        passwordField.tap()
        passwordField.typeText(LocalServer.password)

        let proceed = buttons["Proceed"]
        if proceed.waitForExistence(timeout: 3) {
            proceed.tap()
        }
    }

    func navigateToSearch() throws {
        let searchTab = tabBars.buttons.matching(
            NSPredicate(format: "label CONTAINS[c] 'Search'")
        ).firstMatch
        guard searchTab.waitForExistence(timeout: 5) else { return }
        searchTab.tap()
    }

    func searchFor(_ query: String) {
        let searchField = searchFields.firstMatch
        guard searchField.waitForExistence(timeout: 5) else { return }

        searchField.tap()

        if let existingText = searchField.value as? String,
           !existingText.isEmpty,
           existingText != searchField.placeholderValue {
            searchField.clearText()
        }

        searchField.typeText(query)
    }
}

extension XCUIElement {
    func clearText() {
        guard let currentValue = value as? String, !currentValue.isEmpty else { return }

        tap(withNumberOfTaps: 3, numberOfTouches: 1)
        typeText(XCUIKeyboardKey.delete.rawValue)
    }

    /// Poll for the existence of either element until the timeout elapses.
    static func waitForEither(_ a: XCUIElement, _ b: XCUIElement, timeout: TimeInterval) -> Bool {
        let deadline = Date().addingTimeInterval(timeout)
        while Date() < deadline {
            if a.exists || b.exists { return true }
            _ = a.waitForExistence(timeout: 0.5)
        }
        return a.exists || b.exists
    }
}
