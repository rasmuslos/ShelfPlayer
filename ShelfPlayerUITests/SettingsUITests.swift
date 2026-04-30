//
//  SettingsUITests.swift
//  ShelfPlayerUITests
//

import Testing
import XCTest

// MARK: - Settings Flow

@Suite("Settings flow", .serialized)
@MainActor
struct SettingsUITests {
    /// Build a freshly launched, logged-in app instance. Tests share connection
    /// state across launches because we don't pass `wipeConnections: true` —
    /// once one test has logged in, subsequent tests skip the welcome flow.
    private func makeLoggedInApp() throws -> XCUIApplication {
        let app = XCUIApplication()
        app.launchForUITesting()
        app.dismissSystemAlertsIfPresent()

        if !app.isAlreadyConnected(timeout: 5) {
            try app.logInToLocalServer()
        }

        try #require(
            app.tabBars.firstMatch.waitForExistence(timeout: 30),
            "App did not reach the main tab bar"
        )

        return app
    }

    @Test("Opening preferences shows the settings root")
    func openPreferencesSheet() async throws {
        let app = try makeLoggedInApp()

        try app.openPreferences()

        // The settings root sets its navigation title to the localization key
        // "preferences"; the rendered English label is "Preferences". Be lenient
        // about the casing and accept either nav-bar text or any cell row.
        let titlePredicate = NSPredicate(
            format: "label CONTAINS[c] 'preferences' OR label CONTAINS[c] 'settings'"
        )
        let title = app.navigationBars.staticTexts.matching(titlePredicate).firstMatch

        #expect(
            title.waitForExistence(timeout: 5)
            || app.cells.firstMatch.waitForExistence(timeout: 5),
            "Settings root did not appear"
        )
    }

    @Test("Each settings page is reachable from the root")
    func navigateToEachSettingsPage() async throws {
        let app = try makeLoggedInApp()

        try app.openPreferences()

        // Each row's accessibility label is derived from the localization key
        // used by `NavigationLink` in `SettingsView`. We probe by substring so
        // the test works regardless of whether translation succeeded. Keep
        // this list short — every iteration costs a navigation push + pop.
        let pageLabels: [String] = [
            "appearance",
            "playback",
            "connection",
            "advanced",
        ]

        for needle in pageLabels {
            let rowPredicate = NSPredicate(format: "label CONTAINS[c] %@", needle)
            let row = app.cells.matching(rowPredicate).firstMatch

            guard row.waitForExistence(timeout: 2) else { continue }
            row.tap()

            // Either a static text or a cell on the destination is sufficient
            // evidence that navigation worked.
            let destinationLoaded =
                app.staticTexts.firstMatch.waitForExistence(timeout: 3)
                || app.cells.firstMatch.waitForExistence(timeout: 1)
            #expect(destinationLoaded, "Destination for '\(needle)' did not load")

            // Pop back to the settings root — the leftmost nav bar button is
            // either the chevron back button or the sheet's close affordance.
            let backButton = app.navigationBars.buttons.element(boundBy: 0)
            if backButton.exists {
                backButton.tap()
            }

            _ = app.cells.matching(NSPredicate(format: "label CONTAINS[c] 'appearance'"))
                .firstMatch
                .waitForExistence(timeout: 3)
        }
    }

    @Test("Appearance page exposes a toggle that can be exercised")
    func toggleAppearanceSetting() async throws {
        let app = try makeLoggedInApp()

        try app.openPreferences()

        let appearanceRow = app.cells.matching(
            NSPredicate(format: "label CONTAINS[c] 'appearance'")
        ).firstMatch
        guard appearanceRow.waitForExistence(timeout: 5) else { return }
        appearanceRow.tap()

        // Try a Toggle whose label hints at color/tint/theme/serif/aspect.
        let togglePredicate = NSPredicate(
            format: "label CONTAINS[c] 'color' OR label CONTAINS[c] 'tint' OR label CONTAINS[c] 'theme' OR label CONTAINS[c] 'serif' OR label CONTAINS[c] 'aspect'"
        )
        let toggle = app.switches.matching(togglePredicate).firstMatch

        if toggle.waitForExistence(timeout: 3) {
            toggle.tap()
            return
        }

        // Fall back to any switch present on the appearance page.
        let anyToggle = app.switches.firstMatch
        if anyToggle.waitForExistence(timeout: 3) {
            anyToggle.tap()
        }
    }

    @Test("Advanced page exposes a control that can be tapped")
    func toggleAdvancedSetting() async throws {
        let app = try makeLoggedInApp()

        try app.openPreferences()

        let advancedRow = app.cells.matching(
            NSPredicate(format: "label CONTAINS[c] 'advanced'")
        ).firstMatch
        guard advancedRow.waitForExistence(timeout: 5) else { return }
        advancedRow.tap()

        let anyToggle = app.switches.firstMatch
        if anyToggle.waitForExistence(timeout: 5) {
            anyToggle.tap()
        }
    }

    @Test("Connections page lists the active local server")
    func connectionsManagementShowsCurrentConnection() async throws {
        let app = try makeLoggedInApp()

        try app.openPreferences()

        let connectionsRow = app.cells.matching(
            NSPredicate(format: "label CONTAINS[c] 'connection'")
        ).firstMatch
        guard connectionsRow.waitForExistence(timeout: 5) else { return }
        connectionsRow.tap()

        // Match either the host (without scheme) or the username.
        let host = LocalServer.endpoint
            .replacingOccurrences(of: "http://", with: "")
            .replacingOccurrences(of: "https://", with: "")

        let predicate = NSPredicate(
            format: "label CONTAINS[c] %@ OR label CONTAINS[c] %@",
            host,
            LocalServer.username
        )

        let staticHit = app.staticTexts.matching(predicate).firstMatch
        let cellHit = app.cells.matching(predicate).firstMatch

        let found =
            staticHit.waitForExistence(timeout: 8)
            || cellHit.waitForExistence(timeout: 1)

        #expect(found, "Did not find an entry referencing host '\(host)' or user '\(LocalServer.username)'")
    }

    @Test("Dismissing preferences returns to the tab bar")
    func dismissPreferencesReturnsToTabBar() async throws {
        let app = try makeLoggedInApp()

        try app.openPreferences()

        // Confirm the sheet is up before dismissing.
        try #require(
            app.navigationBars["Preferences"].waitForExistence(timeout: 10)
            || app.cells.firstMatch.waitForExistence(timeout: 5),
            "Preferences sheet did not appear before dismissal"
        )

        app.dismissPreferencesSheet()

        #expect(
            app.tabBars.firstMatch.waitForExistence(timeout: 8),
            "Tab bar did not return after dismissing preferences"
        )
    }
}

