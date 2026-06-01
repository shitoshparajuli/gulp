import SwiftUI

struct ProfileView: View {
    @Bindable var auth: AuthViewModel
    var refreshTrigger: Int = 0
    @State private var showSignOutConfirm = false

    var body: some View {
        RatingsView(
            refreshTrigger: refreshTrigger,
            topAccessory: AnyView(profileHero)
        )
        .confirmationDialog(
            "Sign out of gulp?",
            isPresented: $showSignOutConfirm,
            titleVisibility: .visible
        ) {
            Button("Sign Out", role: .destructive) {
                Task { await auth.signOut() }
            }
            Button("Cancel", role: .cancel) {}
        }
    }

    private var profileHero: some View {
        VStack(spacing: 14) {
            HStack {
                Spacer()
                Menu {
                    Button(role: .destructive) {
                        showSignOutConfirm = true
                    } label: {
                        Label("Sign Out", systemImage: "rectangle.portrait.and.arrow.right")
                    }
                } label: {
                    Image(systemName: "ellipsis")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundStyle(Theme.textSecondary)
                        .frame(width: 36, height: 36)
                        .background(Theme.surfaceElevated)
                        .clipShape(Circle())
                }
            }
            .padding(.horizontal, 20)

            ZStack {
                Circle()
                    .fill(Theme.surface)
                    .overlay { Circle().stroke(Theme.hairline, lineWidth: 1) }
                    .frame(width: 88, height: 88)
                Text(auth.username.prefix(1).uppercased())
                    .font(.system(size: 34, weight: .bold, design: .rounded))
                    .foregroundStyle(Theme.accent)
            }
            Text("@\(auth.username)")
                .font(.system(size: 18, weight: .semibold))
                .foregroundStyle(Theme.textPrimary)
        }
        .padding(.top, 12)
        .padding(.bottom, 20)
        .frame(maxWidth: .infinity)
    }
}
