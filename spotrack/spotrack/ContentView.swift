import SwiftUI

struct ContentView: View {
    @State private var engine = GameEngine()

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            switch engine.state {
            case .menu:
                menuView
            case .playing:
                GameView(engine: engine)
            case .gameOver:
                gameOverView
            }
        }
        .frame(width: 800, height: 500)
    }

    // MARK: - Menu

    private var menuView: some View {
        VStack(spacing: 24) {
            Spacer()

            Text("SPOTRACK")
                .font(.system(size: 56, weight: .black, design: .rounded))
                .foregroundStyle(.white)
                .shadow(color: .yellow.opacity(0.5), radius: 20)

            Text("Track the characters with your spotlights!")
                .font(.system(size: 18, weight: .medium))
                .foregroundStyle(.white.opacity(0.7))

            VStack(spacing: 8) {
                Text("Place 4 fingers on the trackpad")
                Text("Keep the spotlight on each character")
                Text("Light up multiple characters for combo bonus!")
            }
            .font(.system(size: 14))
            .foregroundStyle(.white.opacity(0.5))

            Spacer()

            Button {
                engine.startGame()
            } label: {
                Text("START")
                    .font(.system(size: 24, weight: .bold, design: .rounded))
                    .foregroundStyle(.black)
                    .padding(.horizontal, 48)
                    .padding(.vertical, 16)
                    .background(.yellow)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
            }
            .buttonStyle(.plain)

            Spacer()
        }
    }

    // MARK: - Game Over

    private var gameOverView: some View {
        VStack(spacing: 16) {
            Text("TIME'S UP!")
                .font(.system(size: 40, weight: .heavy, design: .rounded))
                .foregroundStyle(.white)

            Text("\(engine.score)")
                .font(.system(size: 64, weight: .bold, design: .monospaced))
                .foregroundStyle(.yellow)
                .shadow(color: .yellow.opacity(0.5), radius: 15)

            Text("points")
                .font(.system(size: 18))
                .foregroundStyle(.white.opacity(0.6))

            VStack(spacing: 6) {
                ForEach(engine.characters) { char in
                    HStack {
                        Circle()
                            .fill(char.color)
                            .frame(width: 10, height: 10)
                        Text(char.name)
                            .foregroundStyle(.white.opacity(0.8))
                        Spacer()
                        Text(String(format: "%.1fs lit", char.litDuration))
                            .foregroundStyle(.white.opacity(0.6))
                            .font(.system(.body, design: .monospaced))
                    }
                    .font(.system(size: 14))
                }
            }
            .frame(width: 220)
            .padding(.vertical, 8)

            HStack(spacing: 16) {
                Button("Play Again") {
                    engine.startGame()
                }
                .buttonStyle(.borderedProminent)
                .tint(.yellow)
                .foregroundStyle(.black)

                Button("Menu") {
                    engine.returnToMenu()
                }
                .buttonStyle(.bordered)
                .tint(.white)
            }
            .padding(.top, 8)
        }
        .padding(36)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(.ultraThinMaterial.opacity(0.9))
        )
    }
}

#Preview {
    ContentView()
}
