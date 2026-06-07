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
                        .padding(.bottom, 18)

                    searchBar
                        .padding(.horizontal, 18)
                        .padding(.bottom, 24)

                    if viewModel.isLoading && viewModel.feed.isEmpty && viewModel.suggestions.isEmpty {
                        loadingState
                    } else if viewModel.feed.isEmpty {
                        emptyState
                    } else {
                        LazyVStack(spacing: 28) {
                            ForEach(viewModel.feed) { item in
                                FeedCard(item: item)
                            }
                        }
                        .padding(.horizontal, 18)
                        .padding(.top, 4)
                        .padding(.bottom, 48)
                    }
                }
            }
            .refreshable { await viewModel.load() }
        }
        .preferredColorScheme(.dark)
        .toolbar(.hidden, for: .navigationBar)
        .task(id: refreshTrigger) { await viewModel.load() }
    }

    private var header: some View {
        Text("Home")
            .font(.system(size: 34, weight: .bold))
            .foregroundStyle(Theme.textPrimary)
    }

    // Looks like SearchField but is a link — tapping opens the full-screen search
    // page rather than editing in place.
    private var searchBar: some View {
        NavigationLink {
            SearchView()
        } label: {
            HStack(spacing: 10) {
                Image(systemName: "magnifyingglass")
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(Theme.textTertiary)
                Text("Search dishes & restaurants")
                    .font(.system(size: 16))
                    .foregroundStyle(Theme.textTertiary)
                Spacer(minLength: 0)
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 12)
            .background(Theme.surface)
            .overlay { Capsule().stroke(Theme.hairline, lineWidth: 1) }
            .clipShape(Capsule())
            .contentShape(Capsule())
        }
        .buttonStyle(.plain)
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

    private var hasPhoto: Bool { item.rating.photoPath != nil }
    private var hasNotes: Bool {
        if let notes = item.rating.notes { return !notes.isEmpty }
        return false
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            header
                .padding(.horizontal, 16)
                .padding(.top, 16)
                .padding(.bottom, hasPhoto || hasNotes ? 14 : 16)

            if hasPhoto || hasNotes {
                NavigationLink {
                    DishDetailView(dish: item.rating.dish)
                } label: {
                    VStack(alignment: .leading, spacing: 13) {
                        if hasPhoto, let path = item.rating.photoPath,
                           let url = dishPhotoURL(path: path) {
                            photo(url: url)
                        }
                        if hasNotes, let notes = item.rating.notes {
                            note(notes)
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.bottom, 18)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
            }
        }
        .elevatedCard(cornerRadius: 22)
    }

    // Avatar → profile, the conversational line + score → dish.
    private var header: some View {
        HStack(alignment: .top, spacing: 11) {
            NavigationLink {
                UserProfileView(profile: item.profile)
            } label: {
                Avatar(profile: item.profile, size: 40)
            }
            .buttonStyle(.plain)

            NavigationLink {
                DishDetailView(dish: item.rating.dish)
            } label: {
                HStack(alignment: .top, spacing: 12) {
                    VStack(alignment: .leading, spacing: 5) {
                        sentence
                        subline
                    }
                    Spacer(minLength: 8)
                    if let score = item.rating.score {
                        ScoreChip(score: score)
                    }
                }
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
        }
    }

    // "Shitosh ate Margherita Pizza" — name & dish pop, the verb recedes.
    private var sentence: Text {
        Text(item.profile.resolvedName).fontWeight(.bold).foregroundColor(Theme.textPrimary)
        + Text(" ate ").fontWeight(.regular).foregroundColor(Theme.textSecondary)
        + Text(item.rating.dish.displayName).fontWeight(.bold).foregroundColor(Theme.textPrimary)
    }

    private var subline: some View {
        HStack(spacing: 6) {
            Text(item.rating.dish.restaurant.name.uppercased())
                .font(.system(size: 10, weight: .heavy))
                .tracking(1.2)
                .foregroundStyle(Theme.textTertiary)
                .lineLimit(1)
            Circle()
                .fill(Theme.textTertiary)
                .frame(width: 3, height: 3)
            Text(timeAgo(item.rating.createdAt))
                .font(.system(size: 10, weight: .semibold))
                .foregroundStyle(Theme.textTertiary)
                .lineLimit(1)
        }
    }

    private func photo(url: URL) -> some View {
        AsyncImage(url: url) { phase in
            switch phase {
            case .success(let image):
                image.resizable().scaledToFill()
            case .empty:
                ZStack {
                    Theme.surface
                    ProgressView().tint(Theme.textTertiary)
                }
            default:
                ZStack {
                    Theme.surface
                    Image(systemName: "fork.knife")
                        .font(.system(size: 24))
                        .foregroundStyle(Theme.textTertiary)
                }
            }
        }
        .frame(maxWidth: .infinity)
        .frame(height: 280)
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .stroke(Theme.hairline, lineWidth: 1)
        }
    }

    private func note(_ text: String) -> some View {
        HStack(alignment: .top, spacing: 10) {
            Capsule()
                .fill(Theme.accent.opacity(0.5))
                .frame(width: 2.5)
            Text(text)
                .font(.system(size: 14))
                .italic()
                .foregroundStyle(Theme.textSecondary)
                .lineLimit(4)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

struct ScoreChip: View {
    let score: Int

    var body: some View {
        Text("\(score)")
            .font(.system(size: 22, weight: .bold, design: .rounded))
            .foregroundStyle(.white)
            .monospacedDigit()
            .frame(width: 44, height: 44)
            .background(
                scoreGradient(Double(score)),
                in: RoundedRectangle(cornerRadius: 13, style: .continuous)
            )
            .shadow(color: scoreColor(Double(score)).opacity(0.45), radius: 8, x: 0, y: 3)
    }
}

struct SuggestionRow: View {
    let profile: ProfileLite
    let isFollowing: Bool
    let onToggle: () -> Void

    var body: some View {
        HStack(spacing: 12) {
            NavigationLink {
                UserProfileView(profile: profile)
            } label: {
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
                    Spacer(minLength: 8)
                }
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)

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
