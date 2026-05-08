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
        .frame(width: 1200, height: 750)
    }

    // MARK: - Menu

    private var menuView: some View {
        VStack(spacing: 32) {
            Spacer()

            Text("SPOTRACK")
                .font(.system(size: 88, weight: .black, design: .rounded))
                .foregroundStyle(.white)
                .shadow(color: .yellow.opacity(0.5), radius: 28)

            Text("光で追え。")
                .font(.system(size: 28, weight: .medium))
                .foregroundStyle(.white.opacity(0.75))

            VStack(spacing: 10) {
                Text("指でスポットライトを動かす")
                Text("動き回るキャラを照らし続ける")
                Text("同時に照らすほどスコア倍増")
            }
            .font(.system(size: 18))
            .foregroundStyle(.white.opacity(0.55))

            Spacer()

            Button {
                engine.startGame()
            } label: {
                Text("はじめる")
                    .font(.system(size: 30, weight: .bold, design: .rounded))
                    .foregroundStyle(.black)
                    .padding(.horizontal, 64)
                    .padding(.vertical, 20)
                    .background(.yellow)
                    .clipShape(RoundedRectangle(cornerRadius: 16))
            }
            .buttonStyle(.plain)

            Spacer()
        }
    }

    // MARK: - Game Over

    private var gameOverView: some View {
        VStack(spacing: 20) {
            Text("タイムアップ")
                .font(.system(size: 52, weight: .heavy, design: .rounded))
                .foregroundStyle(.white)

            Text("\(engine.score)")
                .font(.system(size: 88, weight: .bold, design: .monospaced))
                .foregroundStyle(.yellow)
                .shadow(color: .yellow.opacity(0.5), radius: 20)

            Text("点")
                .font(.system(size: 22))
                .foregroundStyle(.white.opacity(0.6))

            VStack(spacing: 8) {
                ForEach(engine.characters) { char in
                    HStack {
                        Circle()
                            .fill(char.color)
                            .frame(width: 12, height: 12)
                        Text(char.name)
                            .foregroundStyle(.white.opacity(0.8))
                        Spacer()
                        Text(String(format: "%.1f秒", char.litDuration))
                            .foregroundStyle(.white.opacity(0.6))
                            .font(.system(.body, design: .monospaced))
                    }
                    .font(.system(size: 17))
                }
            }
            .frame(width: 280)
            .padding(.vertical, 10)

            HStack(spacing: 20) {
                Button("もう一度") {
                    engine.startGame()
                }
                .buttonStyle(.borderedProminent)
                .tint(.yellow)
                .foregroundStyle(.black)
                .controlSize(.large)

                Button("メニュー") {
                    engine.returnToMenu()
                }
                .buttonStyle(.bordered)
                .tint(.white)
                .controlSize(.large)
            }
            .padding(.top, 12)
        }
        .padding(48)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(.ultraThinMaterial.opacity(0.9))
        )
    }
}

#Preview {
    ContentView()
}
