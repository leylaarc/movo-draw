import SwiftUI
import UIKit

/// Owns the doodle canvas so SwiftUI re-creates don't lose the drawing surface.
@MainActor
final class CanvasController: ObservableObject {
    let view = DoodleCanvasView()

    var hasInk: Bool { view.hasInk }

    func undo() { view.undo() }
    func clear() { view.clear() }
    func seedDragonDoodle() { view.seedDragonDoodle() }
    func exportImage() -> UIImage { view.exportImage() }
}

/// UIKit-backed canvas for reliable fat-finger drawing + image export.
final class DoodleCanvasView: UIView {
    var strokeColor: UIColor = .black
    var lineWidth: CGFloat = PenSize.medium.width
    var strokeOpacity: CGFloat = 1
    var strokeStyle: StrokeStyle = .pen

    private var strokes: [DoodleStroke] = []
    private var undone: [DoodleStroke] = []
    private var currentPoints: [CGPoint] = []

    private let paperUIColor = UIColor(red: 1.0, green: 0.99, blue: 0.97, alpha: 1)

    var hasInk: Bool {
        !strokes.isEmpty || currentPoints.count > 1
    }

    override init(frame: CGRect) {
        super.init(frame: frame)
        backgroundColor = paperUIColor
        isMultipleTouchEnabled = false
        layer.cornerRadius = 36
        layer.masksToBounds = true
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func undo() {
        guard let last = strokes.popLast() else { return }
        undone.append(last)
        setNeedsDisplay()
    }

    func clear() {
        strokes.removeAll()
        undone.removeAll()
        currentPoints.removeAll()
        setNeedsDisplay()
    }

    /// Seeds a simple black + red dragon-like doodle for Simulator demos.
    func seedDragonDoodle() {
        clear()
        layoutIfNeeded()
        let w = max(bounds.width, 320)
        let h = max(bounds.height, 420)
        let black = UIColor.black
        let red = UIColor(red: 0.92, green: 0.18, blue: 0.22, alpha: 1)
        let thick = PenSize.medium.width

        let body: [CGPoint] = [
            CGPoint(x: w * 0.28, y: h * 0.62),
            CGPoint(x: w * 0.42, y: h * 0.55),
            CGPoint(x: w * 0.55, y: h * 0.48),
            CGPoint(x: w * 0.62, y: h * 0.38),
            CGPoint(x: w * 0.68, y: h * 0.30),
            CGPoint(x: w * 0.74, y: h * 0.28),
            CGPoint(x: w * 0.78, y: h * 0.32)
        ]
        strokes.append(DoodleStroke(color: black, width: thick, opacity: 1, style: .pen, points: body))

        let wing: [CGPoint] = [
            CGPoint(x: w * 0.48, y: h * 0.52),
            CGPoint(x: w * 0.38, y: h * 0.34),
            CGPoint(x: w * 0.52, y: h * 0.28),
            CGPoint(x: w * 0.58, y: h * 0.42)
        ]
        strokes.append(DoodleStroke(color: red, width: thick, opacity: 1, style: .marker, points: wing))

        let tail: [CGPoint] = [
            CGPoint(x: w * 0.28, y: h * 0.62),
            CGPoint(x: w * 0.18, y: h * 0.70),
            CGPoint(x: w * 0.14, y: h * 0.78),
            CGPoint(x: w * 0.22, y: h * 0.74)
        ]
        strokes.append(DoodleStroke(color: black, width: thick * 0.85, opacity: 1, style: .crayon, points: tail))

        let belly: [CGPoint] = [
            CGPoint(x: w * 0.40, y: h * 0.58),
            CGPoint(x: w * 0.50, y: h * 0.52),
            CGPoint(x: w * 0.58, y: h * 0.46)
        ]
        strokes.append(DoodleStroke(color: red, width: thick * 0.7, opacity: 0.85, style: .marker, points: belly))

        setNeedsDisplay()
    }

    func exportImage() -> UIImage {
        let exportBounds = bounds.width > 1
            ? bounds
            : CGRect(x: 0, y: 0, width: 320, height: 420)
        let format = UIGraphicsImageRendererFormat()
        format.scale = UIScreen.main.scale
        format.opaque = true
        let renderer = UIGraphicsImageRenderer(bounds: exportBounds, format: format)
        return renderer.image { ctx in
            paperUIColor.setFill()
            ctx.fill(exportBounds)
            drawInk(in: ctx.cgContext)
        }
    }

    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let point = touches.first?.location(in: self) else { return }
        currentPoints = [point]
        undone.removeAll()
        setNeedsDisplay()
    }

    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let point = touches.first?.location(in: self) else { return }
        currentPoints.append(point)
        setNeedsDisplay()
    }

    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        finishStroke()
    }

    override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent?) {
        finishStroke()
    }

    private func finishStroke() {
        guard currentPoints.count > 1 else {
            currentPoints.removeAll()
            setNeedsDisplay()
            return
        }
        let stroke = DoodleStroke(
            color: strokeColor,
            width: lineWidth,
            opacity: strokeOpacity,
            style: strokeStyle,
            points: currentPoints
        )
        strokes.append(stroke)
        currentPoints.removeAll()
        setNeedsDisplay()
    }

    override func draw(_ rect: CGRect) {
        guard let ctx = UIGraphicsGetCurrentContext() else { return }
        drawInk(in: ctx)
    }

    private func drawInk(in ctx: CGContext) {
        var all = strokes
        if currentPoints.count > 1 {
            all.append(DoodleStroke(
                color: strokeColor,
                width: lineWidth,
                opacity: strokeOpacity,
                style: strokeStyle,
                points: currentPoints
            ))
        }
        for stroke in all {
            render(stroke, in: ctx)
        }
    }

    private func render(_ stroke: DoodleStroke, in ctx: CGContext) {
        guard stroke.points.count > 1 else { return }
        ctx.saveGState()
        defer { ctx.restoreGState() }

        switch stroke.style {
        case .pen:
            drawSolidPath(stroke.points, width: stroke.width, color: stroke.color, opacity: stroke.opacity, in: ctx)

        case .marker:
            // Soft marker: slightly wider, translucent undercoat + brighter core.
            let soft = min(1, stroke.opacity * 0.55)
            drawSolidPath(stroke.points, width: stroke.width * 1.35, color: stroke.color, opacity: soft, in: ctx)
            drawSolidPath(stroke.points, width: stroke.width * 0.85, color: stroke.color, opacity: stroke.opacity, in: ctx)

        case .crayon:
            drawCrayonPath(stroke, in: ctx)

        case .eraser:
            // Paint paper color so undo/export stay reliable on an opaque canvas.
            drawSolidPath(stroke.points, width: stroke.width * 1.2, color: paperUIColor, opacity: 1, in: ctx)
        }
    }

    private func drawSolidPath(
        _ points: [CGPoint],
        width: CGFloat,
        color: UIColor,
        opacity: CGFloat,
        in ctx: CGContext
    ) {
        guard let first = points.first else { return }
        ctx.setLineCap(.round)
        ctx.setLineJoin(.round)
        ctx.setStrokeColor(color.withAlphaComponent(opacity).cgColor)
        ctx.setLineWidth(width)
        ctx.beginPath()
        ctx.move(to: first)
        for point in points.dropFirst() {
            ctx.addLine(to: point)
        }
        ctx.strokePath()
    }

    /// Chalky crayon: several jittered semi-opaque passes + speckles along the path.
    private func drawCrayonPath(_ stroke: DoodleStroke, in ctx: CGContext) {
        let offsets: [(CGFloat, CGFloat, CGFloat)] = [
            (0, 0, 1.0),
            (1.4, -1.1, 0.55),
            (-1.6, 0.9, 0.45),
            (0.8, 1.5, 0.4),
            (-1.2, -1.3, 0.35)
        ]
        for (dx, dy, weight) in offsets {
            let shifted = stroke.points.map { CGPoint(x: $0.x + dx, y: $0.y + dy) }
            drawSolidPath(
                shifted,
                width: stroke.width * (0.55 + weight * 0.25),
                color: stroke.color,
                opacity: stroke.opacity * weight * 0.7,
                in: ctx
            )
        }

        // Speckle texture
        ctx.setFillColor(stroke.color.withAlphaComponent(stroke.opacity * 0.35).cgColor)
        let step = max(3, Int(stroke.width * 0.35))
        var i = 0
        while i < stroke.points.count {
            let p = stroke.points[i]
            let seed = Int(p.x * 12 + p.y * 7)
            let jx = CGFloat((seed % 7) - 3)
            let jy = CGFloat(((seed / 7) % 7) - 3)
            let r = max(1.2, stroke.width * 0.12)
            ctx.fillEllipse(in: CGRect(x: p.x + jx - r, y: p.y + jy - r, width: r * 2, height: r * 2))
            i += step
        }
    }
}

struct DoodleCanvasRepresentable: UIViewRepresentable {
    @ObservedObject var controller: CanvasController
    var color: UIColor
    var lineWidth: CGFloat
    var opacity: CGFloat
    var style: StrokeStyle

    func makeUIView(context: Context) -> UIView {
        let host = UIView()
        host.backgroundColor = .clear
        let canvas = controller.view
        canvas.translatesAutoresizingMaskIntoConstraints = false
        host.addSubview(canvas)
        NSLayoutConstraint.activate([
            canvas.leadingAnchor.constraint(equalTo: host.leadingAnchor),
            canvas.trailingAnchor.constraint(equalTo: host.trailingAnchor),
            canvas.topAnchor.constraint(equalTo: host.topAnchor),
            canvas.bottomAnchor.constraint(equalTo: host.bottomAnchor)
        ])
        applyTools(to: canvas)
        return host
    }

    func updateUIView(_ uiView: UIView, context: Context) {
        applyTools(to: controller.view)
    }

    private func applyTools(to canvas: DoodleCanvasView) {
        canvas.strokeColor = color
        canvas.lineWidth = lineWidth
        canvas.strokeOpacity = opacity
        canvas.strokeStyle = style
    }
}
