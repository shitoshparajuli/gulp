import SwiftUI
import GoogleSignIn
import UIKit

@main
struct gulpApp: App {
    @State private var auth = AuthViewModel()

    init() {
        let appearance = UITabBarAppearance()
        appearance.configureWithOpaqueBackground()
        appearance.backgroundColor = UIColor(red: 0.04, green: 0.04, blue: 0.05, alpha: 1.0)
        appearance.shadowColor = UIColor.white.withAlphaComponent(0.06)
        UITabBar.appearance().standardAppearance = appearance
        UITabBar.appearance().scrollEdgeAppearance = appearance
    }

    var body: some Scene {
        WindowGroup {
            Group {
                if auth.isSignedIn {
                    TabView {
                        RatingsView()
                            .tabItem { Label("Ratings", systemImage: "star.fill") }
                        ProfileView(auth: auth)
                            .tabItem { Label("Profile", systemImage: "person.fill") }
                    }
                    .tint(Theme.accent)
                } else {
                    LoginView(auth: auth)
                }
            }
            .preferredColorScheme(.dark)
            .onOpenURL { url in
                GIDSignIn.sharedInstance.handle(url)
            }
        }
    }
}
