import SwiftUI

struct ProfileSetupView: View {
    @EnvironmentObject var dataManager: PulseDataManager
    @State private var displayName = ""
    @State private var selectedEmoji = "👤"
    @State private var isCreatingProfile = false

    let emojiOptions = ["👤", "👨", "👩", "👶", "👦", "👧", "🧑", "👴", "👵"]

    var body: some View {
        NavigationStack {
            Form {
                Section("Profile") {
                    TextField("Display Name", text: $displayName)

                    Picker("Emoji", selection: $selectedEmoji) {
                        ForEach(emojiOptions, id: \.self) { emoji in
                            Text(emoji).tag(emoji)
                        }
                    }
                    .pickerStyle(.segmented)
                }

                Section {
                    Button {
                        createProfile()
                    } label: {
                        Text(isCreatingProfile ? "Creating..." : "Continue")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.glassProminent)
                    .disabled(displayName.isEmpty || isCreatingProfile)
                }
            }
            .navigationTitle("Set Up Profile")
            .navigationBarTitleDisplayMode(.large)
        }
    }

    private func createProfile() {
        isCreatingProfile = true
        Task {
            do {
                try await dataManager.createUserProfile(displayName: displayName, emoji: selectedEmoji)
                // Navigate to group join/create
            } catch {
                print("Failed to create profile: \(error)")
            }
            isCreatingProfile = false
        }
    }
}

#Preview {
    ProfileSetupView()
        .environmentObject(PulseDataManager.shared)
}
