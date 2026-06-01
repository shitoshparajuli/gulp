import SwiftUI

struct FollowingListView: View {
    @State private var viewModel = FollowingViewModel()
    @State private var pendingUnfollow: ProfileLite?

    var body: some View {
        ZStack {
            Theme.background.ignoresSafeArea()

            ScrollView {
                VStack(alignment: .leading, spacing: 0) {
                    if viewModel.isLoading && viewModel.profiles.isEmpty {
                        loading
                    } else if viewModel.profiles.isEmpty {
                        emptyState
                    } else {
                        VStack(alignment: .leading, spacing: 0) {
                            ForEach(Array(viewModel.profiles.enumerated()), id: \.element.id) { index, profile in
                                FollowingRow(
                                    profile: profile,
                                    onUnfollow: { pendingUnfollow = profile }
                                )
                                if index < viewModel.profiles.count - 1 {
                                    Rectangle()
                                        .fill(Theme.hairline)
                                        .frame(height: 1)
                                        .padding(.leading, 70)
                                }
                            }
                        }
                        .padding(.top, 4)
                        .padding(.bottom, 40)
                    }
                }
            }
            .refreshable { await viewModel.load() }
        }
        .preferredColorScheme(.dark)
        .navigationTitle("Following")
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(Theme.background, for: .navigationBar)
        .toolbarBackground(.visible, for: .navigationBar)
        .toolbarColorScheme(.dark, for: .navigationBar)
        .task { await viewModel.load() }
        .confirmationDialog(
            pendingUnfollow.map { "Unfollow @\($0.username)?" } ?? "",
            isPresented: .init(
                get: { pendingUnfollow != nil },
                set: { if !$0 { pendingUnfollow = nil } }
            ),
            titleVisibility: .visible
        ) {
            Button("Unfollow", role: .destructive) {
                if let profile = pendingUnfollow {
                    Task { await viewModel.unfollow(profile) }
                }
                pendingUnfollow = nil
            }
            Button("Cancel", role: .cancel) {
                pendingUnfollow = nil
            }
        }
    }

    private var loading: some View {
        ProgressView()
            .tint(Theme.textSecondary)
            .frame(maxWidth: .infinity)
            .padding(.top, 100)
    }

    private var emptyState: some View {
        VStack(spacing: 14) {
            ZStack {
                Circle()
                    .fill(Theme.surface)
                    .frame(width: 72, height: 72)
                Image(systemName: "person.2.fill")
                    .font(.system(size: 28, weight: .medium))
                    .foregroundStyle(Theme.accent)
            }
            Text("Not following anyone yet")
                .font(.system(size: 18, weight: .semibold))
                .foregroundStyle(Theme.textPrimary)
            Text("Find people to follow from Home.")
                .font(.system(size: 14))
                .foregroundStyle(Theme.textSecondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.top, 100)
    }
}

private struct FollowingRow: View {
    let profile: ProfileLite
    let onUnfollow: () -> Void

    var body: some View {
        HStack(spacing: 14) {
            NavigationLink {
                UserProfileView(profile: profile)
            } label: {
                HStack(spacing: 14) {
                    Avatar(profile: profile, size: 44)
                    VStack(alignment: .leading, spacing: 2) {
                        Text(profile.resolvedName)
                            .font(.system(size: 15, weight: .semibold))
                            .foregroundStyle(Theme.textPrimary)
                            .lineLimit(1)
                        Text("@\(profile.username)")
                            .font(.system(size: 12))
                            .foregroundStyle(Theme.textTertiary)
                            .lineLimit(1)
                    }
                    Spacer(minLength: 8)
                }
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)

            Button(action: onUnfollow) {
                Text("Following")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(Theme.textPrimary)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 7)
                    .background(Theme.surfaceElevated)
                    .overlay { Capsule().stroke(Theme.hairline, lineWidth: 1) }
                    .clipShape(Capsule())
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 12)
    }
}
