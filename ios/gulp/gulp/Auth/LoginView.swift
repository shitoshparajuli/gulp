import SwiftUI
import GoogleSignInSwift

struct LoginView: View {
    @Bindable var auth: AuthViewModel

    var body: some View {
        ZStack {
            Theme.background.ignoresSafeArea()

            RadialGradient(
                colors: [Theme.accent.opacity(0.18), .clear],
                center: .topLeading,
                startRadius: 50,
                endRadius: 400
            )
            .ignoresSafeArea()

            VStack(spacing: 0) {
                Spacer()

                VStack(spacing: 16) {
                    Text("gulp")
                        .font(.system(size: 64, weight: .bold, design: .rounded))
                        .foregroundStyle(Theme.textPrimary)
                    Text("Rate every bite.")
                        .font(.system(size: 17, weight: .medium))
                        .foregroundStyle(Theme.textSecondary)
                }

                Spacer()

                VStack(spacing: 16) {
                    if let error = auth.errorMessage {
                        Text(error)
                            .font(.system(size: 13))
                            .foregroundStyle(Color(red: 0.95, green: 0.45, blue: 0.45))
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 24)
                    }

                    GoogleSignInButton(
                        viewModel: GoogleSignInButtonViewModel(
                            scheme: .light,
                            style: .wide,
                            state: .normal
                        )
                    ) {
                        Task { await auth.signInWithGoogle() }
                    }
                    .frame(height: 52)
                    .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                    .padding(.horizontal, 24)
                }
                .padding(.bottom, 56)
            }
        }
        .preferredColorScheme(.dark)
    }
}
