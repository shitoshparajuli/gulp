import SwiftUI

struct DishPickerStep: View {
    @Bindable var viewModel: AddRatingViewModel
    @Binding var path: [AddRatingStep]
    @State private var addingNew = false
    @FocusState private var newDishFocused: Bool

    var body: some View {
        ZStack {
            Theme.background.ignoresSafeArea()

            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    restaurantHeader
                        .padding(.horizontal, 20)
                        .padding(.top, 12)

                    suggestionsSection

                    if addingNew || viewModel.existingDishes.isEmpty {
                        newDishCard
                            .padding(.horizontal, 20)
                    }

                    if !viewModel.myRatedDishes.isEmpty {
                        dishSection(
                            title: "ALREADY ORDERED HERE",
                            dishes: viewModel.myRatedDishes
                        )
                    }

                    if !viewModel.otherDishes.isEmpty {
                        dishSection(
                            title: "DISHES HERE",
                            dishes: viewModel.otherDishes
                        )
                    }

                    if !addingNew && !viewModel.existingDishes.isEmpty {
                        Button { addingNew = true; newDishFocused = true } label: {
                            HStack(spacing: 8) {
                                Image(systemName: "plus.circle.fill")
                                    .font(.system(size: 16, weight: .semibold))
                                Text("Add a different dish")
                                    .font(.system(size: 14, weight: .semibold))
                            }
                            .foregroundStyle(Theme.accent)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                        }
                        .padding(.horizontal, 20)
                    }

                    Spacer(minLength: 100)
                }
            }

            VStack {
                Spacer()
                continueButton
                    .padding(.horizontal, 20)
                    .padding(.bottom, 24)
            }
        }
        .navigationTitle("What'd you have?")
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(Theme.background, for: .navigationBar)
        .toolbarBackground(.visible, for: .navigationBar)
    }

    private var restaurantHeader: some View {
        HStack(spacing: 10) {
            Image(systemName: "mappin.and.ellipse")
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(Theme.accent)
            VStack(alignment: .leading, spacing: 2) {
                Text(viewModel.pickedRestaurant?.name.uppercased() ?? "")
                    .font(.system(size: 13, weight: .bold))
                    .tracking(0.6)
                    .foregroundStyle(Theme.textPrimary)
                if let addr = viewModel.pickedRestaurant?.address {
                    Text(addr)
                        .font(.system(size: 11))
                        .foregroundStyle(Theme.textSecondary)
                        .lineLimit(1)
                }
            }
            Spacer()
        }
    }

    @ViewBuilder
    private var suggestionsSection: some View {
        if viewModel.isSuggestingDishes || !viewModel.suggestedDishNames.isEmpty {
            VStack(alignment: .leading, spacing: 12) {
                Text("FROM YOUR PHOTO")
                    .font(.system(size: 10, weight: .heavy))
                    .tracking(1.2)
                    .foregroundStyle(Theme.textTertiary)
                    .padding(.horizontal, 20)

                if viewModel.suggestedDishNames.isEmpty {
                    suggestionsLoading
                        .padding(.horizontal, 20)
                } else {
                    VStack(alignment: .leading, spacing: 10) {
                        heroSuggestion(viewModel.suggestedDishNames[0])
                        let rest = Array(viewModel.suggestedDishNames.dropFirst())
                        if !rest.isEmpty {
                            FlowLayout(spacing: 8) {
                                ForEach(rest, id: \.self) { name in
                                    secondaryChip(name)
                                }
                            }
                        }
                    }
                    .padding(.horizontal, 20)
                }
            }
            .animation(.easeInOut(duration: 0.25), value: viewModel.suggestedDishNames)
        }
    }

    private func use(_ name: String) {
        addingNew = true
        viewModel.newDishName = name
    }

    /// The most-likely dish — accent-tinted, elevated with a soft coral glow.
    private func heroSuggestion(_ name: String) -> some View {
        Button { use(name) } label: {
            HStack(spacing: 12) {
                Text(name)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(Theme.textPrimary)
                    .lineLimit(1)
                Spacer(minLength: 8)
                Image(systemName: "arrow.right")
                    .font(.system(size: 13, weight: .bold))
                    .foregroundStyle(Theme.accent)
            }
            .padding(.horizontal, 18)
            .padding(.vertical, 15)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(Theme.accent.opacity(0.13))
            )
            .overlay {
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .stroke(Theme.accent.opacity(0.40), lineWidth: 1)
            }
            .shadow(color: Theme.accent.opacity(0.18), radius: 12, x: 0, y: 4)
        }
        .buttonStyle(PressableButtonStyle())
    }

    /// Lower-ranked picks — quiet, borderless-feeling chips that defer to the hero.
    private func secondaryChip(_ name: String) -> some View {
        Button { use(name) } label: {
            Text(name)
                .font(.system(size: 14, weight: .medium))
                .foregroundStyle(Theme.textPrimary)
                .lineLimit(1)
                .padding(.horizontal, 14)
                .padding(.vertical, 9)
                .background(Theme.surface, in: Capsule())
                .overlay {
                    Capsule().stroke(Theme.hairline, lineWidth: 1)
                }
        }
        .buttonStyle(PressableButtonStyle())
    }

    private var suggestionsLoading: some View {
        VStack(alignment: .leading, spacing: 10) {
            ghost(height: 52, corner: 16)
                .frame(maxWidth: .infinity)
            HStack(spacing: 8) {
                ghost(width: 120, height: 34, corner: 17)
                ghost(width: 84, height: 34, corner: 17)
            }
        }
    }

    private func ghost(width: CGFloat? = nil, height: CGFloat, corner: CGFloat) -> some View {
        RoundedRectangle(cornerRadius: corner, style: .continuous)
            .fill(Theme.surfaceElevated)
            .frame(width: width, height: height)
            .overlay(ShimmerOverlay())
            .clipShape(RoundedRectangle(cornerRadius: corner, style: .continuous))
    }

    private var newDishCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("NEW DISH")
                .font(.system(size: 10, weight: .heavy))
                .tracking(1.2)
                .foregroundStyle(Theme.textTertiary)
            TextField("Dish name", text: $viewModel.newDishName)
                .textFieldStyle(.plain)
                .font(.system(size: 17, weight: .medium))
                .foregroundStyle(Theme.textPrimary)
                .tint(Theme.accent)
                .focused($newDishFocused)
                .onChange(of: viewModel.newDishName) { _, val in
                    if !val.isEmpty { viewModel.clearDishSelection() }
                }
            Rectangle().fill(Theme.hairline).frame(height: 1)
            TextField("Cuisine (optional)", text: $viewModel.newDishCuisine)
                .textFieldStyle(.plain)
                .font(.system(size: 14))
                .foregroundStyle(Theme.textPrimary)
                .tint(Theme.accent)
        }
        .padding(18)
        .elevatedCard(cornerRadius: 16)
    }

    private func dishSection(title: String, dishes: [DishOption]) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(title)
                .font(.system(size: 10, weight: .heavy))
                .tracking(1.2)
                .foregroundStyle(Theme.textTertiary)
                .padding(.horizontal, 20)

            VStack(spacing: 0) {
                ForEach(dishes) { dish in
                    dishRow(dish)
                    if dish.id != dishes.last?.id {
                        Rectangle()
                            .fill(Theme.hairline)
                            .frame(height: 1)
                            .padding(.leading, 20)
                    }
                }
            }
            .elevatedCard(cornerRadius: 16)
            .padding(.horizontal, 20)
        }
    }

    private func dishRow(_ dish: DishOption) -> some View {
        Button {
            Task { await viewModel.selectExistingDish(dish) }
            addingNew = false
        } label: {
            HStack(spacing: 12) {
                VStack(alignment: .leading, spacing: 2) {
                    Text(dish.displayName)
                        .font(.system(size: 15, weight: .medium))
                        .foregroundStyle(Theme.textPrimary)
                    if let cuisine = dish.cuisine {
                        Text(cuisine)
                            .font(.system(size: 11))
                            .foregroundStyle(Theme.textTertiary)
                    }
                }
                Spacer()
                if viewModel.pickedDish?.id == dish.id {
                    if viewModel.editingRatingId != nil {
                        Text("EDIT")
                            .font(.system(size: 9, weight: .heavy))
                            .tracking(0.8)
                            .foregroundStyle(Theme.accent)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(Theme.accent.opacity(0.15))
                            .clipShape(Capsule())
                    }
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundStyle(Theme.accent)
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 14)
            .contentShape(Rectangle())
        }
        .buttonStyle(PressableButtonStyle())
    }

    private var continueButton: some View {
        Button { path.append(.score) } label: {
            Text(viewModel.editingRatingId != nil ? "Edit Rating" : "Continue")
                .font(.system(size: 16, weight: .semibold))
                .foregroundStyle(.black)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(viewModel.canProceedToScore ? Theme.accent : Theme.surface)
                .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        }
        .disabled(!viewModel.canProceedToScore || viewModel.isWorking)
        .animation(.easeOut(duration: 0.15), value: viewModel.canProceedToScore)
    }
}

