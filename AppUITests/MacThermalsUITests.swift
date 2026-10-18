import AppKit
import XCTest

/// Drives the built app through its windows and the menu bar panel.
///
/// UI tests use XCTest because Swift Testing can't drive XCUIApplication. The panel tests don't
/// assert a particular throttle status, because the runner's thermal pressure isn't controllable.
@MainActor
final class MacThermalsUITests: XCTestCase {
    private var app: XCUIApplication?

    override func setUp() async {
        continueAfterFailure = false
    }

    override func tearDown() async {
        app?.terminate()
    }

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
        XCTAssertTrue(item.waitForExistence(timeout: 10))
        XCTAssertTrue(item.label.hasPrefix("Mac Thermals, "), "Unexpected label \(item.label)")
    }

    func testPanelShowsSignalsAndClosesWithEscape() {
        let app = launch(hasCompletedWelcome: true)
        openPanel(in: app)
        XCTAssertTrue(element(in: app, labeled: "Thermal pressure").exists)
        XCTAssertTrue(element(in: app, labeled: "System thermal state").exists)
        XCTAssertTrue(app.buttons["Quit Mac Thermals"].exists)

        app.typeKey(.escape, modifierFlags: [])
        XCTAssertTrue(app.buttons["Settings…"].waitForNonExistence(timeout: 5))
    }

    func testPanelOpensSettings() {
        let app = launch(hasCompletedWelcome: true)
        openPanel(in: app)
        app.buttons["Settings…"].click()
        XCTAssertTrue(element(in: app, labeled: "Launch at login").waitForExistence(timeout: 10))
        XCTAssertTrue(element(in: app, labeled: "Version").exists)
    }

    func testOpeningAgainWhileRunningShowsSettings() async throws {
        let app = launch(hasCompletedWelcome: true)
        XCTAssertTrue(statusItem(in: app).waitForExistence(timeout: 10))
        XCTAssertFalse(element(in: app, labeled: "Launch at login").exists)

        let configuration = NSWorkspace.OpenConfiguration()
        configuration.activates = true
        _ = try await NSWorkspace.shared.openApplication(at: appURL(), configuration: configuration)
        XCTAssertTrue(element(in: app, labeled: "Launch at login").waitForExistence(timeout: 10))
    }

    func testQuitButtonQuitsApp() {
        let app = launch(hasCompletedWelcome: true)
        openPanel(in: app)
        app.buttons["Quit Mac Thermals"].click()
        XCTAssertTrue(app.wait(for: .notRunning, timeout: 10))
    }

    // MARK: - Helpers

    /// Launches the app with the welcome flag set through the arguments domain, so the test
    /// doesn't depend on, or change, which window a previous run left behind.
    private func launch(hasCompletedWelcome: Bool) -> XCUIApplication {
        let app = XCUIApplication()
        app.launchArguments = ["-hasCompletedWelcome", hasCompletedWelcome ? "YES" : "NO"]
        app.launch()
        self.app = app
        return app
    }

    private func statusItem(in app: XCUIApplication) -> XCUIElement {
        app.descendants(matching: .statusItem).firstMatch
    }

    private func openPanel(in app: XCUIApplication) {
        let item = statusItem(in: app)
        XCTAssertTrue(item.waitForExistence(timeout: 10))
        item.click()
        XCTAssertTrue(app.buttons["Settings…"].waitForExistence(timeout: 5))
    }

    private func element(in app: XCUIApplication, labeled label: String) -> XCUIElement {
        app.descendants(matching: .any).matching(NSPredicate(format: "label == %@", label)).firstMatch
    }

    /// The app bundle sits next to the UI test runner in the build products directory.
    private func appURL() -> URL {
        let url = Bundle.main.bundleURL.deletingLastPathComponent().appending(path: "Mac Thermals.app")
        XCTAssertTrue(FileManager.default.fileExists(atPath: url.path(percentEncoded: false)), "No app at \(url)")
        return url
    }
}
