import SwiftUI
import GoogleSignInSwift

struct LoginView: View {
    @Bindable var auth: AuthViewModel

    var body: some View {
        VStack(spacing: 24) {
            Spacer()
            Text("Gulp")
                .font(.largeTitle)
                .bold()
            Spacer()
            if let error = auth.errorMessage {
                Text(error)
                    .foregroundStyle(.red)
                    .font(.caption)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
            }
            GoogleSignInButton {
                Task { await auth.signInWithGoogle() }
            }
            .frame(height: 50)
            .padding(.horizontal, 40)
            Spacer()
        }
    }
}
