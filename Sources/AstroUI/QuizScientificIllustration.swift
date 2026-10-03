import AstroGameCore
import SwiftUI

/// Original offline schematics of authored answer proposals.
/// Geometry never reads answer IDs, correctness, score, or semantic substrings.
/// Sizes are illustrative except the explicit coverage fractions and diameter ratios.
struct QuizScientificIllustration: View {
    let picture: QuizPicture
    var compact = false

    var body: some View {
        Canvas { context, size in
            var bounded = context
            bounded.clip(to: Path(CGRect(origin: .zero, size: size)))
            ScientificQuizCanvas(context: bounded, size: size, compact: compact).draw(picture)
        }
        .accessibilityHidden(true)
    }
}

private struct ScientificQuizCanvas {
    let context: GraphicsContext
    let frame: CGRect
    let compact: Bool

    init(context: GraphicsContext, size: CGSize, compact: Bool) {
        self.context = context
        self.compact = compact
        let side = max(1, min(size.width, size.height) - 4)
        frame = CGRect(
            x: (size.width - side) / 2, y: (size.height - side) / 2,
            width: side, height: side)
    }

    func draw(_ picture: QuizPicture) {
        switch picture.scene {
        case .star, .rockyWorld, .moon, .gasWorld, .icyWorld, .dwarfWorld, .rust:
            world(picture.scene, tone: picture.tone)
        case .solarLoops:
            solarLoops()
        case .heartPlain:
            heartPlain()
        case .saltSpots:
            saltSpots()
        case .clouds:
            cloudyWorld(tone: picture.tone)
        case .ice:
            iceBlock()
        case .ocean:
            surfaceOcean(tone: picture.tone)
        case .subsurfaceOcean:
            subsurfaceOcean()
        case .livingEarth, .livingWorlds:
            livingWorlds(many: picture.scene == .livingWorlds)
        case .waterCoverage:
            waterCoverage(picture.fraction)
        case .forest:
            forest(tone: picture.tone)
        case .desert:
            desert()
        case .crater, .hollows:
            crater(shallow: picture.scene == .hollows)
        case .canyon:
            canyon()
        case .volcano:
            volcano()
        case .blocks:
            iceBlocks()
        case .aurora:
            aurora()
        case .rings, .solidRing:
            rings(particulate: picture.scene == .rings, tone: picture.tone)
        case .spacecraft, .wingedSatellite, .sailingSatellite, .solarPanels:
            satellite(picture.scene)
        case .telescope:
            telescope()
        case .gravity:
            gravity()
        case .cube:
            iceCube()
        case .sunlight:
            sun(25, 30, radius: 13)
            arrow(from: (40, 35), to: (74, 70), color: .yellow)
            sphere(77, 70, radius: 16, color: .brown, rocky: true)
        case .reflection:
            reflection()
        case .distance:
            distance()
        case .craterWidth, .canyonLength, .volcanoWidth, .flybyDistance:
            measurement(picture.scene)
        case .planetDiameter, .spacecraftSize, .classroomDistance, .earthWorldDistance,
            .changingOrbitDistance, .movingSun, .movingStars:
            endpointProposal(picture.scene)
        case .duration:
            clock()
        case .spinOrbit, .retrogradeSpinOrbit, .orbit:
            solarOrbit(
                withSpin: picture.scene != .orbit,
                retrograde: picture.scene == .retrogradeSpinOrbit)
        case .innerOrbit:
            innerOrbit()
        case .spin, .retrogradeSpin:
            axialSpin(reverse: picture.scene == .retrogradeSpin)
        case .sidewaysSpin, .uprightSpin, .tiltedSpin:
            let tilt: Double =
                switch picture.scene {
                case .sidewaysSpin: 98
                case .tiltedSpin: 23.5
                default: 0
                }
            axis(tilt: tilt, tone: picture.tone)
        case .moonOrbit:
            lunarOrbit(synchronous: false)
        case .synchronousMoon:
            lunarOrbit(synchronous: true)
        case .galacticOrbit:
            galacticOrbit()
        case .oppositeSpins, .sameSpins:
            pairedSpins(opposite: picture.scene == .oppositeSpins)
        case .oppositeMotion, .sameMotion:
            relativeMoonMotion(opposite: picture.scene == .oppositeMotion)
        case .stillWorld:
            sphere(50, 50, radius: 29, color: tone(picture.tone, fallback: .gray))
        case .thinAtmosphere:
            thinAtmosphere()
        case .storm:
            storm(tone: picture.tone)
        case .magnet:
            magnet()
        case .robot:
            rover()
        case .rocket:
            rocket()
        case .temperature:
            symbol("thermometer.medium", at: box(29, 12, 42, 76))
        case .shadow:
            polarShadow()
        case .signal, .antenna:
            antenna(withSignal: picture.scene == .signal)
        case .computer:
            symbol("desktopcomputer", at: box(12, 16, 76, 67))
        case .laboratory:
            symbol("testtube.2", at: box(23, 10, 54, 76))
        case .paint:
            symbol("paintbrush.fill", at: box(21, 12, 58, 72))
        case .mountain:
            mountain()
        case .rain:
            cloud(50, 34, color: .white)
            for x in [28.0, 42, 56, 70] {
                line([(x, 57), (x - 4, 72)], color: .cyan, width: 3)
            }
        case .sound:
            symbol("speaker.wave.2.fill", at: box(16, 18, 68, 64))
        case .vehicle:
            symbol("car.fill", at: box(12, 25, 76, 50))
        case .city:
            symbol("building.2.fill", at: box(15, 12, 70, 77))
        case .measurement, .singleImage:
            observations(multiple: picture.scene == .measurement)
        case .tools:
            symbol("wrench.and.screwdriver.fill", at: box(18, 15, 64, 70))
        case .hexagon, .triangle, .line:
            geometricShape(picture.scene)
        case .nameTag:
            symbol("tag.fill", at: box(19, 17, 62, 66))
        case .clothing:
            symbol("shoe.fill", at: box(12, 29, 76, 45))
        case .rockLayers:
            rockLayers()
        case .lamp:
            symbol("flashlight.on.fill", at: box(25, 10, 50, 80))
        case .seasonalIce, .steadyIce, .escapingIce:
            iceCaps(picture.scene)
        case .sizeComparison:
            sizeComparison(picture.label)
        case .plume:
            plume()
        case .rope:
            tetheredParticles()
        case .spacesuit, .wingedSuit, .crewSuit:
            spacesuit(picture.scene)
        case .emptyTank:
            emptyTank()
        case .ironCave:
            ironCave()
        }
    }

    private func point(_ x: Double, _ y: Double) -> CGPoint {
        CGPoint(
            x: frame.minX + CGFloat(x) * frame.width / 100,
            y: frame.minY + CGFloat(y) * frame.height / 100)
    }

