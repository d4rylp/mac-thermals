import AppKit
import XCTest

/// Drives the built app through its windows and the menu bar panel.
///
/// UI tests use XCTest because Swift Testing can't drive XCUIApplication. The panel tests don't
/// assert a particular throttle status, because the runner's thermal pressure isn't controllable.
@MainActor
final class MacThermalsUITests: XCTestCase {
    func testFirstLaunchShowsWelcomeWindowUntilContinue() {
        let app = launch(hasCompletedWelcome: false)
        let continueButton = app.buttons["Continue"]
        XCTAssertTrue(continueButton.waitForExistence(timeout: 10))
        XCTAssertTrue(element(in: app, labeled: "Welcome to Mac Thermals").exists)
        XCTAssertTrue(element(in: app, labeled: "Launch at login").exists)

        continueButton.click()
        XCTAssertTrue(continueButton.waitForNonExistence(timeout: 5))
    }

    func testLaterLaunchesSkipWelcomeWindow() {
        let app = launch(hasCompletedWelcome: true)
        XCTAssertTrue(statusItem(in: app).waitForExistence(timeout: 10))
        XCTAssertFalse(app.buttons["Continue"].exists)
    }

    func testStatusItemStatesStatus() {
        let app = launch(hasCompletedWelcome: true)
        let item = statusItem(in: app)
        assertAppears(item, in: app)
        // A status item exposes its accessibility label to XCTest as its title.
        XCTAssertTrue(item.title.hasPrefix("Mac Thermals, "), "Unexpected title \(item.title)")
    }

    func testPanelShowsSignalsAndClosesWithEscape() {
        let app = launch(hasCompletedWelcome: true)
        openPanel(in: app)
        assertAppears(element(in: app, labeled: "Thermal pressure"), in: app)
        assertAppears(element(in: app, labeled: "System thermal state"), in: app)
        assertAppears(app.buttons["Quit Mac Thermals"], in: app)

        app.typeKey(.escape, modifierFlags: [])
        XCTAssertTrue(app.buttons["Settings…"].waitForNonExistence(timeout: 5))
    }

    func testPanelOpensSettings() {
        let app = launch(hasCompletedWelcome: true)
        openPanel(in: app)
        app.buttons["Settings…"].click()
        assertAppears(element(in: app, labeled: "Launch at login"), in: app)
        assertAppears(element(in: app, labeled: "Version"), in: app)
    }

    func testOpeningAgainWhileRunningShowsSettings() {
        let app = launch(hasCompletedWelcome: true)
        XCTAssertTrue(statusItem(in: app).waitForExistence(timeout: 10))
        XCTAssertFalse(element(in: app, labeled: "Launch at login").exists)

        let configuration = NSWorkspace.OpenConfiguration()
        configuration.activates = true
        NSWorkspace.shared.openApplication(at: appURL(), configuration: configuration, completionHandler: nil)
        assertAppears(element(in: app, labeled: "Launch at login"), in: app)
    }

    func testQuitButtonQuitsApp() {
        let app = launch(hasCompletedWelcome: true)
        openPanel(in: app)
        app.buttons["Quit Mac Thermals"].click()
        XCTAssertTrue(app.wait(for: .notRunning, timeout: 10))
    }

    // MARK: - Helpers

    /// Launches the app with the welcome flag set through the arguments domain, so the test
    /// doesn't depend on, or change, which window a previous run left behind. Launching also
    /// terminates any instance an earlier test left running.
    private func launch(hasCompletedWelcome: Bool) -> XCUIApplication {
        continueAfterFailure = false
        let app = XCUIApplication()
        app.launchArguments = ["-hasCompletedWelcome", hasCompletedWelcome ? "YES" : "NO"]
        app.launch()
        return app
    }

    private func statusItem(in app: XCUIApplication) -> XCUIElement {
        app.descendants(matching: .statusItem).firstMatch
    }

    private func openPanel(in app: XCUIApplication) {
        let item = statusItem(in: app)
        assertAppears(item, in: app)
        item.click()
        assertAppears(app.buttons["Settings…"], in: app)
    }

    /// Finds an element whose label or title starts with the given text. Combined accessibility
    /// elements, such as a labelled row, append their value to the label.
    private func element(in app: XCUIApplication, labeled label: String) -> XCUIElement {
        let predicate = NSPredicate(format: "label BEGINSWITH %@ OR title BEGINSWITH %@", label, label)
        return app.descendants(matching: .any).matching(predicate).firstMatch
    }

    /// Waits for an element and, if it never appears, fails with the app's accessibility hierarchy
    /// so the log shows what was on screen instead.
    private func assertAppears(
        _ element: XCUIElement,
        in app: XCUIApplication,
        file: StaticString = #filePath,
        line: UInt = #line
    ) {
        if !element.waitForExistence(timeout: 10) {
            XCTFail("\(element) didn't appear. Hierarchy:\n\(app.debugDescription)", file: file, line: line)
        }
    }

    /// The app bundle sits next to the UI test runner in the build products directory.
    private func appURL() -> URL {
        let url = Bundle.main.bundleURL.deletingLastPathComponent().appending(path: "Mac Thermals.app")
        XCTAssertTrue(FileManager.default.fileExists(atPath: url.path(percentEncoded: false)), "No app at \(url)")
        return url
    }
}
