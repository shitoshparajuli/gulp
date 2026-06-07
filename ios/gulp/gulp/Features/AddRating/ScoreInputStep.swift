import SwiftUI
import PhotosUI

struct ScoreInputStep: View {
    @Bindable var viewModel: AddRatingViewModel
    @Binding var path: [AddRatingStep]
    /// Whether to offer "Save & add another" (false when editing a single rating).
    var allowAddAnother: Bool = false
    /// The navigation path to return to after "Save & add another".
    var loopBase: [AddRatingStep] = []
    @Environment(\.dismissAddFlow) private var dismissAddFlow

    @State private var photoItem: PhotosPickerItem?
    @State private var showCamera = false
    @State private var showLibrary = false
    @State private var activeSave: SaveAction?

    private enum SaveAction { case finish, another }

    var body: some View {
        ZStack {
            Theme.background.ignoresSafeArea()

            ScrollView {
                VStack(spacing: 0) {
                    if viewModel.isEditing {
                        editPhotoStrip
                            .padding(.horizontal, 20)
                            .padding(.top, 12)
                            .padding(.bottom, 18)
                    }

                    dishHeader
                        .padding(.top, viewModel.isEditing ? 0 : 8)
                        .padding(.bottom, 28)

                    scoreHero
                        .padding(.bottom, 18)

                    slider
                        .padding(.horizontal, 24)
                        .padding(.bottom, 32)

                    notesCard
                        .padding(.horizontal, 20)

                    if let error = viewModel.errorMessage {
                        Text(error)
                            .font(.system(size: 13))
                            .foregroundStyle(Color(red: 0.95, green: 0.45, blue: 0.45))
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 24)
                            .padding(.top, 16)
                    }

                    Spacer(minLength: 120)
                }
            }

            VStack {
                Spacer()
                actionBar
                    .padding(.horizontal, 20)
                    .padding(.bottom, 24)
            }
        }
        .navigationTitle(viewModel.isEditing ? "Edit rating" : "Rate it")
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(Theme.background, for: .navigationBar)
        .toolbarBackground(.visible, for: .navigationBar)
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

    private var dishName: String {
        viewModel.pickedDish?.displayName
            ?? (viewModel.newDishName.isEmpty ? "Your dish" : viewModel.newDishName)
    }

    @ViewBuilder
    private var editPhotoStrip: some View {
        PhotoSourceMenu(onCamera: { showCamera = true }, onLibrary: { showLibrary = true }) {
            HStack(spacing: 12) {
                photoThumbnail
                VStack(alignment: .leading, spacing: 2) {
                    Text(hasAnyPhoto ? "Replace photo" : "Add a photo")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(Theme.textPrimary)
                    Text(hasAnyPhoto ? "Take a new one or pick from your library"
                                     : "Snap one or pick from your library")
                        .font(.system(size: 11))
                        .foregroundStyle(Theme.textSecondary)
                }
                Spacer()
                Image(systemName: "camera.fill")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(Theme.accent)
            }
            .padding(12)
            .elevatedCard(cornerRadius: 14)
        }
    }

    private var hasAnyPhoto: Bool {
        viewModel.selectedPhoto != nil || viewModel.existingPhotoPath != nil
    }

    @ViewBuilder
    private var photoThumbnail: some View {
        Group {
            if let img = viewModel.selectedPhoto {
                Image(uiImage: img).resizable().scaledToFill()
            } else if let path = viewModel.existingPhotoPath, let url = dishPhotoURL(path: path) {
                AsyncImage(url: url) { image in
                    image.resizable().scaledToFill()
                } placeholder: {
                    Theme.surfaceElevated
                }
            } else {
                Theme.surfaceElevated
                    .overlay {
                        Image(systemName: "camera")
                            .font(.system(size: 16))
                            .foregroundStyle(Theme.textTertiary)
                    }
            }
        }
        .frame(width: 56, height: 56)
        .clipped()
        .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
    }

    private var dishHeader: some View {
        VStack(spacing: 4) {
            Text(dishName)
                .font(.system(size: 20, weight: .semibold))
                .foregroundStyle(Theme.textPrimary)
                .multilineTextAlignment(.center)
            if let rest = viewModel.pickedRestaurant {
                Text(rest.name.uppercased())
                    .font(.system(size: 10, weight: .heavy))
                    .tracking(1.2)
                    .foregroundStyle(Theme.textTertiary)
            }
        }
        .padding(.horizontal, 24)
    }

