import SwiftUI

struct DishDetailView: View {
    let dish: DishResponse
    @State private var viewModel: DishDetailViewModel
    @State private var editingRating: RatingResponse?
    @State private var rateExisting: RestaurantResponse?

    init(dish: DishResponse) {
        self.dish = dish
        _viewModel = State(initialValue: DishDetailViewModel(dish: dish))
    }

    var body: some View {
        ZStack {
            Theme.background.ignoresSafeArea()

            ScrollView {
                VStack(spacing: 28) {
                    if let path = viewModel.myRating?.photoPath, let url = dishPhotoURL(path: path) {
                        photoBlock(url: url)
                            .padding(.horizontal, 20)
                    }

                    hero
                    dishInfo
                    if viewModel.myRating != nil { communityChip }
                    if let notes = viewModel.myRating?.notes, !notes.isEmpty {
                        notesCard(notes).padding(.horizontal, 20)
                    }
                    Spacer(minLength: 104)
                }
                .padding(.top, 18)
            }

            VStack {
                Spacer()
                bottomCTA
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
        .sheet(item: $editingRating, onDismiss: { Task { await viewModel.load() } }) { rating in
            AddRatingView(mode: .editRating(rating))
        }
        .sheet(item: $rateExisting, onDismiss: { Task { await viewModel.load() } }) { restaurant in
            AddRatingView(mode: .addToRestaurant(restaurant))
        }
    }

    @ViewBuilder
    private var hero: some View {
        if let myScore = viewModel.myRating?.score {
            VStack(spacing: 6) {
                Text("\(myScore)")
                    .font(.system(size: 120, weight: .bold, design: .rounded))
                    .foregroundStyle(scoreGradient(Double(myScore)))
                    .shadow(color: scoreColor(Double(myScore)).opacity(0.4), radius: 30, x: 0, y: 0)
                    .monospacedDigit()
                Text("YOUR RATING")
                    .font(.system(size: 11, weight: .heavy))
                    .tracking(1.5)
                    .foregroundStyle(Theme.textTertiary)
            }
            .frame(maxWidth: .infinity)
        } else if let avg = viewModel.communityAvg {
            VStack(spacing: 6) {
                Text(formattedAvg(avg))
                    .font(.system(size: 96, weight: .bold, design: .rounded))
                    .foregroundStyle(scoreGradient(avg))
                    .shadow(color: scoreColor(avg).opacity(0.35), radius: 24, x: 0, y: 0)
                    .monospacedDigit()
                Text("COMMUNITY AVG · \(viewModel.communityCount) RATING\(viewModel.communityCount == 1 ? "" : "S")")
                    .font(.system(size: 11, weight: .heavy))
                    .tracking(1.4)
                    .foregroundStyle(Theme.textTertiary)
            }
            .frame(maxWidth: .infinity)
        } else {
            VStack(spacing: 6) {
                Text("—")
                    .font(.system(size: 96, weight: .bold, design: .rounded))
                    .foregroundStyle(Theme.textTertiary)
                Text("NO RATINGS YET")
                    .font(.system(size: 11, weight: .heavy))
                    .tracking(1.4)
                    .foregroundStyle(Theme.textTertiary)
            }
            .frame(maxWidth: .infinity)
        }
    }

    private var dishInfo: some View {
        VStack(spacing: 10) {
            Text(dish.displayName)
                .font(.system(size: 28, weight: .bold))
                .foregroundStyle(Theme.textPrimary)
                .multilineTextAlignment(.center)

            NavigationLink {
                RestaurantDetailView(restaurant: dish.restaurant)
            } label: {
                HStack(spacing: 8) {
                    Text(dish.restaurant.name.uppercased())
                        .font(.system(size: 12, weight: .heavy))
                        .tracking(1.2)
                        .foregroundStyle(Theme.textSecondary)
                    if let cuisine = dish.cuisine {
                        Circle().fill(Theme.textTertiary).frame(width: 3, height: 3)
                        Text(cuisine)
                            .font(.system(size: 12, weight: .medium))
                            .foregroundStyle(Theme.textTertiary)
                    }
                    Image(systemName: "chevron.right")
                        .font(.system(size: 9, weight: .bold))
                        .foregroundStyle(Theme.textTertiary)
                }
            }
            .buttonStyle(.plain)
        }
        .frame(maxWidth: .infinity)
        .padding(.horizontal, 24)
    }

    @ViewBuilder
    private var communityChip: some View {
        if let avg = viewModel.communityAvg {
            HStack(spacing: 10) {
                Text(formattedAvg(avg))
                    .font(.system(size: 18, weight: .bold, design: .rounded))
                    .foregroundStyle(scoreGradient(avg))
                    .monospacedDigit()
                Rectangle()
                    .fill(Theme.hairline)
                    .frame(width: 1, height: 18)
                VStack(alignment: .leading, spacing: 1) {
                    Text("COMMUNITY")
                        .font(.system(size: 9, weight: .heavy))
                        .tracking(1.2)
                        .foregroundStyle(Theme.textTertiary)
                    Text("\(viewModel.communityCount) rating\(viewModel.communityCount == 1 ? "" : "s")")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundStyle(Theme.textSecondary)
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
            .background(Theme.surface)
            .overlay {
                Capsule().stroke(Theme.hairline, lineWidth: 1)
            }
            .clipShape(Capsule())
        } else {
            EmptyView()
        }
    }

    private func notesCard(_ notes: String) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 6) {
                Image(systemName: "quote.opening")
                    .font(.system(size: 10, weight: .bold))
                Text("YOUR NOTES")
                    .font(.system(size: 10, weight: .heavy))
                    .tracking(1.2)
            }
            .foregroundStyle(Theme.textTertiary)

            Text(notes)
                .font(.system(size: 16))
                .foregroundStyle(Theme.textPrimary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(20)
        .elevatedCard(cornerRadius: 16)
    }

    private func photoBlock(url: URL) -> some View {
        AsyncImage(url: url) { image in
            image.resizable().scaledToFill()
        } placeholder: {
            Theme.surface
        }
        .frame(maxWidth: .infinity)
        .frame(height: 240)
        .clipped()
        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .stroke(Theme.hairline, lineWidth: 1)
        }
    }

    @ViewBuilder
    private var bottomCTA: some View {
        if let mine = viewModel.myRating {
            Button {
                editingRating = mine
            } label: {
                ctaLabel(icon: "pencil", text: "Edit your rating", filled: false)
            }
        } else {
            Button {
                rateExisting = dish.restaurant
            } label: {
                ctaLabel(icon: "plus", text: "Rate this dish", filled: true)
            }
        }
    }

    private func ctaLabel(icon: String, text: String, filled: Bool) -> some View {
        HStack(spacing: 8) {
            Image(systemName: icon)
                .font(.system(size: 14, weight: .semibold))
            Text(text)
                .font(.system(size: 15, weight: .semibold))
        }
        .foregroundStyle(filled ? .white : Theme.textPrimary)
        .frame(maxWidth: .infinity)
        .padding(.vertical, 14)
        .background(filled ? Theme.accent : Theme.surface)
        .overlay {
            if !filled {
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .stroke(Theme.hairline, lineWidth: 1)
            }
        }
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
    }

    private func formattedAvg(_ value: Double) -> String {
        value.truncatingRemainder(dividingBy: 1) == 0
            ? String(format: "%.0f", value)
            : String(format: "%.1f", value)
    }
}
