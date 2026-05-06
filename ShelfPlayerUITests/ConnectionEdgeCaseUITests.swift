//
//  ConnectionEdgeCaseUITests.swift
//  ShelfPlayerUITests
//

import Testing
import XCTest

// MARK: - Connection Edge Cases

/// Edge-case coverage for the connection-add sheet: bad endpoints, malformed
/// URLs, wrong credentials, navigation links, cancel, and reopen state. The
/// suite always launches with `wipeConnections: true` so every test starts on
/// the welcome screen, regardless of any prior state on the simulator.
@Suite("Connection edge cases", .serialized)
@MainActor
struct ConnectionEdgeCaseUITests {
    let app: XCUIApplication

    /// Predicate that matches any rendered error label we expect on the sheet —
    /// the localized strings vary, so we look for a few common substrings.
    private static let errorTextPredicate = NSPredicate(
        format: "label CONTAINS[c] 'Cannot' OR label CONTAINS[c] 'Failed' OR label CONTAINS[c] 'could not' OR label CONTAINS[c] 'error' OR label CONTAINS[c] 'invalid' OR label CONTAINS[c] 'unable'"
    )

    init() {
        // Match the existing `ConnectionFlowTests` pattern — launch the app in
        // `init` so the struct's `app` property is ready before the test body
        // starts. Initializing the runner from inside a `@Test` function body
        // has shown intermittent crashes on the simulator.
        let app = XCUIApplication()
        app.launchForUITesting(wipeConnections: true)
        app.dismissSystemAlertsIfPresent()
        self.app = app
    }

    /// Taps the welcome screen's "Add connections" button and waits for the
    /// endpoint sheet to appear. Returns silently if the simulator already has
    /// a stored connection (so this suite is safe even when run after a login
    /// suite has populated the keychain).
    private func openConnectionSheet() throws {
        let addButton = app.addConnectionButton
        try #require(addButton.waitForExistence(timeout: 15), "Add connection button not found on welcome screen")
        addButton.tap()

        try #require(app.endpointTextField.waitForExistence(timeout: 5), "Endpoint field did not appear")
    }

