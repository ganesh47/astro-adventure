import AstroGameCore
import SwiftUI

#if canImport(RealityKit)
    import RealityKit
    import simd

    #if canImport(UIKit)
        import UIKit
        private typealias DioramaColor = UIColor
    #elseif canImport(AppKit)
        import AppKit
        private typealias DioramaColor = NSColor
    #endif

    /// Fixed-camera, procedural toys. The core cursor is the only source of discoveries.
    /// Every interaction is also available through the playground's accessible buttons.
    public struct ExplorationWorldView: View {
        private let adventure: ExplorationAdventure
        private let cursor: ExplorationCursor
        private let isPaused: Bool
        @Environment(\.accessibilityReduceMotion) private var reduceMotion

        public init(adventure: ExplorationAdventure, cursor: ExplorationCursor, isPaused: Bool) {
            self.adventure = adventure
            self.cursor = cursor
            self.isPaused = isPaused
        }

        public var body: some View {
            GeometryReader { geometry in
                let viewportAspect = Float(geometry.size.width / max(geometry.size.height, 1))
                RealityView { content in
                    DioramaBuilder.registerSystems()
                    let root = Entity()
                    root.name = "ExplorationDiorama"
                    let texture =
                        adventure.destinationID == "mars"
                        ? try? await TextureResource(named: "mars-regolith.png", in: .module) : nil
                    DioramaBuilder.build(adventure.destinationID, texture: texture, into: root)
                    content.add(root)
                    synchronize(root, viewportAspect: viewportAspect)
                } update: { content in
                    if let root = content.entities.first {
                        synchronize(root, viewportAspect: viewportAspect)
                    }
                }
                .id(adventure.id)
                .accessibilityHidden(true)
                .allowsHitTesting(false)
                .background(
                    LinearGradient(
                        colors: adventure.destinationID == "mars"
                            ? [
                                Color(red: 0.11, green: 0.09, blue: 0.17),
                                Color(red: 0.48, green: 0.27, blue: 0.20),
                                Color(red: 0.77, green: 0.43, blue: 0.24),
                            ]
                            : [.black, Color(red: 0.06, green: 0.04, blue: 0.07)], startPoint: .top,
                        endPoint: .bottom))
            }
        }

        private func synchronize(_ root: Entity, viewportAspect: Float) {
            // Preserve the landscape's horizontal view on a portrait tablet rather than
            // cropping the rover, companion, and outcrop at the viewport's side edges.
            if let camera = root.findEntity(named: "ExplorationCamera"),
                var projection = camera.components[PerspectiveCameraComponent.self]
            {
                let landscapeAspect: Float = 16 / 9
                let baseHalfAngle: Float = 22 * .pi / 180
                projection.fieldOfViewInDegrees =
                    viewportAspect < 1
                    ? min(
                        100,
                        2 * atan(tan(baseHalfAngle) * landscapeAspect / max(viewportAspect, 0.4))
                            * 180 / .pi)
                    : 44
                camera.components.set(projection)
            }
            // Logical effects update immediately. Moving the explorer is cosmetic and bounded.
            if isPaused { root.stopAllAnimations(recursive: true) }
            let observations = cursor.observations
            let selected = adventure.targets.first { $0.id == cursor.selectedTargetID }
            let anchor = adventure.targets.first { $0.id == cursor.avatarAnchorID }
            if let explorer = root.findEntity(named: "rover"), let anchor {
                let position = DioramaBuilder.groundPoint(anchor.position)
                let target = SIMD3<Float>(position.x - 0.45, -0.13, min(position.z + 0.55, 1.7))
                if simd_distance(explorer.position, target) > 0.015 {
                    var transform = explorer.transform
                    transform.translation = target
                    if reduceMotion || isPaused {
                        explorer.transform = transform
                    } else {
                        explorer.move(to: transform, relativeTo: root, duration: 0.45)
                    }
                }
            }
            if let marker = root.findEntity(named: "selectionHalo"), let selected {
                var point = DioramaBuilder.groundPoint(selected.position)
                point.y = 0.025
                marker.position = point
                marker.isEnabled = cursor.phase != .arriving
            }
            if let smile = root.findEntity(named: "happyEyes") {
                smile.isEnabled = !observations.isEmpty
            }
            if let eyes = root.findEntity(named: "curiousEyes") {
                eyes.isEnabled = observations.isEmpty
            }
            root.findEntity(named: "scanner")?.isEnabled = observations.contains(
                "mars.rock.brushed")
            root.findEntity(named: "rockDust")?.isEnabled = !observations.contains(
                "mars.rock.brushed")
            root.findEntity(named: "photoFrame")?.isEnabled = observations.contains(
                "mars.rock.photographed")
            root.findEntity(named: "waterFlow")?.isEnabled =
                cursor.modelSettings["mars.water", default: 0] % 2 == 1
            root.findEntity(named: "depositComparison")?.isEnabled =
                cursor.modelSettings["mars.compare", default: 0] % 2 == 1

            let smallCount = min(cursor.modelSettings["impact.small.count", default: 0], 12)
            let largeCount = min(cursor.modelSettings["impact.large.count", default: 0], 12)
            for index in 0..<12 {
                root.findEntity(named: "smallImpact.\(index)")?.isEnabled = index < smallCount
                root.findEntity(named: "largeImpact.\(index)")?.isEnabled = index < largeCount
            }
            root.findEntity(named: "ejecta")?.isEnabled = observations.contains(
                "mercury.ejecta.traced")
            root.findEntity(named: "warmReading")?.isEnabled = observations.contains(
                "mercury.sensor.sunlit")
            root.findEntity(named: "coldReading")?.isEnabled = observations.contains(
                "mercury.sensor.shadow")
            if let sensor = root.findEntity(named: "sensor") {
                if let site = cursor.placements["mercury.sensor"],
                    let target = adventure.targets.first(where: { $0.id == site })
                {
                    var point = DioramaBuilder.groundPoint(target.position)
                    point.y = 0.08
                    sensor.position = point
                } else if cursor.carriedItemID == "mercury.sensor" {
                    sensor.position = [-0.7, 0.3, 1.25]
                } else {
                    sensor.position = DioramaBuilder.groundPoint(ExplorationPoint(0.23, 0.70))
                }
            }

            root.findEntity(named: "innerIce")?.isEnabled = observations.contains(
                "saturn.ring.inner")
            root.findEntity(named: "outerIce")?.isEnabled = observations.contains(
                "saturn.ring.outer")
            let moving = cursor.modelSettings["saturn.motion", default: 0] % 2 == 1
            root.findEntity(named: "orbitTrails")?.isEnabled = moving
            if let system = root.findEntity(named: "SaturnSystem") {
                let edge = cursor.modelSettings["saturn.view", default: 0] % 2 == 1
                system.orientation = simd_quatf(angle: edge ? -0.360 : 0.68, axis: [1, 0, 0])
            }
            if let inner = root.findEntity(named: "innerIce") {
                if var orbit = inner.components[IllustrativeOrbit.self] {
                    orbit.isRunning = moving && !isPaused && !reduceMotion
                    inner.components.set(orbit)
                }
                if !moving {
                    inner.position = [-1.45, 0.09, 0.7]
                } else if reduceMotion {
                    inner.position = [-0.15, 0.09, -1.55]
                }
            }
            if let outer = root.findEntity(named: "outerIce") {
                if var orbit = outer.components[IllustrativeOrbit.self] {
                    orbit.isRunning = moving && !isPaused && !reduceMotion
                    outer.components.set(orbit)
                }
                if !moving {
                    outer.position = [2.05, 0.1, 0.7]
                } else if reduceMotion {
                    outer.position = [1.1, 0.1, 2.15]
                }
            }
        }
    }

    @MainActor
    private enum DioramaBuilder {
        static let sand = color(0.73, 0.31, 0.13)
        static let gold = color(1, 0.65, 0.08)
        static let cyan = color(0.12, 0.9, 1)
        private static let registration: Void = {
            IllustrativeOrbit.registerComponent()
            IllustrativeOrbitSystem.registerSystem()
        }()

        static func registerSystems() { _ = registration }

        static func groundPoint(_ point: ExplorationPoint) -> SIMD3<Float> {
            [Float(point.x - 0.5) * 6, 0, Float(point.y - 0.5) * 4.4]
        }

        static func build(_ destination: String, texture: TextureResource?, into root: Entity) {
            camera(into: root, destination: destination)
            lighting(into: root, warm: destination == "mars")
            stars(into: root)
            switch destination {
            case "mars": mars(into: root, texture: texture)
            case "mercury": mercury(into: root)
            default: saturn(into: root)
            }
            companion(into: root, space: destination == "saturn")
            let halo = model(ring(radius: 0.24, tube: 0.018), cyan, unlit: true)
            halo.name = "selectionHalo"
            root.addChild(halo)
        }

        static func camera(into root: Entity, destination: String) {
            let space = destination == "saturn"
            let camera = Entity()
            camera.name = "ExplorationCamera"
            camera.components.set(
                PerspectiveCameraComponent(near: 0.05, far: 80, fieldOfViewInDegrees: 44))
            camera.look(
                at: space ? [0, 0.1, 0] : [0, 0.25, 0],
                from: space
                    ? [0, 3.2, 8.5] : destination == "mars" ? [0, 2.9, 7.4] : [0, 3.5, 7.8],
                relativeTo: nil)
            root.addChild(camera)
        }

        static func lighting(into root: Entity, warm: Bool) {
            let key = DirectionalLight()
            key.light.color = warm ? color(1, 0.76, 0.53) : color(0.78, 0.85, 1)
            key.light.intensity = 3500
            var shadow = DirectionalLightComponent.Shadow()
            shadow.shadowProjection = .automatic(maximumDistance: 18)
            key.shadow = shadow
            key.look(at: [0, 0, 0], from: [-3, 7, 4], relativeTo: nil)
            root.addChild(key)
            let fill = PointLight()
            fill.light.color = color(0.24, 0.64, 1)
            fill.light.intensity = 1300
            fill.light.attenuationRadius = 15
            fill.position = [4, 3, 3]
            root.addChild(fill)
        }

        static func stars(into root: Entity) {
            for index in 0..<65 {
                let star = model(
                    .generateSphere(radius: index % 9 == 0 ? 0.018 : 0.009), color(0.64, 0.81, 1),
                    unlit: true)
                star.position = [
                    -7 + Float((index * 37) % 140) / 10, 1.5 + Float((index * 19) % 65) / 10, -7,
                ]
                root.addChild(star)
            }
        }

        static func mars(into root: Entity, texture: TextureResource?) {
            let terrain = model(terrainMesh(mars: true), color(1, 0.95, 0.90), texture: texture)
            terrain.position.y = -0.45
            root.addChild(terrain)
            // Individual layers create an actual rock cross-section, revealed by brushing.
            let outcrop = Entity()
            outcrop.position = [1.3, -0.30, -0.3]
            for index in 0..<9 {
                let pale = index % 3 == 0
                let layerColor =
                    pale ? color(0.94, 0.83, 0.62) : color(0.91, 0.80, 0.69)
                let layer = model(
                    rockMesh(radius: 0.87 - Float(index) * 0.018, height: 0.22, seed: index),
                    layerColor, texture: pale ? nil : texture
                )
                layer.position.y = Float(index) * 0.18
                layer.scale = [1.20, 1, 0.61]
                layer.orientation = simd_quatf(angle: Float(index % 3) * 0.08, axis: [0, 1, 0])
                outcrop.addChild(layer)
            }
            root.addChild(outcrop)
            let dust = model(
                .generateBox(size: [1.96, 1.4, 0.12], cornerRadius: 0.08), color(0.72, 0.33, 0.15))
            dust.name = "rockDust"
            dust.position = [1.3, 0.39, 0.24]
            root.addChild(dust)
            for index in 0..<22 {
                let rock = model(
                    rockMesh(
                        radius: 0.15 + Float(index % 4) * 0.05, height: 0.24, seed: index + 31),
                    color(0.81 + Double(index % 3) * 0.06, 0.68, 0.58), texture: texture)
                rock.scale = [1.1, 0.55 + Float(index % 3) * 0.12, 0.8]
                rock.position = [
                    -3.2 + Float((index * 17) % 62) / 10, -0.27,
                    -1.8 + Float((index * 13) % 39) / 10,
                ]
                root.addChild(rock)
            }
            for index in 0..<65 {
                let pebble = model(
                    .generateSphere(radius: 0.025 + Float(index % 3) * 0.012),
                    color(0.56, 0.29, 0.16))
                pebble.position = [
                    -3.5 + Float((index * 29) % 68) / 10, -0.29,
                    -2.5 + Float((index * 17) % 51) / 10,
                ]
                pebble.scale = [1.2, 0.45, 0.8]
                root.addChild(pebble)
            }
            // Distant mesas supply depth without a flat illustrated backdrop.
            for index in 0..<8 {
                let mesa = model(
                    rockMesh(radius: 0.8, height: 1.3 + Float(index % 3) * 0.55, seed: index + 5),
                    color(0.91, 0.78, 0.69), texture: texture)
                mesa.position = [-4 + Float(index) * 1.15, 0.15, -3.8 - Float(index % 2) * 0.3]
                mesa.scale = [1.2, 1, 0.55]
                root.addChild(mesa)
            }
            rover(into: root)
            let scanner = Entity()
            scanner.name = "scanner"
            for index in 0..<4 {
                let arc = model(
                    ring(radius: 0.25 + Float(index) * 0.19, tube: 0.014), gold, unlit: true)
                arc.orientation = simd_quatf(angle: .pi / 2, axis: [1, 0, 0])
                arc.position = [1.3, 0.56, 0.36]
                scanner.addChild(arc)
            }
            root.addChild(scanner)
            let frame = model(.generateBox(size: [0.83, 0.05, 0.08]), cyan, unlit: true)
            frame.name = "photoFrame"
            frame.position = [1.3, 1.35, 0.45]
            root.addChild(frame)
            let water = Entity()
            water.name = "waterFlow"
            for index in 0..<12 {
                let segment = model(
                    .generateBox(size: [0.26, 0.035, 0.4], cornerRadius: 0.015),
                    color(0.12, 0.65, 0.8))
                segment.position = [-1.9 + Float(index) * 0.17, -0.22, -1.6 + Float(index) * 0.21]
                segment.orientation = simd_quatf(angle: -0.25, axis: [0, 1, 0])
                water.addChild(segment)
            }
            root.addChild(water)
            let comparison = Entity()
            comparison.name = "depositComparison"
            for index in 0..<5 {
                let layer = model(
                    .generateBox(size: [0.80, 0.11, 0.65], cornerRadius: 0.035),
                    index % 2 == 0 ? color(0.87, 0.70, 0.42) : color(0.65, 0.34, 0.19))
                layer.position = [2.4, -0.20 + Float(index) * 0.1, -1.35]
                comparison.addChild(layer)
            }
            root.addChild(comparison)
            crater(radius: 0.40, at: [-1.6, -0.19, 0.50], into: root, pale: false)
        }

        static func mercury(into root: Entity) {
            let terrain = model(terrainMesh(mars: false), color(0.37, 0.35, 0.32))
            terrain.position.y = -0.36
            root.addChild(terrain)
            for index in 0..<8 {
                crater(
                    radius: 0.13 + Float(index % 3) * 0.09,
                    at: [
                        -3.1 + Float((index * 17) % 57) / 10, -0.12,
                        -1.5 + Float((index * 13) % 28) / 10,
                    ], into: root, pale: true)
            }
            for index in 0..<12 {
                let small = Entity()
                small.name = "smallImpact.\(index)"
                crater(
                    radius: 0.16 + Float(index % 3) * 0.025,
                    at: [-1.5 + Float(index % 4) * 0.23, -0.08, -0.55 + Float(index / 4) * 0.27],
                    into: small, pale: true)
                root.addChild(small)
                let large = Entity()
                large.name = "largeImpact.\(index)"
                crater(
                    radius: 0.37 + Float(index % 2) * 0.03,
                    at: [0.6 + Float(index % 3) * 0.16, -0.055, -0.65 + Float(index / 3) * 0.18],
                    into: large, pale: true)
                root.addChild(large)
            }
            let shadowWall = model(ring(radius: 0.68, tube: 0.26), color(0.23, 0.22, 0.24))
            shadowWall.position = [2.05, 0.05, 0.45]
            shadowWall.scale = [0.9, 1.6, 0.85]
            root.addChild(shadowWall)
            let shadow = model(
                .generateCylinder(height: 0.025, radius: 0.74), color(0.035, 0.055, 0.10))
            shadow.position = [1.95, -0.12, 0.65]
            shadow.scale = [1.1, 1, 0.65]
            root.addChild(shadow)
            let ejecta = Entity()
            ejecta.name = "ejecta"
            for index in 0..<15 {
                let piece = model(
                    .generateSphere(radius: 0.045 + Float(index % 3) * 0.012), gold, unlit: true)
                piece.position = [
                    0.58 - Float(index) * 0.11, -0.055, -0.1 + Float(index % 4) * 0.11,
                ]
                ejecta.addChild(piece)
            }
            root.addChild(ejecta)
            let sensor = Entity()
            sensor.name = "sensor"
            let body = model(
                .generateBox(size: [0.17, 0.36, 0.14], cornerRadius: 0.03), color(0.93, 0.91, 0.83))
            body.position.y = 0.1
            sensor.addChild(body)
            let screen = model(
                .generateBox(size: [0.13, 0.17, 0.015], cornerRadius: 0.015), cyan, unlit: true)
            screen.position = [0, 0.12, 0.078]
            sensor.addChild(screen)
            root.addChild(sensor)
            let warm = model(.generateSphere(radius: 0.13), color(1, 0.40, 0.10), unlit: true)
            warm.name = "warmReading"
            warm.position = [-0.40, 0.45, 0.98]
            root.addChild(warm)
            let cold = model(.generateSphere(radius: 0.13), cyan, unlit: true)
            cold.name = "coldReading"
            cold.position = [1.85, 0.38, 0.7]
            root.addChild(cold)
            let sun = model(.generateSphere(radius: 0.46), color(1, 0.72, 0.23), unlit: true)
            sun.position = [-3.2, 2.4, -4.6]
            root.addChild(sun)
        }

        static func saturn(into root: Entity) {
            let system = Entity()
            system.name = "SaturnSystem"
            let planet = model(.generateSphere(radius: 1.04), color(0.85, 0.69, 0.42))
            system.addChild(planet)
            for index in 0..<12 {
                let latitude = -0.85 + Float(index) * 0.145
                let radius = sqrt(max(0.02, 1.045 * 1.045 - latitude * latitude))
                let belt = model(
                    ring(radius: radius, tube: 0.018 + Float(index % 2) * 0.012),
                    index % 2 == 0 ? color(0.63, 0.48, 0.29) : color(0.95, 0.83, 0.60))
                belt.position.y = latitude
                system.addChild(belt)
            }
            for index in 0..<18 {
                let band = model(
                    ring(radius: 1.34 + Float(index) * 0.055, tube: 0.018),
                    index % 4 == 0
                        ? color(0.37, 0.34, 0.31)
                        : color(0.79 + Double(index % 3) * 0.045, 0.71, 0.53))
                band.scale.y = 0.22
                system.addChild(band)
            }
            for index in 0..<180 {
                let angle = Float(index) * 2.39996
                let radius = 1.37 + Float((index * 17) % 87) / 100
                let ice = model(
                    .generateSphere(radius: 0.017 + Float(index % 3) * 0.007),
                    color(0.88, 0.89, 0.87))
                ice.scale = [1, 0.6, 0.8]
                ice.position = [cos(angle) * radius, 0, sin(angle) * radius]
                system.addChild(ice)
            }
            let inner = model(.generateSphere(radius: 0.17), cyan, unlit: true)
            inner.name = "innerIce"
            inner.scale = [1.2, 0.75, 0.8]
            inner.components.set(IllustrativeOrbit(radius: 1.6, radiansPerSecond: 0.85, angle: 2.7))
            system.addChild(inner)
            let outer = model(.generateSphere(radius: 0.19), gold, unlit: true)
            outer.name = "outerIce"
            outer.scale = [0.9, 0.7, 1.15]
            outer.components.set(
                IllustrativeOrbit(radius: 2.2, radiansPerSecond: 0.43, angle: 0.35))
            system.addChild(outer)
            let trails = Entity()
            trails.name = "orbitTrails"
            for radius: Float in [1.6, 2.2] {
                let trail = model(ring(radius: radius, tube: 0.022), cyan, unlit: true)
                trail.position.y = 0.06
                trails.addChild(trail)
            }
            system.addChild(trails)
            root.addChild(system)
            let kit = model(
                .generateBox(size: [0.48, 0.28, 0.40], cornerRadius: 0.07), color(0.94, 0.93, 0.88))
            kit.position = [-2.1, -0.65, 1.2]
            root.addChild(kit)
        }

        static func rover(into root: Entity) {
            let rover = Entity()
            rover.name = "rover"
            let base = model(
                .generateBox(size: [0.86, 0.26, 0.65], cornerRadius: 0.06), color(0.91, 0.86, 0.71))
            base.position.y = 0.22
            rover.addChild(base)
            let trim = model(.generateBox(size: [0.90, 0.07, 0.68], cornerRadius: 0.02), gold)
            trim.position.y = 0.29
            rover.addChild(trim)
            for index in 0..<4 {
                let panel = model(
                    .generateBox(size: [0.13, 0.025, 0.40], cornerRadius: 0.015),
                    color(0.07, 0.16, 0.25))
                panel.position = [-0.29 + Float(index) * 0.19, 0.375, -0.04]
                rover.addChild(panel)
            }
            for side: Float in [-1, 1] {
                let lamp = model(.generateSphere(radius: 0.045), cyan, unlit: true)
                lamp.position = [side * 0.30, 0.25, 0.35]
                rover.addChild(lamp)
                let suspension = model(
                    .generateBox(size: [0.07, 0.08, 0.70], cornerRadius: 0.02),
                    color(0.21, 0.23, 0.24))
                suspension.position = [side * 0.43, 0.18, 0]
                rover.addChild(suspension)
            }
            for side: Float in [-1, 1] {
                for index in 0..<3 {
                    let wheel = model(
                        .generateCylinder(height: 0.15, radius: 0.17), color(0.045, 0.06, 0.085))
                    wheel.orientation = simd_quatf(angle: .pi / 2, axis: [0, 0, 1])
                    wheel.position = [side * 0.48, 0.08, -0.26 + Float(index) * 0.26]
                    rover.addChild(wheel)
                    let hub = model(.generateCylinder(height: 0.17, radius: 0.08), gold)
                    hub.orientation = wheel.orientation
                    hub.position = wheel.position
                    rover.addChild(hub)
                }
            }
            let mast = model(
                .generateCylinder(height: 0.36, radius: 0.043), color(0.19, 0.22, 0.25))
            mast.position.y = 0.5
            rover.addChild(mast)
            let head = model(
                .generateBox(size: [0.34, 0.25, 0.22], cornerRadius: 0.05), color(0.95, 0.94, 0.89))
            head.position = [0, 0.70, 0]
            rover.addChild(head)
            let lens = model(.generateSphere(radius: 0.065), cyan, unlit: true)
            lens.position = [0, 0.70, 0.12]
            rover.addChild(lens)
            rover.position = [-1.45, -0.13, 1.3]
            root.addChild(rover)
        }

        static func companion(into root: Entity, space: Bool) {
            let bot = Entity()
            bot.position = space ? [-2.35, 1.15, 0] : [-2.05, 1.35, 0]
            let shell = model(.generateSphere(radius: 0.32), color(0.96, 0.94, 0.84))
            shell.scale = [1, 0.9, 0.83]
            bot.addChild(shell)
            let face = model(
                .generateBox(size: [0.44, 0.32, 0.06], cornerRadius: 0.10),
                color(0.015, 0.035, 0.065))
            face.position.z = 0.24
            bot.addChild(face)
            for side: Float in [-1, 1] {
                let ear = model(.generateCylinder(height: 0.10, radius: 0.16), gold)
                ear.orientation = simd_quatf(angle: .pi / 2, axis: [0, 0, 1])
                ear.position = [side * 0.33, 0, 0]
                bot.addChild(ear)
                let antenna = model(.generateCylinder(height: 0.20, radius: 0.025), gold)
                antenna.position = [side * 0.18, 0.33, 0]
                bot.addChild(antenna)
            }
            let curious = Entity()
            curious.name = "curiousEyes"
            let happy = Entity()
            happy.name = "happyEyes"
            for side: Float in [-1, 1] {
                let eye = model(.generateSphere(radius: 0.048), cyan, unlit: true)
                eye.scale.y = 1.25
                eye.position = [side * 0.11, 0.03, 0.29]
                curious.addChild(eye)
                let smiling = model(ring(radius: 0.05, tube: 0.012), cyan, unlit: true)
                smiling.orientation = simd_quatf(angle: .pi / 2, axis: [1, 0, 0])
                smiling.position = [side * 0.11, 0.04, 0.29]
                smiling.scale = [1, 0.6, 1]
                happy.addChild(smiling)
            }
            bot.addChild(curious)
            bot.addChild(happy)
            let glow = model(.generateCone(height: 0.20, radius: 0.07), cyan, unlit: true)
            glow.position.y = -0.35
            bot.addChild(glow)
            root.addChild(bot)
        }

        static func crater(radius: Float, at point: SIMD3<Float>, into root: Entity, pale: Bool) {
            let floor = model(
                .generateCylinder(height: 0.026, radius: radius),
                pale ? color(0.11, 0.13, 0.17) : color(0.31, 0.14, 0.09))
            floor.position = point
            root.addChild(floor)
            let rim = model(
                ring(radius: radius, tube: radius * 0.14),
                pale ? color(0.56, 0.54, 0.49) : color(0.80, 0.45, 0.24))
            rim.position = point + [0, 0.016, 0]
            rim.scale.y = 0.7
            root.addChild(rim)
        }

        static func model(
            _ mesh: MeshResource, _ tint: DioramaColor, unlit: Bool = false,
            texture: TextureResource? = nil
        )
            -> ModelEntity
        {
            if unlit { return ModelEntity(mesh: mesh, materials: [UnlitMaterial(color: tint)]) }
            var material = SimpleMaterial(color: tint, roughness: 0.72, isMetallic: false)
            if let texture { material.color = .init(tint: tint, texture: .init(texture)) }
            return ModelEntity(mesh: mesh, materials: [material])
        }

        static func color(_ red: Double, _ green: Double, _ blue: Double) -> DioramaColor {
            DioramaColor(red: red, green: green, blue: blue, alpha: 1)
        }

        /// Irregular carved silhouettes, rather than identical cylinders. Each band remains
        /// individually visible so brushing reveals a real cross-section in the toy.
        static func rockMesh(radius: Float, height: Float, seed: Int) -> MeshResource {
            let sides = 28
            var positions: [SIMD3<Float>] = []
            var normals: [SIMD3<Float>] = []
            var uv: [SIMD2<Float>] = []
            var triangles: [UInt32] = []
            let phase = Float(seed) * 0.37
            for row in 0...1 {
                for index in 0...sides {
                    let angle = Float(index) / Float(sides) * 2 * .pi
                    let uneven = 1 + 0.10 * sin(angle * 3 + phase) + 0.06 * cos(angle * 7 - phase)
                    let taper: Float = row == 0 ? 1.06 : 0.87
                    let r = radius * uneven * taper
                    let y =
                        (Float(row) - 0.5) * height + sin(angle * 4 + phase)
                        * min(height * 0.1, 0.045)
                    positions.append([cos(angle) * r, y, sin(angle) * r])
                    normals.append(simd_normalize([cos(angle), 0.14, sin(angle)]))
                    uv.append([Float(index) / Float(sides) * 2, Float(row) * max(0.15, height)])
                    if row == 0, index < sides {
                        let a = UInt32(index)
                        let b = a + UInt32(sides + 1)
                        triangles.append(contentsOf: [a, b, a + 1, a + 1, b, b + 1])
                    }
                }
            }
            for row in 0...1 {
                let center = UInt32(positions.count)
                positions.append([0, (Float(row) - 0.5) * height, 0])
                normals.append([0, row == 0 ? -1 : 1, 0])
                uv.append([0.5, 0.5])
                for index in 0...sides {
                    let source = row * (sides + 1) + index
                    positions.append(positions[source])
                    normals.append([0, row == 0 ? -1 : 1, 0])
                    uv.append([
                        positions[source].x / radius * 0.5 + 0.5,
                        positions[source].z / radius * 0.5 + 0.5,
                    ])
                    if index < sides {
                        let a = center + 1 + UInt32(index)
                        triangles.append(
                            contentsOf: row == 0 ? [center, a, a + 1] : [center, a + 1, a])
                    }
                }
            }
            var descriptor = MeshDescriptor(name: "SculptedRock")
            descriptor.positions = MeshBuffers.Positions(positions)
            descriptor.normals = MeshBuffers.Normals(normals)
            descriptor.textureCoordinates = MeshBuffers.TextureCoordinates(uv)
            descriptor.primitives = .triangles(triangles)
            return (try? MeshResource.generate(from: [descriptor]))
                ?? .generateSphere(radius: radius)
        }

        static func ring(radius: Float, tube: Float) -> MeshResource {
            var positions: [SIMD3<Float>] = []
            var normals: [SIMD3<Float>] = []
            var triangles: [UInt32] = []
            let around = 64
            let across = 8
            for row in 0...around {
                let angle = Float(row) / Float(around) * 2 * .pi
                for column in 0...across {
                    let section = Float(column) / Float(across) * 2 * .pi
                    positions.append([
                        (radius + tube * cos(section)) * cos(angle), tube * sin(section),
                        (radius + tube * cos(section)) * sin(angle),
                    ])
                    normals.append([
                        cos(section) * cos(angle), sin(section), cos(section) * sin(angle),
                    ])
                    if row < around, column < across {
                        let a = UInt32(row * (across + 1) + column)
                        let b = a + UInt32(across + 1)
                        triangles.append(contentsOf: [a, b, a + 1, a + 1, b, b + 1])
                    }
                }
            }
            var descriptor = MeshDescriptor(name: "ProceduralRing")
            descriptor.positions = MeshBuffers.Positions(positions)
            descriptor.normals = MeshBuffers.Normals(normals)
            descriptor.primitives = .triangles(triangles)
            return (try? MeshResource.generate(from: [descriptor]))
                ?? .generateSphere(radius: radius)
        }

        static func terrainMesh(mars: Bool) -> MeshResource {
            let width = 40
            let depth = 32
            var positions: [SIMD3<Float>] = []
            var normals: [SIMD3<Float>] = []
            var uv: [SIMD2<Float>] = []
            var triangles: [UInt32] = []
            for row in 0...depth {
                for column in 0...width {
                    let x = -4.2 + Float(column) / Float(width) * 8.4
                    let z = -3.5 + Float(row) / Float(depth) * 6.5
                    let height = sin(x * 2.2 + z * 1.4) * 0.07 + cos(z * 3.2 - x) * 0.04
                    positions.append([x, height + (mars ? max(0, -z - 1.6) * 0.15 : 0), z])
                    let dx = cos(x * 2.2 + z * 1.4) * 0.154 + sin(z * 3.2 - x) * 0.04
                    let dz =
                        cos(x * 2.2 + z * 1.4) * 0.098 - sin(z * 3.2 - x) * 0.128
                        - (mars && z < -1.6 ? 0.15 : 0)
                    normals.append(simd_normalize([-dx, 1, -dz]))
                    uv.append([Float(column) / 10, Float(row) / 10])
                    if row < depth, column < width {
                        let a = UInt32(row * (width + 1) + column)
                        let b = a + UInt32(width + 1)
                        triangles.append(contentsOf: [a, b, a + 1, a + 1, b, b + 1])
                    }
                }
            }
            var descriptor = MeshDescriptor(name: "RockyTerrain")
            descriptor.positions = MeshBuffers.Positions(positions)
            descriptor.normals = MeshBuffers.Normals(normals)
            descriptor.textureCoordinates = MeshBuffers.TextureCoordinates(uv)
            descriptor.primitives = .triangles(triangles)
            return (try? MeshResource.generate(from: [descriptor]))
                ?? .generatePlane(width: 8.4, depth: 6.5)
        }
    }

    /// Cosmetic-only motion runs inside RealityKit, never through observable session ticks.
    private struct IllustrativeOrbit: Component {
        var radius: Float
        var radiansPerSecond: Float
        var angle: Float
        var isRunning = false
    }

    private struct IllustrativeOrbitSystem: System {
        static let query = EntityQuery(where: .has(IllustrativeOrbit.self))
        init(scene: RealityKit.Scene) {}

        func update(context: SceneUpdateContext) {
            for entity in context.entities(matching: Self.query, updatingSystemWhen: .rendering) {
                guard var orbit = entity.components[IllustrativeOrbit.self], orbit.isRunning else {
                    continue
                }
                orbit.angle =
                    (orbit.angle + Float(min(context.deltaTime, 0.1)) * orbit.radiansPerSecond)
                    .truncatingRemainder(dividingBy: 2 * .pi)
                entity.position = [
                    cos(orbit.angle) * orbit.radius, 0.09, sin(orbit.angle) * orbit.radius,
                ]
                entity.components.set(orbit)
            }
        }
    }
#else
    public struct ExplorationWorldView: View {
        public init(adventure: ExplorationAdventure, cursor: ExplorationCursor, isPaused: Bool) {}
        public var body: some View { Color.black }
    }
#endif
