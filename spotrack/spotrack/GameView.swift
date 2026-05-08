import SwiftUI

struct GameView: View {
    let engine: GameEngine

    var body: some View {
        ZStack {
            TimelineView(.animation(paused: engine.state != .playing)) { timeline in
                let time = timeline.date.timeIntervalSinceReferenceDate
                Canvas { context, size in
                    drawBackground(in: &context, size: size)
                    drawSpotlights(in: &context, size: size)
                    drawCharacters(in: &context, size: size, time: time)
                    drawNameTags(in: &context, size: size)
                }
            }

            VStack {
                hudBar
                Spacer()
                if engine.litCount > 1 {
                    comboIndicator
                }
                Spacer()
            }
        }
    }

    // MARK: - HUD

    private var hudBar: some View {
        HStack {
            Text("\(engine.score)")
                .font(.system(size: 32, weight: .bold, design: .monospaced))
                .foregroundStyle(.white)
                .shadow(color: .white.opacity(0.5), radius: 10)

            Spacer()

            let seconds = Int(engine.timeRemaining)
            let fraction = Int((engine.timeRemaining - Double(seconds)) * 100)
            Text(String(format: "%d.%02d", seconds, fraction))
                .font(.system(size: 28, weight: .medium, design: .monospaced))
                .foregroundStyle(engine.timeRemaining < 10 ? .red : .white.opacity(0.8))
        }
        .padding(.horizontal, 20)
        .padding(.top, 12)
    }

    private var comboIndicator: some View {
        Text("x\(engine.litCount) COMBO")
            .font(.system(size: 48, weight: .heavy, design: .rounded))
            .foregroundStyle(.yellow)
            .shadow(color: .yellow.opacity(0.8), radius: 20)
    }

    // MARK: - Background

    private func drawBackground(in context: inout GraphicsContext, size: CGSize) {
        context.fill(
            Path(CGRect(origin: .zero, size: size)),
            with: .color(Color(white: 0.015))
        )

        let groundScreenY = (1 - GameEngine.groundLevel) * size.height
        let r = GameEngine.characterRadius * size.width

        let groundRect = CGRect(
            x: 0, y: groundScreenY + r * 0.5,
            width: size.width, height: size.height - groundScreenY
        )
        context.fill(
            Path(groundRect),
            with: .linearGradient(
                Gradient(colors: [Color(white: 0.08), Color(white: 0.03)]),
                startPoint: CGPoint(x: 0, y: groundScreenY),
                endPoint: CGPoint(x: 0, y: size.height)
            )
        )

        var line = Path()
        line.move(to: CGPoint(x: 0, y: groundScreenY + r * 0.5))
        line.addLine(to: CGPoint(x: size.width, y: groundScreenY + r * 0.5))
        context.stroke(line, with: .color(Color(white: 0.12)), lineWidth: 1)
    }

    // MARK: - Spotlights

    private func drawSpotlights(in context: inout GraphicsContext, size: CGSize) {
        var ctx = context
        ctx.blendMode = .plusLighter

        for finger in engine.fingers {
            let center = CGPoint(
                x: finger.x * size.width,
                y: (1 - finger.y) * size.height
            )
            let radius = GameEngine.spotlightRadius * size.width

            let gradient = Gradient(stops: [
                .init(color: Color(white: 1.0, opacity: 0.12), location: 0),
                .init(color: Color(hue: 0.13, saturation: 0.3, brightness: 1.0, opacity: 0.06), location: 0.4),
                .init(color: Color(hue: 0.13, saturation: 0.3, brightness: 1.0, opacity: 0.02), location: 0.8),
                .init(color: .clear, location: 1.0),
            ])

            let rect = CGRect(
                x: center.x - radius * 1.5,
                y: center.y - radius * 1.5,
                width: radius * 3,
                height: radius * 3
            )
            ctx.fill(
                Path(ellipseIn: rect),
                with: .radialGradient(gradient, center: center, startRadius: 0, endRadius: radius * 1.5)
            )

            let innerGradient = Gradient(stops: [
                .init(color: Color(white: 1.0, opacity: 0.2), location: 0),
                .init(color: Color(white: 1.0, opacity: 0.05), location: 0.6),
                .init(color: .clear, location: 1.0),
            ])
            let innerRect = CGRect(
                x: center.x - radius,
                y: center.y - radius,
                width: radius * 2,
                height: radius * 2
            )
            ctx.fill(
                Path(ellipseIn: innerRect),
                with: .radialGradient(innerGradient, center: center, startRadius: 0, endRadius: radius)
            )
        }
    }

