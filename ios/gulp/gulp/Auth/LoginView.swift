import SwiftUI
import GoogleSignIn

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

                VStack(spacing: 24) {
                    Image("GulpLogo")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 100, height: 100)
                        .shadow(color: Theme.accent.opacity(0.4), radius: 24, x: 0, y: 8)
                    VStack(spacing: 8) {
                        Text("gulp")
                            .font(.system(size: 48, weight: .bold, design: .rounded))
                            .foregroundStyle(Theme.textPrimary)
                        Text("Rate every bite.")
                            .font(.system(size: 17, weight: .medium))
                            .foregroundStyle(Theme.textSecondary)
                    }
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
                            GoogleGLogo()
                                .frame(width: 18, height: 18)
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

private struct GoogleGLogo: View {
    var body: some View {
        if let image = Self.image {
            Image(uiImage: image)
                .resizable()
                .scaledToFit()
        }
    }

    private static let image: UIImage? = {
        let sdkBundle = Bundle(for: GIDSignIn.self)
        if let path = sdkBundle.path(forResource: "GoogleSignIn_GoogleSignIn", ofType: "bundle"),
           let resourceBundle = Bundle(path: path),
           let img = UIImage(named: "google", in: resourceBundle, compatibleWith: nil) {
            return img
        }
        if let mainPath = Bundle.main.path(forResource: "GoogleSignIn_GoogleSignIn", ofType: "bundle"),
           let resourceBundle = Bundle(path: mainPath),
           let img = UIImage(named: "google", in: resourceBundle, compatibleWith: nil) {
            return img
        }
        return UIImage(named: "google", in: sdkBundle, compatibleWith: nil)
    }()
}