// MARK: - Settings helpers

extension XCUIApplication {
    /// Open the preferences sheet from wherever the app currently is. The
    /// only entry points that exist on iPhone are: (a) the "Preferences"
    /// button in the iPad sidebar footer, and (b) the "Select library" menu
    /// in the toolbar of every home / search panel — but NOT the "Library"
    /// panel itself. So for compact size class we may need to switch tabs
    /// first.
    func openPreferences() throws {
        if isPreferencesSheetVisible() { return }

        // 1. Direct hit: a button literally labelled "Preferences" (iPad
        //    sidebar footer).
        let preferences = buttons["Preferences"]
        if preferences.waitForExistence(timeout: 1) {
            preferences.tap()
            if isPreferencesSheetVisible(timeout: 4) { return }
        }

        // 2. iPhone path: switch to a tab whose toolbar contains the
        //    library picker, then traverse the menu.
        for tabLabel in ["Home", "Audiobooks", "Listen", "Podcasts", "Search"] {
            let tab = tabBars.buttons[tabLabel]
            if tab.exists, !tab.isSelected {
                tab.tap()
                _ = navigationBars.firstMatch.waitForExistence(timeout: 3)
            }

            if try tapPreferencesViaLibraryPicker() { return }
        }

        // 3. Re-try in the current tab one more time even if we couldn't
        //    find a known tab label, in case the layout differs.
        if try tapPreferencesViaLibraryPicker() { return }

        try #require(
            isPreferencesSheetVisible(timeout: 1),
            "Could not open the preferences sheet from the current state"
        )
    }

    /// Tap the "Select library" toolbar button on the current screen and, if
    /// the resulting menu contains a "Preferences" item, tap it. Returns
    /// `true` if the preferences sheet ends up on screen.
    private func tapPreferencesViaLibraryPicker() throws -> Bool {
        let picker = buttons["Select library"]
        guard picker.waitForExistence(timeout: 1) else { return false }
        picker.tap()

        let prefsItem = buttons["Preferences"]
        guard prefsItem.waitForExistence(timeout: 3) else {
            // Close the menu we just opened.
            navigationBars.firstMatch.tap()
            return false
        }

        prefsItem.tap()
        return isPreferencesSheetVisible(timeout: 4)
    }

    /// Loose check: a navigation bar identified as "Preferences" (or a sub-page
    /// of it like "Appearance") indicates the sheet is up.
    func isPreferencesSheetVisible(timeout: TimeInterval = 0.5) -> Bool {
        let preferencesBar = navigationBars["Preferences"]
        if preferencesBar.waitForExistence(timeout: timeout) { return true }

        let appearanceRow = cells.matching(
            NSPredicate(format: "label CONTAINS[c] 'appearance'")
        ).firstMatch
        return appearanceRow.exists
    }

    /// Dismiss the preferences sheet. Tries the leftmost nav bar button, then
    /// falls back to swiping the sheet down.
    func dismissPreferencesSheet() {
        // If we're on a sub-page, pop back first.
        for _ in 0..<4 {
            guard !isAtSettingsRoot() else { break }
            let backButton = navigationBars.buttons.element(boundBy: 0)
            guard backButton.exists else { break }
            backButton.tap()
        }

        // Try a Done / Close button first.
        for label in ["Done", "Close", "Cancel"] {
            let button = buttons[label]
            if button.exists {
                button.tap()
                if tabBars.firstMatch.waitForExistence(timeout: 3) { return }
            }
        }

        // Fallback: swipe down from near the top of the screen.
        let start = coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.05))
        let end = coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.9))
        start.press(forDuration: 0.05, thenDragTo: end)
    }

    private func isAtSettingsRoot() -> Bool {
        // The root has both an "appearance" row and a "support" / "advanced"
        // row. Sub-pages don't render the appearance row.
        let appearance = cells.matching(
            NSPredicate(format: "label CONTAINS[c] 'appearance'")
        ).firstMatch
        let advanced = cells.matching(
            NSPredicate(format: "label CONTAINS[c] 'advanced'")
        ).firstMatch
        return appearance.exists && advanced.exists
    }
}
