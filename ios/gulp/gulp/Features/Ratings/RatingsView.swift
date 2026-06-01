import SwiftUI

struct RatingsView: View {
    @State private var viewModel = RatingsViewModel()
    @State private var selectedRating: RatingResponse?

    var body: some View {
        ZStack {
            Theme.background.ignoresSafeArea()

            ScrollView {
                VStack(alignment: .leading, spacing: 0) {
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
                                RestaurantCard(group: group) { rating in
                                    selectedRating = rating
                                }
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
        .task { await viewModel.load() }
        .sheet(item: $selectedRating) { rating in
            DishDetailSheet(rating: rating)
        }
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
        let allScores = viewModel.groups.flatMap { $0.ratings.compactMap(\.score) }
        let avg = allScores.isEmpty ? 0 : Double(allScores.reduce(0, +)) / Double(allScores.count)

        return HStack(spacing: 14) {
            statChip(value: "\(dishCount)", label: "dishes")
            dot
            statChip(value: "\(placeCount)", label: placeCount == 1 ? "place" : "places")
            dot
            HStack(spacing: 6) {
                Text(String(format: "%.1f", avg))
                    .font(.system(size: 15, weight: .semibold, design: .rounded))
                    .foregroundStyle(scoreColor(avg))
                Text("avg")
                    .font(.system(size: 13, weight: .medium))
                    .foregroundStyle(Theme.textTertiary)
            }
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
            Text("Dishes you rate will live here.")
                .font(.system(size: 14))
                .foregroundStyle(Theme.textSecondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.top, 80)
    }
}

struct RestaurantCard: View {
    let group: RestaurantGroup
    let onDishTap: (RatingResponse) -> Void

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
            VStack(alignment: .leading, spacing: 6) {
                Text(group.restaurant.name.uppercased())
                    .font(.system(size: 17, weight: .bold))
                    .tracking(0.5)
                    .foregroundStyle(Theme.textPrimary)
                    .lineLimit(1)

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
