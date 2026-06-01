import SwiftUI

struct ProfileView: View {
    @Bindable var auth: AuthViewModel

    var body: some View {
        ZStack {
            Theme.background.ignoresSafeArea()

            VStack(spacing: 0) {
                VStack(spacing: 16) {
                    ZStack {
                        Circle()
                            .fill(Theme.surface)
                            .overlay {
                                Circle().stroke(Theme.hairline, lineWidth: 1)
                            }
                            .frame(width: 96, height: 96)
                        Text(auth.username.prefix(1).uppercased())
                            .font(.system(size: 36, weight: .bold, design: .rounded))
                            .foregroundStyle(Theme.accent)
                    }
                    Text("@\(auth.username)")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundStyle(Theme.textPrimary)
                }
                .padding(.top, 60)
                .padding(.bottom, 48)

                Spacer()

                Button { Task { await auth.signOut() } } label: {
                    Text("Sign Out")
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundStyle(Color(red: 0.95, green: 0.45, blue: 0.45))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(Theme.surface)
                        .overlay {
                            RoundedRectangle(cornerRadius: 14, style: .continuous)
                                .stroke(Theme.hairline, lineWidth: 1)
                        }
                        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 32)
            }
        }
        .preferredColorScheme(.dark)
    }
}