    private func box(_ x: Double, _ y: Double, _ width: Double, _ height: Double) -> CGRect {
        CGRect(
            origin: point(x, y),
            size: CGSize(
                width: CGFloat(width) * frame.width / 100,
                height: CGFloat(height) * frame.height / 100))
    }

    private func fill(_ path: Path, color: Color) {
        context.fill(path, with: .color(color))
    }

    private func stroke(_ path: Path, color: Color, width: Double = 1.8, dashed: Bool = false) {
        context.stroke(
            path, with: .color(color),
            style: StrokeStyle(
                lineWidth: max(0.8, CGFloat(width) * frame.width / 100),
                lineCap: .round, lineJoin: .round,
                dash: dashed ? [3, 3] : []))
    }

    private func circle(_ x: Double, _ y: Double, radius: Double, color: Color) {
        fill(Path(ellipseIn: box(x - radius, y - radius, radius * 2, radius * 2)), color: color)
    }

    private func polygon(_ coordinates: [(Double, Double)], color: Color) {
        guard let first = coordinates.first else { return }
        var path = Path()
        path.move(to: point(first.0, first.1))
        for pair in coordinates.dropFirst() { path.addLine(to: point(pair.0, pair.1)) }
        path.closeSubpath()
        fill(path, color: color)
    }

    private func line(_ coordinates: [(Double, Double)], color: Color, width: Double = 1.8) {
        guard let first = coordinates.first else { return }
        var path = Path()
        path.move(to: point(first.0, first.1))
        for pair in coordinates.dropFirst() { path.addLine(to: point(pair.0, pair.1)) }
        stroke(path, color: color, width: width)
    }

    private func arrow(from: (Double, Double), to: (Double, Double), color: Color = .cyan) {
        line([from, to], color: color, width: 2.2)
        let angle = atan2(to.1 - from.1, to.0 - from.0)
        let wing = 5.0
        let back = (to.0 - cos(angle) * wing, to.1 - sin(angle) * wing)
        line(
            [
                (back.0 - sin(angle) * wing / 2, back.1 + cos(angle) * wing / 2),
                to,
                (back.0 + sin(angle) * wing / 2, back.1 - cos(angle) * wing / 2),
            ],
            color: color, width: 2.2)
    }

    private func arcArrow(
        _ x: Double, _ y: Double, radius: Double, start: Double, end: Double, color: Color = .cyan
    ) {
        let points = (0...24).map { index -> (Double, Double) in
            let angle = (start + (end - start) * Double(index) / 24) * .pi / 180
            return (x + cos(angle) * radius, y + sin(angle) * radius)
        }
        line(points, color: color, width: 2.1)
        arrow(from: points[22], to: points[24], color: color)
    }

    private func label(_ value: String, _ x: Double, _ y: Double, size: Double = 7) {
        context.draw(
            Text(value)
                .font(
                    .system(
                        size: max(compact ? 6 : 10, CGFloat(size) * frame.width / 100),
                        weight: .semibold, design: .rounded)
                )
                .foregroundColor(.white),
            at: point(x, y))
    }

    private func symbol(_ name: String, at rectangle: CGRect, color: Color = .cyan) {
        var image = context.resolve(Image(systemName: name))
        image.shading = .color(color)
        context.draw(image, in: rectangle)
    }

    private func tone(_ value: QuizPicture.Tone?, fallback: Color) -> Color {
        switch value {
        case .cream: Color(red: 0.96, green: 0.88, blue: 0.65)
        case .gold: Color(red: 0.92, green: 0.69, blue: 0.3)
        case .blueGreen: Color(red: 0.35, green: 0.78, blue: 0.79)
        case .blueWhite: Color(red: 0.27, green: 0.55, blue: 0.88)
        case .gray: Color(red: 0.39, green: 0.42, blue: 0.48)
        case .rust: Color(red: 0.74, green: 0.36, blue: 0.23)
        case .green: Color(red: 0.28, green: 0.73, blue: 0.41)
        case nil: fallback
        }
    }

    // Scientific compositions below use the same neutral styling for every proposal.

    private func ellipse(
        _ x: Double, _ y: Double, _ width: Double, _ height: Double,
        color: Color = .white.opacity(0.6), dashed: Bool = false
    ) {
        stroke(Path(ellipseIn: box(x, y, width, height)), color: color, dashed: dashed)
    }

    private func curve(
        from: (Double, Double), to: (Double, Double),
        control1: (Double, Double), control2: (Double, Double),
        color: Color, width: Double = 2
    ) {
        var path = Path()
        path.move(to: point(from.0, from.1))
        path.addCurve(
            to: point(to.0, to.1),
            control1: point(control1.0, control1.1), control2: point(control2.0, control2.1))
        stroke(path, color: color, width: width)
    }

    private func sphere(
        _ x: Double, _ y: Double, radius: Double, color: Color,
        rocky: Bool = false, bands: Bool = false
    ) {
        let disk = Path(ellipseIn: box(x - radius, y - radius, radius * 2, radius * 2))
        fill(disk, color: color)
        var clipped = context
        clipped.clip(to: disk)
        if bands {
            for offset in [-0.5, -0.05, 0.42] {
                clipped.fill(
                    Path(
                        ellipseIn: box(
                            x - radius * 1.15, y + radius * offset,
                            radius * 2.3, radius * 0.2)),
                    with: .color(.white.opacity(0.22)))
            }
        }
        if rocky {
            for (dx, dy, scale) in [
                (-0.35, -0.28, 0.18), (0.34, 0.18, 0.23), (-0.2, 0.53, 0.12),
            ] {
                let r = radius * scale
                let rim = Path(
                    ellipseIn: box(
                        x + radius * dx - r, y + radius * dy - r, 2 * r, 2 * r))
                clipped.fill(rim, with: .color(.black.opacity(0.18)))
                clipped.stroke(rim, with: .color(.white.opacity(0.22)), lineWidth: 0.9)
            }
        }
        // A broad terminator gives depth without inventing craters on atmospheric worlds.
        clipped.fill(
            Path(ellipseIn: box(x + radius * 0.2, y - radius, radius * 1.6, radius * 2)),
            with: .color(.black.opacity(0.13)))
        stroke(disk, color: .white.opacity(0.5), width: 1)
    }

    private func sun(_ x: Double, _ y: Double, radius: Double) {
        for index in 0..<12 {
            let angle = Double(index) * .pi / 6
            line(
                [
                    (x + cos(angle) * (radius + 2), y + sin(angle) * (radius + 2)),
                    (x + cos(angle) * (radius + 6), y + sin(angle) * (radius + 6)),
                ], color: .yellow.opacity(0.8), width: 1.7)
        }
        circle(x, y, radius: radius, color: .orange)
        circle(x - radius * 0.12, y - radius * 0.12, radius: radius * 0.82, color: .yellow)
    }

