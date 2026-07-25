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

            let destinationPositions: [SIMD3<Float>] = [
                [-1.8, 0.3, 0],
                [0, 0.15, 0],
                [1.8, 0.3, 0],
            ]
            let destinationColors: [PlatformColor] = [
                PlatformColor(red: 0.65, green: 0.65, blue: 0.61, alpha: 1),
                PlatformColor(red: 0.87, green: 0.28, blue: 0.13, alpha: 1),
                PlatformColor(red: 0.48, green: 0.82, blue: 1, alpha: 1),
            ]

            for (index, lesson) in lessons.prefix(3).enumerated() {
                let radius: Float = lesson.id == "mars" ? 0.42 : 0.34
                let material = SimpleMaterial(
                    color: destinationColors[index],
                    roughness: 0.72,
                    isMetallic: false
                )
                let destination = ModelEntity(
                    mesh: .generateSphere(radius: radius),
                    materials: [material]
                )
                destination.name = lesson.id
                destination.position = destinationPositions[index]
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
}
