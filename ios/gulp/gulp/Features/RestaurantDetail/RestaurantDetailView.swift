import SwiftUI

struct RestaurantDetailView: View {
    let restaurant: RestaurantResponse
    @State private var viewModel: RestaurantDetailViewModel
    @State private var addingDish: RestaurantResponse?
    @State private var showMapOptions = false

    init(restaurant: RestaurantResponse) {
        self.restaurant = restaurant
        _viewModel = State(initialValue: RestaurantDetailViewModel(restaurant: restaurant))
    }

    var body: some View {
        ZStack {
            Theme.background.ignoresSafeArea()

            ScrollView {
                VStack(alignment: .leading, spacing: 28) {
                    hero
                    if viewModel.isLoading && viewModel.dishes.isEmpty {
                        loading
                    } else if viewModel.dishes.isEmpty {
                        emptyState
                    } else {
                        dishSections
                            .padding(.horizontal, 18)
                    }
                    Spacer(minLength: 104)
                }
                .padding(.top, 18)
            }

            VStack {
                Spacer()
                Button {
                    addingDish = restaurant
                } label: {
                    HStack(spacing: 8) {
                        Image(systemName: "plus")
                            .font(.system(size: 14, weight: .semibold))
                        Text("Add a dish")
                            .font(.system(size: 15, weight: .semibold))
                    }
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(Theme.accent)
                    .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 24)
            }
        }
        .preferredColorScheme(.dark)
        .navigationTitle("")
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(Theme.background, for: .navigationBar)
        .toolbarBackground(.visible, for: .navigationBar)
        .toolbarColorScheme(.dark, for: .navigationBar)
        .hidesAppTabBar()
        .task { await viewModel.load() }
        .refreshable { await viewModel.load() }
        .sheet(item: $addingDish, onDismiss: { Task { await viewModel.load() } }) { restaurant in
            AddRatingView(mode: .addToRestaurant(restaurant))
        }
    }

    private var hero: some View {
        VStack(spacing: 12) {
            Text(restaurant.name.uppercased())
                .font(.system(size: 26, weight: .heavy))
                .tracking(1.4)
                .foregroundStyle(Theme.textPrimary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 24)

            if let address = restaurant.address {
                Button {
                    openInMaps()
                } label: {
                    HStack(spacing: 4) {
                        Image(systemName: "mappin.and.ellipse")
                            .font(.system(size: 11, weight: .semibold))
                            .foregroundStyle(Theme.accent.opacity(0.85))
                        Text(address)
                            .font(.system(size: 13, weight: .medium))
                            .foregroundStyle(Theme.textSecondary)
                        Image(systemName: "arrow.up.right")
                            .font(.system(size: 9, weight: .bold))
                            .foregroundStyle(Theme.textTertiary)
                    }
                    .contentShape(Rectangle())
                }
                .buttonStyle(PressableButtonStyle())
                .confirmationDialog("Open in", isPresented: $showMapOptions, titleVisibility: .visible) {
                    ForEach(MapLauncher.available) { app in
                        Button(app.displayName) { MapLauncher.open(app, query: mapQuery) }
                    }
                }
            }

            if !viewModel.dishes.isEmpty {
                statsRow
                    .padding(.top, 6)
            }
        }
        .frame(maxWidth: .infinity)
    }

    private var statsRow: some View {
        HStack(spacing: 14) {
            chip(value: "\(viewModel.dishes.count)", label: viewModel.dishes.count == 1 ? "dish" : "dishes")
            if let avg = viewModel.restaurantAvg {
                dot
                avgChip(avg)
            }
            if viewModel.totalRatings > 0 {
                dot
                chip(
                    value: "\(viewModel.totalRatings)",
                    label: viewModel.totalRatings == 1 ? "rating" : "ratings"
                )
            }
        }
    }

    private func chip(value: String, label: String) -> some View {
        HStack(spacing: 6) {
            Text(value)
                .font(.system(size: 15, weight: .semibold, design: .rounded))
                .foregroundStyle(Theme.textPrimary)
            Text(label)
                .font(.system(size: 13, weight: .medium))
                .foregroundStyle(Theme.textTertiary)
        }
    }

    private func avgChip(_ avg: Double) -> some View {
        HStack(spacing: 6) {
            Text(formattedAvg(avg))
                .font(.system(size: 15, weight: .bold, design: .rounded))
                .foregroundStyle(scoreGradient(avg))
            Text("avg")
                .font(.system(size: 13, weight: .medium))
                .foregroundStyle(Theme.textTertiary)
        }
    }

    private var dot: some View {
        Circle().fill(Theme.textTertiary).frame(width: 3, height: 3)
    }

    private var loading: some View {
        ProgressView()
            .tint(Theme.textSecondary)
            .frame(maxWidth: .infinity)
            .padding(.top, 80)
    }

