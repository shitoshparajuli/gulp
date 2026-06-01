import SwiftUI

struct HomeView: View {
    var refreshTrigger: Int = 0
    @State private var viewModel = HomeViewModel()

    var body: some View {
        ZStack {
            Theme.background.ignoresSafeArea()

            ScrollView {
                VStack(alignment: .leading, spacing: 0) {
                    header
                        .padding(.horizontal, 20)
                        .padding(.top, 12)
                        .padding(.bottom, 22)

                    if viewModel.isLoading && viewModel.feed.isEmpty && viewModel.suggestions.isEmpty {
                        loadingState
                    } else if viewModel.feed.isEmpty {
                        emptyState
                    } else {
                        LazyVStack(spacing: 22) {
                            ForEach(viewModel.feed) { item in
                                FeedCard(item: item)
                            }
                        }
                        .padding(.horizontal, 18)
                        .padding(.top, 4)
                        .padding(.bottom, 40)
                    }
                }
            }
            .refreshable { await viewModel.load() }
        }
        .preferredColorScheme(.dark)
        .task(id: refreshTrigger) { await viewModel.load() }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("Home")
                .font(.system(size: 34, weight: .bold))
                .foregroundStyle(Theme.textPrimary)
            Text("What your friends are eating")
                .font(.system(size: 14, weight: .medium))
                .foregroundStyle(Theme.textTertiary)
        }
    }

    private var loadingState: some View {
        ProgressView()
            .tint(Theme.textSecondary)
            .frame(maxWidth: .infinity)
            .padding(.top, 100)
    }

    private var emptyState: some View {
        VStack(spacing: 28) {
            VStack(spacing: 14) {
                ZStack {
                    Circle()
                        .fill(Theme.surface)
                        .frame(width: 72, height: 72)
                    Image(systemName: "person.2.fill")
                        .font(.system(size: 28, weight: .medium))
                        .foregroundStyle(Theme.accent)
                }
                Text("Your feed is empty")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundStyle(Theme.textPrimary)
                Text("Follow people to see their bites.")
                    .font(.system(size: 14))
                    .foregroundStyle(Theme.textSecondary)
            }
            .padding(.top, 60)

            if !viewModel.suggestions.isEmpty {
                VStack(alignment: .leading, spacing: 0) {
                    Text("SUGGESTED")
                        .font(.system(size: 10, weight: .heavy))
                        .tracking(1.2)
                        .foregroundStyle(Theme.textTertiary)
                        .padding(.horizontal, 18)
                        .padding(.top, 16)
                        .padding(.bottom, 10)

                    ForEach(Array(viewModel.suggestions.enumerated()), id: \.element.id) { index, profile in
                        SuggestionRow(
                            profile: profile,
                            isFollowing: viewModel.followingIds.contains(profile.id),
                            onToggle: {
                                Task {
                                    if viewModel.followingIds.contains(profile.id) {
                                        await viewModel.unfollow(profile)
                                    } else {
                                        await viewModel.follow(profile)
                                    }
                                }
                            }
                        )
                        if index < viewModel.suggestions.count - 1 {
                            Rectangle()
                                .fill(Theme.hairline)
                                .frame(height: 1)
                                .padding(.leading, 18)
                        }
                    }
                    Spacer().frame(height: 8)
                }
                .elevatedCard(cornerRadius: 20)
                .padding(.horizontal, 18)
            }
        }
        .padding(.bottom, 80)
    }
}

struct FeedCard: View {
    let item: FeedItem

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            if let photoPath = item.rating.photoPath,
               let url = dishPhotoURL(path: photoPath) {
                AsyncImage(url: url) { phase in
                    switch phase {
                    case .success(let image):
                        image.resizable().scaledToFill()
                    case .failure:
                        Theme.surface
                    case .empty:
                        Theme.surface
                    @unknown default:
                        Theme.surface
                    }
                }
                .frame(maxWidth: .infinity)
                .frame(height: 240)
                .clipped()
            }

            VStack(alignment: .leading, spacing: 16) {
                userRow
                contentRow
                if let notes = item.rating.notes, !notes.isEmpty {
                    Text(notes)
                        .font(.system(size: 14))
                        .foregroundStyle(Theme.textSecondary)
                        .lineLimit(4)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
            .padding(.horizontal, 18)
            .padding(.top, 16)
            .padding(.bottom, 18)
        }
        .elevatedCard(cornerRadius: 20)
    }