    // MARK: - Characters

    private func drawCharacters(in context: inout GraphicsContext, size: CGSize, time: Double) {
        let r = GameEngine.characterRadius * size.width

        for char in engine.characters {
            let footX = char.x * size.width
            let footY = (1 - char.y) * size.height
            let color = char.isLit ? char.color : char.dimColor

            let legH = r * 0.8
            let bodyH = r * 1.2
            let bodyW = r * 0.9
            let headR = r * 0.4

            let hipY = footY - legH
            let bodyTopY = hipY - bodyH
            let headCenterY = bodyTopY - headR

            // Shadow when in air
            if !char.isOnGround {
                let groundY = (1 - GameEngine.groundLevel) * size.height
                let shadowAlpha = max(0, 1 - (char.y - GameEngine.groundLevel) * 3)
                let shadowRect = CGRect(
                    x: footX - r * 0.6, y: groundY + r * 0.1,
                    width: r * 1.2, height: r * 0.3
                )
                context.fill(
                    Path(ellipseIn: shadowRect),
                    with: .color(.black.opacity(0.4 * Double(shadowAlpha)))
                )
            }

            // Glow when lit
            if char.isLit {
                let glowR = r * 2.5
                let glowCenter = CGPoint(x: footX, y: hipY - bodyH / 2)
                context.fill(
                    Path(ellipseIn: CGRect(
                        x: glowCenter.x - glowR, y: glowCenter.y - glowR,
                        width: glowR * 2, height: glowR * 2
                    )),
                    with: .radialGradient(
                        Gradient(colors: [char.color.opacity(0.25), .clear]),
                        center: glowCenter, startRadius: 0, endRadius: glowR
                    )
                )
            }

            // Legs
            let speed = Double(abs(char.vx))
            let walkPhase = (char.isOnGround && speed > 0.01)
                ? sin(time * 12 * speed / 0.1)
                : 0
            let legStep = r * 0.35 * CGFloat(walkPhase)
            let lineW = max(2, r * 0.15)

            var leftLeg = Path()
            leftLeg.move(to: CGPoint(x: footX - r * 0.1, y: hipY))
            leftLeg.addLine(to: CGPoint(x: footX + legStep, y: footY))
            context.stroke(
                leftLeg, with: .color(color),
                style: StrokeStyle(lineWidth: lineW, lineCap: .round)
            )

            var rightLeg = Path()
            rightLeg.move(to: CGPoint(x: footX + r * 0.1, y: hipY))
            rightLeg.addLine(to: CGPoint(x: footX - legStep, y: footY))
            context.stroke(
                rightLeg, with: .color(color),
                style: StrokeStyle(lineWidth: lineW, lineCap: .round)
            )

            // Body
            let bodyRect = CGRect(
                x: footX - bodyW / 2, y: bodyTopY,
                width: bodyW, height: bodyH
            )
            context.fill(
                Path(roundedRect: bodyRect, cornerRadius: r * 0.2),
                with: .color(color)
            )

            // Head
            context.fill(
                Path(ellipseIn: CGRect(
                    x: footX - headR, y: headCenterY - headR,
                    width: headR * 2, height: headR * 2
                )),
                with: .color(color)
            )

            // Eyes when lit
            if char.isLit {
                let eyeR = headR * 0.18
                let eyeY = headCenterY - headR * 0.05
                let eyeSpacing = headR * 0.38
                context.fill(
                    Path(ellipseIn: CGRect(
                        x: footX - eyeSpacing - eyeR, y: eyeY - eyeR,
                        width: eyeR * 2, height: eyeR * 2
                    )),
                    with: .color(.white)
                )
                context.fill(
                    Path(ellipseIn: CGRect(
                        x: footX + eyeSpacing - eyeR, y: eyeY - eyeR,
                        width: eyeR * 2, height: eyeR * 2
                    )),
                    with: .color(.white)
                )
            }
        }
    }

    // MARK: - Name Tags

    private func drawNameTags(in context: inout GraphicsContext, size: CGSize) {
        let r = GameEngine.characterRadius * size.width

        for char in engine.characters where char.isLit {
            let x = char.x * size.width
            let y = (1 - char.y) * size.height
            let tagY = y - r * 3.8

            let text = Text(char.name)
                .font(.system(size: max(9, r * 0.6), weight: .bold))
                .foregroundStyle(char.color)
            let resolved = context.resolve(text)
            context.draw(resolved, at: CGPoint(x: x, y: tagY), anchor: .center)
        }
    }
}
