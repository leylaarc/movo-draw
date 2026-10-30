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
            // Clean ink — round tip, solid.
            drawPolyline(
                stroke.points,
                width: stroke.width,
                color: stroke.color,
                opacity: stroke.opacity,
                cap: .round,
                join: .round,
                in: ctx
            )

        case .marker:
            drawMarkerPath(stroke, in: ctx)

        case .crayon:
            drawCrayonPath(stroke, in: ctx)

        case .eraser:
            // Paint paper color so undo/export stay reliable on an opaque canvas.
            drawPolyline(
                stroke.points,
                width: stroke.width * 1.25,
                color: paperUIColor,
                opacity: 1,
                cap: .round,
                join: .round,
                in: ctx
            )
        }
    }

    private func drawPolyline(
        _ points: [CGPoint],
        width: CGFloat,
        color: UIColor,
        opacity: CGFloat,
        cap: CGLineCap,
        join: CGLineJoin,
        in ctx: CGContext
    ) {
        guard let first = points.first else { return }
        ctx.setLineCap(cap)
        ctx.setLineJoin(join)
        ctx.setStrokeColor(color.withAlphaComponent(opacity).cgColor)
        ctx.setLineWidth(width)
        ctx.beginPath()
        ctx.move(to: first)
        for point in points.dropFirst() {
            ctx.addLine(to: point)
        }
        ctx.strokePath()
    }

    /// Highlighter: flat chisel tip, always see-through wash (not solid like pen/crayon).
    private func drawMarkerPath(_ stroke: DoodleStroke, in ctx: CGContext) {
        let wash = min(stroke.opacity, 1) * 0.38
        let band = stroke.width * 1.9

        // Soft outer glow of ink
        drawPolyline(
            stroke.points,
            width: band * 1.15,
            color: stroke.color,
            opacity: wash * 0.45,
            cap: .butt,
            join: .miter,
            in: ctx
        )
        // Main flat highlighter ribbon
        drawPolyline(
            stroke.points,
            width: band,
            color: stroke.color,
            opacity: wash,
            cap: .butt,
            join: .miter,
            in: ctx
        )
        // Slight side offset = chisel / felt tip band
        let tip = stroke.width * 0.22
        let edged = stroke.points.enumerated().map { index, point -> CGPoint in
            guard index + 1 < stroke.points.count else { return point }
            let next = stroke.points[index + 1]
            let dx = next.x - point.x
            let dy = next.y - point.y
            let len = max(0.001, hypot(dx, dy))
            // Perpendicular nudge
            return CGPoint(x: point.x - dy / len * tip, y: point.y + dx / len * tip)
        }
        drawPolyline(
            edged,
            width: band * 0.55,
            color: stroke.color,
            opacity: wash * 1.15,
            cap: .butt,
            join: .miter,
            in: ctx
        )
    }

    /// Waxy crayon: rough broken edges, uneven coverage, chalk speckles.
    private func drawCrayonPath(_ stroke: DoodleStroke, in ctx: CGContext) {
        let w = stroke.width
        let baseOpacity = stroke.opacity

        // Fat waxy undercoat — broken / incomplete
        let underOffsets: [(CGFloat, CGFloat, CGFloat)] = [
            (0, 0, 0.55),
            (w * 0.28, -w * 0.18, 0.35),
            (-w * 0.32, w * 0.22, 0.30),
            (w * 0.18, w * 0.30, 0.28),
            (-w * 0.24, -w * 0.26, 0.25)
        ]
        for (dx, dy, weight) in underOffsets {
            let shifted = stroke.points.map { CGPoint(x: $0.x + dx, y: $0.y + dy) }
            drawPolyline(
                shifted,
                width: w * (0.65 + weight * 0.4),
                color: stroke.color,
                opacity: baseOpacity * weight,
                cap: .round,
                join: .round,
                in: ctx
            )
        }

        // Short scratchy segments with uneven width (wax catch on paper)
        if stroke.points.count >= 2 {
            var i = 0
            while i < stroke.points.count - 1 {
                let a = stroke.points[i]
                let b = stroke.points[min(i + 1, stroke.points.count - 1)]
                let seed = Int(a.x * 17 + a.y * 11 + CGFloat(i) * 3)
                let skip = (seed % 9) == 0 // occasional gaps = dry crayon
                if !skip {
                    let wobble = 0.55 + CGFloat(seed % 5) * 0.12
                    let alpha = baseOpacity * (0.35 + CGFloat(seed % 4) * 0.12)
                    let jx = CGFloat((seed % 5) - 2) * 0.35
                    let jy = CGFloat(((seed / 5) % 5) - 2) * 0.35
                    drawPolyline(
                        [
                            CGPoint(x: a.x + jx, y: a.y + jy),
                            CGPoint(x: b.x + jx, y: b.y + jy)
                        ],
                        width: w * wobble,
                        color: stroke.color,
                        opacity: alpha,
                        cap: .round,
                        join: .round,
                        in: ctx
                    )
                }
                i += 1
            }
        }

        // Dense chalk speckles
        ctx.setFillColor(stroke.color.withAlphaComponent(baseOpacity * 0.5).cgColor)
        let step = max(2, Int(w * 0.22))
        var i = 0
        while i < stroke.points.count {
            let p = stroke.points[i]
            let seed = Int(p.x * 13 + p.y * 9 + CGFloat(i))
            for n in 0..<3 {
                let s2 = seed &+ n &* 47
                let jx = CGFloat((s2 % 9) - 4) * max(0.6, w * 0.08)
                let jy = CGFloat(((s2 / 9) % 9) - 4) * max(0.6, w * 0.08)
                let r = max(0.9, w * (0.08 + CGFloat(s2 % 3) * 0.03))
                ctx.fillEllipse(in: CGRect(x: p.x + jx - r, y: p.y + jy - r, width: r * 2, height: r * 2))
            }
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
