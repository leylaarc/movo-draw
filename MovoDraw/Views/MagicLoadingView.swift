import SwiftUI

struct MagicLoadingView: View {
    @State private var spin = false
    @State private var bounce = false
    @State private var sparkle = false

    var body: some View {
        ZStack {
            LinearGradient(
                colors: [MDColor.grape.opacity(0.85), MDColor.coral.opacity(0.9), MDColor.sunshine.opacity(0.8)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            VStack(spacing: 28) {
                ZStack {
                    Circle()
                        .strokeBorder(.white.opacity(0.35), lineWidth: 8)
                        .frame(width: 140, height: 140)
                        .rotationEffect(.degrees(spin ? 360 : 0))
                        .animation(.linear(duration: 2.2).repeatForever(autoreverses: false), value: spin)

                    Image(systemName: "sparkles")
                        .font(.system(size: 64, weight: .bold))
                        .foregroundStyle(.white)
                        .scaleEffect(bounce ? 1.15 : 0.9)
                        .animation(.easeInOut(duration: 0.7).repeatForever(autoreverses: true), value: bounce)
                }

                Text("Magic…")
                    .font(.system(size: 40, weight: .heavy, design: .rounded))
                    .foregroundStyle(.white)
                    .shadow(color: .black.opacity(0.15), radius: 4, y: 2)

                HStack(spacing: 14) {
                    ForEach(0..<3, id: \.self) { i in
                        Circle()
                            .fill(.white)
                            .frame(width: 16, height: 16)
                            .offset(y: sparkle ? -10 : 10)
                            .animation(
                                .easeInOut(duration: 0.45)
                                    .repeatForever(autoreverses: true)
                                    .delay(Double(i) * 0.15),
                                value: sparkle
                            )
                    }
                }
            }
        }
        .onAppear {
            spin = true
            bounce = true
            sparkle = true
        }
        .accessibilityLabel("Magic loading")
    }
}