    private var scoreHero: some View {
        VStack(spacing: 12) {
            Text("\(viewModel.score)")
                .font(.system(size: 140, weight: .bold, design: .rounded))
                .foregroundStyle(scoreGradient(Double(viewModel.score)))
                .shadow(color: scoreColor(Double(viewModel.score)).opacity(0.5), radius: 36, x: 0, y: 0)
                .contentTransition(.numericText(value: Double(viewModel.score)))
                .animation(.spring(response: 0.3, dampingFraction: 0.7), value: viewModel.score)

            Text(scoreLabel(viewModel.score))
                .font(.system(size: 17, weight: .semibold))
                .foregroundStyle(scoreColor(Double(viewModel.score)))
                .contentTransition(.opacity)
                .id(viewModel.score)
                .transition(.opacity)
        }
        .frame(maxWidth: .infinity)
    }

    private var slider: some View {
        VStack(spacing: 8) {
            Slider(
                value: Binding(
                    get: { Double(viewModel.score) },
                    set: { viewModel.score = Int($0.rounded()) }
                ),
                in: 1...10,
                step: 1
            )
            .tint(scoreColor(Double(viewModel.score)))

            HStack {
                Text("1")
                Spacer()
                Text("10")
            }
            .font(.system(size: 11, weight: .medium))
            .foregroundStyle(Theme.textTertiary)
        }
    }

    private var notesCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("NOTES")
                .font(.system(size: 10, weight: .heavy))
                .tracking(1.2)
                .foregroundStyle(Theme.textTertiary)

            ZStack(alignment: .topLeading) {
                if viewModel.notes.isEmpty {
                    Text("What stood out? Anything to remember?")
                        .font(.system(size: 14))
                        .foregroundStyle(Theme.textTertiary)
                        .padding(.top, 4)
                        .padding(.leading, 4)
                }
                TextEditor(text: $viewModel.notes)
                    .scrollContentBackground(.hidden)
                    .font(.system(size: 14))
                    .foregroundStyle(Theme.textPrimary)
                    .tint(Theme.accent)
                    .frame(minHeight: 80)
            }
        }
        .padding(16)
        .elevatedCard(cornerRadius: 16)
    }

    @ViewBuilder
    private var actionBar: some View {
        VStack(spacing: 10) {
            if allowAddAnother {
                addAnotherButton
            }
            finishButton
        }
    }

    private var finishTitle: String {
        if allowAddAnother { return "Save & finish" }
        return viewModel.isEditing ? "Save Changes" : "Save Rating"
    }

    private var finishButton: some View {
        Button {
            activeSave = .finish
            Task {
                let ok = await viewModel.save()
                if ok {
                    dismissAddFlow?()
                } else {
                    activeSave = nil
                }
            }
        } label: {
            HStack(spacing: 8) {
                if activeSave == .finish {
                    ProgressView().tint(.black)
                }
                Text(activeSave == .finish ? "Saving..." : finishTitle)
                    .font(.system(size: 16, weight: .semibold))
            }
            .foregroundStyle(.black)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(Theme.accent)
            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        }
        .disabled(activeSave != nil)
    }

    private var addAnotherButton: some View {
        Button {
            activeSave = .another
            Task {
                let ok = await viewModel.save()
                guard ok else { activeSave = nil; return }
                // Clear the just-rated dish and pop back in one update so the
                // score screen never flashes its reset values, then refresh the
                // dish list (the dish just rated moves to "already ordered").
                viewModel.clearForNextDish()
                path = loopBase
                activeSave = nil
                await viewModel.loadDishes()
            }
        } label: {
            HStack(spacing: 8) {
                if activeSave == .another {
                    ProgressView().tint(Theme.accent)
                } else {
                    Image(systemName: "plus")
                        .font(.system(size: 14, weight: .semibold))
                }
                Text(activeSave == .another ? "Saving..." : "Save & add another")
                    .font(.system(size: 16, weight: .semibold))
            }
            .foregroundStyle(Theme.textPrimary)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(Theme.surface)
            .overlay {
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .stroke(Theme.hairline, lineWidth: 1)
            }
            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        }
        .disabled(activeSave != nil)
    }
}
