import SwiftUI
import PhotosUI

struct PhotoStep: View {
    @Bindable var viewModel: AddRatingViewModel
    @State private var photoItem: PhotosPickerItem?
    @State private var showCamera = false
    @State private var showLibrary = false
    @State private var navigateToDish = false

    private var hasPhoto: Bool {
        viewModel.selectedPhoto != nil || viewModel.existingPhotoPath != nil
    }

    var body: some View {
        ZStack {
            Theme.background.ignoresSafeArea()

            VStack(spacing: 0) {
                restaurantHeader
                    .padding(.horizontal, 20)
                    .padding(.top, 12)

                photoArea
                    .padding(.horizontal, 20)
            }
        }
        .safeAreaInset(edge: .bottom) {
            bottomBar
                .padding(.horizontal, 20)
                .padding(.bottom, 12)
                .background(Theme.background)
        }
        .navigationTitle("Add a photo")
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(Theme.background, for: .navigationBar)
        .toolbarBackground(.visible, for: .navigationBar)
        .toolbar {
            if !hasPhoto {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Skip") { navigateToDish = true }
                        .foregroundStyle(Theme.accent)
                }
            }
        }
        .navigationDestination(isPresented: $navigateToDish) {
            DishPickerStep(viewModel: viewModel)
        }
        .fullScreenCover(isPresented: $showCamera) {
            CameraPicker { viewModel.selectedPhoto = $0 }
                .ignoresSafeArea()
        }
        .photosPicker(isPresented: $showLibrary, selection: $photoItem, matching: .images)
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
        Group {
            if let image = viewModel.selectedPhoto {
                VStack(spacing: 0) {
                    selectedPhotoView(image).padding(.top, 24)
                    Spacer(minLength: 0)
                }
            } else if let path = viewModel.existingPhotoPath,
                      let url = dishPhotoURL(path: path) {
                VStack(spacing: 0) {
                    existingPhotoView(url).padding(.top, 24)
                    Spacer(minLength: 0)
                }
            } else {
                VStack {
                    Spacer()
                    sourceButtons
                    Spacer()
                }
            }
        }
        .frame(maxHeight: .infinity)
    }

    // MARK: - Empty state

    private var sourceButtons: some View {
        HStack(spacing: 12) {
            if cameraIsAvailable {
                sourceButton(icon: "camera.fill", title: "Take Photo") {
                    showCamera = true
                }
            }
            sourceButton(icon: "photo.on.rectangle", title: "Choose from Library") {
                showLibrary = true
            }
        }
    }

    private func sourceButton(
        icon: String,
        title: String,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            VStack(spacing: 12) {
                Image(systemName: icon)
                    .font(.system(size: 26, weight: .medium))
                    .foregroundStyle(Theme.accent)
                Text(title)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(Theme.textPrimary)
                    .multilineTextAlignment(.center)
            }
            .frame(maxWidth: .infinity)
            .frame(height: 150)
            .elevatedCard(cornerRadius: 18)
        }
        .buttonStyle(PressableButtonStyle())
    }

    // MARK: - Photo present

    private func selectedPhotoView(_ image: UIImage) -> some View {
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
    }

    private func existingPhotoView(_ url: URL) -> some View {
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

            PhotoSourceMenu(onCamera: { showCamera = true }, onLibrary: { showLibrary = true }) {
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
    }

    // MARK: - Bottom bar

    private var bottomBar: some View {
        Button {
            navigateToDish = true
        } label: {
            HStack(spacing: 8) {
                Text(hasPhoto ? "Continue" : "Skip for now")
                if !hasPhoto {
                    Image(systemName: "arrow.right")
                        .font(.system(size: 14, weight: .semibold))
                }
            }
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
    }
}
