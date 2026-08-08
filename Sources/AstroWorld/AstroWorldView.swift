import AstroGameCore
import RealityKit
import SwiftUI

#if canImport(UIKit)
    import UIKit

    private typealias PlatformColor = UIColor
#elseif canImport(AppKit)
    import AppKit

    private typealias PlatformColor = NSColor
#endif

public struct AstroWorldView: View {
    private let lessons: [DestinationLesson]

    public init(lessons: [DestinationLesson]) {
        self.lessons = lessons
    }

    public var body: some View {
        RealityView { content in
            let root = Entity()
            root.name = "AstroAdventureWorld"

            let planets = lessons.filter { $0.kind == "planet" }
            for (index, lesson) in planets.enumerated() {
                let spacing = Float(index) / Float(max(planets.count - 1, 1))
                let radius = radius(for: lesson.id)
                let material = SimpleMaterial(
                    color: color(for: lesson.id),
                    roughness: 0.72,
                    isMetallic: false
                )
                let destination = ModelEntity(
                    mesh: .generateSphere(radius: radius),
                    materials: [material]
                )
                destination.name = lesson.id
                destination.position = [
                    -2.75 + spacing * 5.5,
                    0.1 + sin(spacing * .pi) * 0.38,
                    -Float(index % 3) * 0.12,
                ]
                destination.generateCollisionShapes(recursive: false)
                root.addChild(destination)
            }

            let sunMaterial = UnlitMaterial(
                color: PlatformColor(red: 1, green: 0.68, blue: 0.18, alpha: 1)
            )
            let sun = ModelEntity(
                mesh: .generateSphere(radius: 0.7),
                materials: [sunMaterial]
            )
            sun.position = [-3.5, 1.7, -1]
            root.addChild(sun)

            let shipMaterial = SimpleMaterial(
                color: PlatformColor(red: 0.34, green: 0.88, blue: 1, alpha: 1),
                roughness: 0.25,
                isMetallic: true
            )
            let ship = ModelEntity(
                mesh: .generateCone(height: 0.45, radius: 0.2),
                materials: [shipMaterial]
            )
            ship.name = "ExplorerShip"
            ship.orientation = simd_quatf(angle: -.pi / 2, axis: [1, 0, 0])
            ship.position = [0, -0.75, 0.25]
            root.addChild(ship)

            let starMaterial = UnlitMaterial(color: PlatformColor.white)
            for index in 0..<48 {
                let star = ModelEntity(
                    mesh: .generateSphere(radius: 0.012 + Float(index % 3) * 0.004),
                    materials: [starMaterial]
                )
                let column = Float(index % 12)
                let row = Float(index / 12)
                star.position = [
                    -3.2 + column * 0.58,
                    -1.4 + row * 0.9,
                    -1.8 - Float(index % 4) * 0.2,
                ]
                root.addChild(star)
            }

            let camera = Entity()
            camera.components.set(
                PerspectiveCameraComponent(
                    near: 0.01,
                    far: 100,
                    fieldOfViewInDegrees: 48
                )
            )
            camera.look(at: [0, 0, 0], from: [0, 0.35, 6.5], relativeTo: nil)
            root.addChild(camera)

            content.add(root)
        }
        .accessibilityHidden(true)
        .background(Color.black)
    }

    private func radius(for destinationID: String) -> Float {
        switch destinationID {
        case "jupiter": 0.38
        case "saturn": 0.34
        case "uranus", "neptune": 0.27
        case "earth", "venus": 0.2
        case "mars": 0.17
        default: 0.14
        }
    }

    private func color(for destinationID: String) -> PlatformColor {
        switch destinationID {
        case "mercury": PlatformColor(red: 0.62, green: 0.61, blue: 0.57, alpha: 1)
        case "venus": PlatformColor(red: 0.91, green: 0.68, blue: 0.28, alpha: 1)
        case "earth": PlatformColor(red: 0.2, green: 0.58, blue: 0.92, alpha: 1)
        case "mars": PlatformColor(red: 0.82, green: 0.25, blue: 0.12, alpha: 1)
        case "jupiter": PlatformColor(red: 0.79, green: 0.59, blue: 0.43, alpha: 1)
        case "saturn": PlatformColor(red: 0.88, green: 0.75, blue: 0.48, alpha: 1)
        case "uranus": PlatformColor(red: 0.45, green: 0.86, blue: 0.87, alpha: 1)
        case "neptune": PlatformColor(red: 0.18, green: 0.37, blue: 0.88, alpha: 1)
        default: PlatformColor.white
        }
    }
}
