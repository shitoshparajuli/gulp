import SwiftUI
import PhotosUI

struct PhotoStep: View {
    @Bindable var viewModel: AddRatingViewModel
    @State private var photoItem: PhotosPickerItem?
    @State private var navigateToDish = false

    var body: some View {
        ZStack {
            Theme.background.ignoresSafeArea()

            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    restaurantHeader
                        .padding(.horizontal, 20)
                        .padding(.top, 12)

                    photoArea
                        .padding(.horizontal, 20)
                }
                .padding(.bottom, 24)
            }
        }
        .safeAreaInset(edge: .bottom) {
            continueButton
                .padding(.horizontal, 20)
                .padding(.bottom, 12)
                .background(Theme.background)
        }
        .navigationTitle("Add a photo")
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(Theme.background, for: .navigationBar)
        .toolbarBackground(.visible, for: .navigationBar)
        .navigationDestination(isPresented: $navigateToDish) {
            DishPickerStep(viewModel: viewModel)
        }
    }

    private var restaurantHeader: some View {
        HStack(alignment: .top, spacing: 10) {
            Image(systemName: "mappin.and.ellipse")
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(Theme.accent)
                .padding(.top, 2)
            VStack(alignment: .leading, spacing: 2) {
                Text(viewModel.pickedRestaurant?.name.uppercased() ?? "")
                    .font(.system(size: 13, weight: .bold))
                    .tracking(0.6)
                    .foregroundStyle(Theme.textPrimary)
                    .lineLimit(2)
                if let addr = viewModel.pickedRestaurant?.address {
                    Text(addr)
                        .font(.system(size: 11))
                        .foregroundStyle(Theme.textSecondary)
                        .lineLimit(1)
                }
            }
            Spacer(minLength: 8)
        }
    }

    @ViewBuilder
    private var photoArea: some View {
        if let image = viewModel.selectedPhoto {
            ZStack(alignment: .topTrailing) {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFill()
                    .frame(maxWidth: .infinity)
                    .frame(height: 320)
                    .clipped()
                    .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
                    .overlay {
                        RoundedRectangle(cornerRadius: 20, style: .continuous)
                            .stroke(Theme.hairline, lineWidth: 1)
                    }

                Button {
                    viewModel.selectedPhoto = nil
                    photoItem = nil
                } label: {
                    Image(systemName: "xmark")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundStyle(.white)
                        .frame(width: 28, height: 28)
                        .background(.black.opacity(0.55))
                        .clipShape(Circle())
                }
                .padding(10)
            }
        } else if let path = viewModel.existingPhotoPath,
                  let url = dishPhotoURL(path: path) {
            ZStack(alignment: .bottomTrailing) {
                AsyncImage(url: url) { image in
                    image.resizable().scaledToFill()
                } placeholder: {
                    Theme.surface
                }
                .frame(maxWidth: .infinity)
                .frame(height: 320)
                .clipped()
                .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
                .overlay {
                    RoundedRectangle(cornerRadius: 20, style: .continuous)
                        .stroke(Theme.hairline, lineWidth: 1)
                }

                PhotosPicker(selection: $photoItem, matching: .images) {
                    Text("Replace")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(.white)
                        .padding(.horizontal, 14)
                        .padding(.vertical, 8)
                        .background(.black.opacity(0.6))
                        .clipShape(Capsule())
                }
                .padding(12)
            }
        } else {
            PhotosPicker(selection: $photoItem, matching: .images) {
                VStack(spacing: 14) {
                    Image(systemName: "camera.fill")
                        .font(.system(size: 28, weight: .medium))
                        .foregroundStyle(Theme.accent)
                    Text("Add a photo")
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundStyle(Theme.textPrimary)
                    Text("So you remember exactly what it looked like.")
                        .font(.system(size: 12))
                        .foregroundStyle(Theme.textSecondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 24)
                }
                .frame(maxWidth: .infinity)
                .frame(height: 220)
                .background(
                    LinearGradient(
                        colors: [Theme.cardTop, Theme.cardBottom],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .overlay {
                    RoundedRectangle(cornerRadius: 20, style: .continuous)
                        .strokeBorder(
                            Theme.hairline,
                            style: StrokeStyle(lineWidth: 1, dash: [6, 4])
                        )
                }
                .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
            }
        }
    }

    private var continueButton: some View {
        let hasPhoto = viewModel.selectedPhoto != nil
        return Button {
            navigateToDish = true
        } label: {
            Text(hasPhoto ? "Continue" : "Skip for now")
                .font(.system(size: 16, weight: .semibold))
                .foregroundStyle(hasPhoto ? .black : Theme.textPrimary)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(hasPhoto ? AnyShapeStyle(Theme.accent) : AnyShapeStyle(Theme.surface))
                .overlay {
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .stroke(hasPhoto ? Color.clear : Theme.hairline, lineWidth: 1)
                }
                .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        }
        .onChange(of: photoItem) { _, item in
            guard let item else { return }
            Task {
                if let data = try? await item.loadTransferable(type: Data.self),
                   let image = UIImage(data: data) {
                    viewModel.selectedPhoto = image
                }
            }
        }
    }
}