    private func cloud(_ x: Double, _ y: Double, color: Color) {
        circle(x - 15, y, radius: 9, color: color)
        circle(x - 5, y - 7, radius: 13, color: color)
        circle(x + 10, y - 3, radius: 12, color: color)
        fill(
            Path(roundedRect: box(x - 23, y - 2, 47, 15), cornerRadius: frame.width / 25),
            color: color)
    }

    private func world(_ scene: QuizPicture.Scene, tone value: QuizPicture.Tone?) {
        switch scene {
        case .star:
            sun(50, 50, radius: 29)
        case .moon:
            ellipse(14, 28, 73, 42)
            sphere(37, 50, radius: 22, color: .blue.opacity(0.8), bands: true)
            sphere(
                78, 48, radius: 11, color: tone(value, fallback: .gray),
                rocky: value != .blueWhite)
            if value == .blueWhite {
                line(
                    [(72, 41), (78, 47), (76, 52), (82, 56)], color: .white.opacity(0.8), width: 1)
            }
            label("Planet", 36, 84)
            label("Moon", 78, 76)
        case .gasWorld:
            sphere(50, 50, radius: 31, color: tone(value, fallback: .orange), bands: true)
        case .icyWorld:
            sphere(50, 50, radius: 31, color: tone(value, fallback: .cyan), bands: true)
            label("Atmosphere", 50, 90)
        case .dwarfWorld:
            sun(18, 27, radius: 7)
            ellipse(8, 28, 84, 48, dashed: true)
            sphere(69, 54, radius: 19, color: tone(value, fallback: .brown), rocky: true)
            if value == .rust {
                polygon(
                    [(57, 48), (64, 40), (72, 41), (78, 49), (72, 57), (65, 60)],
                    color: .white.opacity(0.8))
            }
            for (x, y) in [(34.0, 70.0), (46, 73), (84, 36)] {
                circle(x, y, radius: 2, color: .gray)
            }
            label("Orbit neighbourhood", 50, 90, size: 6)
        case .rust:
            sphere(44, 48, radius: 27, color: tone(value, fallback: .orange), rocky: true)
            polygon([(69, 65), (83, 61), (91, 75), (79, 83), (67, 77)], color: .brown)
            label("Iron", 79, 72, size: 6)
        default:
            sphere(50, 50, radius: 31, color: tone(value, fallback: .brown), rocky: true)
            if value == .gray {
                fill(Path(ellipseIn: box(31, 29, 27, 20)), color: .black.opacity(0.25))
                fill(Path(ellipseIn: box(43, 56, 23, 13)), color: .black.opacity(0.2))
            }
        }
    }

    private func solarLoops() {
        sun(50, 63, radius: 26)
        for (left, right, top) in [(27.0, 44.0, 8.0), (46, 70, 1), (63, 80, 20)] {
            curve(
                from: (left, 44), to: (right, 45),
                control1: (left - 5, top), control2: (right + 5, top),
                color: .orange, width: 3)
            curve(
                from: (left + 3, 45), to: (right - 3, 45),
                control1: (left, top + 10), control2: (right, top + 10),
                color: .yellow, width: 1.2)
        }
    }

    private func heartPlain() {
        sphere(50, 50, radius: 33, color: Color(red: 0.65, green: 0.46, blue: 0.34))
        var heart = Path()
        heart.move(to: point(50, 69))
        heart.addCurve(to: point(29, 45), control1: point(23, 58), control2: point(23, 39))
        heart.addCurve(to: point(50, 42), control1: point(34, 34), control2: point(47, 34))
        heart.addCurve(to: point(73, 43), control1: point(54, 34), control2: point(68, 33))
        heart.addCurve(to: point(50, 69), control1: point(85, 52), control2: point(63, 65))
        heart.closeSubpath()
        fill(heart, color: .white.opacity(0.87))
        label("Icy plain", 50, 91)
    }

    private func saltSpots() {
        sphere(50, 48, radius: 31, color: .gray, rocky: true)
        ellipse(33, 37, 37, 24, color: .black.opacity(0.45))
        for (x, y, r) in [(46.0, 49.0, 4.0), (52, 46, 2.4), (59, 50, 2), (56, 53, 1.4)] {
            circle(x, y, radius: r, color: .white)
        }
        label("Salt deposits", 50, 90)
    }

    private func cloudyWorld(tone value: QuizPicture.Tone?) {
        let color = tone(value, fallback: .white)
        sphere(50, 50, radius: 28, color: color.opacity(0.75))
        cloud(43, 41, color: color)
        cloud(57, 57, color: color.opacity(0.8))
    }

    private func iceBlock() {
        polygon([(23, 29), (72, 22), (84, 65), (34, 78)], color: .cyan.opacity(0.6))
        polygon([(23, 29), (34, 78), (20, 67), (12, 37)], color: .blue.opacity(0.7))
        polygon([(23, 29), (72, 22), (61, 14), (12, 37)], color: .white.opacity(0.9))
        line([(36, 34), (43, 44), (39, 51), (55, 68)], color: .white, width: 1.4)
        line([(43, 44), (63, 38)], color: .white.opacity(0.75), width: 1)
    }

    private func surfaceOcean(tone value: QuizPicture.Tone?) {
        if value == .blueWhite {
            sphere(50, 50, radius: 31, color: .blue)
            cloud(40, 42, color: .white.opacity(0.85))
            cloud(58, 60, color: .white.opacity(0.85))
            return
        }
        fill(Path(box(12, 48, 76, 33)), color: .blue.opacity(0.8))
        for y in [40.0, 52, 64, 76] {
            curve(
                from: (12, y), to: (88, y), control1: (36, y - 10), control2: (64, y + 10),
                color: .cyan)
        }
        label("Surface water", 50, 91)
    }

    private func subsurfaceOcean() {
        polygon(
            [(11, 29), (30, 24), (52, 30), (72, 25), (90, 29), (90, 43), (11, 43)], color: .white)
        fill(Path(box(11, 43, 79, 29)), color: .blue)
        for y in [52.0, 64] {
            curve(
                from: (12, y), to: (89, y), control1: (32, y - 6), control2: (66, y + 6),
                color: .cyan)
        }
        polygon(
            [(11, 72), (34, 66), (53, 72), (78, 66), (90, 72), (90, 84), (11, 84)], color: .brown)
        label("Ice", 51, 35)
        label("Water", 51, 57)
    }

    private func earth(_ x: Double, _ y: Double, radius: Double) {
        sphere(x, y, radius: radius, color: .blue)
        polygon(
            [
                (x - radius * 0.6, y - radius * 0.5), (x - radius * 0.2, y - radius * 0.7),
                (x + radius * 0.1, y - radius * 0.25), (x - radius * 0.2, y + radius * 0.25),
                (x - radius * 0.45, y + radius * 0.05),
            ], color: .green.opacity(0.8))
        polygon(
            [
                (x + radius * 0.15, y + radius * 0.1), (x + radius * 0.65, y + radius * 0.05),
                (x + radius * 0.35, y + radius * 0.6),
            ], color: .green.opacity(0.8))
    }

