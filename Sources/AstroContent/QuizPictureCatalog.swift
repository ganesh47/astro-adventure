import AstroGameCore

/// Reviewed schematic meanings for the generated solar-system choices.
/// Lookup uses authored answer text and concept, never the correct answer ID.
enum QuizPictureCatalog {
    static func expansion(
        concept: String, text: String, destinationName: String
    ) -> QuizPicture {
        let scene: QuizPicture.Scene
        let detail: String
        var tone: QuizPicture.Tone? = nil
        switch concept {
        case "type":
            scene = requiredScene(
                text,
                in: [
                    "A star": .star,
                    "A rocky planet": .rockyWorld,
                    "A moon": .moon,
                    "A gas giant": .gasWorld,
                    "An ice giant": .icyWorld,
                    "A dwarf planet": .dwarfWorld,
                ])
            detail = "An illustrated kind of space object"
            if text == "An ice giant" { tone = .blueGreen }
        case "color":
            scene = requiredScene(
                text,
                in: [
                    "White light, often pictured gold or orange": .star,
                    "Cream and golden clouds": .clouds,
                    "Blue oceans and white clouds": .ocean,
                    "Gray rock with dark lava plains": .rockyWorld,
                    "Cream, orange and brown cloud bands": .gasWorld,
                    "Pale gold clouds and bright icy rings": .rings,
                    "Pale blue-green": .icyWorld,
                    "Blue with bright white clouds": .icyWorld,
                    "Tan, white and rusty red": .dwarfWorld,
                    "Dark gray with brilliant white spots": .saltSpots,
                ])
            let tones: [String: QuizPicture.Tone] = [
                "White light, often pictured gold or orange": .gold,
                "Cream and golden clouds": .cream,
                "Blue oceans and white clouds": .blueWhite,
                "Gray rock with dark lava plains": .gray,
                "Cream, orange and brown cloud bands": .gold,
                "Pale gold clouds and bright icy rings": .gold,
                "Pale blue-green": .blueGreen,
                "Blue with bright white clouds": .blueWhite,
                "Tan, white and rusty red": .rust,
                "Dark gray with brilliant white spots": .gray,
            ]
            tone = tones[text]
            detail = "A schematic color and surface clue"
        case "shape":
            scene = requiredScene(
                text,
                in: [
                    "Gravity pulls material toward its center": .gravity,
                    "Space objects begin as perfect cubes": .cube,
                    "Sunlight carves every world into a ball": .sunlight,
                ])
            detail = "An illustrated proposal for a round shape"
        case "au":
            scene = .distance
            detail = "Sun to \(destinationName); 1 AU is the Sun-to-Earth reference"
        case "light":
            scene = .duration
            let target = destinationName == "Sun" ? "Earth" : destinationName
            detail = "Sunlight travelling from the Sun to \(target)"
        case "motion":
            let centeredMotion: [String: QuizPicture.Scene] = [
                "A ≈25-day equator spin; a ≈230-million-year galactic orbit": .galacticOrbit,
                "A 243-day backward spin; a 225-day year": .retrogradeSpinOrbit,
                "A 27.3-day spin and 27.3-day orbit": .synchronousMoon,
            ]
            scene = centeredMotion[text] ?? .spinOrbit
            detail = "Separate spin and orbit clues proposed for \(destinationName)"
        case "wonder":
            scene = requiredScene(
                text,
                in: [
                    "Magnetic loops and solar prominences": .solarLoops,
                    "Volcanoes hidden beneath thick clouds": .volcano,
                    "Surface oceans and known life": .livingEarth,
                    "It keeps nearly the same face toward Earth": .synchronousMoon,
                    "The giant Great Red Spot storm": .storm,
                    "A vast system of icy rings": .rings,
                    "It rotates almost completely on its side": .sidewaysSpin,
                    "The fastest winds measured on a planet": .storm,
                    "A heart-shaped nitrogen-ice plain": .heartPlain,
                    "Bright salt deposits in Occator Crater": .saltSpots,
                ])
            let featureTones: [String: QuizPicture.Tone] = [
                "The giant Great Red Spot storm": .gold,
                "A vast system of icy rings": .gold,
                "It rotates almost completely on its side": .blueGreen,
                "The fastest winds measured on a planet": .blueWhite,
            ]
            tone = featureTones[text]
            detail = "An illustrated feature idea"
        default:
            preconditionFailure("Unmapped authored quiz concept: \(concept)")
        }
        return QuizPicture(scene: scene, label: text, detail: detail, tone: tone)
    }

    private static func requiredScene(
        _ text: String, in scenes: [String: QuizPicture.Scene]
    ) -> QuizPicture.Scene {
        guard let scene = scenes[text] else {
            preconditionFailure("Unmapped authored quiz picture: \(text)")
        }
        return scene
    }
}
