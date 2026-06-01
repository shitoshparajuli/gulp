import SwiftUI

enum AddRatingMode {
    case newFromScratch
    case addToRestaurant(RestaurantResponse)
    case editRating(RatingResponse)
}

struct AddRatingView: View {
    let mode: AddRatingMode
    @State private var viewModel = AddRatingViewModel()
    @Environment(\.dismiss) private var dismiss

    init(mode: AddRatingMode = .newFromScratch) {
        self.mode = mode
    }

    var body: some View {
        NavigationStack {
            root
                .navigationTitle(title)
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .topBarLeading) {
                        Button("Cancel") { dismiss() }
                            .foregroundStyle(Theme.textSecondary)
                    }
                }
                .toolbarBackground(Theme.background, for: .navigationBar)
                .toolbarBackground(.visible, for: .navigationBar)
        }
        .preferredColorScheme(.dark)
        .presentationBackground(Theme.background)
        .environment(\.dismissAddFlow, dismiss)
        .task { await configure() }
    }

    private var title: String {
        switch mode {
        case .newFromScratch:      return "Where'd you eat?"
        case .addToRestaurant:     return "Add a photo"
        case .editRating:          return "Edit rating"
        }
    }

    @ViewBuilder
    private var root: some View {
        switch mode {
        case .newFromScratch:
            RestaurantPickerStep(viewModel: viewModel)
        case .addToRestaurant:
            PhotoStep(viewModel: viewModel)
        case .editRating:
            ScoreInputStep(viewModel: viewModel)
        }
    }

    private func configure() async {
        switch mode {
        case .newFromScratch:
            break
        case .addToRestaurant(let restaurant):
            await viewModel.configureForAddToRestaurant(restaurant: restaurant)
        case .editRating(let rating):
            viewModel.configureForEdit(rating: rating)
        }
    }
}

private struct DismissAddFlowKey: EnvironmentKey {
    static let defaultValue: DismissAction? = nil
}

extension EnvironmentValues {
    var dismissAddFlow: DismissAction? {
        get { self[DismissAddFlowKey.self] }
        set { self[DismissAddFlowKey.self] = newValue }
    }
}
