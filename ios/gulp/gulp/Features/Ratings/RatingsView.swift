import SwiftUI

struct RatingsView: View {
    var refreshTrigger: Int = 0
    var topAccessory: AnyView? = nil
    var userId: UUID? = nil
    var readOnly: Bool = false
    @State private var viewModel = RatingsViewModel()
    @State private var editingRating: RatingResponse?
    @State private var addToRestaurant: RestaurantResponse?
    @State private var pendingDelete: PendingDelete?

    var body: some View {
        ZStack {
            Theme.background.ignoresSafeArea()

            ScrollView {
                VStack(alignment: .leading, spacing: 0) {
                    if let topAccessory {
                        topAccessory
                    }

                    header
                        .padding(.horizontal, 20)
                        .padding(.top, 12)
                        .padding(.bottom, 24)

                    if viewModel.isLoading && viewModel.groups.isEmpty {
                        loadingState
                    } else if viewModel.groups.isEmpty {
                        emptyState
                    } else {
                        LazyVStack(spacing: 24) {
                            ForEach(viewModel.groups) { group in
                                RestaurantCard(
                                    group: group,
                                    readOnly: readOnly,
                                    // Edit/Delete fire from a context menu; defer the
                                    // presentation past the menu's dismissal or the
                                    // sheet/dialog gets swallowed (SwiftUI quirk).
                                    onEditDish: { rating in afterMenuDismiss { editingRating = rating } },
                                    onDeleteDish: { rating in afterMenuDismiss { pendingDelete = .rating(rating) } },
                                    onAddDish: { addToRestaurant = group.restaurant },
                                    onRemoveRestaurant: { pendingDelete = .restaurant(group) }
                                )
                            }
                        }
                        .padding(.horizontal, 18)
                        .padding(.top, 4)
                        .padding(.bottom, 40)
                    }
                }
            }
            .refreshable { await viewModel.load(userId: userId) }
        }
        .preferredColorScheme(.dark)
        .task(id: refreshTrigger) { await viewModel.load(userId: userId) }
        .sheet(item: $editingRating, onDismiss: { Task { await viewModel.load(userId: userId) } }) { rating in
            AddRatingView(mode: .editRating(rating))
        }
        .sheet(item: $addToRestaurant, onDismiss: { Task { await viewModel.load(userId: userId) } }) { restaurant in
            AddRatingView(mode: .addToRestaurant(restaurant))
        }
        .confirmationDialog(
            deleteTitle,
            isPresented: .init(get: { pendingDelete != nil }, set: { if !$0 { pendingDelete = nil } }),
            titleVisibility: .visible
        ) {
            Button(deleteActionLabel, role: .destructive) {
                // Capture before the binding's dismissal resets pendingDelete,
                // then run the delete on the (stable) view model directly.
                let target = pendingDelete
                pendingDelete = nil
                Task {
                    switch target {
                    case .rating(let r): await viewModel.deleteRating(r)
                    case .restaurant(let g): await viewModel.removeRestaurant(g)
                    case .none: break
                    }
                }
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text(deleteMessage)
        }
        .alert(
            "Something went wrong",
            isPresented: .init(
                get: { viewModel.errorMessage != nil },
                set: { if !$0 { viewModel.errorMessage = nil } }
            )
        ) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(viewModel.errorMessage ?? "")
        }
    }