    private var emptyState: some View {
        VStack(spacing: 12) {
            Text("No dishes yet")
                .font(.system(size: 16, weight: .semibold))
                .foregroundStyle(Theme.textPrimary)
            Text("Tap the button below to be the first.")
                .font(.system(size: 13))
                .foregroundStyle(Theme.textSecondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.top, 60)
    }

    private var dishSections: some View {
        VStack(alignment: .leading, spacing: 24) {
            if !viewModel.triedDishes.isEmpty {
                section(
                    title: "YOU'VE TRIED",
                    icon: "checkmark.circle.fill",
                    dishes: viewModel.triedDishes
                )
            }
            if !viewModel.untriedDishes.isEmpty {
                section(
                    title: "HAVEN'T TRIED",
                    icon: "circle.dashed",
                    dishes: viewModel.untriedDishes
                )
            }
        }
    }

    private func section(title: String, icon: String, dishes: [DishAggregate]) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 7) {
                Image(systemName: icon)
                    .font(.system(size: 11, weight: .bold))
                    .foregroundStyle(Theme.textTertiary)
                Text(title)
                    .font(.system(size: 11, weight: .heavy))
                    .tracking(1.2)
                    .foregroundStyle(Theme.textTertiary)
                Text("\(dishes.count)")
                    .font(.system(size: 11, weight: .heavy, design: .rounded))
                    .foregroundStyle(Theme.textSecondary)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 1)
                    .background(Theme.surfaceElevated)
                    .clipShape(Capsule())
            }
            .padding(.leading, 4)

            dishCard(dishes)
        }
    }

    private func dishCard(_ dishes: [DishAggregate]) -> some View {
        VStack(spacing: 0) {
            ForEach(Array(dishes.enumerated()), id: \.element.id) { index, dish in
                NavigationLink {
                    DishDetailView(dish: dish.asDishResponse(restaurant: restaurant))
                } label: {
                    DishAggregateRow(dish: dish)
                }
                .buttonStyle(PressableButtonStyle())

                if index < dishes.count - 1 {
                    Rectangle()
                        .fill(Theme.hairline)
                        .frame(height: 1)
                        .padding(.leading, 20)
                }
            }
        }
        .elevatedCard(cornerRadius: 20)
    }

    private func formattedAvg(_ value: Double) -> String {
        value.truncatingRemainder(dividingBy: 1) == 0
            ? String(format: "%.0f", value)
            : String(format: "%.1f", value)
    }

    private var mapQuery: String {
        [restaurant.name, restaurant.address]
            .compactMap { $0 }
            .joined(separator: ", ")
    }

    private func openInMaps() {
        let apps = MapLauncher.available
        // Only one choice (typically Apple Maps alone) → skip the picker.
        if apps.count <= 1 {
            MapLauncher.open(apps.first ?? .apple, query: mapQuery)
        } else {
            showMapOptions = true
        }
    }
}

private struct DishAggregateRow: View {
    let dish: DishAggregate

    var body: some View {
        HStack(alignment: .center, spacing: 14) {
            VStack(alignment: .leading, spacing: 4) {
                Text(dish.displayName)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(Theme.textPrimary)
                    .lineLimit(2)

                HStack(spacing: 8) {
                    if dish.communityCount > 0 {
                        Text("\(dish.communityCount) rating\(dish.communityCount == 1 ? "" : "s")")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundStyle(Theme.textTertiary)
                    } else {
                        Text("No ratings yet")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundStyle(Theme.textTertiary)
                    }

                    if let myScore = dish.myScore {
                        youChip(score: myScore)
                    }
                }
            }
            Spacer(minLength: 8)
            scoreBlock
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 16)
        .contentShape(Rectangle())
    }

    @ViewBuilder
    private var scoreBlock: some View {
        if let avg = dish.communityAvg {
            VStack(spacing: 0) {
                Text(format(avg))
                    .font(.system(size: 26, weight: .bold, design: .rounded))
                    .foregroundStyle(scoreGradient(avg))
                    .monospacedDigit()
                Text("AVG")
                    .font(.system(size: 8, weight: .heavy))
                    .tracking(1.0)
                    .foregroundStyle(Theme.textTertiary)
            }
        } else {
            Text("—")
                .font(.system(size: 22, weight: .bold, design: .rounded))
                .foregroundStyle(Theme.textTertiary)
        }
    }

    private func youChip(score: Int) -> some View {
        HStack(spacing: 4) {
            Text("YOU")
                .font(.system(size: 9, weight: .heavy))
                .tracking(1.0)
                .foregroundStyle(Theme.textTertiary)
            Text("\(score)")
                .font(.system(size: 11, weight: .bold, design: .rounded))
                .foregroundStyle(scoreColor(Double(score)))
        }
        .padding(.horizontal, 7)
        .padding(.vertical, 3)
        .background(Theme.surfaceElevated)
        .clipShape(Capsule())
    }

    private func format(_ value: Double) -> String {
        value.truncatingRemainder(dividingBy: 1) == 0
            ? String(format: "%.0f", value)
            : String(format: "%.1f", value)
    }
}
