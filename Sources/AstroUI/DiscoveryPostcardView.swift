import AstroGameCore
import SwiftUI

/// A static drawing of the saved creation, independent of live scene and GPU lifecycles.
struct DiscoveryPostcardView: View {
    let adventure: ExplorationAdventure
    let cursor: ExplorationCursor

    private let ink = Color(red: 0.035, green: 0.065, blue: 0.12)
    private let rust = Color(red: 0.72, green: 0.32, blue: 0.17)
    private let sand = Color(red: 0.95, green: 0.76, blue: 0.49)
    private let cyan = Color(red: 0.24, green: 0.88, blue: 0.98)
    private let gold = Color(red: 1, green: 0.77, blue: 0.24)

    var body: some View {
        Canvas { context, size in
            context.fill(Path(CGRect(origin: .zero, size: size)), with: .color(ink))
            for index in 0..<32 {
                let point = CGPoint(
                    x: size.width * CGFloat((index * 37 + 7) % 100) / 100,
                    y: size.height * CGFloat((index * 19 + 3) % 77) / 100)
                let radius: CGFloat = index % 5 == 0 ? 1.4 : 0.7
                context.fill(
                    Path(
                        ellipseIn: CGRect(
                            x: point.x, y: point.y, width: radius * 2, height: radius * 2)),
                    with: .color(.white.opacity(0.32)))
            }
            switch adventure.destinationID {
            case "mercury": mercury(context, size: size)
            case "mars": mars(context, size: size)
            default: saturn(context, size: size)
            }
        }
        .allowsHitTesting(false)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(savedModelDescription)
    }

    private var savedModelDescription: String {
        switch adventure.destinationID {
        case "mercury":
            let small = cursor.modelSettings["impact.small.count", default: 0]
            let large = cursor.modelSettings["impact.large.count", default: 0]
            let rays =
                cursor.observations.contains("mercury.ejecta.traced")
                ? "Traced ejecta surrounds the craters." : "Ejecta has not been traced."
            let site =
                cursor.placements["mercury.sensor"]
                    == "mercury-shadow-sensor-site" ? "polar shadow" : "sunlit site"
            return
                "Saved Mercury model: \(small) small and \(large) large impacts. \(rays) The sensor is at the \(site)."
        case "mars":
            let photo =
                cursor.observations.contains("mars.rock.photographed")
                ? "Exposed rock layers are photographed." : "The rock photo is waiting."
            let water =
                cursor.modelSettings["mars.water", default: 0] % 2 == 1
                ? "The ancient-water model is flowing." : "The ancient-water model is paused."
            let comparison =
                cursor.modelSettings["mars.compare", default: 0] % 2 == 1
                ? "Deposited layers are shown for comparison." : "The deposit comparison is off."
            return "Saved Mars model: \(photo) \(water) \(comparison)"
        default:
            let edge =
                cursor.modelSettings["saturn.view", default: 0] % 2 == 1
                ? "edge view" : "face view"
            let motion =
                cursor.modelSettings["saturn.motion", default: 0] % 2 == 1
                ? "Orbit motion was on." : "Orbit motion was paused."
            return
                "Saved Saturn model: separate icy pieces in inner and outer orbits, seen from the \(edge). \(motion)"
        }
    }

