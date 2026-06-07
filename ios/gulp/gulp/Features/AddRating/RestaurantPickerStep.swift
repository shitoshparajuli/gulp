import SwiftUI

struct RestaurantPickerStep: View {
    @Bindable var viewModel: AddRatingViewModel
    @Binding var path: [AddRatingStep]
    @State private var searchService = RestaurantSearchService()
    @State private var query: String = ""

    var body: some View {
        ZStack {
            Theme.background.ignoresSafeArea()

            VStack(spacing: 0) {
                searchField
                    .padding(.horizontal, 20)
                    .padding(.top, 8)
                    .padding(.bottom, 12)

                if query.isEmpty {
                    promptState
                } else if searchService.suggestions.isEmpty {
                    Spacer()
                } else {
                    suggestionsList
                }
            }
        }
    }

    private var searchField: some View {
        HStack(spacing: 10) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(Theme.textTertiary)
            TextField("Search restaurants, cafes...", text: $query)
                .textFieldStyle(.plain)
                .foregroundStyle(Theme.textPrimary)
                .tint(Theme.accent)
                .autocorrectionDisabled()
                .onChange(of: query) { _, new in
                    searchService.update(query: new)
                }
            if !query.isEmpty {
                Button { query = "" } label: {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 14))
                        .foregroundStyle(Theme.textTertiary)
                }
            }
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
        .background(Theme.surface)
        .overlay {
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .stroke(Theme.hairline, lineWidth: 1)
        }
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
    }

    private var promptState: some View {
        VStack(spacing: 12) {
            Spacer()
            Image(systemName: "mappin.and.ellipse")
                .font(.system(size: 36, weight: .medium))
                .foregroundStyle(Theme.accent.opacity(0.7))
            Text("Find the place")
                .font(.system(size: 17, weight: .semibold))
                .foregroundStyle(Theme.textPrimary)
            Text("We'll save what you order and how it was.")
                .font(.system(size: 13))
                .foregroundStyle(Theme.textSecondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)
            Spacer()
        }
    }

    private var suggestionsList: some View {
        ScrollView {
            LazyVStack(spacing: 0) {
                ForEach(searchService.suggestions) { suggestion in
                    Button {
                        Task { await pick(suggestion) }
                    } label: {
                        HStack(spacing: 12) {
                            Image(systemName: "fork.knife")
                                .font(.system(size: 13, weight: .semibold))
                                .foregroundStyle(Theme.accent)
                                .frame(width: 32, height: 32)
                                .background(Theme.surface)
                                .clipShape(Circle())
                            VStack(alignment: .leading, spacing: 2) {
                                Text(suggestion.title)
                                    .font(.system(size: 15, weight: .semibold))
                                    .foregroundStyle(Theme.textPrimary)
                                    .lineLimit(1)
                                if !suggestion.subtitle.isEmpty {
                                    Text(suggestion.subtitle)
                                        .font(.system(size: 12))
                                        .foregroundStyle(Theme.textSecondary)
                                        .lineLimit(1)
                                }
                            }
                            Spacer()
                            Image(systemName: "chevron.right")
                                .font(.system(size: 11, weight: .semibold))
                                .foregroundStyle(Theme.textTertiary)
                        }
                        .padding(.horizontal, 20)
                        .padding(.vertical, 12)
                        .contentShape(Rectangle())
                    }
                    .buttonStyle(PressableButtonStyle())

                    Rectangle()
                        .fill(Theme.hairline)
                        .frame(height: 1)
                        .padding(.leading, 64)
                }
            }
        }
        .overlay(alignment: .top) {
            if viewModel.isWorking {
                ProgressView()
                    .tint(Theme.accent)
                    .padding(.top, 8)
            }
        }
    }

    private func pick(_ suggestion: SearchSuggestion) async {
        do {
            let place = try await searchService.resolve(suggestion)
            await viewModel.selectRestaurant(place)
            if viewModel.pickedRestaurantId != nil {
                path.append(.photo)
            }
        } catch {
            viewModel.errorMessage = error.localizedDescription
        }
    }
}
