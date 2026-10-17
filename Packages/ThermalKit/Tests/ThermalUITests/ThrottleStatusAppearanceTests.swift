import AppKit
import SwiftUI
import Testing
import ThermalCore

@testable import ThermalUI

@MainActor
struct ThrottleStatusAppearanceTests {
    @Test("Every status uses an SF Symbol that exists", arguments: ThrottleStatusAppearance.allStatuses)
    func symbolExists(status: ThrottleStatus?) {
        let name = ThrottleStatusAppearance(status: status).symbolName
        #expect(NSImage(systemSymbolName: name, accessibilityDescription: nil) != nil, "Missing symbol \(name)")
    }

    @Test("Every status uses a thermometer symbol")
    func thermometerFamily() {
        for status in ThrottleStatusAppearance.allStatuses {
            #expect(ThrottleStatusAppearance(status: status).symbolName.hasPrefix("thermometer."))
        }
    }

    @Test("Every status has its own symbol, colour and wording")
    func distinct() {
        let appearances = ThrottleStatusAppearance.allStatuses.map(ThrottleStatusAppearance.init(status:))
        #expect(Set(appearances.map(\.symbolName)).count == appearances.count)
        #expect(Set(appearances.map(\.tint)).count == appearances.count)
        #expect(Set(appearances.map(\.menuBarAccessibilityLabel)).count == appearances.count)
    }

    @Test(
        "The menu bar label states the status",
        arguments: [
            (ThrottleStatus?.none, "Mac Thermals, status unavailable"),
            (.notThrottled, "Mac Thermals, not throttling"),
            (.throttled(.moderate), "Mac Thermals, throttling slightly"),
            (.throttled(.heavy), "Mac Thermals, throttling significantly"),
            (.throttled(.critical), "Mac Thermals, throttling as much as possible"),
        ]
    )
    func menuBarAccessibilityLabel(status: ThrottleStatus?, expected: String) {
        #expect(ThrottleStatusAppearance(status: status).menuBarAccessibilityLabel == expected)
    }
}