    private func mercury(_ context: GraphicsContext, size: CGSize) {
        context.fill(
            Path(CGRect(x: 0, y: size.height * 0.23, width: size.width, height: size.height)),
            with: .linearGradient(
                Gradient(colors: [rust.opacity(0.8), Color(red: 0.24, green: 0.15, blue: 0.15)]),
                startPoint: point(0, 0.23, size), endPoint: point(0, 1, size)))
        label(
            "Your Mercury crater model", at: point(0.05, 0.12, size), context: context, size: size)
        let small = min(max(cursor.modelSettings["impact.small.count", default: 0], 0), 12)
        let large = min(max(cursor.modelSettings["impact.large.count", default: 0], 0), 12)
        let traced = cursor.observations.contains("mercury.ejecta.traced")
        for index in 0..<small {
            let center = point(
                0.10 + Double(index % 4) * 0.063, 0.43 + Double(index / 4) * 0.115, size)
            crater(
                at: center, radius: min(size.width * 0.027, size.height * 0.085),
                traced: traced, context: context)
        }
        for index in 0..<large {
            let center = point(
                0.40 + Double(index % 4) * 0.075, 0.43 + Double(index / 4) * 0.115, size)
            crater(
                at: center, radius: min(size.width * 0.034, size.height * 0.105),
                traced: traced, context: context)
        }
        label(
            "Small impacts · \(small)", at: point(0.07, 0.86, size),
            context: context, size: size, color: sand)
        label(
            "Large impacts · \(large)", at: point(0.37, 0.86, size),
            context: context, size: size, color: sand)

        let warm = point(0.76, 0.48, size)
        let cold = point(0.89, 0.66, size)
        let siteRadius = min(size.width * 0.039, size.height * 0.13)
        context.fill(
            Path(ellipseIn: circle(warm, radius: siteRadius)),
            with: .color(gold.opacity(0.25)))
        context.stroke(
            Path(ellipseIn: circle(warm, radius: siteRadius)),
            with: .color(gold), lineWidth: 2)
        context.fill(Path(ellipseIn: circle(cold, radius: siteRadius * 1.15)), with: .color(ink))
        context.stroke(
            Path(ellipseIn: circle(cold, radius: siteRadius * 1.15)),
            with: .color(cyan.opacity(0.65)), lineWidth: 2)
        if cursor.observations.contains("mercury.sensor.sunlit") {
            label(
                "Warm", at: point(0.76, 0.30, size), context: context, size: size,
                color: gold, anchor: .center)
        }
        if cursor.observations.contains("mercury.sensor.shadow") {
            label(
                "Cold", at: point(0.89, 0.86, size), context: context, size: size,
                color: cyan, anchor: .center)
        }
        let sensorPoint: CGPoint
        switch cursor.placements["mercury.sensor"] {
        case "mercury-sunlit-sensor-site": sensorPoint = warm
        case "mercury-shadow-sensor-site": sensorPoint = cold
        default: sensorPoint = point(0.76, 0.71, size)
        }
        sensor(at: sensorPoint, scale: siteRadius * 0.7, context: context)
        if cursor.carriedItemID == "mercury.sensor" {
            label(
                "Sensor in hand", at: point(0.70, 0.95, size),
                context: context, size: size, color: cyan)
        }
    }

    private func crater(
        at center: CGPoint, radius: CGFloat, traced: Bool, context: GraphicsContext
    ) {
        if traced {
            var rays = Path()
            for index in 0..<9 {
                let angle = Double(index) * .pi * 2 / 9
                rays.move(
                    to: CGPoint(
                        x: center.x + cos(angle) * radius * 1.2,
                        y: center.y + sin(angle) * radius * 0.75))
                rays.addLine(
                    to: CGPoint(
                        x: center.x + cos(angle) * radius * 1.9,
                        y: center.y + sin(angle) * radius * 1.25))
            }
            context.stroke(rays, with: .color(sand.opacity(0.62)), lineWidth: 1.3)
        }
        let rim = CGRect(
            x: center.x - radius, y: center.y - radius * 0.65,
            width: radius * 2, height: radius * 1.3)
        context.fill(Path(ellipseIn: rim), with: .color(sand))
        context.fill(
            Path(ellipseIn: rim.insetBy(dx: radius * 0.2, dy: radius * 0.16)),
            with: .color(Color(red: 0.28, green: 0.15, blue: 0.15)))
        var lowerRim = Path()
        lowerRim.move(to: CGPoint(x: center.x - radius * 0.7, y: center.y + radius * 0.24))
        lowerRim.addQuadCurve(
            to: CGPoint(x: center.x + radius * 0.7, y: center.y + radius * 0.24),
            control: CGPoint(x: center.x, y: center.y + radius * 0.68))
        context.stroke(lowerRim, with: .color(gold.opacity(0.5)), lineWidth: 1.5)
    }

    private func sensor(at center: CGPoint, scale: CGFloat, context: GraphicsContext) {
        let body = CGRect(
            x: center.x - scale * 0.6, y: center.y - scale * 0.45,
            width: scale * 1.2, height: scale * 0.9)
        context.fill(Path(roundedRect: body, cornerRadius: 3), with: .color(cyan))
        context.fill(
            Path(
                CGRect(
                    x: body.minX + scale * 0.2, y: body.minY + scale * 0.15,
                    width: scale * 0.8, height: scale * 0.25)), with: .color(ink))
        var stand = Path()
        stand.move(to: CGPoint(x: center.x, y: body.minY))
        stand.addLine(to: CGPoint(x: center.x, y: body.minY - scale * 0.6))
        stand.move(to: CGPoint(x: body.minX, y: body.maxY))
        stand.addLine(to: CGPoint(x: body.minX - scale * 0.2, y: body.maxY + scale * 0.25))
        stand.move(to: CGPoint(x: body.maxX, y: body.maxY))
        stand.addLine(to: CGPoint(x: body.maxX + scale * 0.2, y: body.maxY + scale * 0.25))
        context.stroke(stand, with: .color(.white), lineWidth: 2)
        context.fill(
            Path(
                ellipseIn: circle(
                    CGPoint(x: center.x, y: body.minY - scale * 0.6), radius: 2)),
            with: .color(gold))
    }

