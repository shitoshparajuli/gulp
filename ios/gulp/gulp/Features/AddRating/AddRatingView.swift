import SwiftUI

struct AddRatingView: View {
    @State private var viewModel = AddRatingViewModel()
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            RestaurantPickerStep(viewModel: viewModel)
                .navigationTitle("Where'd you eat?")
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
