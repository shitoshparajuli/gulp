import SwiftUI

enum AppTab {
    case home, profile
}

struct AppRoot: View {
    @Bindable var auth: AuthViewModel
    @State private var selectedTab: AppTab = .home
    @State private var showAdd = false
    @State private var contentVersion = 0

    var body: some View {
        ZStack(alignment: .bottom) {
            Group {
                switch selectedTab {
                case .home:
                    NavigationStack {
                        HomeView(refreshTrigger: contentVersion)
                    }
                case .profile:
                    NavigationStack {
                        ProfileView(auth: auth, refreshTrigger: contentVersion)
                    }
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .safeAreaPadding(.bottom, 64)

            CustomTabBar(selection: $selectedTab) {
                showAdd = true
            }
        }
        .ignoresSafeArea(.keyboard)
        .sheet(isPresented: $showAdd, onDismiss: {
            contentVersion &+= 1
        }) {
            AddRatingView()
        }
    }
}

struct CustomTabBar: View {
    @Binding var selection: AppTab
    let onAddTap: () -> Void

    var body: some View {
        GlassEffectContainer(spacing: 20) {
            HStack(spacing: 0) {
                tabButton(.home, icon: "house.fill", label: "Home")
                addButton
                tabButton(.profile, icon: "person.fill", label: "Profile")
            }
            .padding(.horizontal, 12)
            .padding(.top, 10)
            .padding(.bottom, 8)
            .glassEffect(.regular, in: Rectangle())
            .ignoresSafeArea(edges: .bottom)
        }
    }

    private var addButton: some View {
        Button(action: onAddTap) {
            Image(systemName: "plus")
                .font(.system(size: 22, weight: .bold))
                .foregroundStyle(.white)
                .frame(width: 54, height: 54)
                .glassEffect(
                    .regular.tint(Theme.accent).interactive(),
                    in: Circle()
                )
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
