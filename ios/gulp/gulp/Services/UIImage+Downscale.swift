import UIKit

extension UIImage {
    /// Returns a copy scaled so its longest edge is at most `maxDimension`,
    /// preserving aspect ratio. Never upscales — images already smaller than
    /// the limit are returned unchanged. Renders at scale 1 so the pixel
    /// dimensions are exactly what we intend to store.
    func downscaled(maxDimension: CGFloat) -> UIImage {
        let longestEdge = max(size.width, size.height)
        guard longestEdge > maxDimension, longestEdge > 0 else { return self }

        let ratio = maxDimension / longestEdge
        let targetSize = CGSize(width: size.width * ratio, height: size.height * ratio)

        let format = UIGraphicsImageRendererFormat.default()
        format.scale = 1
        format.opaque = true
        let renderer = UIGraphicsImageRenderer(size: targetSize, format: format)
        return renderer.image { _ in
            draw(in: CGRect(origin: .zero, size: targetSize))
        }
    }
}