    /// Runs `action` after a context menu has had time to dismiss. Presenting a
    /// sheet or confirmation dialog synchronously from a context-menu button
    /// races the menu's own dismissal and often no-ops.
    private func afterMenuDismiss(_ action: @escaping () -> Void) {
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.4, execute: action)
    }

    private var deleteTitle: String {
        switch pendingDelete {
        case .rating: return "Delete this rating?"
        case .restaurant: return "Remove from your list?"
        case .none: return ""
        }
    }

    private var deleteActionLabel: String {
        switch pendingDelete {
        case .rating: return "Delete"
        case .restaurant: return "Remove"
        case .none: return ""
        }
    }

    private var deleteMessage: String {
        switch pendingDelete {
        case .rating(let r): return "\(r.dish.displayName) will be removed from your ratings."
        case .restaurant(let g): return "All \(g.ratings.count) ratings at \(g.restaurant.name) will be removed from your list."
        case .none: return ""
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 10) {
            if !readOnly {
                Text("My Ratings")
                    .font(.system(size: 34, weight: .bold))
                    .foregroundStyle(Theme.textPrimary)
            }

            if !viewModel.groups.isEmpty {
                statLine
            }
        }
    }

    private var statLine: some View {
        let dishCount = viewModel.groups.reduce(0) { $0 + $1.ratings.count }
        let placeCount = viewModel.groups.count

        return HStack(spacing: 14) {
            statChip(value: "\(dishCount)", label: dishCount == 1 ? "dish" : "dishes")
            dot
            statChip(value: "\(placeCount)", label: placeCount == 1 ? "place" : "places")
        }
    }

    private var dot: some View {
        Circle()
            .fill(Theme.textTertiary)
            .frame(width: 3, height: 3)
    }

    private func statChip(value: String, label: String) -> some View {
        HStack(spacing: 6) {
            Text(value)
                .font(.system(size: 15, weight: .semibold, design: .rounded))
                .foregroundStyle(Theme.textPrimary)
            Text(label)
                .font(.system(size: 13, weight: .medium))
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
        VStack(spacing: 14) {
            ZStack {
                Circle()
                    .fill(Theme.surface)
                    .frame(width: 72, height: 72)
                Image(systemName: "fork.knife")
                    .font(.system(size: 28, weight: .medium))
                    .foregroundStyle(Theme.accent)
            }
            Text(readOnly ? "No ratings yet" : "Nothing rated yet")
                .font(.system(size: 18, weight: .semibold))
                .foregroundStyle(Theme.textPrimary)
            if !readOnly {
                Text("Tap the + below to rate a dish.")
                    .font(.system(size: 14))
                    .foregroundStyle(Theme.textSecondary)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.top, 80)
    }
}

enum PendingDelete {
    case rating(RatingResponse)
    case restaurant(RestaurantGroup)
}

struct RestaurantCard: View {
    let group: RestaurantGroup
    var readOnly: Bool = false
    let onEditDish: (RatingResponse) -> Void
    let onDeleteDish: (RatingResponse) -> Void
    let onAddDish: () -> Void
    let onRemoveRestaurant: () -> Void

    private var primaryCuisine: String? {
        let cuisines = group.ratings.compactMap { $0.dish.cuisine }
        let counts = Dictionary(grouping: cuisines, by: { $0 }).mapValues(\.count)
        return counts.max(by: { $0.value < $1.value })?.key
    }

    private var subtitle: String? {
        let parts = [primaryCuisine, group.restaurant.address].compactMap { $0 }
        return parts.isEmpty ? nil : parts.joined(separator: "  ·  ")
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            header
            VStack(spacing: 4) {
                ForEach(group.ratings) { rating in
                    dishRow(rating)
                }
            }
            .padding(.horizontal, 6)
            .padding(.bottom, 12)
        }
        .elevatedCard(cornerRadius: 24)
    }

    private var header: some View {
        ZStack(alignment: .topTrailing) {
            NavigationLink {
                RestaurantDetailView(restaurant: group.restaurant)
            } label: {
                HStack(alignment: .top, spacing: 16) {
                    VStack(alignment: .leading, spacing: 5) {
                        Text(group.restaurant.name.uppercased())
                            .font(.system(size: 18, weight: .bold))
                            .tracking(0.5)
                            .foregroundStyle(Theme.textPrimary)
                            .lineLimit(1)

                        if let subtitle {
                            Text(subtitle)
                                .font(.system(size: 12, weight: .medium))
                                .foregroundStyle(Theme.textTertiary)
                                .lineLimit(1)
                        }
                    }

                    Spacer(minLength: 8)

                    if let avg = group.averageScore {
                        VStack(spacing: 1) {
                            Text(String(format: "%.1f", avg))
                                .font(.system(size: 32, weight: .bold, design: .rounded))
                                .foregroundStyle(scoreGradient(avg))
                                .monospacedDigit()
                                .shadow(color: scoreColor(avg).opacity(0.4), radius: 12, y: 0)
                            Text("AVG")
                                .font(.system(size: 9, weight: .heavy))
                                .tracking(1.2)
                                .foregroundStyle(Theme.textTertiary)
                        }
                    }

                    if !readOnly {
                        Color.clear.frame(width: 24, height: 28)
                    }
                }
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)

            if !readOnly {
                Menu {
                    Button {
                        onAddDish()
                    } label: {
                        Label("Add a dish", systemImage: "plus")
                    }
                    Button(role: .destructive) {
                        onRemoveRestaurant()
                    } label: {
                        Label("Remove from list", systemImage: "trash")
                    }
                } label: {
                    Image(systemName: "ellipsis")
                        .font(.system(size: 15, weight: .bold))
                        .foregroundStyle(Theme.textTertiary)
                        .frame(width: 24, height: 28)
                        .contentShape(Rectangle())
                }
            }
        }
        .padding(.horizontal, 20)
        .padding(.top, 20)
        .padding(.bottom, 8)
    }

    private func dishRow(_ rating: RatingResponse) -> some View {
        NavigationLink {
            DishDetailView(dish: rating.dish)
        } label: {
            HStack(spacing: 14) {
                scoreTile(rating)
                Text(rating.dish.displayName)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(Theme.textPrimary)
                    .lineLimit(2)
                Spacer(minLength: 8)
                Image(systemName: "chevron.right")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundStyle(Theme.textTertiary.opacity(0.5))
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 7)
            .contentShape(Rectangle())
        }
        .buttonStyle(PressableButtonStyle())
        .if(!readOnly) { view in
            view.contextMenu {
                Button {
                    onEditDish(rating)
                } label: {
                    Label("Edit", systemImage: "pencil")
                }
                Button(role: .destructive) {
                    onDeleteDish(rating)
                } label: {
                    Label("Delete", systemImage: "trash")
                }
            }
        }
    }

    @ViewBuilder
    private func scoreTile(_ rating: RatingResponse) -> some View {
        ZStack {
            if let path = rating.photoPath, let url = dishPhotoURL(path: path) {
                AsyncImage(url: url) { phase in
                    switch phase {
                    case .success(let img):
                        img.resizable().scaledToFill()
                    default:
                        tileFill(rating)
                    }
                }
                Color.black.opacity(0.22)
                LinearGradient(
                    colors: [.clear, .black.opacity(0.45)],
                    startPoint: .center,
                    endPoint: .bottom
                )
            } else {
                tileFill(rating)
            }

            if let score = rating.score {
                Text("\(score)")
                    .font(.system(size: 20, weight: .heavy, design: .rounded))
                    .foregroundStyle(.white)
                    .monospacedDigit()
                    .shadow(color: .black.opacity(0.35), radius: 3, y: 1)
            }
        }
        .frame(width: 54, height: 54)
        .clipShape(RoundedRectangle(cornerRadius: 15, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 15, style: .continuous)
                .stroke(Color.white.opacity(0.10), lineWidth: 1)
        }
    }

    @ViewBuilder
    private func tileFill(_ rating: RatingResponse) -> some View {
        if let score = rating.score {
            scoreGradient(Double(score))
        } else {
            LinearGradient(
                colors: [Theme.surfaceElevated, Theme.surface],
                startPoint: .top,
                endPoint: .bottom
            )
        }
    }
}

extension View {
    @ViewBuilder
    fileprivate func `if`<Content: View>(_ condition: Bool, transform: (Self) -> Content) -> some View {
        if condition { transform(self) } else { self }
    }
}

struct PressableButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .background(configuration.isPressed ? Theme.surfaceElevated : Color.clear)
            .scaleEffect(configuration.isPressed ? 0.99 : 1.0)
            .animation(.easeOut(duration: 0.12), value: configuration.isPressed)
    }
}