    private func sprout(_ x: Double, _ y: Double, scale: Double = 1) {
        line([(x, y), (x, y - 14 * scale)], color: .green, width: 2)
        polygon(
            [(x, y - 7 * scale), (x - 10 * scale, y - 14 * scale), (x - 7 * scale, y - 3 * scale)],
            color: .green)
        polygon(
            [
                (x, y - 11 * scale), (x + 10 * scale, y - 19 * scale),
                (x + 7 * scale, y - 5 * scale),
            ], color: .green)
    }

    private func livingWorlds(many: Bool) {
        if many {
            sphere(22, 52, radius: 14, color: .brown)
            earth(50, 52, radius: 14)
            sphere(78, 52, radius: 14, color: .orange, bands: true)
            for x in [22.0, 50, 78] { sprout(x, 36, scale: 0.7) }
            label("Life on every world", 50, 86, size: 6)
        } else {
            earth(50, 53, radius: 28)
            sprout(50, 26)
            label("Earth life", 50, 92)
        }
    }

    private func waterCoverage(_ fraction: Double?) {
        guard let fraction, fraction.isFinite, (0...1).contains(fraction) else {
            ellipse(20, 15, 60, 60)
            return
        }
        circle(50, 45, radius: 30, color: .brown)
        if fraction == 1 {
            circle(50, 45, radius: 30, color: .blue)
        } else if fraction > 0 {
            var sector = Path()
            sector.move(to: point(50, 45))
            for index in 0...72 {
                let angle = (-90 + fraction * 360 * Double(index) / 72) * .pi / 180
                sector.addLine(to: point(50 + cos(angle) * 30, 45 + sin(angle) * 30))
            }
            sector.closeSubpath()
            fill(sector, color: .blue)
        }
        label("\(Int((fraction * 100).rounded()))% water", 50, 87)
    }

    private func forest(tone value: QuizPicture.Tone?) {
        let leaves = tone(value, fallback: .green)
        for (x, y, scale) in [(25.0, 72.0, 0.8), (51, 80, 1.1), (77, 72, 0.8)] {
            line([(x, y), (x, y - 37 * scale)], color: .brown, width: 5)
            polygon(
                [
                    (x - 17 * scale, y - 16 * scale), (x, y - 62 * scale),
                    (x + 17 * scale, y - 16 * scale),
                ], color: leaves)
        }
    }

    private func desert() {
        sun(76, 23, radius: 9)
        polygon([(8, 66), (31, 43), (64, 74), (92, 48), (92, 86), (8, 86)], color: .orange)
        curve(
            from: (8, 77), to: (92, 73), control1: (26, 59), control2: (61, 92),
            color: .yellow.opacity(0.8), width: 3)
    }

    private func crater(shallow: Bool) {
        fill(Path(box(9, 48, 82, 36)), color: .brown)
        if shallow {
            for x in [25.0, 50, 75] {
                curve(
                    from: (x - 10, 46), to: (x + 10, 46), control1: (x - 7, 60),
                    control2: (x + 7, 60), color: .white, width: 3)
            }
            label("Shallow hollows", 50, 91)
        } else {
            polygon(
                [
                    (8, 49), (22, 41), (32, 51), (42, 69), (61, 69), (72, 49), (82, 41), (92, 49),
                    (92, 87), (8, 87),
                ], color: .brown)
            line(
                [(8, 49), (22, 41), (32, 51), (42, 69), (61, 69), (72, 49), (82, 41), (92, 49)],
                color: .white.opacity(0.8), width: 2)
        }
    }

    private func canyon() {
        polygon(
            [(9, 25), (39, 25), (43, 69), (55, 72), (61, 25), (91, 25), (91, 84), (9, 84)],
            color: .brown)
        polygon([(39, 25), (48, 33), (49, 66), (43, 69)], color: .orange.opacity(0.7))
        line([(39, 25), (43, 69), (55, 72), (61, 25)], color: .white.opacity(0.8))
    }

    private func volcano() {
        polygon([(8, 78), (34, 51), (43, 47), (55, 47), (66, 52), (92, 78)], color: .brown)
        ellipse(41, 44, 18, 8, color: .orange)
        line([(54, 52), (60, 61), (63, 62), (70, 73)], color: .orange, width: 3)
        line([(8, 79), (92, 79)], color: .white.opacity(0.6))
    }

    private func iceBlocks() {
        for (x, y, width, height) in [(10.0, 29.0, 35.0, 27.0), (57, 18, 28, 34), (39, 65, 40, 20)]
        {
            fill(Path(box(x, y, width, height)), color: .cyan.opacity(0.6))
            line([(x, y), (x + width, y), (x + width, y + height)], color: .white)
            line([(x + 4, y + 5), (x + width / 2, y + height / 2)], color: .white.opacity(0.7))
        }
    }

    private func aurora() {
        sphere(50, 117, radius: 60, color: .blue)
        for x in [19.0, 32, 45, 58, 71, 84] {
            curve(
                from: (x, 30), to: (x - 6, 61), control1: (x - 12, 41), control2: (x + 9, 43),
                color: .green.opacity(0.8), width: 5)
        }
        curve(
            from: (13, 35), to: (86, 35), control1: (36, 17), control2: (63, 51), color: .cyan,
            width: 2)
    }

    private func rings(particulate: Bool, tone value: QuizPicture.Tone?) {
        if particulate {
            for index in 0..<72 {
                let angle = Double(index) * .pi / 36
                let x = 50 + cos(angle) * 40
                let y = 50 + sin(angle) * 15
                if sin(angle) <= 0 {
                    circle(
                        x, y, radius: index.isMultiple(of: 3) ? 1.5 : 1, color: .white.opacity(0.85)
                    )
                }
            }
        } else {
            ellipse(10, 35, 80, 30, color: .white)
        }
        sphere(50, 48, radius: 24, color: tone(value, fallback: .orange), bands: true)
        if particulate {
            for index in 0...36 {
                let angle = Double(index) * .pi / 36
                circle(
                    50 + cos(angle) * 40, 50 + sin(angle) * 15,
                    radius: index.isMultiple(of: 3) ? 1.5 : 1, color: .white.opacity(0.85))
            }
            label("Separate particles", 50, 87, size: 6)
        } else {
            curve(
                from: (10, 50), to: (90, 50), control1: (10, 71), control2: (90, 71), color: .white,
                width: 3)
            label("Connected hoop", 50, 87, size: 6)
        }
    }

    private func solarOrbit(withSpin: Bool, retrograde: Bool) {
        ellipse(9, 24, 82, 49, color: .white.opacity(0.65))
        sun(41, 48, radius: 12)
        sphere(80, 50, radius: 10, color: .blue, bands: true)
        arrow(from: (61, 29), to: (42, 24))
        label("Orbit", 32, 84)
        if withSpin {
            arcArrow(
                80, 50, radius: 16, start: retrograde ? -140 : 140, end: retrograde ? 120 : -120,
                color: .orange)
            label("Spin", 79, 84)
        }
    }

