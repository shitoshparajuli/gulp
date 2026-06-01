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

                    Button { Task { await auth.signInWithGoogle() } } label: {
                        HStack(spacing: 10) {
                            Image(systemName: "g.circle.fill")
                                .font(.system(size: 18, weight: .semibold))
                            Text("Continue with Google")
                                .font(.system(size: 16, weight: .semibold))
                        }
                        .foregroundStyle(.black)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(.white)
                        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                    }
                    .padding(.horizontal, 24)
                }
                .padding(.bottom, 56)
            }
        }
        .preferredColorScheme(.dark)
    }
}