    private var userRow: some View {
        HStack(spacing: 10) {
            Avatar(profile: item.profile, size: 34)
            VStack(alignment: .leading, spacing: 1) {
                Text(item.profile.resolvedName)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(Theme.textPrimary)
                Text("@\(item.profile.username) · \(timeAgo(item.rating.createdAt))")
                    .font(.system(size: 11))
                    .foregroundStyle(Theme.textTertiary)
            }
            Spacer()
        }
    }

    private var contentRow: some View {
        HStack(alignment: .center, spacing: 16) {
            VStack(alignment: .leading, spacing: 6) {
                Text(item.rating.dish.restaurant.name.uppercased())
                    .font(.system(size: 11, weight: .heavy))
                    .tracking(1.1)
                    .foregroundStyle(Theme.textTertiary)
                    .lineLimit(1)
                Text(item.rating.dish.displayName)
                    .font(.system(size: 19, weight: .semibold))
                    .foregroundStyle(Theme.textPrimary)
                    .lineLimit(2)
                if let address = item.rating.dish.restaurant.address {
                    HStack(spacing: 4) {
                        Image(systemName: "mappin.and.ellipse")
                            .font(.system(size: 10, weight: .semibold))
                            .foregroundStyle(Theme.accent.opacity(0.85))
                        Text(address)
                            .font(.system(size: 11, weight: .medium))
                            .foregroundStyle(Theme.textSecondary)
                            .lineLimit(1)
                    }
                }
            }
            Spacer(minLength: 8)
            if let score = item.rating.score {
                VStack(spacing: -2) {
                    Text("\(score)")
                        .font(.system(size: 46, weight: .bold, design: .rounded))
                        .foregroundStyle(scoreGradient(Double(score)))
                        .shadow(color: scoreColor(Double(score)).opacity(0.35), radius: 14, x: 0, y: 0)
                    Text("/ 10")
                        .font(.system(size: 10, weight: .heavy))
                        .tracking(0.8)
                        .foregroundStyle(Theme.textTertiary)
                }
            }
        }
    }
}

struct SuggestionRow: View {
    let profile: ProfileLite
    let isFollowing: Bool
    let onToggle: () -> Void

    var body: some View {
        HStack(spacing: 12) {
            Avatar(profile: profile, size: 38)
            VStack(alignment: .leading, spacing: 2) {
                Text(profile.resolvedName)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(Theme.textPrimary)
                    .lineLimit(1)
                Text("@\(profile.username)")
                    .font(.system(size: 12))
                    .foregroundStyle(Theme.textTertiary)
                    .lineLimit(1)
            }
            Spacer()
            Button(action: onToggle) {
                Text(isFollowing ? "Following" : "Follow")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(isFollowing ? Theme.textSecondary : .white)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 7)
                    .background(isFollowing ? Theme.surfaceElevated : Theme.accent)
                    .clipShape(Capsule())
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 18)
        .padding(.vertical, 12)
    }
}

struct Avatar: View {
    let profile: ProfileLite
    var size: CGFloat = 32

    var body: some View {
        ZStack {
            Circle()
                .fill(Theme.surface)
                .overlay {
                    Circle().stroke(Theme.hairline, lineWidth: 1)
                }
            if let raw = profile.avatarURL, let url = URL(string: raw) {
                AsyncImage(url: url) { phase in
                    switch phase {
                    case .success(let img):
                        img.resizable().scaledToFill()
                    default:
                        initial
                    }
                }
                .clipShape(Circle())
            } else {
                initial
            }
        }
        .frame(width: size, height: size)
    }

    private var initial: some View {
        Text(String(profile.resolvedName.prefix(1).uppercased()))
            .font(.system(size: size * 0.42, weight: .bold, design: .rounded))
            .foregroundStyle(Theme.accent)
    }
}

private func timeAgo(_ date: Date) -> String {
    let interval = Date().timeIntervalSince(date)
    if interval < 60 { return "now" }
    if interval < 3600 { return "\(Int(interval / 60))m" }
    if interval < 86_400 { return "\(Int(interval / 3600))h" }
    if interval < 86_400 * 7 { return "\(Int(interval / 86_400))d" }
    let f = DateFormatter()
    f.dateFormat = "MMM d"
    return f.string(from: date)
}