    private func innerOrbit() {
        sun(30, 49, radius: 10)
        ellipse(12, 32, 36, 34)
        ellipse(5, 23, 58, 53, color: .white.opacity(0.45))
        ellipse(2, 15, 86, 68, color: .white.opacity(0.35))
        sphere(46, 48, radius: 5, color: .gray, rocky: true)
        earth(81, 54, radius: 8)
        label("Inner orbit", 39, 93, size: 6)
        label("Earth", 82, 84, size: 6)
    }

    private func axialSpin(reverse: Bool) {
        sphere(50, 51, radius: 26, color: .blue, bands: true)
        line([(50, 14), (50, 87)], color: .white.opacity(0.8), width: 1.5)
        arcArrow(50, 50, radius: 35, start: reverse ? -145 : 145, end: reverse ? 110 : -110)
        label("Spin", 50, 95)
    }

    private func axis(tilt: Double, tone value: QuizPicture.Tone?) {
        let angle = tilt * .pi / 180
        let dx = sin(angle) * 36
        let dy = -cos(angle) * 36
        var reference = Path()
        reference.move(to: point(50, 10))
        reference.addLine(to: point(50, 88))
        stroke(reference, color: .white.opacity(0.4), width: 1, dashed: true)
        var plane = Path()
        plane.move(to: point(9, 52))
        plane.addLine(to: point(91, 52))
        stroke(plane, color: .white.opacity(0.4), width: 1, dashed: true)
        sphere(50, 50, radius: 25, color: tone(value, fallback: .blue), bands: true)
        line([(50 - dx, 50 - dy), (50 + dx, 50 + dy)], color: .white, width: 2.3)
        circle(50 + dx, 50 + dy, radius: 2, color: .white)
        if tilt != 0 {
            let points = (0...20).map { index -> (Double, Double) in
                let a = (-90 + tilt * Double(index) / 20) * .pi / 180
                return (50 + cos(a) * 31, 50 + sin(a) * 31)
            }
            line(points, color: .orange, width: 1.5)
        }
        label(tilt == 23.5 ? "23.5°" : "\(Int(tilt))°", 50, 93)
    }

    private func lunarOrbit(synchronous: Bool) {
        ellipse(10, 22, 80, 57)
        earth(50, 50, radius: 17)
        let locations: [(Double, Double)] =
            synchronous
            ? [(13, 50), (50, 22), (87, 50)] : [(85, 50)]
        for (x, y) in locations {
            sphere(x, y, radius: 8, color: .gray)
            if synchronous {
                let angle = atan2(50 - y, 50 - x)
                circle(x + cos(angle) * 4.5, y + sin(angle) * 4.5, radius: 2.3, color: .white)
            } else {
                arcArrow(x, y, radius: 12, start: 130, end: -130, color: .orange)
            }
        }
        arrow(from: (71, 74), to: (51, 79))
        label("Earth", 50, 51, size: 6)
        label(synchronous ? "Same face toward Earth" : "Moon around Earth", 50, 94, size: 6)
    }

    private func galacticOrbit() {
        for phase in [0.0, .pi] {
            let points = (0...60).map { index -> (Double, Double) in
                let a = Double(index) * .pi / 20 + phase
                let radius = 3 + Double(index) * 0.36
                return (44 + cos(a) * radius, 48 + sin(a) * radius * 0.55)
            }
            line(points, color: .white.opacity(0.8), width: 3)
        }
        circle(44, 48, radius: 6, color: .white)
        ellipse(8, 20, 84, 58, dashed: true)
        sun(82, 45, radius: 7)
        arcArrow(82, 45, radius: 13, start: 100, end: -150, color: .orange)
        arrow(from: (64, 75), to: (45, 78))
        label("Galaxy", 39, 88, size: 6)
        label("Sun", 82, 69, size: 6)
    }

    private func pairedSpins(opposite: Bool) {
        for (x, reverse) in [(26.0, false), (74.0, opposite)] {
            sphere(x, 46, radius: 17, color: .blue, bands: true)
            line([(x, 21), (x, 71)], color: .white.opacity(0.6))
            arcArrow(x, 46, radius: 23, start: reverse ? -140 : 140, end: reverse ? 90 : -90)
        }
        label("Axial spins", 50, 89)
    }

    private func relativeMoonMotion(opposite: Bool) {
        ellipse(8, 15, 84, 65)
        sphere(49, 49, radius: 21, color: .blue, bands: true)
        arcArrow(49, 49, radius: 27, start: 120, end: -110, color: .orange)
        sphere(87, 46, radius: 7, color: .gray)
        if opposite {
            arrow(from: (45, 15), to: (65, 20))
        } else {
            arrow(from: (65, 20), to: (45, 15))
        }
        label("Planet spin", 35, 91, size: 6)
        label("Moon orbit", 77, 81, size: 6)
    }

    private func satellite(_ scene: QuizPicture.Scene) {
        if scene == .wingedSatellite {
            polygon(
                [(40, 43), (14, 23), (7, 29), (18, 39), (9, 42), (25, 53), (40, 57)], color: .white)
            polygon(
                [(60, 43), (86, 23), (93, 29), (82, 39), (91, 42), (75, 53), (60, 57)],
                color: .white)
            line([(17, 32), (40, 52)], color: .gray, width: 1)
            line([(83, 32), (60, 52)], color: .gray, width: 1)
        } else if scene == .sailingSatellite {
            line([(52, 14), (52, 48)], color: .white, width: 2)
            polygon([(55, 15), (79, 40), (55, 40)], color: .white)
            polygon([(48, 20), (27, 41), (48, 41)], color: .white.opacity(0.7))
            line([(52, 65), (52, 86)], color: .white)
            circle(52, 83, radius: 3, color: .gray)
            curve(
                from: (40, 81), to: (64, 81), control1: (42, 98), control2: (63, 98), color: .gray,
                width: 3)
            line([(40, 81), (39, 88)], color: .gray)
            line([(64, 81), (65, 88)], color: .gray)
        } else {
            for x in [7.0, 66] {
                fill(Path(box(x, 36, 27, 25)), color: .blue)
                for offset in [9.0, 18] {
                    line([(x + offset, 36), (x + offset, 61)], color: .cyan.opacity(0.8), width: 1)
                }
                line([(x, 48), (x + 27, 48)], color: .cyan.opacity(0.8), width: 1)
            }
            line([(34, 48), (66, 48)], color: .white, width: 2)
        }
        fill(Path(roundedRect: box(38, 39, 24, 27), cornerRadius: frame.width / 40), color: .gray)
        polygon([(38, 39), (45, 32), (67, 32), (62, 39)], color: .white.opacity(0.8))
        line([(51, 32), (51, 23), (64, 18)], color: .white)
        curve(
            from: (58, 15), to: (71, 22), control1: (63, 26), control2: (67, 26), color: .white,
            width: 2)
        if scene == .solarPanels {
            label("Power panels", 26, 81, size: 6)
            label("Antenna", 72, 8, size: 6)
        }
    }

