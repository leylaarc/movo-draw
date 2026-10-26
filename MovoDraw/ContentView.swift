import SwiftUI
import UIKit

enum AppScreen {
    case draw
    case magic
    case living
}

struct ContentView: View {
    @StateObject private var canvas = CanvasController()
    @State private var screen: AppScreen = .draw
    @State private var selectedUIColor: UIColor = .black
    @State private var result: LifeResult?
    @State private var errorMessage: String?
    @State private var showEmptyHint = false
    @State private var didAutoDemo = false
    @State private var resultAppeared = false

    private var shouldAutoDemo: Bool {
        ProcessInfo.processInfo.arguments.contains("-DemoDragon")
    }

    private let palette: [(name: String, color: UIColor)] = [
        ("Black", .black),
        ("Red", UIColor(red: 0.92, green: 0.22, blue: 0.28, alpha: 1)),
        ("Blue", UIColor(red: 0.22, green: 0.48, blue: 0.95, alpha: 1)),
        ("Yellow", UIColor(red: 1.0, green: 0.82, blue: 0.18, alpha: 1)),
        ("Green", UIColor(red: 0.22, green: 0.72, blue: 0.42, alpha: 1)),
        ("Purple", UIColor(red: 0.55, green: 0.38, blue: 0.92, alpha: 1)),
        ("Orange", UIColor(red: 1.0, green: 0.52, blue: 0.18, alpha: 1))
    ]

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
            // Brand hero — first-screen signal
            HStack(alignment: .top) {
                MovoBrandMark(size: 46)
                Spacer()
            }
            .padding(.horizontal, MDLayout.screenPad)
            .padding(.top, 10)
            .padding(.bottom, 14)

            // Paper plane — the drawing surface, not a “card”
            DoodleCanvasRepresentable(
                controller: canvas,
                color: selectedUIColor,
                lineWidth: MDLayout.brushWidth
            )
            .background(MDColor.paper)
            .clipShape(RoundedRectangle(cornerRadius: MDLayout.corner, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: MDLayout.corner, style: .continuous)
                    .strokeBorder(MDColor.paperEdge, lineWidth: 3)
            )
            .padding(.horizontal, MDLayout.screenPad)
            .frame(maxWidth: .infinity, maxHeight: .infinity)

            // Calm dock: crayons → quiet tools → one full-width CTA
            VStack(spacing: 16) {
                colorBar

                HStack(spacing: 14) {
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

                    Spacer(minLength: 0)
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
            .padding(.top, 16)
            .padding(.bottom, 14)
        }
    }

    private var colorBar: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 12) {
                ForEach(Array(palette.enumerated()), id: \.offset) { _, item in
                    CrayonSwatch(
                        color: Color(item.color),
                        selected: colorsMatch(selectedUIColor, item.color),
                        name: item.name
                    ) {
                        selectedUIColor = item.color
                    }
                }
            }
            .padding(.horizontal, 4)
            .padding(.vertical, 8)
            .frame(maxWidth: .infinity)
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
                        Text("Add FAL_KEY for real magic")
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

#Preview {
    ContentView()
}