/// Animated highlight sweep for skeleton placeholders while suggestions load.
private struct ShimmerOverlay: View {
    @State private var phase: CGFloat = 0

    var body: some View {
        GeometryReader { geo in
            let w = geo.size.width
            LinearGradient(
                colors: [.clear, Color.white.opacity(0.10), .clear],
                startPoint: .leading,
                endPoint: .trailing
            )
            .frame(width: w * 0.55)
            .offset(x: -w * 0.8 + phase * (w * 1.6))
            .onAppear {
                withAnimation(.linear(duration: 1.1).repeatForever(autoreverses: false)) {
                    phase = 1
                }
            }
        }
        .allowsHitTesting(false)
    }
}

/// Simple left-to-right wrapping layout for the suggestion chips.
struct FlowLayout: Layout {
    var spacing: CGFloat = 8

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let maxWidth = proposal.width ?? .infinity
        var x: CGFloat = 0
        var y: CGFloat = 0
        var rowHeight: CGFloat = 0

        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)
            if x + size.width > maxWidth, x > 0 {
                x = 0
                y += rowHeight + spacing
                rowHeight = 0
            }
            x += size.width + spacing
            rowHeight = max(rowHeight, size.height)
        }
        return CGSize(width: proposal.width ?? x, height: y + rowHeight)
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        var x = bounds.minX
        var y = bounds.minY
        var rowHeight: CGFloat = 0

        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)
            if x + size.width > bounds.maxX, x > bounds.minX {
                x = bounds.minX
                y += rowHeight + spacing
                rowHeight = 0
            }
            subview.place(at: CGPoint(x: x, y: y), anchor: .topLeading, proposal: ProposedViewSize(size))
            x += size.width + spacing
            rowHeight = max(rowHeight, size.height)
        }
    }
}
