import SwiftUI

struct DishDetailSheet: View {
    let rating: RatingResponse
    var onEdit: (() -> Void)? = nil
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        ZStack {
            Theme.background.ignoresSafeArea()

            ScrollView {
                VStack(spacing: 32) {
                    handle

                    if let path = rating.photoPath, let url = dishPhotoURL(path: path) {
                        photoBlock(url: url)
                            .padding(.horizontal, 20)
                    }

                    scoreHero
                    dishInfo

                    if let notes = rating.notes, !notes.isEmpty {
                        notesCard(notes)
                            .padding(.horizontal, 20)
                    }

                    metaRow
                    Spacer(minLength: onEdit != nil ? 96 : 24)
                }
                .padding(.top, 12)
            }

            if onEdit != nil {
                VStack {
                    Spacer()
                    editButton
                        .padding(.horizontal, 20)
                        .padding(.bottom, 24)
                }
            }
        }
        .preferredColorScheme(.dark)
        .presentationDetents([.medium, .large])
        .presentationDragIndicator(.hidden)
        .presentationBackground(Theme.background)
    }

    private var handle: some View {
        Capsule()
            .fill(Theme.textTertiary)
            .frame(width: 36, height: 4)
            .padding(.bottom, 8)
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

    private var scoreHero: some View {
        VStack(spacing: 8) {
            if let score = rating.score {
                Text("\(score)")
                    .font(.system(size: 120, weight: .bold, design: .rounded))
                    .foregroundStyle(scoreGradient(Double(score)))
                    .shadow(color: scoreColor(Double(score)).opacity(0.4), radius: 30, x: 0, y: 0)
                Text("OUT OF 10")
                    .font(.system(size: 11, weight: .heavy))
                    .tracking(1.5)
                    .foregroundStyle(Theme.textTertiary)
            } else {
                Text("—")
                    .font(.system(size: 120, weight: .bold, design: .rounded))
                    .foregroundStyle(Theme.textTertiary)
                Text("NOT SCORED")
                    .font(.system(size: 11, weight: .heavy))
                    .tracking(1.5)
                    .foregroundStyle(Theme.textTertiary)
            }
        }
        .frame(maxWidth: .infinity)
    }

    private var dishInfo: some View {
        VStack(spacing: 8) {
            Text(rating.dish.displayName)
                .font(.system(size: 28, weight: .bold))
                .foregroundStyle(Theme.textPrimary)
                .multilineTextAlignment(.center)

            HStack(spacing: 8) {
                Text(rating.dish.restaurant.name.uppercased())
                    .font(.system(size: 12, weight: .semibold))
                    .tracking(1.0)
                    .foregroundStyle(Theme.textSecondary)
                if let cuisine = rating.dish.cuisine {
                    Circle()
                        .fill(Theme.textTertiary)
                        .frame(width: 3, height: 3)
                    Text(cuisine)
                        .font(.system(size: 12, weight: .medium))
                        .foregroundStyle(Theme.textTertiary)
                }
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.horizontal, 24)
    }

    private func notesCard(_ notes: String) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 6) {
                Image(systemName: "quote.opening")
                    .font(.system(size: 10, weight: .bold))
                Text("NOTES")
                    .font(.system(size: 10, weight: .heavy))
                    .tracking(1.2)
            }
            .foregroundStyle(Theme.textTertiary)

            Text(notes)
                .font(.system(size: 16, weight: .regular))
                .foregroundStyle(Theme.textPrimary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(20)
        .elevatedCard(cornerRadius: 16)
    }

    private var metaRow: some View {
        HStack(spacing: 6) {
            Image(systemName: "calendar")
                .font(.system(size: 11, weight: .medium))
            Text(rating.createdAt.formatted(date: .long, time: .omitted))
                .font(.system(size: 12, weight: .medium))
        }
        .foregroundStyle(Theme.textTertiary)
        .frame(maxWidth: .infinity)
    }

    private var editButton: some View {
        Button {
            dismiss()
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) {
                onEdit?()
            }
        } label: {
            HStack(spacing: 8) {
                Image(systemName: "pencil")
                    .font(.system(size: 14, weight: .semibold))
                Text("Edit")
                    .font(.system(size: 15, weight: .semibold))
            }
            .foregroundStyle(.black)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 14)
            .background(Theme.accent)
            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        }
    }
}
