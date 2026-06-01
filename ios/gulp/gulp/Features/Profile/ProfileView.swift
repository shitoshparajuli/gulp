import SwiftUI
import Supabase

struct ProfileView: View {
    @Bindable var auth: AuthViewModel
    var refreshTrigger: Int = 0
    @State private var showSignOutConfirm = false
    @State private var followingCount: Int = 0

    var body: some View {
        RatingsView(
            refreshTrigger: refreshTrigger,
            topAccessory: AnyView(profileHero)
        )
        .toolbar(.hidden, for: .navigationBar)
        .task(id: refreshTrigger) { await loadFollowingCount() }
        .onAppear { Task { await loadFollowingCount() } }
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

            NavigationLink {
                FollowingListView()
            } label: {
                HStack(spacing: 6) {
                    Text("\(followingCount)")
                        .font(.system(size: 14, weight: .bold, design: .rounded))
                        .foregroundStyle(Theme.textPrimary)
                    Text("following")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundStyle(Theme.textSecondary)
                    Image(systemName: "chevron.right")
                        .font(.system(size: 10, weight: .bold))
                        .foregroundStyle(Theme.textTertiary)
                }
                .padding(.horizontal, 14)
                .padding(.vertical, 7)
                .background(Theme.surfaceElevated)
                .overlay { Capsule().stroke(Theme.hairline, lineWidth: 1) }
                .clipShape(Capsule())
            }
            .buttonStyle(.plain)
        }
        .padding(.top, 12)
        .padding(.bottom, 20)
        .frame(maxWidth: .infinity)
    }

    private func loadFollowingCount() async {
        struct Row: Decodable { let followee_id: UUID }
        do {
            let me = try await supabase.auth.session.user.id
            let rows: [Row] = try await supabase
                .from("follows")
                .select("followee_id")
                .eq("follower_id", value: me)
                .execute()
                .value
            followingCount = rows.count
        } catch {
            // silent: chip just shows 0
        }
    }
}