    private func mars(_ context: GraphicsContext, size: CGSize) {
        context.fill(
            Path(CGRect(x: 0, y: size.height * 0.29, width: size.width, height: size.height)),
            with: .linearGradient(
                Gradient(colors: [rust, Color(red: 0.32, green: 0.14, blue: 0.15)]),
                startPoint: point(0, 0.29, size), endPoint: point(0, 1, size)))
        label(
            "Your Mars rover and river model", at: point(0.05, 0.12, size),
            context: context, size: size)

        let rock = CGRect(
            x: size.width * 0.58, y: size.height * 0.31,
            width: size.width * 0.33, height: size.height * 0.43)
        var layers = context
        let silhouette = polygon([
            CGPoint(x: rock.minX, y: rock.maxY),
            CGPoint(x: rock.minX + rock.width * 0.15, y: rock.minY + rock.height * 0.12),
            CGPoint(x: rock.maxX - rock.width * 0.12, y: rock.minY),
            CGPoint(x: rock.maxX, y: rock.maxY),
        ])
        layers.clip(to: silhouette)
        for index in 0..<8 {
            let y = rock.minY + CGFloat(index) * rock.height / 8
            layers.fill(
                polygon([
                    CGPoint(x: rock.minX, y: y + rock.height * 0.045),
                    CGPoint(x: rock.maxX, y: y),
                    CGPoint(x: rock.maxX, y: y + rock.height / 8),
                    CGPoint(x: rock.minX, y: y + rock.height / 8 + rock.height * 0.045),
                ]), with: .color(index % 3 == 0 ? sand : index % 2 == 0 ? rust : gold.opacity(0.65))
            )
        }
        if !cursor.observations.contains("mars.rock.brushed") {
            context.fill(silhouette, with: .color(rust.opacity(0.85)))
        }
        if cursor.observations.contains("mars.rock.photographed") {
            context.stroke(
                Path(roundedRect: rock.insetBy(dx: -8, dy: -8), cornerRadius: 5),
                with: .color(.white.opacity(0.8)), lineWidth: 2)
            label(
                "Rock photo", at: point(0.75, 0.84, size), context: context, size: size,
                color: sand, anchor: .center)
        }

        let water = cursor.modelSettings["mars.water", default: 0] % 2 == 1
        let deposits = cursor.modelSettings["mars.compare", default: 0] % 2 == 1
        if water {
            var river = Path()
            river.move(to: point(0.09, 0.34, size))
            river.addCurve(
                to: point(0.41, 0.69, size),
                control1: point(0.36, 0.31, size), control2: point(0.16, 0.59, size))
            context.stroke(
                river, with: .color(cyan.opacity(0.3)),
                style: StrokeStyle(lineWidth: size.height * 0.06, lineCap: .round))
            context.stroke(
                river, with: .color(cyan),
                style: StrokeStyle(lineWidth: size.height * 0.022, lineCap: .round))
        }
        if deposits {
            context.fill(
                polygon([
                    point(0.40, 0.64, size), point(0.49, 0.75, size), point(0.30, 0.75, size),
                ]), with: .color(sand))
            for index in 0..<4 {
                var layer = Path()
                layer.move(
                    to: point(0.32 + Double(index) * 0.018, 0.73 - Double(index) * 0.022, size))
                layer.addLine(
                    to: point(0.47 - Double(index) * 0.022, 0.73 - Double(index) * 0.022, size))
                context.stroke(layer, with: .color(rust), lineWidth: 1.5)
            }
        }

        // The rover route records the child's two landmark visits.
        if cursor.observations.contains("mars.landmark.crater")
            && cursor.observations.contains("mars.landmark.rock")
        {
            var route = Path()
            route.move(to: point(0.13, 0.78, size))
            route.addQuadCurve(to: point(0.57, 0.74, size), control: point(0.32, 0.94, size))
            context.stroke(
                route, with: .color(gold.opacity(0.7)),
                style: StrokeStyle(lineWidth: 2, dash: [4, 5]))
        }
        let rover = point(0.17, 0.72, size)
        let unit = min(size.width * 0.033, size.height * 0.085)
        context.fill(
            Path(
                roundedRect: CGRect(
                    x: rover.x - unit, y: rover.y - unit * 0.45,
                    width: unit * 2, height: unit * 0.9), cornerRadius: 3), with: .color(sand))
        for offset in [-0.7, 0.7] {
            context.fill(
                Path(
                    ellipseIn: circle(
                        CGPoint(
                            x: rover.x + unit * offset,
                            y: rover.y + unit * 0.45), radius: unit * 0.28)), with: .color(ink))
        }
        sensor(
            at: CGPoint(x: rover.x, y: rover.y - unit * 0.55), scale: unit * 0.55, context: context)
        label(
            water ? "Ancient-water model · flowing" : "Ancient-water model · paused",
            at: point(0.05, 0.91, size), context: context, size: size, color: cyan)
    }

