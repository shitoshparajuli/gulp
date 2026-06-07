import SwiftUI

/// Full-screen global search: one field that finds dishes (ranked by community
/// average) and restaurants across the whole app. Pushed from Home.
struct SearchView: View {
    @State private var viewModel = SearchViewModel()

    var body: some View {
        ZStack {
            Theme.background.ignoresSafeArea()

            VStack(spacing: 0) {
                SearchField(
                    text: $viewModel.searchText,
                    placeholder: "Dishes & restaurants",
                    autoFocus: true
                )
                .padding(.horizontal, 18)
                .padding(.top, 8)
                .padding(.bottom, 14)

                content
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
            }
        }
        .preferredColorScheme(.dark)
        .navigationTitle("")
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(Theme.background, for: .navigationBar)
        .toolbarBackground(.visible, for: .navigationBar)
        .toolbarColorScheme(.dark, for: .navigationBar)
        .hidesAppTabBar()
        .task(id: viewModel.searchText) { await viewModel.search() }
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

    @ViewBuilder
    private var content: some View {
        if !viewModel.hasQuery {
            promptState
        } else if viewModel.isSearching && !viewModel.hasResults {
            loadingState
        } else if !viewModel.hasResults {
            noResultsState
        } else {
            resultsList
        }
    }

    private var resultsList: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 26) {
                if !viewModel.dishResults.isEmpty {
                    section(title: "DISHES", count: viewModel.dishResults.count) {
                        ForEach(Array(viewModel.dishResults.enumerated()), id: \.element.id) { index, dish in
                            NavigationLink {
                                DishDetailView(dish: dish.asDishResponse())
                            } label: {
                                DishResultRow(dish: dish)
                            }
                            .buttonStyle(PressableButtonStyle())
                            if index < viewModel.dishResults.count - 1 { divider }
                        }
                    }
                }

                if !viewModel.restaurantResults.isEmpty {
                    section(title: "RESTAURANTS", count: viewModel.restaurantResults.count) {
                        ForEach(Array(viewModel.restaurantResults.enumerated()), id: \.element.id) { index, restaurant in
                            NavigationLink {
                                RestaurantDetailView(restaurant: restaurant)
                            } label: {
                                RestaurantResultRow(restaurant: restaurant)
                            }
                            .buttonStyle(PressableButtonStyle())
                            if index < viewModel.restaurantResults.count - 1 { divider }
                        }
                    }
                }

                Spacer(minLength: 40)
            }
            .padding(.horizontal, 18)
            .padding(.top, 4)
        }
        .scrollDismissesKeyboard(.immediately)
    }

    private func section<Content: View>(
        title: String,
        count: Int,
        @ViewBuilder content: () -> Content
    ) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 7) {
                Text(title)
                    .font(.system(size: 11, weight: .heavy))
                    .tracking(1.2)
                    .foregroundStyle(Theme.textTertiary)
                Text("\(count)")
                    .font(.system(size: 11, weight: .heavy, design: .rounded))
                    .foregroundStyle(Theme.textSecondary)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 1)
                    .background(Theme.surfaceElevated)
                    .clipShape(Capsule())
            }
            .padding(.leading, 4)

            VStack(spacing: 0) { content() }
                .elevatedCard(cornerRadius: 20)
        }
    }

    private var divider: some View {
        Rectangle()
            .fill(Theme.hairline)
            .frame(height: 1)
            .padding(.leading, 20)
    }

    // MARK: - States

    private var promptState: some View {
        VStack(spacing: 14) {
            ZStack {
                Circle().fill(Theme.surface).frame(width: 72, height: 72)
                Image(systemName: "magnifyingglass")
                    .font(.system(size: 28, weight: .medium))
                    .foregroundStyle(Theme.accent)
            }
            Text("Search dishes & restaurants")
                .font(.system(size: 18, weight: .semibold))
                .foregroundStyle(Theme.textPrimary)
            Text("Find the best-rated bites across gulp.")
                .font(.system(size: 14))
                .foregroundStyle(Theme.textSecondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.top, 90)
    }

    private var loadingState: some View {
        ProgressView()
            .tint(Theme.textSecondary)
            .frame(maxWidth: .infinity)
            .padding(.top, 110)
    }

    private var noResultsState: some View {
        VStack(spacing: 10) {
            Text("No matches")
                .font(.system(size: 18, weight: .semibold))
                .foregroundStyle(Theme.textPrimary)
            Text("Nothing found for “\(viewModel.searchText.trimmingCharacters(in: .whitespacesAndNewlines))”.")
                .font(.system(size: 14))
                .foregroundStyle(Theme.textSecondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.horizontal, 32)
        .padding(.top, 100)
    }
}

private struct DishResultRow: View {
    let dish: DishSearchResult

    var body: some View {
        HStack(spacing: 14) {
            scoreBlock
                .frame(width: 50)

            VStack(alignment: .leading, spacing: 4) {
                Text(dish.displayName)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(Theme.textPrimary)
                    .lineLimit(2)
                subtitle
            }

            Spacer(minLength: 8)

            Image(systemName: "chevron.right")
                .font(.system(size: 12, weight: .bold))
                .foregroundStyle(Theme.textTertiary.opacity(0.5))
        }
        .padding(.horizontal, 18)
        .padding(.vertical, 14)
        .contentShape(Rectangle())
    }

    @ViewBuilder
    private var scoreBlock: some View {
        if let avg = dish.communityAvg {
            VStack(spacing: 0) {
                Text(formattedAvg(avg))
                    .font(.system(size: 24, weight: .bold, design: .rounded))
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

    private var subtitle: some View {
        HStack(spacing: 6) {
            Text(dish.restaurant.name.uppercased())
                .font(.system(size: 11, weight: .heavy))
                .tracking(1.0)
                .foregroundStyle(Theme.textTertiary)
                .lineLimit(1)
            if let cuisine = dish.cuisine {
                Circle().fill(Theme.textTertiary).frame(width: 3, height: 3)
                Text(cuisine)
                    .font(.system(size: 11, weight: .medium))
                    .foregroundStyle(Theme.textTertiary)
                    .lineLimit(1)
            }
        }
    }

    private func formattedAvg(_ value: Double) -> String {
        value.truncatingRemainder(dividingBy: 1) == 0
            ? String(format: "%.0f", value)
            : String(format: "%.1f", value)
    }
}

private struct RestaurantResultRow: View {
    let restaurant: RestaurantResponse

    var body: some View {
        HStack(spacing: 14) {
            ZStack {
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .fill(Theme.surfaceElevated)
                Image(systemName: "fork.knife")
                    .font(.system(size: 17, weight: .medium))
                    .foregroundStyle(Theme.textSecondary)
            }
            .frame(width: 46, height: 46)

            VStack(alignment: .leading, spacing: 3) {
                Text(restaurant.name.uppercased())
                    .font(.system(size: 15, weight: .bold))
                    .tracking(0.5)
                    .foregroundStyle(Theme.textPrimary)
                    .lineLimit(1)
                if let address = restaurant.address {
                    Text(address)
                        .font(.system(size: 12, weight: .medium))
                        .foregroundStyle(Theme.textTertiary)
                        .lineLimit(1)
                }
            }

            Spacer(minLength: 8)

            Image(systemName: "chevron.right")
                .font(.system(size: 12, weight: .bold))
                .foregroundStyle(Theme.textTertiary.opacity(0.5))
        }
        .padding(.horizontal, 18)
        .padding(.vertical, 14)
        .contentShape(Rectangle())
    }
}
