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
    var lineWidth: CGFloat = MDLayout.brushWidth

    private var strokes: [(color: UIColor, width: CGFloat, points: [CGPoint])] = []
    private var undone: [(color: UIColor, width: CGFloat, points: [CGPoint])] = []
    private var currentPoints: [CGPoint] = []

    var hasInk: Bool {
        !strokes.isEmpty || currentPoints.count > 1
    }

    override init(frame: CGRect) {
        super.init(frame: frame)
        backgroundColor = .white
        isMultipleTouchEnabled = false
        layer.cornerRadius = 32
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
        let thick: CGFloat = 16

        let body: [CGPoint] = [
            CGPoint(x: w * 0.28, y: h * 0.62),
            CGPoint(x: w * 0.42, y: h * 0.55),
            CGPoint(x: w * 0.55, y: h * 0.48),
            CGPoint(x: w * 0.62, y: h * 0.38),
            CGPoint(x: w * 0.68, y: h * 0.30),
            CGPoint(x: w * 0.74, y: h * 0.28),
            CGPoint(x: w * 0.78, y: h * 0.32)
        ]
        strokes.append((black, thick, body))

        let wing: [CGPoint] = [
            CGPoint(x: w * 0.48, y: h * 0.52),
            CGPoint(x: w * 0.38, y: h * 0.34),
            CGPoint(x: w * 0.52, y: h * 0.28),
            CGPoint(x: w * 0.58, y: h * 0.42)
        ]
        strokes.append((red, thick, wing))

        let tail: [CGPoint] = [
            CGPoint(x: w * 0.28, y: h * 0.62),
            CGPoint(x: w * 0.18, y: h * 0.70),
            CGPoint(x: w * 0.14, y: h * 0.78),
            CGPoint(x: w * 0.22, y: h * 0.74)
        ]
        strokes.append((black, thick * 0.85, tail))

        let belly: [CGPoint] = [
            CGPoint(x: w * 0.40, y: h * 0.58),
            CGPoint(x: w * 0.50, y: h * 0.52),
            CGPoint(x: w * 0.58, y: h * 0.46)
        ]
        strokes.append((red, thick * 0.7, belly))

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
            UIColor.white.setFill()
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
        strokes.append((strokeColor, lineWidth, currentPoints))
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
            all.append((strokeColor, lineWidth, currentPoints))
        }
        ctx.setLineCap(.round)
        ctx.setLineJoin(.round)
        for stroke in all {
            guard let first = stroke.points.first else { continue }
            ctx.setStrokeColor(stroke.color.cgColor)
            ctx.setLineWidth(stroke.width)
            ctx.beginPath()
            ctx.move(to: first)
            for point in stroke.points.dropFirst() {
                ctx.addLine(to: point)
            }
            ctx.strokePath()
        }
    }
}

struct DoodleCanvasRepresentable: UIViewRepresentable {
    @ObservedObject var controller: CanvasController
    var color: UIColor
    var lineWidth: CGFloat

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
        canvas.strokeColor = color
        canvas.lineWidth = lineWidth
        return host
    }

    func updateUIView(_ uiView: UIView, context: Context) {
        controller.view.strokeColor = color
        controller.view.lineWidth = lineWidth
    }
}
