import SwiftUI

/// Theme-styled rounded search input. Reused by the global search page and the
/// My Ratings filter so both feel like one feature. Owns its focus internally;
/// pass `autoFocus: true` to raise the keyboard when the field appears.
struct SearchField: View {
    @Binding var text: String
    var placeholder: String = "Search"
    var autoFocus: Bool = false
    @FocusState private var isFocused: Bool

    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 15, weight: .semibold))
                .foregroundStyle(Theme.textTertiary)

            TextField(
                "",
                text: $text,
                prompt: Text(placeholder).foregroundColor(Theme.textTertiary)
            )
            .textFieldStyle(.plain)
            .font(.system(size: 16))
            .foregroundStyle(Theme.textPrimary)
            .tint(Theme.accent)
            .autocorrectionDisabled()
            .textInputAutocapitalization(.never)
            .submitLabel(.search)
            .focused($isFocused)

            if !text.isEmpty {
                Button {
                    text = ""
                    isFocused = true
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 16))
                        .foregroundStyle(Theme.textTertiary)
                }
                .buttonStyle(.plain)
                .transition(.opacity)
            }
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 11)
        .background(Theme.surface)
        .overlay { Capsule().stroke(Theme.hairline, lineWidth: 1) }
        .clipShape(Capsule())
        .animation(.easeOut(duration: 0.15), value: text.isEmpty)
        .task {
            guard autoFocus else { return }
            // Let the navigation push settle before raising the keyboard, otherwise
            // the focus is dropped mid-transition (SwiftUI quirk).
            try? await Task.sleep(for: .milliseconds(350))
            isFocused = true
        }
    }
}
