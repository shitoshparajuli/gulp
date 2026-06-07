import SwiftUI

enum AddRatingMode {
    case newFromScratch
    case addToRestaurant(RestaurantResponse)
    case editRating(RatingResponse)
}

/// The per-dish steps that get pushed onto the flow's navigation stack. The
/// restaurant pick (when present) is the stack root, not a step here, so it's
/// never revisited once chosen. Driving navigation through a shared path lets
/// "Save & add another" pop straight back to `.photo` for the next dish.
enum AddRatingStep: Hashable {
    case photo
    case dish
    case score
}

struct AddRatingView: View {
    let mode: AddRatingMode
    @State private var viewModel = AddRatingViewModel()
    @State private var path: [AddRatingStep] = []
    @Environment(\.dismiss) private var dismiss

    init(mode: AddRatingMode = .newFromScratch) {
        self.mode = mode
    }

    var body: some View {
        NavigationStack(path: $path) {
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
                .navigationDestination(for: AddRatingStep.self) { step in
                    switch step {
                    case .photo:
                        PhotoStep(viewModel: viewModel, path: $path)
                    case .dish:
                        DishPickerStep(viewModel: viewModel, path: $path)
                    case .score:
                        ScoreInputStep(
                            viewModel: viewModel,
                            path: $path,
                            allowAddAnother: allowsAddingAnother,
                            loopBase: loopBase
                        )
                    }
                }
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
            RestaurantPickerStep(viewModel: viewModel, path: $path)
        case .addToRestaurant:
            PhotoStep(viewModel: viewModel, path: $path)
        case .editRating:
            ScoreInputStep(viewModel: viewModel, path: $path)
        }
    }

    /// Editing a single existing rating is a standalone action — no looping.
    /// The two "new rating" flows let you keep rating dishes at the same place.
    private var allowsAddingAnother: Bool {
        switch mode {
        case .editRating: return false
        default:          return true
        }
    }

    /// Where "Save & add another" returns to. For `.newFromScratch` the photo
    /// step sits above the restaurant root, so we leave `.photo` on the stack;
    /// for `.addToRestaurant` the photo step *is* the root, so we clear to it.
    private var loopBase: [AddRatingStep] {
        switch mode {
        case .newFromScratch: return [.photo]
        default:              return []
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
