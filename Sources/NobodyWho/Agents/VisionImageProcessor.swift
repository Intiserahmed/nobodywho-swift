import Foundation
import CoreGraphics
import ImageIO
import UniformTypeIdentifiers

/// Prepares images for vision models by resizing them to fit within a token budget.
///
/// GLM-OCR encodes images into patches of 14×14 pixels, merged by factor 2:
///   tokens ≈ (width × height) / (14 × 14 × 4) = (w × h) / 784
///
/// With a context of 2048, keeping image tokens ≤ 1200 leaves ~800 tokens for the response.
public struct VisionImageProcessor {

    /// Patch size used by GLM-OCR / glm4v projection model.
    public static let patchSize: Int = 14
    /// Merge factor (n_merge) from the mmproj config.
    public static let mergeFactor: Int = 2

    /// Estimates how many tokens an image of the given size will consume.
    public static func estimatedTokens(width: Int, height: Int) -> Int {
        let divisor = patchSize * patchSize * mergeFactor * mergeFactor
        return (width * height) / divisor
    }

    /// Prepares an image at `path` for the model.
    /// If the image exceeds `maxTokens`, it is resized and saved to a temp file.
    /// Returns the path to use (original or resized).
    public static func prepare(
        imagePath: String,
        maxTokens: Int = 1100
    ) throws -> String {
        guard let source = CGImageSourceCreateWithURL(
            URL(fileURLWithPath: imagePath) as CFURL, nil
        ) else {
            throw VisionImageError.cannotLoadImage(imagePath)
        }

        guard let cgImage = CGImageSourceCreateImageAtIndex(source, 0, nil) else {
            throw VisionImageError.cannotLoadImage(imagePath)
        }

        let originalWidth = cgImage.width
        let originalHeight = cgImage.height
        let tokens = estimatedTokens(width: originalWidth, height: originalHeight)

        // Already within budget — use original
        if tokens <= maxTokens {
            return imagePath
        }

        // Calculate scale factor to fit within maxTokens
        // tokens = (w * h) / 784, so w * h = maxTokens * 784
        let maxPixels = maxTokens * patchSize * patchSize * mergeFactor * mergeFactor
        let scale = sqrt(Double(maxPixels) / Double(originalWidth * originalHeight))

        let newWidth = Int(Double(originalWidth) * scale)
        let newHeight = Int(Double(originalHeight) * scale)

        // Resize
        let resized = try resize(cgImage, to: CGSize(width: newWidth, height: newHeight))

        // Save to temp file
        let tempURL = FileManager.default.temporaryDirectory
            .appendingPathComponent("nobodywho_vision_\(UUID().uuidString).jpg")

        try save(resized, to: tempURL)

        return tempURL.path
    }

    // MARK: - Private

    private static func resize(_ image: CGImage, to size: CGSize) throws -> CGImage {
        let width = Int(size.width)
        let height = Int(size.height)

        guard let context = CGContext(
            data: nil,
            width: width,
            height: height,
            bitsPerComponent: image.bitsPerComponent,
            bytesPerRow: 0,
            space: image.colorSpace ?? CGColorSpaceCreateDeviceRGB(),
            bitmapInfo: image.bitmapInfo.rawValue
        ) else {
            throw VisionImageError.resizeFailed
        }

        context.interpolationQuality = .high
        context.draw(image, in: CGRect(origin: .zero, size: size))

        guard let resized = context.makeImage() else {
            throw VisionImageError.resizeFailed
        }

        return resized
    }

    private static func save(_ image: CGImage, to url: URL) throws {
        guard let destination = CGImageDestinationCreateWithURL(
            url as CFURL, UTType.jpeg.identifier as CFString, 1, nil
        ) else {
            throw VisionImageError.saveFailed
        }

        let options: [CFString: Any] = [
            kCGImageDestinationLossyCompressionQuality: 0.92
        ]

        CGImageDestinationAddImage(destination, image, options as CFDictionary)

        guard CGImageDestinationFinalize(destination) else {
            throw VisionImageError.saveFailed
        }
    }
}

public enum VisionImageError: Error, LocalizedError {
    case cannotLoadImage(String)
    case resizeFailed
    case saveFailed

    public var errorDescription: String? {
        switch self {
        case .cannotLoadImage(let path): return "Cannot load image at: \(path)"
        case .resizeFailed: return "Failed to resize image"
        case .saveFailed: return "Failed to save resized image"
        }
    }
}
