import SwiftUI

enum AppTab {
    case home, profile
}

struct AppRoot: View {
    @Bindable var auth: AuthViewModel
    @State private var selectedTab: AppTab = .home
    @State private var showAdd = false
    @State private var contentVersion = 0
    @State private var tabBar = TabBarVisibility()

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
            // 100pt = ~34pt system safe area (now ignored by ZStack) + ~66pt tab bar height.
            .safeAreaPadding(.bottom, tabBar.isHidden ? 0 : 100)

            if !tabBar.isHidden {
                CustomTabBar(selection: $selectedTab) {
                    showAdd = true
                }
                .transition(.move(edge: .bottom).combined(with: .opacity))
            }
        }
        .environment(tabBar)
        .animation(.easeInOut(duration: 0.25), value: tabBar.isHidden)
        .ignoresSafeArea(.keyboard)
        // Extend the ZStack to the physical screen bottom so the tab bar can
        // float at a fixed distance above the home indicator.
        .ignoresSafeArea(edges: .bottom)
        .sheet(isPresented: $showAdd, onDismiss: {
            contentVersion &+= 1
        }) {
            AddRatingView()
        }
    }
}

/// Visibility state for the global floating tab bar. Uses a depth counter so the
/// bar stays hidden across nested detail pushes (e.g. dish → restaurant → dish)
/// and only reappears once every drilled-in screen has been popped.
@MainActor
@Observable
final class TabBarVisibility {
    private var depth = 0
    var isHidden: Bool { depth > 0 }
    func push() { depth += 1 }
    func pop() { depth = max(0, depth - 1) }

    /// Whether the bar is in its shrunken state (scrolled down). Driven by the
    /// main scroll views via `.tracksTabBarScroll()`; the bar reads it to swap
    /// between the full, labelled pill and the compact, faded one.
    private(set) var isCompact = false
    func setCompact(_ value: Bool) {
        if isCompact != value { isCompact = value }
    }
    func expand() { setCompact(false) }
}

private struct HidesAppTabBar: ViewModifier {
    @Environment(TabBarVisibility.self) private var tabBar
    func body(content: Content) -> some View {
        content
            .onAppear { tabBar.push() }
            .onDisappear { tabBar.pop() }
    }
}

extension View {
    /// Hides the global floating tab bar while this screen is on the navigation stack.
    /// Apply to pushed detail screens that own the bottom of the screen.
    func hidesAppTabBar() -> some View {
        modifier(HidesAppTabBar())
    }

    /// Lets a scroll view drive the tab bar's compact state: scrolling down
    /// shrinks the pill, scrolling up (or reaching the top) expands it. Apply to
    /// the primary scroll view of a tab's root screen.
    func tracksTabBarScroll() -> some View {
        modifier(TracksTabBarScroll())
    }
}

/// Reports scroll direction to `TabBarVisibility` so the floating pill can shrink
/// on the way down and grow back on the way up. A small threshold filters out
/// jitter; reaching the top always restores the full bar.
private struct TracksTabBarScroll: ViewModifier {
    @Environment(TabBarVisibility.self) private var tabBar
    func body(content: Content) -> some View {
        content
            .onScrollGeometryChange(for: CGFloat.self) { geo in
                geo.contentOffset.y
            } action: { old, new in
                if new <= 0 {
                    tabBar.setCompact(false)
                } else if new - old > 4 {
                    tabBar.setCompact(true)
                } else if old - new > 4 {
                    tabBar.setCompact(false)
                }
            }
            // Start (and return) expanded whenever this screen appears.
            .onAppear { tabBar.setCompact(false) }
    }
}

struct CustomTabBar: View {
    @Environment(TabBarVisibility.self) private var tabBar
    @Binding var selection: AppTab
    let onAddTap: () -> Void

    private var compact: Bool { tabBar.isCompact }

    var body: some View {
        GlassEffectContainer(spacing: 16) {
            HStack(spacing: 0) {
                tabButton(.home, icon: "house.fill", label: "Home")
                addButton
                tabButton(.profile, icon: "person.fill", label: "Profile")
            }
            .padding(.horizontal, 10)
            .padding(.vertical, compact ? 8 : 11)
            .glassEffect(.regular, in: Capsule())
            .overlay { Capsule().stroke(Theme.hairline, lineWidth: 1) }
            .shadow(color: .black.opacity(0.35), radius: 18, x: 0, y: 8)
        }
        // The whole pill shrinks and fades a touch as you scroll down.
        .scaleEffect(compact ? 0.94 : 1.0, anchor: .bottom)
        .opacity(compact ? 0.9 : 1.0)
        // Wide pill with side margins. 20pt from physical screen bottom puts it
        // just above the home indicator — close enough to feel docked, high enough
        // to feel floating.
        .padding(.horizontal, 28)
        .padding(.bottom, 20)
        .animation(.spring(response: 0.34, dampingFraction: 0.82), value: compact)
    }

    private var addButton: some View {
        Button {
            tabBar.expand()
            onAddTap()
        } label: {
            Image(systemName: "plus")
                .font(.system(size: compact ? 19 : 22, weight: .bold))
                .foregroundStyle(.white)
                .frame(width: compact ? 46 : 54, height: compact ? 46 : 54)
                .glassEffect(
                    .regular.tint(Theme.accent).interactive(),
                    in: Circle()
                )
                .shadow(color: Theme.accent.opacity(0.45), radius: 14, x: 0, y: 6)
        }
        .frame(maxWidth: .infinity)
        // Slightly raised above the pill, like a floating action button.
        .offset(y: compact ? -8 : -12)
    }

    private func tabButton(_ tab: AppTab, icon: String, label: String) -> some View {
        Button {
            selection = tab
            tabBar.expand()
        } label: {
            VStack(spacing: 4) {
                Image(systemName: icon)
                    .font(.system(size: compact ? 19 : 20, weight: .semibold))
                if !compact {
                    Text(label)
                        .font(.system(size: 10, weight: .semibold))
                        .transition(.opacity.combined(with: .scale))
                }
            }
            .foregroundStyle(selection == tab ? Theme.accent : Theme.textTertiary)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 4)
        }
    }
}
