import SwiftUI

func scoreColor(_ score: Double) -> Color {
    switch score {
    case 8.0...: return Color(red: 0.13, green: 0.75, blue: 0.37)
    case 6.0...: return Color(red: 1.0, green: 0.58, blue: 0.0)
    default:     return Color(red: 0.94, green: 0.27, blue: 0.23)
    }
}

struct RatingsView: View {
    @State private var viewModel = RatingsViewModel()
    @State private var selectedRating: RatingResponse?

    var body: some View {
        NavigationStack {
            Group {
                if viewModel.isLoading {
                    ProgressView()
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else if viewModel.groups.isEmpty {
                    emptyState
                } else {
                    ScrollView {
                        LazyVStack(spacing: 14) {
                            ForEach(viewModel.groups) { group in
                                RestaurantCard(group: group) { rating in
                                    selectedRating = rating
                                }
                            }
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 12)
                    }
                }
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("My Ratings")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        Task { await viewModel.load() }
                    } label: {
                        Image(systemName: "arrow.clockwise")
                    }
                }
            }
        }
        .task { await viewModel.load() }
        .sheet(item: $selectedRating) { rating in
            DishDetailSheet(rating: rating)
        }
    }

    private var emptyState: some View {
        VStack(spacing: 12) {
            Text("🍽️")
                .font(.system(size: 60))
            Text("No ratings yet")
                .font(.title3.bold())
            Text("Rate dishes to see them here")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

struct RestaurantCard: View {
    let group: RestaurantGroup
    let onDishTap: (RatingResponse) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(alignment: .center) {
                VStack(alignment: .leading, spacing: 3) {
                    Text(group.restaurant.name)
                        .font(.headline)
                    HStack(spacing: 4) {
                        if let address = group.restaurant.address {
                            Text(address)
                                .lineLimit(1)
                        }
                        Text("·")
                        Text("\(group.ratings.count) dish\(group.ratings.count == 1 ? "" : "es")")
                    }
                    .font(.caption)
                    .foregroundStyle(.secondary)
                }
                Spacer()
                if let avg = group.averageScore {
                    VStack(spacing: 1) {
                        Text(String(format: "%.1f", avg))
                            .font(.title3.bold())
                            .foregroundStyle(scoreColor(avg))
                        Text("avg")
                            .font(.system(size: 9, weight: .medium))
                            .foregroundStyle(.tertiary)
                    }
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 14)

            Divider().padding(.leading, 16)

            ForEach(Array(group.ratings.enumerated()), id: \.element.id) { index, rating in
                Button { onDishTap(rating) } label: {
                    HStack(spacing: 12) {
                        VStack(alignment: .leading, spacing: 2) {
                            Text(rating.dish.displayName)
                                .font(.subheadline)
                                .foregroundStyle(.primary)
                            if let notes = rating.notes, !notes.isEmpty {
                                Text(notes)
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                                    .lineLimit(1)
                            }
                        }
                        Spacer()
                        if let score = rating.score {
                            Text("\(score)")
                                .font(.subheadline.bold())
                                .foregroundStyle(.white)
                                .frame(width: 32, height: 32)
                                .background(scoreColor(Double(score)))
                                .clipShape(Circle())
                        }
                        Image(systemName: "chevron.right")
                            .font(.caption2)
                            .foregroundStyle(.tertiary)
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)
                }
                .buttonStyle(.plain)

                if index < group.ratings.count - 1 {
                    Divider().padding(.leading, 16)
                }
            }
        }
        .background(Color(.secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 2)
    }
}
