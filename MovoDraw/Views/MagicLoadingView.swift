import SwiftUI

struct MagicLoadingView: View {
    @State private var phase = false
    @State private var breathe = false
    @State private var ring = false

    var body: some View {
        ZStack {
            // Soft shifting wash — intentional, not strobing
            LinearGradient(
                colors: phase
                    ? [MDColor.magicA, MDColor.magicB, MDColor.magicC.opacity(0.85)]
                    : [MDColor.magicC.opacity(0.85), MDColor.magicA, MDColor.magicB],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
            .animation(.easeInOut(duration: 2.4).repeatForever(autoreverses: true), value: phase)

            VStack(spacing: 28) {
                ZStack {
                    Circle()
                        .fill(.white.opacity(0.18))
                        .frame(width: 168, height: 168)
                        .scaleEffect(breathe ? 1.08 : 0.92)

                    Circle()
                        .strokeBorder(.white.opacity(0.55), lineWidth: 5)
                        .frame(width: 132, height: 132)
                        .rotationEffect(.degrees(ring ? 360 : 0))

                    Image(systemName: "wand.and.stars")
                        .font(.system(size: 54, weight: .semibold))
                        .foregroundStyle(.white)
                        .scaleEffect(breathe ? 1.06 : 0.94)
                }

                Text("Magic")
                    .font(MDType.brand(44))
                    .foregroundStyle(.white)

                // Three quiet dots — presence, not clutter
                HStack(spacing: 12) {
                    ForEach(0..<3, id: \.self) { i in
                        Circle()
                            .fill(.white.opacity(0.95))
                            .frame(width: 12, height: 12)
                            .offset(y: breathe ? -6 : 6)
                            .animation(
                                .easeInOut(duration: 0.55)
                                    .repeatForever(autoreverses: true)
                                    .delay(Double(i) * 0.14),
                                value: breathe
                            )
                    }
                }
            }
        }
        .onAppear {
            phase = true
            breathe = true
            withAnimation(.linear(duration: 3.2).repeatForever(autoreverses: false)) {
                ring = true
            }
        }
        .accessibilityLabel("Magic")
    }
}
