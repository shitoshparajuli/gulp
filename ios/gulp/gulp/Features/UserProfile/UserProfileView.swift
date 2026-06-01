import SwiftUI

struct UserProfileView: View {
    let profile: ProfileLite
    @State private var viewModel: UserProfileViewModel

    init(profile: ProfileLite) {
        self.profile = profile
        _viewModel = State(initialValue: UserProfileViewModel(profile: profile))
    }

    var body: some View {
        RatingsView(
            topAccessory: AnyView(hero),
            userId: profile.id,
            readOnly: true
        )
        .toolbarBackground(Theme.background, for: .navigationBar)
        .toolbarBackground(.visible, for: .navigationBar)
        .toolbarColorScheme(.dark, for: .navigationBar)
        .navigationTitle("")
        .navigationBarTitleDisplayMode(.inline)
        .task { await viewModel.load() }
    }

    private var hero: some View {
        VStack(spacing: 14) {
            ZStack {
                Circle()
                    .fill(Theme.surface)
                    .overlay { Circle().stroke(Theme.hairline, lineWidth: 1) }
                    .frame(width: 88, height: 88)
                if let raw = profile.avatarURL, let url = URL(string: raw) {
                    AsyncImage(url: url) { phase in
                        switch phase {
                        case .success(let img):
                            img.resizable().scaledToFill()
                        default:
                            initial
                        }
                    }
                    .frame(width: 88, height: 88)
                    .clipShape(Circle())
                } else {
                    initial
                }
            }

            VStack(spacing: 2) {
                Text(profile.resolvedName)
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundStyle(Theme.textPrimary)
                Text("@\(profile.username)")
                    .font(.system(size: 14))
                    .foregroundStyle(Theme.textTertiary)
            }

            if !viewModel.isOwnProfile {
                followButton
                    .padding(.top, 4)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.top, 12)
        .padding(.bottom, 20)
    }

    private var initial: some View {
        Text(profile.resolvedName.prefix(1).uppercased())
            .font(.system(size: 34, weight: .bold, design: .rounded))
            .foregroundStyle(Theme.accent)
    }

    private var followButton: some View {
        Button {
            Task { await viewModel.toggleFollow() }
        } label: {
            HStack(spacing: 6) {
                Image(systemName: viewModel.isFollowing ? "checkmark" : "plus")
                    .font(.system(size: 12, weight: .bold))
                Text(viewModel.isFollowing ? "Following" : "Follow")
                    .font(.system(size: 14, weight: .semibold))
            }
            .foregroundStyle(viewModel.isFollowing ? Theme.textPrimary : .white)
            .padding(.horizontal, 22)
            .padding(.vertical, 10)
            .background(viewModel.isFollowing ? Theme.surfaceElevated : Theme.accent)
            .clipShape(Capsule())
            .overlay {
                if viewModel.isFollowing {
                    Capsule().stroke(Theme.hairline, lineWidth: 1)
                }
            }
        }
        .buttonStyle(.plain)
    }
}
