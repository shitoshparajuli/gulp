import Foundation

extension Error {
    /// True when this is a task/URL cancellation rather than a real failure.
    /// SwiftUI cancels `.task` / `.refreshable` work routinely (a superseded
    /// load, a retracted refresh control), so surfacing these as errors just
    /// produces spurious alerts. Callers should treat them as no-ops.
    var isCancellation: Bool {
        self is CancellationError || (self as? URLError)?.code == .cancelled
    }
}
