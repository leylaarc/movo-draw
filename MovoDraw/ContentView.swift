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

    /// `-DemoDragon` launch arg seeds a black/red dragon and brings it to life.
    private var shouldAutoDemo: Bool {
        ProcessInfo.processInfo.arguments.contains("-DemoDragon")
    }

    private let palette: [(name: String, color: UIColor)] = [
        ("Black", .black),
        ("Red", UIColor(red: 0.92, green: 0.18, blue: 0.22, alpha: 1)),
        ("Blue", UIColor(red: 0.2, green: 0.45, blue: 0.98, alpha: 1)),
        ("Yellow", UIColor(red: 1.0, green: 0.8, blue: 0.1, alpha: 1)),
        ("Green", UIColor(red: 0.2, green: 0.75, blue: 0.35, alpha: 1)),
        ("Purple", UIColor(red: 0.58, green: 0.35, blue: 0.95, alpha: 1)),
        ("Orange", UIColor(red: 1.0, green: 0.5, blue: 0.15, alpha: 1))
    ]

    private let lifeService: any LifeService = LifeServiceFactory.make()

    var body: some View {
        ZStack {
            background

            switch screen {
            case .draw:
                drawScreen
                    .transition(.opacity)
            case .magic:
                MagicLoadingView()
                    .transition(.opacity)
            case .living:
                if let result {
                    resultScreen(result)
                        .transition(.opacity)
                }
            }
        }
        .animation(.easeInOut(duration: 0.35), value: screen)
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

    private var background: some View {
        LinearGradient(
            colors: [MDColor.skyTop, MDColor.skyBottom, MDColor.grass.opacity(0.35)],
            startPoint: .top,
            endPoint: .bottom
        )
        .ignoresSafeArea()
    }

    private var drawScreen: some View {
        VStack(spacing: 16) {
            HStack {
                Text("Movo Draw")
                    .font(.system(size: 34, weight: .heavy, design: .rounded))
                    .foregroundStyle(MDColor.ink)
                Spacer()
            }
            .padding(.horizontal, 20)
            .padding(.top, 8)

            DoodleCanvasRepresentable(
                controller: canvas,
                color: selectedUIColor,
                lineWidth: MDLayout.brushWidth
            )
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .padding(.horizontal, 16)

            colorBar

            HStack(spacing: 16) {
                KidIconButton(systemImage: "arrow.uturn.backward", label: "Undo", color: MDColor.grape) {
                    canvas.undo()
                }
                KidIconButton(systemImage: "trash", label: "Clear", color: MDColor.coral) {
                    canvas.clear()
                }
                Spacer(minLength: 0)
            }
            .padding(.horizontal, 20)

            KidPrimaryButton(
                title: "Bring to Life",
                systemImage: "sparkles",
                color: MDColor.coral
            ) {
                Task { await bringToLife() }
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 12)
        }
    }

    private var colorBar: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 14) {
                ForEach(Array(palette.enumerated()), id: \.offset) { _, item in
                    Button {
                        selectedUIColor = item.color
                    } label: {
                        Circle()
                            .fill(Color(item.color))
                            .frame(width: MDLayout.colorSwatch, height: MDLayout.colorSwatch)
                            .overlay(
                                Circle()
                                    .strokeBorder(.white, lineWidth: colorsMatch(selectedUIColor, item.color) ? 5 : 0)
                            )
                            .shadow(color: .black.opacity(0.15), radius: 4, y: 2)
                    }
                    .accessibilityLabel(item.name)
                }
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 6)
        }
    }

    @ViewBuilder
    private func resultScreen(_ result: LifeResult) -> some View {
        VStack(spacing: 12) {
            HStack {
                Text("Alive!")
                    .font(.system(size: 34, weight: .heavy, design: .rounded))
                    .foregroundStyle(MDColor.ink)
                Spacer()
            }
            .padding(.horizontal, 20)
            .padding(.top, 8)

            Group {
                switch result.kind {
                case .localAnimation(let analysis):
                    LivingDoodleView(image: result.doodleImage, analysis: analysis)
                        .clipShape(RoundedRectangle(cornerRadius: 32, style: .continuous))
                        .shadow(color: .black.opacity(0.12), radius: 16, y: 8)
                        .padding(.horizontal, 16)
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
            .frame(maxWidth: .infinity, maxHeight: .infinity)

            KidPrimaryButton(
                title: "Draw Again",
                systemImage: "pencil.tip",
                color: MDColor.mint
            ) {
                canvas.clear()
                self.result = nil
                screen = .draw
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 12)
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
