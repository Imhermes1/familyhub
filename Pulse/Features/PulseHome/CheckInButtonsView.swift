import SwiftUI

struct CheckInButtonsView: View {
    let onCheckIn: (StatusType) -> Void
    let glassVariant: Glass

    var body: some View {
        GlassEffectContainer {
            HStack(spacing: 12) {
                // Primary: I am here
                Button {
                    onCheckIn(.arrived)
                } label: {
                    VStack(spacing: 6) {
                        Image(systemName: "location.fill")
                            .font(.title2)
                        Text("I am here")
                            .font(.caption)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                }
                .buttonStyle(.glassProminent)
                .tint(.green)

                // Secondary: Leaving
                Button {
                    onCheckIn(.leaving)
                } label: {
                    VStack(spacing: 6) {
                        Image(systemName: "arrow.right.circle.fill")
                            .font(.title2)
                        Text("Leaving")
                            .font(.caption)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                }
                .buttonStyle(.glass)

                // Secondary: On my way
                Button {
                    onCheckIn(.onTheWay)
                } label: {
                    VStack(spacing: 6) {
                        Image(systemName: "car.fill")
                            .font(.title2)
                        Text("On my way")
                            .font(.caption)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                }
                .buttonStyle(.glass)
            }
        }
    }
}

#Preview {
    CheckInButtonsView(
        onCheckIn: { type in
            print("Check in: \(type)")
        },
        glassVariant: .regular
    )
    .padding()
}
