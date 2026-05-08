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

//            VStack {
//                Spacer()
//                debugReadout
//                    .padding(.bottom, 12)
//            }
        }
    }

    // MARK: - Debug

    private var debugReadout: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text("fingers: \(engine.fingers.count)")
                .foregroundStyle(.white.opacity(0.7))
            ForEach(Array(engine.fingers.enumerated()), id: \.offset) { idx, f in
                Text(String(
                    format: "[%d] p=%6.2f  d=%6.3f  →  n=%.3f  i=%.3f",
                    idx, f.rawPressure, f.rawDensity, Double(f.normalized), Double(f.intensity)
                ))
                .foregroundStyle(.green.opacity(0.9))
            }
        }
        .font(.system(size: 13, weight: .medium, design: .monospaced))
        .padding(10)
        .background(Color.black.opacity(0.55), in: RoundedRectangle(cornerRadius: 8))
        .padding(.horizontal, 16)
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    // MARK: - HUD

    private var hudBar: some View {
        HStack {
            Text("\(engine.score)")
                .font(.system(size: 44, weight: .bold, design: .monospaced))
                .foregroundStyle(.white)
                .shadow(color: .white.opacity(0.5), radius: 12)

            Spacer()

            let seconds = Int(engine.timeRemaining)
            let fraction = Int((engine.timeRemaining - Double(seconds)) * 100)
            Text(String(format: "%d.%02d", seconds, fraction))
                .font(.system(size: 36, weight: .medium, design: .monospaced))
                .foregroundStyle(engine.timeRemaining < 10 ? .red : .white.opacity(0.8))
        }
        .padding(.horizontal, 28)
        .padding(.top, 18)
    }

    private var comboIndicator: some View {
        Text("×\(engine.litCount) コンボ")
            .font(.system(size: 64, weight: .heavy, design: .rounded))
            .foregroundStyle(.yellow)
            .shadow(color: .yellow.opacity(0.8), radius: 24)
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

        // Light source mounted on the ceiling, slightly above the visible frame
        let source = CGPoint(x: size.width / 2, y: -size.height * 0.04)
        let sourceHalfWidth: CGFloat = max(6, size.width * 0.008)

        for finger in engine.fingers {
            let target = CGPoint(
                x: finger.position.x * size.width,
                y: (1 - finger.position.y) * size.height
            )
            let radius = GameEngine.spotlightRadius * size.width
            let targetHalfWidth = radius * 0.9
            let i = Double(finger.intensity)

            let dx = target.x - source.x
            let dy = target.y - source.y
            let len = sqrt(dx * dx + dy * dy)
            guard len > 1 else { continue }
            let nx = -dy / len
            let ny = dx / len

            // Cone-shaped beam from source to target
            var beam = Path()
            beam.move(to: CGPoint(x: source.x + nx * sourceHalfWidth, y: source.y + ny * sourceHalfWidth))
            beam.addLine(to: CGPoint(x: source.x - nx * sourceHalfWidth, y: source.y - ny * sourceHalfWidth))
            beam.addLine(to: CGPoint(x: target.x - nx * targetHalfWidth, y: target.y - ny * targetHalfWidth))
            beam.addLine(to: CGPoint(x: target.x + nx * targetHalfWidth, y: target.y + ny * targetHalfWidth))
            beam.closeSubpath()

            let beamGradient = Gradient(stops: [
                .init(color: Color(white: 1.0, opacity: min(1.0, 0.22 * i)), location: 0),
                .init(color: Color(hue: 0.13, saturation: 0.3, brightness: 1.0, opacity: min(1.0, 0.10 * i)), location: 0.55),
                .init(color: Color(hue: 0.13, saturation: 0.3, brightness: 1.0, opacity: min(1.0, 0.02 * i)), location: 0.85),
                .init(color: .clear, location: 1.0),
            ])

            // Blur the beam so the trapezoid edges feather into the surrounding dark
            var blurred = ctx
            blurred.addFilter(.blur(radius: max(8, size.width * 0.012)))
            blurred.fill(
                beam,
                with: .linearGradient(beamGradient, startPoint: source, endPoint: target)
            )

            // Bright pool of light where the beam lands
            let poolRect = CGRect(
                x: target.x - radius * 1.6,
                y: target.y - radius * 1.6,
                width: radius * 3.2,
                height: radius * 3.2
            )
            let poolGradient = Gradient(stops: [
                .init(color: Color(white: 1.0, opacity: min(1.0, 0.28 * i)), location: 0),
                .init(color: Color(hue: 0.13, saturation: 0.35, brightness: 1.0, opacity: min(1.0, 0.12 * i)), location: 0.45),
                .init(color: Color(hue: 0.13, saturation: 0.4, brightness: 1.0, opacity: min(1.0, 0.03 * i)), location: 0.85),
                .init(color: .clear, location: 1.0),
            ])
            ctx.fill(
                Path(ellipseIn: poolRect),
                with: .radialGradient(poolGradient, center: target, startRadius: 0, endRadius: radius * 1.6)
            )

            // Inner hot spot
            let hotRect = CGRect(
                x: target.x - radius * 0.7,
                y: target.y - radius * 0.7,
                width: radius * 1.4,
                height: radius * 1.4
            )
            ctx.fill(
                Path(ellipseIn: hotRect),
                with: .radialGradient(
                    Gradient(colors: [Color(white: 1.0, opacity: min(1.0, 0.35 * i)), .clear]),
                    center: target, startRadius: 0, endRadius: radius * 0.7
                )
            )
        }

        // Light source fixture glow at the ceiling
        if !engine.fingers.isEmpty {
            let glowR = size.width * 0.07
            let glowRect = CGRect(
                x: source.x - glowR, y: source.y - glowR,
                width: glowR * 2, height: glowR * 2
            )
            ctx.fill(
                Path(ellipseIn: glowRect),
                with: .radialGradient(
                    Gradient(colors: [
                        Color(white: 1.0, opacity: 0.45),
                        Color(hue: 0.13, saturation: 0.3, brightness: 1.0, opacity: 0.15),
                        .clear,
                    ]),
                    center: source, startRadius: 0, endRadius: glowR
                )
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

}
