import SwiftUI
import SpriteKit
import UIKit

/// Plays a living version of the kid's doodle using SpriteKit motion.
struct LivingDoodleView: View {
    let image: UIImage
    let analysis: DoodleAnalysis

    var body: some View {
        GeometryReader { geo in
            SpriteView(scene: makeScene(size: geo.size), options: [.allowsTransparency])
                .ignoresSafeArea(edges: .bottom)
        }
    }

    private func makeScene(size: CGSize) -> SKScene {
        let scene = LivingDoodleScene(size: size)
        scene.scaleMode = .resizeFill
        scene.configure(image: image, analysis: analysis)
        return scene
    }
}

final class LivingDoodleScene: SKScene {
    private var doodleNode: SKSpriteNode?
    private var configured = false

    func configure(image: UIImage, analysis: DoodleAnalysis) {
        removeAllChildren()
        configured = true
        backgroundColor = .clear

        // Soft sky + parallax clouds tinted by doodle colors
        backgroundColor = UIColor(red: 0.55, green: 0.82, blue: 0.98, alpha: 1)
        let tint = analysis.dominantColors.first?.withAlphaComponent(0.22)
            ?? UIColor(red: 0.7, green: 0.55, blue: 0.95, alpha: 0.2)
        let wash = SKSpriteNode(color: tint, size: size)
        wash.position = CGPoint(x: size.width / 2, y: size.height / 2)
        wash.zPosition = -10
        addChild(wash)

        addParallaxClouds(tint: analysis.dominantColors.first ?? .systemTeal)

        let flying = makeTransparentDoodle(croppedInk(image, bounds: analysis.inkBounds))
        let texture = SKTexture(image: flying)
        texture.filteringMode = .linear
        let maxSide = min(size.width, size.height) * 0.55
        let aspect = texture.size().width / max(texture.size().height, 1)
        let nodeSize: CGSize
        if aspect >= 1 {
            nodeSize = CGSize(width: maxSide, height: maxSide / aspect)
        } else {
            nodeSize = CGSize(width: maxSide * aspect, height: maxSide)
        }

        let node = SKSpriteNode(texture: texture, size: nodeSize)
        node.position = CGPoint(x: size.width * 0.5, y: size.height * 0.45)
        node.zPosition = 10
        addChild(node)
        doodleNode = node

        node.run(motion(for: analysis.subjectHint, in: size), withKey: "life")

        // Soft shadow under the doodle
        let shadow = SKShapeNode(ellipseOf: CGSize(width: nodeSize.width * 0.55, height: 18))
        shadow.fillColor = UIColor.black.withAlphaComponent(0.12)
        shadow.strokeColor = .clear
        shadow.position = CGPoint(x: size.width * 0.5, y: size.height * 0.22)
        shadow.zPosition = 5
        addChild(shadow)
        shadow.run(
            .repeatForever(
                .sequence([
                    .group([
                        .scaleX(to: 1.15, duration: 1.4),
                        .fadeAlpha(to: 0.08, duration: 1.4)
                    ]),
                    .group([
                        .scaleX(to: 0.85, duration: 1.4),
                        .fadeAlpha(to: 0.18, duration: 1.4)
                    ])
                ])
            )
        )
    }