    private func telescope() {
        polygon([(20, 28), (66, 10), (77, 34), (30, 52)], color: .gray)
        line([(23, 31), (66, 15)], color: .white, width: 2)
        ellipse(62, 11, 14, 23, color: .cyan)
        line([(26, 45), (15, 49)], color: .white, width: 4)
        circle(49, 44, radius: 5, color: .white)
        line([(49, 49), (49, 67)], color: .gray, width: 5)
        for endpoint in [(25.0, 88.0), (73, 88), (49, 93)] {
            line([(49, 65), endpoint], color: .white, width: 2.5)
        }
    }

    private func rover() {
        line([(6, 83), (94, 83)], color: .brown, width: 4)
        fill(Path(box(22, 48, 56, 21)), color: .gray)
        polygon([(22, 48), (33, 41), (85, 41), (78, 48)], color: .white.opacity(0.8))
        line([(46, 44), (46, 20)], color: .white, width: 3)
        fill(Path(box(39, 14, 20, 10)), color: .gray)
        circle(44, 19, radius: 3, color: .cyan)
        circle(54, 19, radius: 3, color: .cyan)
        line([(74, 48), (86, 31), (93, 33)], color: .white, width: 2)
        for x in [27.0, 50, 74] {
            circle(x, 73, radius: 8, color: .gray)
            ellipse(x - 8, 65, 16, 16, color: .white)
            line([(x - 4, 73), (x + 4, 73)], color: .white, width: 1)
        }
    }

    private func rocket() {
        polygon([(39, 28), (50, 10), (61, 28)], color: .orange)
        fill(Path(box(39, 28, 22, 43)), color: .white)
        circle(50, 42, radius: 6, color: .blue)
        polygon([(39, 52), (28, 72), (39, 67)], color: .gray)
        polygon([(61, 52), (72, 72), (61, 67)], color: .gray)
        polygon([(42, 71), (58, 71), (56, 77), (44, 77)], color: .gray)
        polygon([(44, 78), (50, 95), (56, 78)], color: .orange)
        polygon([(47, 78), (50, 89), (53, 78)], color: .yellow)
        arrow(from: (80, 66), to: (80, 27))
    }

    private func antenna(withSignal: Bool) {
        curve(
            from: (24, 31), to: (74, 51), control1: (21, 78), control2: (63, 89), color: .white,
            width: 4)
        line([(24, 31), (74, 51)], color: .gray, width: 2)
        line([(45, 49), (59, 27)], color: .white, width: 2.5)
        circle(59, 27, radius: 3, color: .orange)
        line([(45, 65), (45, 83)], color: .white, width: 4)
        line([(26, 86), (65, 86)], color: .white, width: 3)
        if withSignal {
            for r in [10.0, 18, 26] {
                let points = (0...16).map { index -> (Double, Double) in
                    let a = (-80 + 80 * Double(index) / 16) * .pi / 180
                    return (59 + cos(a) * r, 27 + sin(a) * r)
                }
                line(points, color: .cyan, width: 1.6)
            }
        }
    }

    private func spacesuit(_ scene: QuizPicture.Scene) {
        if scene == .wingedSuit {
            polygon(
                [(35, 43), (9, 24), (5, 35), (12, 43), (6, 48), (27, 65), (35, 62)], color: .white)
            polygon(
                [(65, 43), (91, 24), (95, 35), (88, 43), (94, 48), (73, 65), (65, 62)],
                color: .white)
        }
        circle(50, 22, radius: 13, color: .white)
        ellipse(39, 12, 22, 20, color: .gray)
        fill(Path(roundedRect: box(41, 15, 18, 13), cornerRadius: frame.width / 25), color: .blue)
        fill(Path(roundedRect: box(32, 36, 36, 35), cornerRadius: frame.width / 20), color: .white)
        line([(35, 42), (24, 63)], color: .white, width: 10)
        line([(65, 42), (76, 63)], color: .white, width: 10)
        line([(42, 68), (40, 86)], color: .white, width: 11)
        line([(58, 68), (61, 86)], color: .white, width: 11)
        fill(Path(box(30, 84, 17, 8)), color: .gray)
        fill(Path(box(54, 84, 17, 8)), color: .gray)
        if scene == .crewSuit {
            fill(Path(box(36, 40, 28, 25)), color: .blue.opacity(0.7))
            line([(36, 52), (64, 52)], color: .white, width: 1)
            line([(50, 40), (50, 65)], color: .white, width: 1)
            for (x, y) in [(38.0, 46.0), (52, 46), (38, 59), (52, 59)] {
                line([(x, y), (x + 8, y)], color: .white, width: 2)
                circle(x + 1, y - 2, radius: 1.3, color: .white)
            }
        } else {
            fill(Path(box(40, 43, 20, 18)), color: .gray)
            circle(44, 47, radius: 1.5, color: .cyan)
            line([(40, 57), (27, 52), (27, 36)], color: .gray, width: 2)
        }
    }

    private func emptyTank() {
        fill(Path(box(25, 27, 50, 50)), color: .gray.opacity(0.5))
        ellipse(25, 19, 50, 17, color: .white)
        curve(
            from: (25, 77), to: (75, 77), control1: (25, 90), control2: (75, 90), color: .white,
            width: 2)
        line([(25, 27), (25, 77)], color: .white, width: 2)
        line([(75, 27), (75, 77)], color: .white, width: 2)
        fill(Path(box(35, 39, 30, 26)), color: .black.opacity(0.45))
        label("Empty", 50, 52, size: 6)
        line([(50, 20), (50, 10), (64, 10)], color: .gray, width: 4)
    }

    private func ironCave() {
        polygon(
            [(7, 82), (10, 43), (24, 17), (48, 10), (76, 25), (91, 51), (94, 82)], color: .gray)
        polygon(
            [(24, 82), (27, 52), (37, 36), (54, 32), (69, 44), (77, 65), (78, 82)],
            color: .black.opacity(0.65))
        for (a, b) in [((18.0, 35.0), (25.0, 25.0)), ((66, 31), (78, 43)), ((13, 65), (18, 73))] {
            line([a, b], color: .white.opacity(0.7), width: 3)
        }
        label("Iron", 50, 90)
    }

    private func gravity() {
        sphere(50, 50, radius: 20, color: .blue)
        for (from, to) in [
            ((50.0, 9.0), (50.0, 28.0)), ((50, 91), (50, 72)),
            ((9, 50), (28, 50)), ((91, 50), (72, 50)),
            ((19, 19), (34, 34)), ((81, 81), (66, 66)),
        ] {
            arrow(from: from, to: to)
        }
    }

