import SwiftUI
import UIKit

enum AppScreen {
    case draw
    case magic
    case living
}

struct ContentView: View {
    @StateObject private var canvas = CanvasController()
    @StateObject private var tools = DrawingToolState()
    @State private var screen: AppScreen = .draw
    @State private var result: LifeResult?
    @State private var errorMessage: String?
    @State private var showEmptyHint = false
    @State private var didAutoDemo = false
    @State private var resultAppeared = false

    private var shouldAutoDemo: Bool {
        ProcessInfo.processInfo.arguments.contains("-DemoDragon")
    }

    private let lifeService: any LifeService = LifeServiceFactory.make()

    var body: some View {
        ZStack {
            StudioAtmosphere()

            switch screen {
            case .draw:
                drawScreen
                    .transition(.asymmetric(
                        insertion: .opacity.combined(with: .scale(scale: 0.98)),
                        removal: .opacity
                    ))
            case .magic:
                MagicLoadingView()
                    .transition(.opacity)
            case .living:
                if let result {
                    resultScreen(result)
                        .transition(.asymmetric(
                            insertion: .opacity.combined(with: .scale(scale: 0.94)),
                            removal: .opacity
                        ))
                }
            }
        }
        .animation(.spring(response: 0.45, dampingFraction: 0.86), value: screen)
        .alert("Draw first!", isPresented: $showEmptyHint) {
            Button("OK", role: .cancel) {}
        } message: {
            Text("Make a doodle, then tap Bring to Life.")
        }
        .alert("Oops", isPresented: Binding(
            get: { errorMessage != nil },
            set: { if !$0 { errorMessage = nil } }
        )) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(errorMessage ?? "")
        }
        .sheet(isPresented: $tools.showToolsMenu) {
            DrawingToolsSheet(tools: tools)
                .presentationDetents([.medium, .large])
                .presentationDragIndicator(.visible)
        }
        .sheet(isPresented: $tools.showMoreColors) {
            MoreColorsSheet(tools: tools)
                .presentationDetents([.medium, .large])
                .presentationDragIndicator(.visible)
        }
        .sheet(isPresented: $tools.showColorMixer) {
            ColorMixerSheet(tools: tools)
                .presentationDetents([.medium])
                .presentationDragIndicator(.visible)
        }
        .task {
            guard shouldAutoDemo, !didAutoDemo else { return }
            didAutoDemo = true
            try? await Task.sleep(nanoseconds: 700_000_000)
            canvas.seedDragonDoodle()
            try? await Task.sleep(nanoseconds: 900_000_000)
            await bringToLife()
        }
    }

    // MARK: - Draw (one job: doodle)

    private var drawScreen: some View {
        VStack(spacing: 0) {
            // Slim brand row — canvas gets the room
            HStack(alignment: .center) {
                MovoBrandMark(size: 36)
                Spacer()
                TipPreview(
                    color: Color(tools.color),
                    size: tools.size,
                    opacity: tools.opacityValue,
                    style: tools.style
                )
            }
            .padding(.horizontal, MDLayout.screenPad)
            .padding(.top, 6)
            .padding(.bottom, 6)

            // Paper plane — dominant drawing surface
            DoodleCanvasRepresentable(
                controller: canvas,
                color: tools.color,
                lineWidth: tools.lineWidth,
                opacity: tools.opacityValue,
                style: tools.style
            )
            .background(MDColor.paper)
            .clipShape(RoundedRectangle(cornerRadius: MDLayout.corner, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: MDLayout.corner, style: .continuous)
                    .strokeBorder(MDColor.paperEdge, lineWidth: 3)
            )
            .padding(.horizontal, MDLayout.screenPad)
            .frame(maxWidth: .infinity, maxHeight: .infinity)

            // Slim dock: Tools menu + undo/clear + CTA
            VStack(spacing: 10) {
                HStack(spacing: 12) {
                    ToolsMenuButton(
                        color: Color(tools.color),
                        style: tools.style
                    ) {
                        tools.showToolsMenu = true
                    }

                    Spacer(minLength: 0)

                    KidToolButton(
                        systemImage: "arrow.uturn.backward",
                        label: "Undo",
                        tint: MDColor.tool
                    ) { canvas.undo() }

                    KidToolButton(
                        systemImage: "trash",
                        label: "Clear",
                        tint: MDColor.warn
                    ) { canvas.clear() }
                }

                KidPrimaryButton(
                    title: "Bring to Life",
                    systemImage: "sparkles",
                    color: MDColor.life
                ) {
                    Task { await bringToLife() }
                }
            }
            .padding(.horizontal, MDLayout.screenPad)
            .padding(.top, 10)
            .padding(.bottom, 12)
        }
    }

    // MARK: - Alive (one job: show the result)

    @ViewBuilder
    private func resultScreen(_ result: LifeResult) -> some View {
        VStack(spacing: 0) {
            HStack(alignment: .firstTextBaseline) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(result.isFallback ? "Almost" : "Alive!")
                        .font(MDType.brand(40))
                        .foregroundStyle(MDColor.ink)
                    if result.isFallback {
                        Text("Ask a grown-up to turn on picture magic")
                            .font(MDType.label(15))
                            .foregroundStyle(MDColor.inkSoft)
                    }
                }
                Spacer()
                MovoBrandMark(size: 22, compact: true)
                    .opacity(0.55)
            }
            .padding(.horizontal, MDLayout.screenPad)
            .padding(.top, 10)
            .padding(.bottom, 16)

            Group {
                switch result.kind {
                case .generatedImage(let image):
                    Image(uiImage: image)
                        .resizable()
                        .scaledToFit()
                        .clipShape(RoundedRectangle(cornerRadius: MDLayout.corner, style: .continuous))
                        .padding(.horizontal, MDLayout.screenPad)
                case .localFallback(let analysis):
                    LivingDoodleView(image: result.doodleImage, analysis: analysis)
                        .clipShape(RoundedRectangle(cornerRadius: MDLayout.corner, style: .continuous))
                        .overlay(alignment: .topTrailing) {
                            Text("Offline")
                                .font(MDType.label(13))
                                .foregroundStyle(MDColor.inkSoft)
                                .padding(.horizontal, 12)
                                .padding(.vertical, 7)
                                .background(
                                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                                        .fill(MDColor.paper.opacity(0.92))
                                )
                                .padding(28)
                        }
                        .padding(.horizontal, MDLayout.screenPad)
                case .remoteVideo(let url):
                    VStack {
                        Image(uiImage: result.doodleImage)
                            .resizable()
                            .scaledToFit()
                        Text(url.absoluteString)
                            .font(.caption)
                    }
                    .padding()
                }
            }
            .scaleEffect(resultAppeared ? 1 : 0.92)
            .opacity(resultAppeared ? 1 : 0)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .onAppear {
                resultAppeared = false
                withAnimation(.spring(response: 0.55, dampingFraction: 0.78)) {
                    resultAppeared = true
                }
            }

            KidPrimaryButton(
                title: "Draw Again",
                systemImage: "pencil.tip",
                color: MDColor.again
            ) {
                canvas.clear()
                self.result = nil
                resultAppeared = false
                screen = .draw
            }
            .padding(.horizontal, MDLayout.screenPad)
            .padding(.top, 14)
            .padding(.bottom, 16)
        }
    }

    private func colorsMatch(_ a: UIColor, _ b: UIColor) -> Bool {
        var ar: CGFloat = 0, ag: CGFloat = 0, ab: CGFloat = 0, aa: CGFloat = 0
        var br: CGFloat = 0, bg: CGFloat = 0, bb: CGFloat = 0, ba: CGFloat = 0
        a.getRed(&ar, green: &ag, blue: &ab, alpha: &aa)
        b.getRed(&br, green: &bg, blue: &bb, alpha: &ba)
        return abs(ar - br) < 0.01 && abs(ag - bg) < 0.01 && abs(ab - bb) < 0.01
    }

    @MainActor
    private func bringToLife() async {
        guard canvas.hasInk else {
            showEmptyHint = true
            return
        }
        let image = canvas.exportImage()
        screen = .magic
        do {
            let life = try await lifeService.bringToLife(image)
            self.result = life
            self.screen = .living
        } catch {
            self.errorMessage = error.localizedDescription
            self.screen = .draw
        }
    }
}

