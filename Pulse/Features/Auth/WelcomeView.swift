import SwiftUI

struct WelcomeView: View {
    @State private var email = ""
    @State private var isLoading = false

    var body: some View {
        VStack(spacing: 32) {
            Spacer()

            VStack(spacing: 16) {
                Image(systemName: "waveform.path.ecg")
                    .font(.system(size: 64))
                    .foregroundStyle(.blue)

                Text("Pulse")
                    .font(.largeTitle)
                    .fontWeight(.bold)

                Text("Stay connected with family and friends")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }

            Spacer()

            VStack(spacing: 16) {
                TextField("Email", text: $email)
                    .textFieldStyle(.roundedBorder)
                    .textContentType(.emailAddress)
                    .keyboardType(.emailAddress)
                    .autocapitalization(.none)

                Button {
                    signIn()
                } label: {
                    Text(isLoading ? "Sending..." : "Get Started")
                        .frame(maxWidth: .infinity)
                        .padding()
                }
                .buttonStyle(.glassProminent)
                .tint(.blue)
                .disabled(email.isEmpty || isLoading)
            }
            .padding(.horizontal, 32)
            .padding(.bottom, 48)
        }
    }

    private func signIn() {
        isLoading = true
        Task {
            // TODO: Implement sign in
            // try await PulseDataManager.shared.signIn(email: email)
            isLoading = false
        }
    }
}

#Preview {
    WelcomeView()
}
