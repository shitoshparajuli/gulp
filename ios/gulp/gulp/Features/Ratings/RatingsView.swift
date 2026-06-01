import SwiftUI

struct RatingsView: View {
    var refreshTrigger: Int = 0
    var topAccessory: AnyView? = nil
    @State private var viewModel = RatingsViewModel()
    @State private var selectedRating: RatingResponse?
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
                        LazyVStack(spacing: 18) {
                            ForEach(viewModel.groups) { group in
                                RestaurantCard(
                                    group: group,
                                    onDishTap: { selectedRating = $0 },
                                    onEditDish: { editingRating = $0 },
                                    onDeleteDish: { pendingDelete = .rating($0) },
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
            .refreshable { await viewModel.load() }
        }
        .preferredColorScheme(.dark)
        .task(id: refreshTrigger) { await viewModel.load() }
        .sheet(item: $selectedRating) { rating in
            DishDetailSheet(rating: rating) {
                editingRating = rating
            }
        }
        .sheet(item: $editingRating, onDismiss: { Task { await viewModel.load() } }) { rating in
            AddRatingView(mode: .editRating(rating))
        }
        .sheet(item: $addToRestaurant, onDismiss: { Task { await viewModel.load() } }) { restaurant in
            AddRatingView(mode: .addToRestaurant(restaurant))
        }
        .confirmationDialog(
            deleteTitle,
            isPresented: .init(get: { pendingDelete != nil }, set: { if !$0 { pendingDelete = nil } }),
            titleVisibility: .visible
        ) {
            Button(deleteActionLabel, role: .destructive) {
                Task { await performDelete() }
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text(deleteMessage)
        }
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

    private func performDelete() async {
        switch pendingDelete {
        case .rating(let r): await viewModel.deleteRating(r)
        case .restaurant(let g): await viewModel.removeRestaurant(g)
        case .none: break
        }
        pendingDelete = nil
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("My Ratings")
                .font(.system(size: 34, weight: .bold))
                .foregroundStyle(Theme.textPrimary)

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
            Text("Nothing rated yet")
                .font(.system(size: 18, weight: .semibold))
                .foregroundStyle(Theme.textPrimary)
            Text("Tap the + below to rate a dish.")
                .font(.system(size: 14))
                .foregroundStyle(Theme.textSecondary)
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
    let onDishTap: (RatingResponse) -> Void
    let onEditDish: (RatingResponse) -> Void
    let onDeleteDish: (RatingResponse) -> Void
    let onAddDish: () -> Void
    let onRemoveRestaurant: () -> Void

    private var primaryCuisine: String? {
        let cuisines = group.ratings.compactMap { $0.dish.cuisine }
        let counts = Dictionary(grouping: cuisines, by: { $0 }).mapValues(\.count)
        return counts.max(by: { $0.value < $1.value })?.key
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            header
            ForEach(Array(group.ratings.enumerated()), id: \.element.id) { index, rating in
                dishRow(rating)
                if index < group.ratings.count - 1 {
                    Rectangle()
                        .fill(Theme.hairline)
                        .frame(height: 1)
                        .padding(.leading, 20)
                }
            }
        }
        .elevatedCard(cornerRadius: 20)
    }

    private var header: some View {
        HStack(alignment: .top, spacing: 16) {
            VStack(alignment: .leading, spacing: 8) {
                Text(group.restaurant.name.uppercased())
                    .font(.system(size: 17, weight: .bold))
                    .tracking(0.5)
                    .foregroundStyle(Theme.textPrimary)
                    .lineLimit(1)

                if let address = group.restaurant.address {
                    HStack(spacing: 4) {
                        Image(systemName: "mappin.and.ellipse")
                            .font(.system(size: 10, weight: .semibold))
                            .foregroundStyle(Theme.accent.opacity(0.85))
                        Text(address)
                            .font(.system(size: 12, weight: .medium))
                            .foregroundStyle(Theme.textSecondary)
                            .lineLimit(1)
                    }
                }

                HStack(spacing: 8) {
                    if let cuisine = primaryCuisine {
                        Text(cuisine)
                            .font(.system(size: 11, weight: .semibold))
                            .tracking(0.4)
                            .foregroundStyle(Theme.textSecondary)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 3)
                            .background(Theme.surfaceElevated)
                            .clipShape(Capsule())
                    }
                    Text("\(group.ratings.count) \(group.ratings.count == 1 ? "dish" : "dishes")")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundStyle(Theme.textTertiary)
                }
            }
            Spacer(minLength: 8)

            HStack(alignment: .top, spacing: 10) {
                if let avg = group.averageScore {
                    VStack(spacing: 0) {
                        Text(String(format: "%.1f", avg))
                            .font(.system(size: 30, weight: .bold, design: .rounded))
                            .foregroundStyle(scoreGradient(avg))
                        Text("AVG")
                            .font(.system(size: 9, weight: .heavy))
                            .tracking(1.0)
                            .foregroundStyle(Theme.textTertiary)
                    }
                }

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
                        .font(.system(size: 13, weight: .bold))
                        .foregroundStyle(Theme.textSecondary)
                        .frame(width: 28, height: 28)
                        .background(Theme.surfaceElevated)
                        .clipShape(Circle())
                }
            }
        }
        .padding(.horizontal, 20)
        .padding(.top, 18)
        .padding(.bottom, 16)
    }

    private func dishRow(_ rating: RatingResponse) -> some View {
        Button { onDishTap(rating) } label: {
            HStack(spacing: 14) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(rating.dish.displayName)
                        .font(.system(size: 16, weight: .medium))
                        .foregroundStyle(Theme.textPrimary)
                        .lineLimit(1)
                    if let notes = rating.notes, !notes.isEmpty {
                        Text(notes)
                            .font(.system(size: 13))
                            .foregroundStyle(Theme.textSecondary)
                            .lineLimit(1)
                    }
                }
                Spacer(minLength: 8)
                if rating.photoPath != nil {
                    Image(systemName: "photo.fill")
                        .font(.system(size: 11))
                        .foregroundStyle(Theme.textTertiary)
                }
                if let score = rating.score {
                    Text("\(score)")
                        .font(.system(size: 15, weight: .bold, design: .rounded))
                        .foregroundStyle(.white)
                        .frame(minWidth: 36, minHeight: 28)
                        .padding(.horizontal, 8)
                        .background(scoreGradient(Double(score)))
                        .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                }
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 14)
            .contentShape(Rectangle())
        }
        .buttonStyle(PressableButtonStyle())
        .contextMenu {
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

struct PressableButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .background(configuration.isPressed ? Theme.surfaceElevated : Color.clear)
            .scaleEffect(configuration.isPressed ? 0.99 : 1.0)
            .animation(.easeOut(duration: 0.12), value: configuration.isPressed)
    }
}