// MARK: - Tools menu (color, type, size, soft — off the canvas)

private struct DrawingToolsSheet: View {
    @ObservedObject var tools: DrawingToolState
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 22) {
                    // Color
                    VStack(alignment: .leading, spacing: 10) {
                        TraySectionLabel(title: "Color")
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 10) {
                                MixColorButton(current: Color(tools.color)) {
                                    dismiss()
                                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) {
                                        tools.showColorMixer = true
                                    }
                                }
                                MoreColorsButton {
                                    dismiss()
                                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) {
                                        tools.showMoreColors = true
                                    }
                                }
                                ForEach(CrayonPalette.primary) { swatch in
                                    CrayonSwatch(
                                        color: Color(swatch.color),
                                        selected: tools.style != .eraser
                                            && colorsMatch(tools.color, swatch.color),
                                        name: swatch.name,
                                        size: MDLayout.colorSwatchCompact
                                    ) {
                                        tools.selectCrayon(swatch.color)
                                    }
                                }
                            }
                            .padding(.vertical, 4)
                        }
                    }

                    // Type
                    VStack(alignment: .leading, spacing: 10) {
                        TraySectionLabel(title: "Type")
                        HStack(spacing: 10) {
                            ForEach(StrokeStyle.allCases) { style in
                                StrokeStyleButton(
                                    style: style,
                                    selected: tools.style == style
                                ) {
                                    tools.style = style
                                }
                            }
                            Spacer(minLength: 0)
                        }
                    }

                    // Size
                    VStack(alignment: .leading, spacing: 10) {
                        TraySectionLabel(title: "Size")
                        HStack(spacing: 8) {
                            ForEach(PenSize.allCases) { size in
                                PenSizeChip(
                                    size: size,
                                    color: Color(tools.color),
                                    opacity: tools.opacityValue,
                                    selected: tools.size == size
                                ) {
                                    tools.size = size
                                }
                            }
                            Spacer(minLength: 0)
                        }
                    }

                    // Softness
                    VStack(alignment: .leading, spacing: 10) {
                        TraySectionLabel(title: "Softness")
                        HStack(spacing: 10) {
                            ForEach(OpacityPreset.allCases) { preset in
                                OpacityChip(
                                    preset: preset,
                                    color: Color(tools.color),
                                    selected: tools.opacity == preset
                                ) {
                                    tools.opacity = preset
                                }
                            }
                            Spacer(minLength: 0)
                        }
                    }
                }
                .padding(20)
            }
            .background(MDColor.mist.ignoresSafeArea())
            .navigationTitle("Tools")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }
                        .font(MDType.body(17))
                        .foregroundStyle(MDColor.life)
                }
            }
        }
    }

    private func colorsMatch(_ a: UIColor, _ b: UIColor) -> Bool {
        var ar: CGFloat = 0, ag: CGFloat = 0, ab: CGFloat = 0, aa: CGFloat = 0
        var br: CGFloat = 0, bg: CGFloat = 0, bb: CGFloat = 0, ba: CGFloat = 0
        a.getRed(&ar, green: &ag, blue: &ab, alpha: &aa)
        b.getRed(&br, green: &bg, blue: &bb, alpha: &ba)
        return abs(ar - br) < 0.01 && abs(ag - bg) < 0.01 && abs(ab - bb) < 0.01
    }
}

