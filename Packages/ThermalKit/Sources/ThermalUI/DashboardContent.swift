import AppKit
import SwiftUI
import ThermalCore

/// The panel's layout, built from plain values so every status can be previewed.
struct DashboardContent: View {
    let assessment: ThrottleAssessment
    let pressureLevel: ThermalPressureLevel?
    let thermalState: ThermalStateLevel?

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            StatusHeadline(assessment: assessment)
            Divider()
            SignalRows(pressureLevel: pressureLevel, thermalState: thermalState)
            Divider()
            DashboardFooter()
        }
        .padding()
        .frame(width: 340, alignment: .leading)
    }
}

/// The throttle status: the most important information, first and largest.
private struct StatusHeadline: View {
    let assessment: ThrottleAssessment

    var body: some View {
        let appearance = ThrottleStatusAppearance(status: assessment.status)
        HStack(alignment: .firstTextBaseline, spacing: 10) {
            Image(systemName: appearance.symbolName)
                .font(.title)
                .foregroundStyle(appearance.tint)
                .accessibilityHidden(true)
            VStack(alignment: .leading, spacing: 4) {
                Text(assessment.title)
                    .font(.title)
                    .fontWeight(.semibold)
                Text(assessment.explanation)
                    .font(.body)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .accessibilityElement(children: .combine)
        .accessibilityAddTraits(.isHeader)
    }
}

/// The raw signals behind the headline.
private struct SignalRows: View {
    let pressureLevel: ThermalPressureLevel?
    let thermalState: ThermalStateLevel?

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            SignalRow(value: pressureLevel?.localizedName) {
                Text("Thermal pressure", bundle: .module, comment: "Dashboard row label for the thermal pressure level")
            }
            SignalRow(value: thermalState?.localizedName) {
                Text("System thermal state", bundle: .module, comment: "Dashboard row label for the ProcessInfo state")
            }
        }
        .font(.callout)
        .accessibilityElement(children: .contain)
    }
}

/// One labelled signal; a signal macOS hasn't reported reads "Not available".
private struct SignalRow<RowLabel: View>: View {
    let value: String?
    @ViewBuilder let label: RowLabel

    var body: some View {
        LabeledContent {
            if let value {
                Text(value)
            } else {
                Text("Not available", bundle: .module, comment: "Value of a signal macOS isn't reporting")
            }
        } label: {
            label
        }
        .accessibilityElement(children: .combine)
    }
}

/// Settings and Quit.
private struct DashboardFooter: View {
    @Environment(\.openSettings) private var openSettings

    var body: some View {
        HStack {
            Button {
                NSApplication.shared.activate()
                openSettings()
            } label: {
                Text("Settings…", bundle: .module, comment: "Dashboard button that opens the Settings window")
            }
            .keyboardShortcut(",", modifiers: .command)
            Spacer()
            Button {
                NSApplication.shared.terminate(nil)
            } label: {
                Text("Quit Mac Thermals", bundle: .module, comment: "Dashboard button that quits the app")
            }
            .keyboardShortcut("q", modifiers: .command)
        }
    }
}

@MainActor
private func preview(_ pressureLevel: ThermalPressureLevel?, _ thermalState: ThermalStateLevel?) -> some View {
    let evidence: [(any ThrottleEvidence)?] = [pressureLevel, thermalState]
    return DashboardContent(
        assessment: ThrottleAssessment(evidence: evidence.compactMap(\.self)),
        pressureLevel: pressureLevel,
        thermalState: thermalState
    )
}

#Preview("Nominal, light") { preview(.nominal, .nominal).preferredColorScheme(.light) }
#Preview("Nominal, dark") { preview(.nominal, .nominal).preferredColorScheme(.dark) }
#Preview("Moderate, light") { preview(.moderate, .fair).preferredColorScheme(.light) }
#Preview("Moderate, dark") { preview(.moderate, .fair).preferredColorScheme(.dark) }
#Preview("Heavy, light") { preview(.heavy, .fair).preferredColorScheme(.light) }
#Preview("Heavy, dark") { preview(.heavy, .fair).preferredColorScheme(.dark) }
#Preview("Trapping, light") { preview(.trapping, .serious).preferredColorScheme(.light) }
#Preview("Trapping, dark") { preview(.trapping, .serious).preferredColorScheme(.dark) }
#Preview("Sleeping, light") { preview(.sleeping, .critical).preferredColorScheme(.light) }
#Preview("Sleeping, dark") { preview(.sleeping, .critical).preferredColorScheme(.dark) }
#Preview("Unknown pressure, light") { preview(.unknown(rawState: 7), .serious).preferredColorScheme(.light) }
#Preview("Unknown pressure, dark") { preview(.unknown(rawState: 7), .serious).preferredColorScheme(.dark) }
#Preview("Not available, light") { preview(nil, nil).preferredColorScheme(.light) }
#Preview("Not available, dark") { preview(nil, nil).preferredColorScheme(.dark) }
