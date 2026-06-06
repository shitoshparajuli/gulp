import UIKit

/// A maps app we know how to deep-link into.
///
/// iOS has no public API to read or route to the user's *default* maps app, so
/// instead we detect which apps are installed and let the user pick. Apple Maps
/// is last on purpose — it's the always-available fallback, never the silent
/// default. `comgooglemaps` and `waze` must be whitelisted in
/// `LSApplicationQueriesSchemes` (Info.plist) for `canOpenURL` to see them.
enum MapApp: Identifiable, CaseIterable {
    case googleMaps
    case waze
    case apple

    var id: Self { self }

    var displayName: String {
        switch self {
        case .googleMaps: "Google Maps"
        case .waze: "Waze"
        case .apple: "Apple Maps"
        }
    }

    var isInstalled: Bool {
        switch self {
        case .apple:
            return true // bundled on every device
        case .googleMaps:
            return canOpen("comgooglemaps://")
        case .waze:
            return canOpen("waze://")
        }
    }

    /// Deep link that drops the user into a search for the free-text `query`
    /// (e.g. "Tartine Bakery, 600 Guerrero St, San Francisco").
    func searchURL(query: String) -> URL? {
        let encoded = query.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
        switch self {
        case .googleMaps: return URL(string: "comgooglemaps://?q=\(encoded)")
        case .waze: return URL(string: "https://waze.com/ul?q=\(encoded)")
        case .apple: return URL(string: "http://maps.apple.com/?q=\(encoded)")
        }
    }

    private func canOpen(_ scheme: String) -> Bool {
        guard let url = URL(string: scheme) else { return false }
        return UIApplication.shared.canOpenURL(url)
    }
}

enum MapLauncher {
    /// Installed map apps, in preference order (Google Maps / Waze before Apple).
    static var available: [MapApp] {
        MapApp.allCases.filter(\.isInstalled)
    }

    static func open(_ app: MapApp, query: String) {
        guard let url = app.searchURL(query: query) else { return }
        UIApplication.shared.open(url)
    }
}