    private func iceCube() {
        polygon([(25, 30), (63, 21), (80, 40), (42, 50)], color: .white)
        polygon([(25, 30), (42, 50), (42, 82), (25, 61)], color: .blue)
        polygon([(42, 50), (80, 40), (80, 72), (42, 82)], color: .cyan)
        line(
            [(25, 30), (63, 21), (80, 40), (80, 72), (42, 82), (25, 61), (25, 30)],
            color: .white.opacity(0.8))
    }

    private func reflection() {
        sphere(25, 37, radius: 15, color: .orange, bands: true)
        sphere(76, 66, radius: 18, color: .gray, rocky: true)
        arrow(from: (40, 38), to: (66, 57), color: .orange)
        arrow(from: (39, 48), to: (57, 68), color: .orange)
    }

    private func distance() {
        sun(16, 38, radius: 8)
        sphere(84, 38, radius: 12, color: .blue)
        bracket(20, 80, y: 66)
        label("Sun", 16, 83, size: 6)
        label("World", 83, 83, size: 6)
    }

    private func bracket(_ left: Double, _ right: Double, y: Double) {
        line([(left, y - 4), (left, y + 4)], color: .white)
        line([(right, y - 4), (right, y + 4)], color: .white)
        line([(left, y), (right, y)], color: .white)
        for x in stride(from: left + 10, to: right, by: 10) {
            line([(x, y), (x, y + 2)], color: .white.opacity(0.7), width: 1)
        }
    }

    private func measurement(_ scene: QuizPicture.Scene) {
        switch scene {
        case .craterWidth:
            ellipse(16, 25, 68, 42, color: .brown)
            ellipse(24, 31, 52, 29, color: .gray)
            bracket(16, 84, y: 77)
            label("Crater diameter", 50, 93, size: 6)
        case .canyonLength:
            fill(Path(box(8, 24, 84, 38)), color: .brown.opacity(0.6))
            line(
                [(13, 48), (26, 35), (41, 43), (55, 34), (73, 48), (88, 37)],
                color: .black.opacity(0.8), width: 8)
            line(
                [(13, 45), (26, 32), (41, 40), (55, 31), (73, 45), (88, 34)],
                color: .orange.opacity(0.8), width: 1.5)
            bracket(12, 88, y: 77)
            label("Canyon length", 50, 93, size: 6)
        case .volcanoWidth:
            volcano()
            bracket(8, 92, y: 87)
            label("Base width", 50, 95, size: 6)
        case .flybyDistance:
            fill(Path(box(10, 28, 16, 17)), color: .gray)
            for angle in [-90.0, 30, 150] {
                let a = angle * .pi / 180
                line([(18, 36), (18 + cos(a) * 17, 36 + sin(a) * 17)], color: .blue, width: 4)
            }
            sphere(78, 40, radius: 17, color: .cyan)
            line([(70, 30), (78, 36), (75, 44), (83, 50)], color: .white, width: 1)
            bracket(29, 60, y: 69)
            label("Juno", 18, 87, size: 6)
            label("Europa", 79, 87, size: 6)
        default:
            break
        }
    }

    private func clock() {
        circle(50, 48, radius: 30, color: .blue.opacity(0.3))
        ellipse(20, 18, 60, 60)
        for index in 0..<12 {
            let a = Double(index) * .pi / 6
            line(
                [
                    (50 + sin(a) * 25, 48 - cos(a) * 25),
                    (50 + sin(a) * 28, 48 - cos(a) * 28),
                ],
                color: .white, width: 1.3)
        }
        line([(50, 29), (50, 48), (65, 58)], color: .white, width: 2.5)
        circle(50, 48, radius: 2, color: .cyan)
        label("Elapsed time", 50, 91)
    }

    private func endpointProposal(_ scene: QuizPicture.Scene) {
        switch scene {
        case .planetDiameter:
            sphere(50, 45, radius: 28, color: .blue)
            bracket(22, 78, y: 45)
            label("Planet diameter", 50, 89, size: 6)
        case .spacecraftSize:
            satellite(.spacecraft)
            bracket(7, 93, y: 85)
            label("Spacecraft size", 50, 95, size: 6)
        case .classroomDistance:
            fill(Path(box(8, 32, 24, 29)), color: .gray)
            polygon([(5, 32), (20, 20), (35, 32)], color: .orange)
            fill(Path(box(17, 48, 7, 13)), color: .white.opacity(0.7))
            for (x, height) in [(69.0, 28.0), (81, 42), (91, 22)] {
                fill(Path(box(x - 5, 61 - height, 8, height)), color: .gray)
            }
            bracket(34, 63, y: 74)
            label("Classroom", 22, 89, size: 6)
            label("City", 81, 89, size: 6)
        case .earthWorldDistance:
            earth(22, 40, radius: 15)
            sphere(79, 40, radius: 16, color: tone(.blueWhite, fallback: .blue), bands: true)
            bracket(38, 61, y: 70)
            label("Earth", 22, 87, size: 6)
            label("Neptune", 79, 87, size: 6)
        case .changingOrbitDistance:
            sun(22, 42, radius: 10)
            ellipse(39, 34, 16, 16, color: .white.opacity(0.4), dashed: true)
            sphere(81, 42, radius: 11, color: .gray)
            arrow(from: (56, 42), to: (68, 42))
            bracket(23, 80, y: 73)
            label("Orbit distance changes", 50, 92, size: 6)
        case .movingSun:
            ellipse(8, 28, 22, 22, color: .yellow.opacity(0.4), dashed: true)
            sun(55, 39, radius: 10)
            sphere(84, 39, radius: 11, color: .orange)
            arrow(from: (29, 39), to: (38, 39), color: .yellow)
            label("Sun moves toward Venus", 50, 87, size: 6)
        case .movingStars:
            earth(50, 54, radius: 14)
            for (x, y, endX, endY) in [
                (15.0, 25.0, 35.0, 43.0), (86, 23, 64, 43), (83, 85, 64, 65),
            ] {
                sun(x, y, radius: 5)
                arrow(from: (x + (endX - x) * 0.32, y + (endY - y) * 0.32), to: (endX, endY))
            }
        default:
            break
        }
    }

    private func thinAtmosphere() {
        sphere(50, 56, radius: 25, color: .brown, rocky: true)
        for index in 0..<11 {
            let a = Double(index) * .pi * 2 / 11
            circle(50 + cos(a) * 34, 56 + sin(a) * 34, radius: 1.2, color: .cyan)
        }
        arrow(from: (43, 29), to: (30, 12), color: .orange)
        arrow(from: (59, 29), to: (71, 12), color: .orange)
    }

