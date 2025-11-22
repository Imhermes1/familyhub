import SwiftUI

struct ManualCheckInSheet: View {
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var dataManager: PulseDataManager
    @State private var selectedType: StatusType = .arrived
    @State private var locationNote = ""

    var body: some View {
        NavigationStack {
            Form {
                Section("Status") {
                    Picker("Type", selection: $selectedType) {
                        Text("I am here").tag(StatusType.arrived)
                        Text("Leaving").tag(StatusType.leaving)
                        Text("On my way").tag(StatusType.onTheWay)
                    }
                    .pickerStyle(.segmented)
                }

                Section("Location (Optional)") {
                    TextField("e.g., Home, Work, School", text: $locationNote)
                }

                Section {
                    Button {
                        checkIn()
                    } label: {
                        Text("Check In")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.glassProminent)
                }
            }
            .navigationTitle("Manual Check-In")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
        }
    }

    private func checkIn() {
        Task {
            try? await dataManager.checkIn(
                type: selectedType,
                trigger: .manual,
                locationName: locationNote.isEmpty ? nil : locationNote
            )
            dismiss()
        }
    }
}

#Preview {
    ManualCheckInSheet()
        .environmentObject(PulseDataManager.shared)
}
