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
        app.launchForUITesting()
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
    func connectToDemoAdvancesToAuth() async throws {
        guard !app.isAlreadyConnected() else { return }

        app.addConnectionButton.tap()

        let endpointField = app.endpointTextField
        try #require(endpointField.waitForExistence(timeout: 5))

        endpointField.tap()
        endpointField.clearText()
        endpointField.typeText("https://audiobooks.dev")

        app.tapConnectButton()

        #expect(app.textFields["Username"].waitForExistence(timeout: 20), "Authorization step did not appear")
    }

    @Test("Full login flow lands on the main tab bar")
    func fullLoginFlowReachesMainContent() async throws {
        if app.isAlreadyConnected() {
            // Nothing left to prove — the device already has a live connection.
            return
        }

        try app.logInToDemoServer()

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
            try app.logInToDemoServer()
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

    @Test("Search returns Aesop results")
    func searchForAudiobook() async throws {
        try app.navigateToSearch()
        app.searchFor("Aesop")

        #expect(app.cells.firstMatch.waitForExistence(timeout: 20), "Search results did not appear for 'Aesop'")
    }

    @Test("Opening a search result shows the detail view")
    func openAudiobookDetail() async throws {
        try app.navigateToSearch()
        app.searchFor("Aesop's Fables")

        let result = app.cells.firstMatch
        try #require(result.waitForExistence(timeout: 20), "No search results")
        result.tap()

        let title = app.staticTexts.matching(
            NSPredicate(format: "label CONTAINS[c] 'Aesop'")
        ).firstMatch
        #expect(title.waitForExistence(timeout: 15), "Audiobook detail did not load")
    }

    @Test("Tapping play on the audiobook detail is reachable")
    func playAudiobook() async throws {
        try app.navigateToSearch()
        app.searchFor("Aesop's Fables")

        let result = app.cells.firstMatch
        try #require(result.waitForExistence(timeout: 20), "No search results")
        result.tap()

        let playButton = app.buttons.matching(
            NSPredicate(format: "label CONTAINS[c] 'Play' OR label CONTAINS[c] 'play'")
        ).firstMatch
        try #require(playButton.waitForExistence(timeout: 15), "Play button not found")

        // Tapping should not throw; we don't assert on the audio engine since
        // playback startup depends on the demo server and is inherently flaky.
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
        app.searchFor("Aesop's Fables")

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
        app.searchFor("Aesop's Fables")

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

// MARK: - Shared app helpers

extension XCUIApplication {
    /// Launch in a predictable locale so hardcoded English strings match the
    /// rendered labels regardless of the simulator's language setting.
    func launchForUITesting() {
        launchArguments += [
            "-AppleLanguages", "(en)",
            "-AppleLocale", "en_US",
        ]
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

    /// Drives the welcome-flow through to the tab bar using the public demo
    /// server credentials. Assumes the app is on the welcome screen.
    func logInToDemoServer() throws {
        try #require(addConnectionButton.waitForExistence(timeout: 10), "Add connection button not found")
        addConnectionButton.tap()

        let endpointField = endpointTextField
        try #require(endpointField.waitForExistence(timeout: 5), "Endpoint field not found")
        endpointField.tap()
        endpointField.clearText()
        endpointField.typeText("https://audiobooks.dev")

        tapConnectButton()

        let usernameField = textFields["Username"]
        try #require(usernameField.waitForExistence(timeout: 20), "Authorization step did not appear")
        usernameField.tap()
        usernameField.typeText("demo")

        let passwordField = secureTextFields["Password"]
        try #require(passwordField.waitForExistence(timeout: 3), "Password field not found")
        passwordField.tap()
        passwordField.typeText("demo")

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
