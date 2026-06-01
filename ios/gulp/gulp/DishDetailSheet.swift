import SwiftUI

struct DishDetailSheet: View {
    let rating: RatingResponse
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 28) {
                    scoreHero
                    dishInfo
                    if let notes = rating.notes, !notes.isEmpty {
                        notesSection(notes)
                    }
                    dateRow
                }
                .padding(24)
            }
            .background(Color(.systemGroupedBackground))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }
                        .fontWeight(.semibold)
                }
            }
        }
    }

    private var scoreHero: some View {
        VStack(spacing: 6) {
            if let score = rating.score {
                Text("\(score)")
                    .font(.system(size: 80, weight: .bold, design: .rounded))
                    .foregroundStyle(scoreColor(Double(score)))
                Text("out of 10")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            } else {
                Text("—")
                    .font(.system(size: 80, weight: .bold, design: .rounded))
                    .foregroundStyle(.tertiary)
                Text("not scored")
                    .font(.subheadline)
                    .foregroundStyle(.tertiary)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 8)
    }

    private var dishInfo: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(rating.dish.displayName)
                .font(.title2.bold())
            Text(rating.dish.restaurant.name)
                .font(.subheadline)
                .foregroundStyle(.secondary)
            if let cuisine = rating.dish.cuisine {
                Text(cuisine)
                    .font(.caption)
                    .foregroundStyle(.tertiary)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func notesSection(_ notes: String) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("NOTES")
                .font(.system(size: 11, weight: .semibold))
                .foregroundStyle(.secondary)
                .tracking(0.8)
            Text(notes)
                .font(.body)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(16)
        .background(Color(.secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    private var dateRow: some View {
        HStack(spacing: 6) {
            Image(systemName: "calendar")
                .font(.caption)
                .foregroundStyle(.secondary)
            Text(rating.createdAt.formatted(date: .long, time: .omitted))
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}
