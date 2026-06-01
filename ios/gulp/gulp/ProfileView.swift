import SwiftUI

struct ProfileView: View {
    @Bindable var auth: AuthViewModel

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                VStack(spacing: 12) {
                    Circle()
                        .fill(Color(.secondarySystemGroupedBackground))
                        .frame(width: 80, height: 80)
                        .overlay {
                            Text(auth.username.prefix(1).uppercased())
                                .font(.title.bold())
                                .foregroundStyle(.secondary)
                        }
                    Text("@\(auth.username)")
                        .font(.headline)
                }
                .padding(.top, 32)
                .padding(.bottom, 40)

                Spacer()

                Button(role: .destructive) {
                    Task { await auth.signOut() }
                } label: {
                    Text("Sign Out")
                        .fontWeight(.medium)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(Color(.secondarySystemGroupedBackground))
                        .foregroundStyle(.red)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 40)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(Color(.systemGroupedBackground))
            .navigationTitle("Profile")
        }
    }
}
