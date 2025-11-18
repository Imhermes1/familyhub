import SwiftUI

struct GroupJoinView: View {
    @EnvironmentObject var dataManager: PulseDataManager
    @State private var inviteCode = ""
    @State private var groupName = ""
    @State private var showCreateGroup = false
    @State private var isJoining = false

    var body: some View {
        NavigationStack {
            VStack(spacing: 32) {
                VStack(spacing: 16) {
                    Text("Join Your Group")
                        .font(.title)
                        .fontWeight(.bold)

                    Text("Enter an invite code to join a group, or create your own")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                }
                .padding(.top, 48)

                VStack(spacing: 16) {
                    TextField("Invite Code", text: $inviteCode)
                        .textFieldStyle(.roundedBorder)
                        .textContentType(.oneTimeCode)
                        .autocapitalization(.allCharacters)

                    Button {
                        joinGroup()
                    } label: {
                        Text(isJoining ? "Joining..." : "Join Group")
                            .frame(maxWidth: .infinity)
                            .padding()
                    }
                    .buttonStyle(.glassProminent)
                    .disabled(inviteCode.isEmpty || isJoining)

                    Divider()
                        .padding(.vertical)

                    Button {
                        showCreateGroup = true
                    } label: {
                        Text("Create New Group")
                            .frame(maxWidth: .infinity)
                            .padding()
                    }
                    .buttonStyle(.glass)
                }
                .padding(.horizontal, 32)

                Spacer()
            }
            .sheet(isPresented: $showCreateGroup) {
                CreateGroupSheet()
            }
        }
    }

    private func joinGroup() {
        isJoining = true
        Task {
            do {
                try await dataManager.joinGroup(inviteCode: inviteCode.uppercased())
            } catch {
                print("Failed to join group: \(error)")
            }
            isJoining = false
        }
    }
}

struct CreateGroupSheet: View {
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var dataManager: PulseDataManager
    @State private var groupName = ""

    var body: some View {
        NavigationStack {
            Form {
                TextField("Group Name", text: $groupName)
            }
            .navigationTitle("Create Group")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button("Create") {
                        createGroup()
                    }
                    .disabled(groupName.isEmpty)
                }
            }
        }
    }

    private func createGroup() {
        Task {
            try? await dataManager.createGroup(name: groupName)
            dismiss()
        }
    }
}

#Preview {
    GroupJoinView()
        .environmentObject(PulseDataManager.shared)
}