// MARK: - Mix your own (dedicated sheet with a real ColorPicker)

private struct ColorMixerSheet: View {
    @ObservedObject var tools: DrawingToolState
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            VStack(alignment: .leading, spacing: 20) {
                MixYourOwnColorCard(
                    color: Binding(
                        get: { tools.pickerColor },
                        set: { tools.applyPickerColor($0) }
                    )
                ) { picked in
                    tools.applyPickerColor(picked)
                }

                Text("Tap the color circle, then choose any shade.")
                    .font(MDType.label(15))
                    .foregroundStyle(MDColor.inkSoft)

                Spacer()

                KidPrimaryButton(
                    title: "Use This Color",
                    systemImage: "checkmark",
                    color: MDColor.life
                ) {
                    tools.applyPickerColor(tools.pickerColor)
                    dismiss()
                }
            }
            .padding(22)
            .background(MDColor.mist.ignoresSafeArea())
            .navigationTitle("Mix")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") {
                        tools.applyPickerColor(tools.pickerColor)
                        dismiss()
                    }
                    .font(MDType.body(17))
                    .foregroundStyle(MDColor.life)
                }
            }
        }
    }
}

// MARK: - More colors sheet

private struct MoreColorsSheet: View {
    @ObservedObject var tools: DrawingToolState
    @Environment(\.dismiss) private var dismiss