    private func motion(for hint: DoodleAnalysis.SubjectHint, in size: CGSize) -> SKAction {
        switch hint {
        case .flyer:
            // Gentle figure-eight / flight loop — reads clearly as “flying”
            let path = UIBezierPath()
            let cx = size.width * 0.5
            let cy = size.height * 0.48
            path.move(to: CGPoint(x: cx - 90, y: cy))
            path.addCurve(
                to: CGPoint(x: cx + 90, y: cy),
                controlPoint1: CGPoint(x: cx - 40, y: cy + 70),
                controlPoint2: CGPoint(x: cx + 40, y: cy - 70)
            )
            path.addCurve(
                to: CGPoint(x: cx - 90, y: cy),
                controlPoint1: CGPoint(x: cx + 40, y: cy + 70),
                controlPoint2: CGPoint(x: cx - 40, y: cy - 70)
            )
            let follow = SKAction.follow(path.cgPath, asOffset: false, orientToPath: false, duration: 5.5)
            let flap = SKAction.repeatForever(
                .sequence([
                    .scaleY(to: 0.92, duration: 0.35),
                    .scaleY(to: 1.05, duration: 0.35)
                ])
            )
            let bob = SKAction.repeatForever(
                .sequence([
                    .rotate(toAngle: 0.12, duration: 0.7),
                    .rotate(toAngle: -0.12, duration: 0.7)
                ])
            )
            return .group([.repeatForever(follow), flap, bob])

        case .creature:
            return .repeatForever(
                .sequence([
                    .moveBy(x: 40, y: 30, duration: 0.45),
                    .moveBy(x: 40, y: -30, duration: 0.45),
                    .moveBy(x: -40, y: 30, duration: 0.45),
                    .moveBy(x: -40, y: -30, duration: 0.45)
                ])
            )

        case .vehicle:
            return .repeatForever(
                .sequence([
                    .group([
                        .moveBy(x: size.width * 0.35, y: 0, duration: 2.2),
                        .rotate(toAngle: 0.05, duration: 0.3)
                    ]),
                    .group([
                        .moveBy(x: -size.width * 0.35, y: 0, duration: 2.2),
                        .rotate(toAngle: -0.05, duration: 0.3)
                    ])
                ])
            )

        case .nature:
            return .repeatForever(
                .sequence([
                    .rotate(toAngle: 0.08, duration: 1.2),
                    .rotate(toAngle: -0.08, duration: 1.2)
                ])
            )

        case .mystery:
            return .repeatForever(
                .sequence([
                    .group([
                        .moveBy(x: 0, y: 28, duration: 1.1),
                        .scale(to: 1.06, duration: 1.1)
                    ]),
                    .group([
                        .moveBy(x: 0, y: -28, duration: 1.1),
                        .scale(to: 0.96, duration: 1.1)
                    ])
                ])
            )
        }
    }

    private func addParallaxClouds(tint: UIColor) {
        for i in 0..<4 {
            let w = CGFloat.random(in: 80...140)
            let cloud = SKShapeNode(ellipseOf: CGSize(width: w, height: w * 0.45))
            cloud.fillColor = UIColor.white.withAlphaComponent(0.55)
            cloud.strokeColor = tint.withAlphaComponent(0.15)
            cloud.lineWidth = 2
            cloud.position = CGPoint(
                x: CGFloat.random(in: 0...size.width),
                y: size.height * (0.55 + CGFloat(i) * 0.1)
            )
            cloud.zPosition = CGFloat(-5 + i)
            addChild(cloud)
            let drift = SKAction.repeatForever(
                .sequence([
                    .moveBy(x: size.width * 0.4, y: CGFloat.random(in: -10...10), duration: Double.random(in: 8...14)),
                    .moveBy(x: -size.width * 0.4, y: CGFloat.random(in: -10...10), duration: Double.random(in: 8...14))
                ])
            )
            cloud.run(drift)
        }
    }

    /// Crop roughly to ink so transparent margins don't shrink the flyer.
    private func croppedInk(_ image: UIImage, bounds: CGRect) -> UIImage {
        guard let cg = image.cgImage else { return image }
        let pad: CGFloat = 0.08
        var r = bounds.insetBy(dx: -pad, dy: -pad)
        r = r.intersection(CGRect(x: 0, y: 0, width: 1, height: 1))
        let pixel = CGRect(
            x: r.origin.x * CGFloat(cg.width),
            y: r.origin.y * CGFloat(cg.height),
            width: max(1, r.width * CGFloat(cg.width)),
            height: max(1, r.height * CGFloat(cg.height))
        )
        guard let cropped = cg.cropping(to: pixel) else { return image }
        return UIImage(cgImage: cropped, scale: image.scale, orientation: image.imageOrientation)
    }

    /// Punch out near-white paper so the doodle flies without a white card.
    private func makeTransparentDoodle(_ image: UIImage) -> UIImage {
        guard let cg = image.cgImage else { return image }
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
        ) else { return image }
        ctx.draw(cg, in: CGRect(x: 0, y: 0, width: width, height: height))
        for i in stride(from: 0, to: data.count, by: 4) {
            let r = data[i], g = data[i + 1], b = data[i + 2]
            if r > 230 && g > 230 && b > 230 {
                data[i] = 0; data[i + 1] = 0; data[i + 2] = 0; data[i + 3] = 0
            }
        }
        guard let out = ctx.makeImage() else { return image }
        return UIImage(cgImage: out, scale: image.scale, orientation: image.imageOrientation)
    }
}