    private func storm(tone value: QuizPicture.Tone?) {
        sphere(50, 50, radius: 31, color: tone(value, fallback: .orange), bands: true)
        let points = (0...70).map { index -> (Double, Double) in
            let a = Double(index) * .pi / 14
            let r = 2 + Double(index) * 0.3
            return (50 + cos(a) * r, 51 + sin(a) * r * 0.65)
        }
        line(points, color: .white, width: 3)
    }

    private func magnet() {
        curve(
            from: (28, 31), to: (72, 31), control1: (14, 92), control2: (86, 92), color: .gray,
            width: 15)
        line([(28, 25), (28, 39)], color: .orange, width: 15)
        line([(72, 25), (72, 39)], color: .blue, width: 15)
        label("N", 28, 30, size: 6)
        label("S", 72, 30, size: 6)
        for top in [2.0, 12, 22] {
            curve(
                from: (32, 22), to: (68, 22), control1: (40, top), control2: (60, top),
                color: .cyan, width: 1)
        }
    }

    private func polarShadow() {
        sun(12, 19, radius: 7)
        polygon(
            [(8, 55), (28, 43), (42, 71), (65, 71), (78, 43), (93, 55), (93, 88), (8, 88)],
            color: .brown)
        polygon([(30, 45), (42, 71), (65, 71), (76, 45)], color: .black.opacity(0.8))
        polygon([(44, 69), (50, 65), (58, 68), (65, 67), (65, 73), (43, 73)], color: .cyan)
        arrow(from: (19, 24), to: (27, 42), color: .yellow)
        arrow(from: (23, 22), to: (78, 43), color: .yellow.opacity(0.75))
        label("Shaded crater ice", 50, 95, size: 6)
    }

    private func mountain() {
        polygon([(7, 83), (45, 17), (72, 66), (80, 47), (94, 83)], color: .gray)
        polygon([(45, 17), (34, 38), (43, 35), (48, 44), (56, 37)], color: .white)
        line([(45, 22), (48, 50), (61, 83)], color: .white.opacity(0.45))
    }

    private func observations(multiple: Bool) {
        let panels: [(Double, Double)] = multiple ? [(6, 0), (53, 9)] : [(27, 0)]
        for (x, shift) in panels {
            fill(Path(box(x, 22, 40, 48)), color: .blue.opacity(0.3))
            stroke(Path(box(x, 22, 40, 48)), color: .white)
            circle(x + 15 + shift, 40, radius: 6, color: .white)
            circle(x + 22 + shift, 43, radius: 7, color: .white)
            line([(x + 8, 59), (x + 32, 59)], color: .cyan.opacity(0.7))
            label(shift == 0 ? "1" : "2", x + 20, 80)
        }
        if multiple { arrow(from: (43, 11), to: (59, 11)) }
    }

    private func geometricShape(_ scene: QuizPicture.Scene) {
        switch scene {
        case .hexagon:
            let points = (0..<6).map { index -> (Double, Double) in
                let a = Double(index) * .pi / 3
                return (50 + cos(a) * 32, 50 + sin(a) * 32)
            }
            polygon(points, color: .cyan.opacity(0.45))
            line(points + [points[0]], color: .cyan, width: 3)
        case .triangle:
            polygon([(50, 18), (15, 80), (85, 80)], color: .cyan.opacity(0.45))
            line([(50, 18), (15, 80), (85, 80), (50, 18)], color: .cyan, width: 3)
        default:
            line([(13, 50), (87, 50)], color: .cyan, width: 4)
        }
    }

    private func rockLayers() {
        for (y, color) in [(29.0, Color.orange), (45, .brown), (61, .gray)] {
            polygon(
                [
                    (11, y), (31, y - 3), (56, y + 2), (89, y - 4), (89, y + 16), (56, y + 22),
                    (31, y + 17), (11, y + 16),
                ], color: color)
        }
    }

    private func cappedWorld(_ x: Double, _ y: Double, capWidth: Double) {
        sphere(x, y, radius: 18, color: .orange)
        let width = min(31, max(0, capWidth))
        if width > 0 {
            // The white patch is a polar cap, separate from the atmospheric limb.
            var clipped = context
            clipped.clip(to: Path(ellipseIn: box(x - 18, y - 18, 36, 36)))
            clipped.fill(
                Path(ellipseIn: box(x - width / 2, y - 18, width, width * 0.3)),
                with: .color(.white))
        }
    }

    private func iceCaps(_ scene: QuizPicture.Scene) {
        cappedWorld(25, 45, capWidth: scene == .steadyIce ? 17 : 29)
        cappedWorld(75, 45, capWidth: scene == .escapingIce ? 0 : (scene == .steadyIce ? 17 : 10))
        arrow(from: (43, 45), to: (55, 45))
        if scene == .escapingIce {
            polygon([(79, 17), (90, 13), (94, 19), (83, 22)], color: .white)
            arrow(from: (79, 29), to: (85, 22))
            label("Moving away", 50, 85, size: 6)
        } else {
            label(scene == .steadyIce ? "Same cap" : "Winter → spring", 50, 85, size: 6)
        }
    }

    private func sizeComparison(_ authoredLabel: String) {
        // Exact, authored ratio labels; no fuzzy parsing or answer-ID inference.
        let ratios = ["1/2 × Earth": 0.5, "1 × Earth": 1.0, "2 × Earth": 2.0]
        guard let ratio = ratios[authoredLabel] else { return }
        let earthDiameter = 26.0
        let worldDiameter = earthDiameter * ratio
        earth(22, 43, radius: earthDiameter / 2)
        sphere(68, 43, radius: worldDiameter / 2, color: .orange)
        bracket(9, 35, y: 80)
        bracket(68 - worldDiameter / 2, 68 + worldDiameter / 2, y: 80)
        label("Earth", 22, 93, size: 6)
        label("World", 68, 93, size: 6)
    }

    private func plume() {
        polygon(
            [(8, 73), (30, 70), (45, 75), (58, 70), (92, 73), (92, 88), (8, 88)],
            color: .white.opacity(0.8))
        for offset in [-16.0, -7, 0, 9, 18] {
            curve(
                from: (50, 74), to: (50 + offset * 1.5, 21 + abs(offset) * 0.45),
                control1: (50 + offset / 3, 51), control2: (50 + offset, 32),
                color: .cyan.opacity(0.8), width: 2.3)
            circle(50 + offset * 1.5, 15 + abs(offset) * 0.5, radius: 1.8, color: .white)
        }
        for (x, y) in [(31.0, 34.0), (67, 40), (45, 19), (61, 12)] {
            circle(x, y, radius: 1.3, color: .white)
        }
    }

    private func tetheredParticles() {
        let locations = [(19.0, 35.0), (46, 21), (75, 38), (68, 73), (27, 70)]
        line(locations + [locations[0]], color: .orange, width: 2.8)
        for (x, y) in locations {
            circle(x, y, radius: 8, color: .gray)
            ellipse(x - 4, y - 4, 8, 8, color: .white.opacity(0.7))
        }
    }
}