    private let columns = Array(repeating: GridItem(.flexible(), spacing: 14), count: 4)

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 22) {
                    Text("Colors")
                        .font(MDType.brand(28))
                        .foregroundStyle(MDColor.ink)

                    Button {
                        dismiss()
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) {
                            tools.showColorMixer = true
                        }
                    } label: {
                        HStack(spacing: 14) {
                            ZStack {
                                Circle()
                                    .fill(
                                        AngularGradient(
                                            colors: [
                                                Color(red: 1, green: 0.2, blue: 0.3),
                                                Color(red: 1, green: 0.7, blue: 0.1),
                                                Color(red: 0.25, green: 0.85, blue: 0.35),
                                                Color(red: 0.2, green: 0.55, blue: 1),
                                                Color(red: 0.65, green: 0.3, blue: 0.95),
                                                Color(red: 1, green: 0.2, blue: 0.3)
                                            ],
                                            center: .center
                                        )
                                    )
                                    .frame(width: 52, height: 52)
                                Circle()
                                    .fill(Color(tools.color))
                                    .frame(width: 36, height: 36)
                            }
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Mix your own")
                                    .font(MDType.title(20))
                                    .foregroundStyle(MDColor.ink)
                                Text("Open the color wheel")
                                    .font(MDType.label(14))
                                    .foregroundStyle(MDColor.inkSoft)
                            }
                            Spacer()
                            Image(systemName: "chevron.right")
                                .font(.system(size: 16, weight: .bold))
                                .foregroundStyle(MDColor.inkSoft)
                        }
                        .padding(14)
                        .background(
                            RoundedRectangle(cornerRadius: 24, style: .continuous)
                                .fill(MDColor.paper.opacity(0.95))
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: 24, style: .continuous)
                                .strokeBorder(MDColor.life.opacity(0.35), lineWidth: 2)
                        )
                    }
                    .buttonStyle(.plain)

                    ForEach(CrayonPalette.sections) { section in
                        VStack(alignment: .leading, spacing: 12) {
                            Text(section.title)
                                .font(MDType.title(18))
                                .foregroundStyle(MDColor.inkSoft)

                            LazyVGrid(columns: columns, spacing: 16) {
                                ForEach(section.crayons) { swatch in
                                    NamedCrayonSwatch(
                                        crayon: swatch,
                                        selected: tools.style != .eraser
                                            && colorsMatch(tools.color, swatch.color)
                                    ) {
                                        tools.selectCrayon(swatch.color)
                                        dismiss()
                                    }
                                }
                            }
                        }
                    }
                }
                .padding(22)
            }
            .background(MDColor.mist.ignoresSafeArea())
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }
                        .font(MDType.body(17))
                        .foregroundStyle(MDColor.life)
                }
            }
        }
    }

    private func colorsMatch(_ a: UIColor, _ b: UIColor) -> Bool {
        var ar: CGFloat = 0, ag: CGFloat = 0, ab: CGFloat = 0, aa: CGFloat = 0
        var br: CGFloat = 0, bg: CGFloat = 0, bb: CGFloat = 0, ba: CGFloat = 0
        a.getRed(&ar, green: &ag, blue: &ab, alpha: &aa)
        b.getRed(&br, green: &bg, blue: &bb, alpha: &ba)
        return abs(ar - br) < 0.01 && abs(ag - bg) < 0.01 && abs(ab - bb) < 0.01
    }
}

#Preview {
    ContentView()
}
