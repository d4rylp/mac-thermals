import Foundation
import Testing

/// Checks the built app bundle's configuration, which comes from project.yml.
struct AppBundleTests {
    @Test("The app is a menu bar agent without a Dock icon")
    func isAgent() {
        #expect(Bundle.main.object(forInfoDictionaryKey: "LSUIElement") as? Bool == true)
    }

    @Test("The bundle identifier is stable")
    func bundleIdentifier() {
        #expect(Bundle.main.bundleIdentifier == "io.github.d4rylp.MacThermals")
    }

    @Test("The product is named Mac Thermals")
    func name() {
        #expect(Bundle.main.object(forInfoDictionaryKey: "CFBundleName") as? String == "Mac Thermals")
    }

    @Test("The deployment target is macOS 27")
    func deploymentTarget() {
        #expect(Bundle.main.object(forInfoDictionaryKey: "LSMinimumSystemVersion") as? String == "27.0")
    }

    @Test("The app has a version")
    func version() throws {
        let version = try #require(Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String)
        #expect(!version.isEmpty)
    }
}
