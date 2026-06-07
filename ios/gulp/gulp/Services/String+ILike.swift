import Foundation

extension String {
    /// Sanitizes user input for use inside an `ilike` `%…%` pattern: drops the LIKE
    /// wildcards (`%`, `_`) and the characters that confuse PostgREST's filter parser
    /// (`,`, `(`, `)`, `*`) so the text is matched literally. Slightly lossy, but dish
    /// and restaurant names rarely contain these.
    var ilikeEscaped: String {
        let banned: Set<Character> = ["%", "_", ",", "(", ")", "*"]
        return filter { !banned.contains($0) }
    }
}