    private func saturn(_ context: GraphicsContext, size: CGSize) {
        label("Your Saturn ring model", at: point(0.05, 0.12, size), context: context, size: size)
        let edge = cursor.modelSettings["saturn.view", default: 0] % 2 == 1
        let moving = cursor.modelSettings["saturn.motion", default: 0] % 2 == 1
        let center = point(0.5, 0.50, size)
        let radius = min(size.width * 0.12, size.height * 0.23)
        let flattening: CGFloat = edge ? 0.035 : 0.21
        for front in [false, true] {
            if front {
                let disk = circle(center, radius: radius)
                context.fill(
                    Path(ellipseIn: disk),
                    with: .linearGradient(
                        Gradient(colors: [sand, gold, rust]),
                        startPoint: CGPoint(x: disk.minX, y: disk.minY),
                        endPoint: CGPoint(x: disk.maxX, y: disk.maxY)))
                var stripes = context
                stripes.clip(to: Path(ellipseIn: disk))
                for index in 0..<7 {
                    stripes.fill(
                        Path(
                            CGRect(
                                x: disk.minX, y: disk.minY + CGFloat(index) * radius * 0.3,
                                width: disk.width, height: radius * 0.09)),
                        with: .color(rust.opacity(0.22)))
                }
            }
            for (observation, width, count, color) in [
                ("saturn.ring.inner", 0.25, 28, cyan),
                ("saturn.ring.outer", 0.37, 40, sand),
            ] where cursor.observations.contains(observation) {
                let rx = size.width * width
                let ry = size.height * flattening * (width / 0.25)
                if moving {
                    var trail = Path()
                    for step in 0...40 {
                        let angle = Double(step) * .pi / 40 + (front ? 0 : .pi)
                        let location = CGPoint(
                            x: center.x + cos(angle) * rx,
                            y: center.y + sin(angle) * ry)
                        if step == 0 {
                            trail.move(to: location)
                        } else {
                            trail.addLine(to: location)
                        }
                    }
                    context.stroke(trail, with: .color(color.opacity(0.28)), lineWidth: 1)
                }
                for index in 0..<count {
                    let angle = Double(index) * .pi * 2 / Double(count)
                    guard (sin(angle) >= 0) == front else { continue }
                    let location = CGPoint(
                        x: center.x + cos(angle) * rx,
                        y: center.y + sin(angle) * ry)
                    let dot = min(max(size.height * 0.01, 1.8), 3.5)
                    context.fill(
                        polygon([
                            CGPoint(x: location.x, y: location.y - dot),
                            CGPoint(x: location.x + dot, y: location.y),
                            CGPoint(x: location.x, y: location.y + dot),
                            CGPoint(x: location.x - dot, y: location.y),
                        ]), with: .color(color))
                }
            }
        }
        label(
            "Separate icy pieces · inner + outer orbits", at: point(0.05, 0.83, size),
            context: context, size: size, color: cyan)
        label(
            "\(edge ? "Edge" : "Face") view · \(moving ? "orbits moving" : "orbits paused")",
            at: point(0.05, 0.93, size), context: context, size: size, color: sand)
    }

    private func label(
        _ text: String, at point: CGPoint, context: GraphicsContext, size: CGSize,
        color: Color = .white, anchor: UnitPoint = .leading
    ) {
        let fontSize = min(max(size.height * 0.064, 11), 18)
        context.draw(
            Text(text).font(.system(size: fontSize, weight: .semibold)).foregroundStyle(color),
            at: point, anchor: anchor)
    }

    private func point(_ x: Double, _ y: Double, _ size: CGSize) -> CGPoint {
        CGPoint(x: size.width * x, y: size.height * y)
    }

    private func circle(_ center: CGPoint, radius: CGFloat) -> CGRect {
        CGRect(x: center.x - radius, y: center.y - radius, width: radius * 2, height: radius * 2)
    }

    private func polygon(_ points: [CGPoint]) -> Path {
        Path { path in
            guard let first = points.first else { return }
            path.move(to: first)
            points.dropFirst().forEach { path.addLine(to: $0) }
            path.closeSubpath()
        }
    }
}
