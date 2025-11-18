import SwiftUI

struct CurrentModeCard: View {
    let automationEnabled: Bool
    let manualOnlyMode: Bool
    let glassVariant: Glass

    var modeText: String {
        if manualOnlyMode {
            return "Manual Only"
        } else if automationEnabled {
            return "Auto Updates: Active"
        } else {
            return "Manual Mode"
        }
    }

    var modeIcon: String {
        if manualOnlyMode {
            return "hand.raised.fill"
        } else if automationEnabled {
            return "bolt.fill"
        } else {
            return "hand.tap.fill"
        }
    }

    var modeColor: Color {
        if manualOnlyMode {
            return .orange
        } else if automationEnabled {
            return .green
        } else {
            return .blue
        }
    }

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: modeIcon)
                .font(.title)
                .foregroundStyle(modeColor)

            VStack(alignment: .leading, spacing: 4) {
                Text(modeText)
                    .font(.headline)

                Text("Tap settings below to customize")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()
        }
        .padding()
        .glassEffect(glassVariant.tint(modeColor))
    }
}

#Preview {
    VStack(spacing: 16) {
        CurrentModeCard(
            automationEnabled: true,
            manualOnlyMode: false,
            glassVariant: .regular
        )

        CurrentModeCard(
            automationEnabled: false,
            manualOnlyMode: true,
            glassVariant: .regular
        )

        CurrentModeCard(
            automationEnabled: false,
            manualOnlyMode: false,
            glassVariant: .regular
        )
    }
    .padding()
}
