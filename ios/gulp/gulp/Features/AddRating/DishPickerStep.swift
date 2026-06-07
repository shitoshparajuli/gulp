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
