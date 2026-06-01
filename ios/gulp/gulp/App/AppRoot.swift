import SwiftUI

enum AppTab {
    case ratings, profile
}

struct AppRoot: View {
    @Bindable var auth: AuthViewModel
    @State private var selectedTab: AppTab = .ratings
    @State private var showAdd = false

    var body: some View {
        ZStack(alignment: .bottom) {
            Group {
                switch selectedTab {
                case .ratings: RatingsView()
                case .profile: ProfileView(auth: auth)
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .safeAreaPadding(.bottom, 64)

            CustomTabBar(selection: $selectedTab) {
                showAdd = true
            }
        }
        .ignoresSafeArea(.keyboard)
        .sheet(isPresented: $showAdd) {
            AddRatingView()
        }
    }
}

struct CustomTabBar: View {
    @Binding var selection: AppTab
    let onAddTap: () -> Void

    var body: some View {
        HStack(spacing: 0) {
            tabButton(.ratings, icon: "star.fill", label: "Ratings")
            addButton
            tabButton(.profile, icon: "person.fill", label: "Profile")
        }
        .padding(.horizontal, 12)
        .padding(.top, 10)
        .padding(.bottom, 8)
        .background(
            Theme.background
                .overlay(alignment: .top) {
                    Rectangle()
                        .fill(Theme.hairline)
                        .frame(height: 1)
                }
                .ignoresSafeArea(edges: .bottom)
        )
    }

    private var addButton: some View {
        Button(action: onAddTap) {
            Image(systemName: "plus")
                .font(.system(size: 22, weight: .bold))
                .foregroundStyle(.white)
                .frame(width: 54, height: 54)
                .background(
                    LinearGradient(
                        colors: [Theme.accent, Theme.accent.opacity(0.78)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .clipShape(Circle())
                .shadow(color: Theme.accent.opacity(0.45), radius: 14, x: 0, y: 6)
        }
        .frame(maxWidth: .infinity)
        .offset(y: -12)
    }

    private func tabButton(_ tab: AppTab, icon: String, label: String) -> some View {
        Button {
            selection = tab
        } label: {
            VStack(spacing: 4) {
                Image(systemName: icon)
                    .font(.system(size: 20, weight: .semibold))
                Text(label)
                    .font(.system(size: 10, weight: .semibold))
            }
            .foregroundStyle(selection == tab ? Theme.accent : Theme.textTertiary)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 4)
        }
    }
}