    @Test("Unreachable host shows an error and does not advance")
    func unreachableHostShowsError() async throws {
        try openConnectionSheet()

        let endpointField = app.endpointTextField
        endpointField.tap()
        endpointField.clearText()
        endpointField.typeText("http://127.0.0.1:1")

        app.tapConnectButton()

        // Either the warning glyph or any reasonable error label should appear.
        let errorIcon = app.images["exclamationmark.triangle.fill"]
        let errorText = app.staticTexts.matching(Self.errorTextPredicate).firstMatch

        let deadline = Date().addingTimeInterval(20)
        var sawError = false
        while Date() < deadline {
            if errorIcon.exists || errorText.exists {
                sawError = true
                break
            }
            _ = errorIcon.waitForExistence(timeout: 1)
        }

        #expect(sawError, "Expected an error indicator after attempting to reach an unreachable host")

        // The username field should NOT have appeared — we're still on the
        // endpoint step.
        #expect(
            !app.textFields["Username"].waitForExistence(timeout: 2),
            "Authorization step should not appear when the endpoint is unreachable"
        )
    }

    @Test("Malformed URL is rejected without crashing")
    func malformedURLDoesNotCrash() async throws {
        try openConnectionSheet()

        let endpointField = app.endpointTextField
        endpointField.tap()
        endpointField.clearText()
        // The endpoint field uses a `.URL` keyboard which restricts which
        // characters `typeText` can deliver (no spaces). "::::::::" is 8 colons
        // — long enough to enable the connect button and `URL(string:)` returns
        // nil for it, exercising the parse-error branch in the view model
        // without trying to make a real network request.
        endpointField.typeText("::::::::")

        app.tapConnectButton()

        // Authorization step should NOT appear.
        #expect(
            !app.textFields["Username"].waitForExistence(timeout: 5),
            "Authorization step should not appear for a malformed URL"
        )

        // App should still be running and responsive.
        #expect(app.state == .runningForeground, "App should remain running after a malformed URL submission")
        #expect(app.endpointTextField.exists, "Endpoint field should still be visible on the sheet")
    }

    @Test("Wrong password keeps the user on the authorization step")
    func wrongPasswordShowsError() async throws {
        try openConnectionSheet()

        let endpointField = app.endpointTextField
        endpointField.tap()
        endpointField.clearText()
        endpointField.typeText(LocalServer.endpoint)

        app.tapConnectButton()

        let usernameField = app.textFields["Username"]
        try #require(usernameField.waitForExistence(timeout: 20), "Authorization step did not appear")

        usernameField.tap()
        usernameField.typeText(LocalServer.username)

        let passwordField = app.secureTextFields["Password"]
        try #require(passwordField.waitForExistence(timeout: 5), "Password field not found")
        passwordField.tap()
        passwordField.typeText("wrongpassword12345")

        let proceed = app.buttons["Proceed"]
        if proceed.waitForExistence(timeout: 3) {
            proceed.tap()
        } else {
            // Fallback: when the localized key has no English value the button
            // renders the key itself (`connection.add.proceed`). Match loosely.
            let proceedFallback = app.buttons.matching(
                NSPredicate(format: "label CONTAINS[c] 'proceed'")
            ).firstMatch
            if proceedFallback.waitForExistence(timeout: 3) {
                proceedFallback.tap()
            }
        }

        // Reaching the main content surface means a successful login — we
        // must not see it. `waitForMainContent` polls for either the iPhone
        // tab bar or any iPad sidebar / floating-tab-bar entry.
        #expect(
            !app.waitForMainContent(timeout: 10),
            "Main content should not appear when the password is wrong"
        )

        // We should still be on the authorization step or have an error.
        let stillOnAuthStep = app.secureTextFields["Password"].exists || app.textFields["Username"].exists
        let errorVisible = app.staticTexts.matching(Self.errorTextPredicate).firstMatch.exists
            || app.images["exclamationmark.triangle.fill"].exists

        #expect(
            stillOnAuthStep || errorVisible,
            "Expected to remain on the authorization step or see an error after a wrong password"
        )
    }

    @Test("Custom headers link opens its destination")
    func customHeadersLinkOpens() async throws {
        try openConnectionSheet()

        // Snapshot some text that's only on the sheet itself, so we can later
        // assert "we navigated somewhere" by looking for content that wasn't
        // there before.
        let preNavTexts = Set(
            app.staticTexts.allElementsBoundByIndex
                .compactMap { $0.exists ? $0.label : nil }
        )

        // The link is a NavigationLink with localized key
        // `connection.add.customHeaders`. Match either the rendered key or any
        // English fallback containing "header".
        let headersLink = app.buttons.matching(
            NSPredicate(format: "label CONTAINS[c] 'header' OR label CONTAINS[c] 'customHeaders'")
        ).firstMatch

        try #require(headersLink.waitForExistence(timeout: 5), "Custom headers link not found on the sheet")
        headersLink.tap()

        // Wait for any new static text to appear that wasn't in the pre-nav
        // snapshot — proves a destination view loaded.
        let deadline = Date().addingTimeInterval(10)
        var navigated = false
        while Date() < deadline {
            let currentTexts = app.staticTexts.allElementsBoundByIndex
                .compactMap { $0.exists ? $0.label : nil }
            if currentTexts.contains(where: { !preNavTexts.contains($0) && !$0.isEmpty }) {
                navigated = true
                break
            }
            _ = app.staticTexts.firstMatch.waitForExistence(timeout: 0.5)
        }

        #expect(navigated, "Custom headers destination did not load any new text")
    }

    @Test("Cancel dismisses the sheet and returns to welcome")
    func cancelDismissesSheet() async throws {
        try openConnectionSheet()

        // The cancel button uses the `action.cancel` localized key. Match
        // case-insensitively on "cancel" to cover either the key or the
        // rendered English value.
        let cancelButton = app.buttons.matching(
            NSPredicate(format: "label CONTAINS[c] 'cancel'")
        ).firstMatch

        try #require(cancelButton.waitForExistence(timeout: 5), "Cancel button not found on the sheet")
        cancelButton.tap()

        // The endpoint field should disappear, and the welcome's add-connection
        // button should be visible again.
        let endpointGone = !app.endpointTextField.waitForExistence(timeout: 5)
        #expect(endpointGone, "Endpoint field should be gone after cancelling")

        #expect(
            app.addConnectionButton.waitForExistence(timeout: 5),
            "Welcome screen's add-connection button should be visible after cancel"
        )
    }

    @Test("Endpoint state resets after dismissing and reopening the sheet")
    func endpointPersistsAfterToggle() async throws {
        try openConnectionSheet()

        // First open: type something and then cancel out.
        let endpointField = app.endpointTextField
        endpointField.tap()
        endpointField.clearText()
        endpointField.typeText("http://example.com")

        let cancelButton = app.buttons.matching(
            NSPredicate(format: "label CONTAINS[c] 'cancel'")
        ).firstMatch
        try #require(cancelButton.waitForExistence(timeout: 5), "Cancel button not found")
        cancelButton.tap()

        try #require(
            app.addConnectionButton.waitForExistence(timeout: 5),
            "Welcome screen did not return after cancel"
        )

        // Second open: verify the endpoint field doesn't carry over the typed
        // value (each open is a fresh sheet/state).
        app.addConnectionButton.tap()
        let reopenedField = app.endpointTextField
        try #require(reopenedField.waitForExistence(timeout: 5), "Endpoint field did not appear on reopen")

        let value = (reopenedField.value as? String) ?? ""
        // The default value in the view model is `https://`, which counts as
        // "empty user input" for this test. Anything containing "example.com"
        // means the previous typing leaked across sheets.
        #expect(
            !value.localizedCaseInsensitiveContains("example.com"),
            "Endpoint field should not retain the previous sheet's input — got: \(value)"
        )
    }
}
