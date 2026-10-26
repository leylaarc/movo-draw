import UIKit
import CoreGraphics

enum DoodleAnalyzer {
    static func analyze(_ image: UIImage) -> DoodleAnalysis {
        guard let cg = image.cgImage else {
            return DoodleAnalysis(
                dominantColors: [.black, .red],
                subjectHint: .mystery,
                inkBounds: CGRect(x: 0.2, y: 0.2, width: 0.6, height: 0.6),
                strokeDensity: 0.1
            )
        }

        let width = cg.width
        let height = cg.height
        let bytesPerPixel = 4
        let bytesPerRow = width * bytesPerPixel
        var data = [UInt8](repeating: 0, count: height * bytesPerRow)

        guard let ctx = CGContext(
            data: &data,
            width: width,
            height: height,
            bitsPerComponent: 8,
            bytesPerRow: bytesPerRow,
            space: CGColorSpaceCreateDeviceRGB(),
            bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
        ) else {
            return DoodleAnalysis(
                dominantColors: [.black],
                subjectHint: .mystery,
                inkBounds: .zero,
                strokeDensity: 0
            )
        }
        ctx.draw(cg, in: CGRect(x: 0, y: 0, width: width, height: height))

        var buckets: [String: (count: Int, r: Int, g: Int, b: Int)] = [:]
        var minX = width, minY = height, maxX = 0, maxY = 0
        var inkPixels = 0
        let step = max(1, min(width, height) / 80)

        for y in stride(from: 0, to: height, by: step) {
            for x in stride(from: 0, to: width, by: step) {
                let i = y * bytesPerRow + x * bytesPerPixel
                let r = Int(data[i])
                let g = Int(data[i + 1])
                let b = Int(data[i + 2])
                let a = Int(data[i + 3])
                // Near-white / transparent = paper
                if a < 40 { continue }
                if r > 235 && g > 235 && b > 235 { continue }

                inkPixels += 1
                minX = min(minX, x); maxX = max(maxX, x)
                minY = min(minY, y); maxY = max(maxY, y)

                let key = "\(r / 48)-\(g / 48)-\(b / 48)"
                var bucket = buckets[key] ?? (0, 0, 0, 0)
                bucket.count += 1
                bucket.r += r
                bucket.g += g
                bucket.b += b
                buckets[key] = bucket
            }
        }

        let sampled = Double((width / step) * (height / step))
        let density = sampled > 0 ? Double(inkPixels) / sampled : 0

        let colors: [UIColor] = buckets.values
            .sorted { $0.count > $1.count }
            .prefix(4)
            .map { bucket in
                let n = max(bucket.count, 1)
                return UIColor(
                    red: CGFloat(bucket.r / n) / 255,
                    green: CGFloat(bucket.g / n) / 255,
                    blue: CGFloat(bucket.b / n) / 255,
                    alpha: 1
                )
            }

        let bounds: CGRect
        if inkPixels == 0 || maxX < minX {
            bounds = CGRect(x: 0.25, y: 0.25, width: 0.5, height: 0.5)
        } else {
            bounds = CGRect(
                x: CGFloat(minX) / CGFloat(width),
                y: CGFloat(minY) / CGFloat(height),
                width: CGFloat(max(1, maxX - minX)) / CGFloat(width),
                height: CGFloat(max(1, maxY - minY)) / CGFloat(height)
            )
        }

        let hint = subjectHint(bounds: bounds, colors: colors, density: density)

        return DoodleAnalysis(
            dominantColors: colors.isEmpty ? [.black] : colors,
            subjectHint: hint,
            inkBounds: bounds,
            strokeDensity: density
        )
    }

    private static func subjectHint(
        bounds: CGRect,
        colors: [UIColor],
        density: Double
    ) -> DoodleAnalysis.SubjectHint {
        let aspect = bounds.width / max(bounds.height, 0.001)
        let greenish = colors.contains { c in
            var r: CGFloat = 0, g: CGFloat = 0, b: CGFloat = 0, a: CGFloat = 0
            c.getRed(&r, green: &g, blue: &b, alpha: &a)
            return g > r + 0.12 && g > b + 0.08
        }

        // Tall or mid-air silhouette → flyer (dragons, birds, planes)
        if bounds.minY < 0.35 && bounds.height > 0.28 && aspect < 1.35 {
            return .flyer
        }
        // Wide low shapes → vehicle
        if aspect > 1.6 && bounds.minY > 0.4 {
            return .vehicle
        }
        if greenish && density < 0.35 {
            return .nature
        }
        if density > 0.12 {
            return .creature
        }
        return .mystery
    }
}
