import SwiftUI
import OpenMultitouchSupport

struct GameCharacter: Identifiable {
    let id: Int
    var x: CGFloat
    var y: CGFloat
    var vx: CGFloat
    var vy: CGFloat = 0
    var isOnGround: Bool = true
    var isLit: Bool = false
    var facingRight: Bool = true
    var litDuration: Double = 0

    let baseSpeed: CGFloat
    let jumpForce: CGFloat
    let jumpFrequency: CGFloat
    let turnFrequency: CGFloat
    let hue: Double
    let name: String

    var color: Color {
        Color(hue: hue, saturation: 0.85, brightness: 1.0)
    }

    var dimColor: Color {
        Color(hue: hue, saturation: 0.4, brightness: 0.25)
    }

    mutating func update(dt: CGFloat) {
        if !isOnGround {
            vy -= GameEngine.gravity * dt
        }

        x += vx * dt
        y += vy * dt

        if y <= GameEngine.groundLevel {
            y = GameEngine.groundLevel
            vy = 0
            isOnGround = true
        }

        let margin: CGFloat = 0.04
        if x < margin {
            x = margin
            vx = abs(vx)
            facingRight = true
        } else if x > 1 - margin {
            x = 1 - margin
            vx = -abs(vx)
            facingRight = false
        }

        let dtd = Double(dt)

        if isOnGround && Double.random(in: 0...1) < Double(turnFrequency) * dtd {
            vx = -vx
            facingRight = vx > 0
        }

        if isOnGround && Double.random(in: 0...1) < 0.3 * dtd {
            let speed = CGFloat.random(in: baseSpeed * 0.5...baseSpeed * 1.5)
            vx = facingRight ? speed : -speed
        }

        if isOnGround && Double.random(in: 0...1) < Double(jumpFrequency) * dtd {
            vy = jumpForce * CGFloat.random(in: 0.8...1.2)
            isOnGround = false
        }
    }
}

@Observable
@MainActor
final class GameEngine {
    static let groundLevel: CGFloat = 0.08
    static let gravity: CGFloat = 2.0
    static let characterRadius: CGFloat = 0.025
    static let spotlightRadius: CGFloat = 0.08
    static let gameDuration: Double = 60

    var characters: [GameCharacter] = []
    var fingers: [CGPoint] = []
    var score: Int = 0
    var timeRemaining: Double = 60
    var state: GameState = .menu
    var litCount: Int = 0

    private var scoreAccumulator: Double = 0
    private var lastUpdateTime: Date?
    private var gameTimer: Timer?
    private var touchTask: Task<Void, Never>?
    private let touchManager = OMSManager.shared

    enum GameState: Equatable {
        case menu, playing, gameOver
    }

    func startGame() {
        characters = Self.makeCharacters()
        score = 0
        scoreAccumulator = 0
        timeRemaining = Self.gameDuration
        state = .playing
        litCount = 0
        lastUpdateTime = Date()

        _ = touchManager.startListening()

        let stream = touchManager.touchDataStream
        touchTask = Task { [weak self] in
            for await data in stream {
                let points = data
                    .filter { $0.state == .touching || $0.state == .making || $0.state == .starting }
                    .map { CGPoint(x: CGFloat($0.position.x), y: CGFloat($0.position.y)) }
                // Reject inputs with more than 4 fingers — keeps the game honest
                let valid = points.count > 4 ? [] : points
                await MainActor.run {
                    self?.fingers = valid
                }
            }
        }

        gameTimer = Timer.scheduledTimer(withTimeInterval: 1.0 / 60.0, repeats: true) { [weak self] _ in
            MainActor.assumeIsolated {
                self?.update()
            }
        }
    }

    func stopGame() {
        gameTimer?.invalidate()
        gameTimer = nil
        touchTask?.cancel()
        touchTask = nil
        _ = touchManager.stopListening()
        fingers = []
        state = .gameOver
    }

    func returnToMenu() {
        state = .menu
    }

    private func update() {
        let now = Date()
        guard let last = lastUpdateTime else {
            lastUpdateTime = now
            return
        }

        let dt = CGFloat(min(now.timeIntervalSince(last), 1.0 / 30.0))
        lastUpdateTime = now

        guard dt > 0 else { return }

        timeRemaining -= Double(dt)
        if timeRemaining <= 0 {
            timeRemaining = 0
            stopGame()
            return
        }

        var currentLit = 0
        for i in characters.indices {
            characters[i].update(dt: dt)

            let cx = characters[i].x
            let cy = characters[i].y + Self.characterRadius

            let isLit = fingers.contains { f in
                let dx = f.x - cx
                let dy = f.y - cy
                return sqrt(dx * dx + dy * dy) < Self.spotlightRadius + Self.characterRadius
            }

            characters[i].isLit = isLit
            if isLit {
                currentLit += 1
                characters[i].litDuration += Double(dt)
            }
        }

        litCount = currentLit
        if currentLit > 0 {
            let mult = Double(currentLit)
            scoreAccumulator += Double(dt) * 10.0 * mult * mult
            score = Int(scoreAccumulator)
        }
    }

    private static func makeCharacters() -> [GameCharacter] {
        [
            GameCharacter(
                id: 0, x: 0.15, y: groundLevel, vx: 0.12,
                baseSpeed: 0.12, jumpForce: 0.5, jumpFrequency: 0.3,
                turnFrequency: 0.5, hue: 0.0, name: "Runner"
            ),
            GameCharacter(
                id: 1, x: 0.38, y: groundLevel, vx: -0.07,
                baseSpeed: 0.07, jumpForce: 0.7, jumpFrequency: 1.8,
                turnFrequency: 0.3, hue: 0.55, name: "Jumper"
            ),
            GameCharacter(
                id: 2, x: 0.62, y: groundLevel, vx: 0.18,
                baseSpeed: 0.18, jumpForce: 0.4, jumpFrequency: 0.5,
                turnFrequency: 1.2, hue: 0.33, name: "Dasher"
            ),
            GameCharacter(
                id: 3, x: 0.85, y: groundLevel, vx: -0.09,
                baseSpeed: 0.09, jumpForce: 0.55, jumpFrequency: 0.8,
                turnFrequency: 2.0, hue: 0.08, name: "Trickster"
            ),
        ]
    }
}
