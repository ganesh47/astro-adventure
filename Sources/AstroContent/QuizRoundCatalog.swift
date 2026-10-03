import AstroGameCore

public enum QuizRoundCatalog {
    public static func quizzes(
        destinationID: String,
        ageBand: AgeBand
    ) -> [QuizContent] {
        let sourceQuizzes: [QuizContent] =
            switch destinationID {
            case SpaceTechnologyCatalog.destinationID:
                SpaceTechnologyCatalog.quizzes(ageBand: ageBand)
            case "mercury":
                mercury(for: ageBand) + distanceQuizzes(for: "mercury", ageBand: ageBand)
            case "mars": mars(for: ageBand) + distanceQuizzes(for: "mars", ageBand: ageBand)
            case "europa": europa(for: ageBand) + distanceQuizzes(for: "europa", ageBand: ageBand)
            default:
                SolarSystemExpansionCatalog.quizzes(
                    destinationID: destinationID,
                    ageBand: ageBand
                ) ?? []
            }

        return mixAnswerPositions(
            sourceQuizzes,
            destinationID: destinationID,
            ageBand: ageBand
        )
    }

    private static func mixAnswerPositions(
        _ quizzes: [QuizContent],
        destinationID: String,
        ageBand: AgeBand
    ) -> [QuizContent] {
        let destinationOffset = destinationID.unicodeScalars.reduce(0) {
            ($0 + Int($1.value)) % 3
        }
        let ageOffset =
            switch ageBand {
            case .ages4To6: 0
            case .ages7To9: 1
            case .ages10To12: 2
            }

        return quizzes.enumerated().map { questionIndex, quiz in
            guard
                quiz.choices.count > 1,
                let correctChoice = quiz.choices.first(where: {
                    $0.id == quiz.correctChoiceID
                })
            else { return quiz }

            var reorderedChoices = quiz.choices.filter {
                $0.id != quiz.correctChoiceID
            }
            let targetIndex =
                (questionIndex + destinationOffset + ageOffset + 1)
                % quiz.choices.count
            reorderedChoices.insert(correctChoice, at: targetIndex)

            return QuizContent(
                prompt: quiz.prompt,
                choices: reorderedChoices,
                correctChoiceID: quiz.correctChoiceID,
                correctFeedback: quiz.correctFeedback,
                retryFeedback: quiz.retryFeedback,
                hint: quiz.hint
            )
        }
    }

    private static func mercury(for ageBand: AgeBand) -> [QuizContent] {
        [
            make(
                ageBand: ageBand,
                prompt: ageBand == .ages4To6
                    ? "Which planet is closest to the Sun?"
                    : "Which clue places Mercury in the solar system?",
                choices: [
                    .init(
                        id: "sun", text: "Closest planet to the Sun",
                        picture: .init(
                            scene: .innerOrbit, label: "Closest planet to the Sun",
                            detail: "Mercury on the innermost orbit around the Sun"
                        )
                    ),
                    .init(
                        id: "red_planet", text: "The rusty red planet",
                        picture: .init(
                            scene: .rust, label: "The rusty red planet",
                            detail: "Schematic answer idea for Mercury", tone: .rust
                        )
                    ),
                    .init(
                        id: "icy_moon", text: "An icy moon of Jupiter",
                        picture: .init(
                            scene: .moon, label: "An icy moon of Jupiter",
                            detail: "Schematic answer idea for Mercury", tone: .blueWhite
                        )
                    ),
                ],
                correct: "sun",
                correctFeedback: "Solar-powered! Mercury is the closest planet to the Sun.",
                retryFeedback: "Almost! Think about the first planet from the Sun.",
                hint: "Mercury is planet number 1 from the Sun."
            ),
            make(
                ageBand: ageBand,
                prompt: "About how wide is Mercury’s Caloris Basin?",
                choices: [
                    .init(
                        id: "caloris_1550", text: "1,550 kilometres",
                        picture: .init(
                            scene: .craterWidth, label: "1,550 kilometres",
                            detail: "Proposed diameter of Caloris Basin"
                        )
                    ),
                    .init(
                        id: "caloris_155", text: "155 kilometres",
                        picture: .init(
                            scene: .craterWidth, label: "155 kilometres",
                            detail: "Proposed diameter of Caloris Basin"
                        )
                    ),
                    .init(
                        id: "caloris_15500", text: "15,500 kilometres",
                        picture: .init(
                            scene: .craterWidth, label: "15,500 kilometres",
                            detail: "Proposed diameter of Caloris Basin"
                        )
                    ),
                ],
                correct: "caloris_1550",
                correctFeedback: "Crater champion! Caloris is about 1,550 kilometres wide.",
                retryFeedback: "Recheck the number on the giant crash-mark card.",
                hint: "The answer has four digits and begins with 1."
            ),
            make(
                ageBand: ageBand,
                prompt: "Why can Mercury have scorching days and freezing nights?",
                choices: [
                    .init(
                        id: "thin_air", text: "Almost no atmosphere holds the heat",
                        picture: .init(
                            scene: .thinAtmosphere, label: "Almost no atmosphere holds the heat",
                            detail: "Schematic answer idea for Mercury"
                        )
                    ),
                    .init(
                        id: "red_dust", text: "Red dust cools the whole planet",
                        picture: .init(
                            scene: .desert, label: "Red dust cools the whole planet",
                            detail: "A proposal that dusty rock carries heat away"
                        )
                    ),
                    .init(
                        id: "deep_ocean", text: "A deep ocean carries heat away",
                        picture: .init(
                            scene: .oceanCirculation, label: "A deep ocean carries heat away",
                            detail: "A surface ocean carrying heat away"
                        )
                    ),
                ],
                correct: "thin_air",
                correctFeedback:
                    "Temperature detective! Mercury has almost no atmosphere to share heat.",
                retryFeedback: "Think about what a blanket of air does for a planet.",
                hint: "Mercury is missing a thick blanket of air."
            ),
            make(
                ageBand: ageBand,
                prompt: "What are Mercury’s mysterious hollows?",
                choices: [
                    .init(
                        id: "bright_hollows", text: "Bright, shallow pits in the surface",
                        picture: .init(
                            scene: .hollows, label: "Bright, shallow pits in the surface",
                            detail: "Schematic answer idea for Mercury"
                        )
                    ),
                    .init(
                        id: "storm_clouds", text: "Giant spinning storm clouds",
                        picture: .init(
                            scene: .storm, label: "Giant spinning storm clouds",
                            detail: "Schematic answer idea for Mercury"
                        )
                    ),
                    .init(
                        id: "ice_mountains", text: "Floating mountains of ice",
                        picture: .init(
                            scene: .ice, label: "Floating mountains of ice",
                            detail: "Schematic answer idea for Mercury"
                        )
                    ),
                ],
                correct: "bright_hollows",
                correctFeedback: "Hollow hunter! They are bright, shallow pits found by MESSENGER.",
                retryFeedback: "Look for a feature carved into Mercury’s rocky surface.",
                hint: "They look like small, bright dents."
            ),
            make(
                ageBand: ageBand,
                prompt: "Where can water ice survive on Mercury?",
                choices: [
                    .init(
                        id: "polar_shadow", text: "Inside permanently shadowed polar craters",
                        picture: .init(
                            scene: .shadow, label: "Inside permanently shadowed polar craters",
                            detail: "Schematic answer idea for Mercury"
                        )
                    ),
                    .init(
                        id: "sunny_plain", text: "Across the hottest sunny plains",
                        picture: .init(
                            scene: .sunlight, label: "Across the hottest sunny plains",
                            detail: "Schematic answer idea for Mercury"
                        )
                    ),
                    .init(
                        id: "thick_cloud", text: "Inside Mercury’s thick clouds",
                        picture: .init(
                            scene: .clouds, label: "Inside Mercury’s thick clouds",
                            detail: "Schematic answer idea for Mercury"
                        )
                    ),
                ],
                correct: "polar_shadow",
                correctFeedback: "Ice detective! Deep polar shadows can stay colder than −173°C.",
                retryFeedback: "Choose the place where sunlight never reaches.",
                hint: "The cold hiding places are near Mercury’s poles."
            ),
        ]
    }

    private static func mars(for ageBand: AgeBand) -> [QuizContent] {
        [
            make(
                ageBand: ageBand,
                prompt: "What makes much of Mars look red?",
                choices: [
                    .init(
                        id: "oxidation", text: "Rusty iron in rocks and dust",
                        picture: .init(
                            scene: .rust, label: "Rusty iron in rocks and dust",
                            detail: "Schematic answer idea for Mars", tone: .rust
                        )
                    ),
                    .init(
                        id: "vegetation", text: "Forests of red plants",
                        picture: .init(
                            scene: .forest, label: "Forests of red plants",
                            detail: "Schematic answer idea for Mars", tone: .rust
                        )
                    ),
                    .init(
                        id: "reflected_light", text: "Red light from Jupiter",
                        picture: .init(
                            scene: .reflection, label: "Red light from Jupiter",
                            detail: "Schematic answer idea for Mars"
                        )
                    ),
                ],
                correct: "oxidation",
                correctFeedback: "Red-planet expert! Iron minerals rust and tint the dust.",
                retryFeedback: "Look for the answer involving iron.",
                hint: "The same process can make old metal reddish-brown."
            ),
            make(
                ageBand: ageBand,
                prompt: "Mars is about what fraction of Earth’s diameter?",
                choices: [
                    .init(
                        id: "half_earth", text: "About one-half",
                        picture: .init(
                            scene: .sizeComparison, label: "1/2 × Earth",
                            detail: "Mars diameter one-half of Earth diameter"
                        )
                    ),
                    .init(
                        id: "same_earth", text: "About the same size",
                        picture: .init(
                            scene: .sizeComparison, label: "1 × Earth",
                            detail: "Mars and Earth proposed at equal diameter"
                        )
                    ),
                    .init(
                        id: "double_earth", text: "About twice as wide",
                        picture: .init(
                            scene: .sizeComparison, label: "2 × Earth",
                            detail: "Mars proposed at twice Earth diameter"
                        )
                    ),
                ],
                correct: "half_earth",
                correctFeedback: "Size scanner locked! Mars is about 53% of Earth’s diameter.",
                retryFeedback: "Remember the Earth-and-Mars comparison card.",
                hint: "About two Mars-sized balls fit across Earth."
            ),
            make(
                ageBand: ageBand,
                prompt: "How long is the Valles Marineris canyon system?",
                choices: [
                    .init(
                        id: "canyon_4000", text: "About 4,000 kilometres",
                        picture: .init(
                            scene: .canyonLength, label: "About 4,000 kilometres",
                            detail: "Proposed length of Valles Marineris"
                        )
                    ),
                    .init(
                        id: "canyon_400", text: "About 400 kilometres",
                        picture: .init(
                            scene: .canyonLength, label: "About 400 kilometres",
                            detail: "Proposed length of Valles Marineris"
                        )
                    ),
                    .init(
                        id: "canyon_40", text: "About 40 kilometres",
                        picture: .init(
                            scene: .canyonLength, label: "About 40 kilometres",
                            detail: "Proposed length of Valles Marineris"
                        )
                    ),
                ],
                correct: "canyon_4000",
                correctFeedback: "Canyon champion! It stretches about 4,000 kilometres.",
                retryFeedback: "This canyon is enormous—choose the biggest distance.",
                hint: "It reaches nearly a quarter of the way around Mars."
            ),
            make(
                ageBand: ageBand,
                prompt: "How wide is the giant volcano Olympus Mons?",
                choices: [
                    .init(
                        id: "olympus_600", text: "About 600 kilometres",
                        picture: .init(
                            scene: .volcanoWidth, label: "About 600 kilometres",
                            detail: "Proposed base width of Olympus Mons"
                        )
                    ),
                    .init(
                        id: "olympus_60", text: "About 60 kilometres",
                        picture: .init(
                            scene: .volcanoWidth, label: "About 60 kilometres",
                            detail: "Proposed base width of Olympus Mons"
                        )
                    ),
                    .init(
                        id: "olympus_6", text: "About 6 kilometres",
                        picture: .init(
                            scene: .volcanoWidth, label: "About 6 kilometres",
                            detail: "Proposed base width of Olympus Mons"
                        )
                    ),
                ],
                correct: "olympus_600",
                correctFeedback: "Volcano victory! Olympus Mons is about 600 kilometres wide.",
                retryFeedback: "This volcano is enormous—choose the largest width.",
                hint: "Its width is measured in hundreds of kilometres."
            ),
            make(
                ageBand: ageBand,
                prompt: "What happens to Mars’s polar caps as seasons change?",
                choices: [
                    .init(
                        id: "seasonal_ice", text: "They grow in winter and shrink in spring",
                        picture: .init(
                            scene: .seasonalIce, label: "They grow in winter and shrink in spring",
                            detail: "Schematic answer idea for Mars"
                        )
                    ),
                    .init(
                        id: "never_change", text: "They always stay exactly the same",
                        picture: .init(
                            scene: .steadyIce, label: "They always stay exactly the same",
                            detail: "Schematic answer idea for Mars"
                        )
                    ),
                    .init(
                        id: "fly_away", text: "They leave Mars and orbit the Sun",
                        picture: .init(
                            scene: .escapingIce, label: "They leave Mars and orbit the Sun",
                            detail: "Schematic answer idea for Mars"
                        )
                    ),
                ],
                correct: "seasonal_ice",
                correctFeedback: "Season scientist! Frost makes the polar caps grow and retreat.",
                retryFeedback: "Remember the three Hubble pictures from different months.",
                hint: "Warmer springtime makes part of the cap disappear."
            ),
        ]
    }

    private static func europa(for ageBand: AgeBand) -> [QuizContent] {
        [
            make(
                ageBand: ageBand,
                prompt: "What kind of world is Europa?",
                choices: [
                    .init(
                        id: "icy_moon", text: "An icy moon of Jupiter",
                        picture: .init(
                            scene: .moon, label: "An icy moon of Jupiter",
                            detail: "Schematic answer idea for Europa", tone: .blueWhite
                        )
                    ),
                    .init(
                        id: "red_planet", text: "A rusty planet near Earth",
                        picture: .init(
                            scene: .rust, label: "A rusty planet near Earth",
                            detail: "Schematic answer idea for Europa", tone: .rust
                        )
                    ),
                    .init(
                        id: "sun", text: "A tiny star beside the Sun",
                        picture: .init(
                            scene: .star, label: "A tiny star beside the Sun",
                            detail: "A small glowing star beside the Sun"
                        )
                    ),
                ],
                correct: "icy_moon",
                correctFeedback: "Moon mapper! Europa is an icy moon orbiting Jupiter.",
                retryFeedback: "Europa travels around a giant planet.",
                hint: "Look for Jupiter’s icy companion."
            ),
            make(
                ageBand: ageBand,
                prompt: "What covers Europa’s surface?",
                choices: [
                    .init(
                        id: "cracked_ice", text: "Water ice with cracks and ridges",
                        picture: .init(
                            scene: .ice, label: "Water ice with cracks and ridges",
                            detail: "Schematic answer idea for Europa"
                        )
                    ),
                    .init(
                        id: "red_dust", text: "Warm red desert sand",
                        picture: .init(
                            scene: .desert, label: "Warm red desert sand",
                            detail: "A warm red desert surface"
                        )
                    ),
                    .init(
                        id: "green_clouds", text: "Thick green clouds",
                        picture: .init(
                            scene: .clouds, label: "Thick green clouds",
                            detail: "Schematic answer idea for Europa", tone: .green
                        )
                    ),
                ],
                correct: "cracked_ice",
                correctFeedback:
                    "Ice investigator! Europa’s bright shell is crossed by cracks and ridges.",
                retryFeedback: "Remember the close-up picture of the bright surface.",
                hint: "It is a frozen form of water."
            ),
            make(
                ageBand: ageBand,
                prompt: "What may be hidden beneath Europa’s ice?",
                choices: [
                    .init(
                        id: "deep_ocean", text: "A deep salty ocean",
                        picture: .init(
                            scene: .subsurfaceOcean, label: "A deep salty ocean",
                            detail: "An icy shell with a salty ocean beneath"
                        )
                    ),
                    .init(
                        id: "lava_desert", text: "A dry lava desert",
                        picture: .init(
                            scene: .volcano, label: "A dry lava desert",
                            detail: "Schematic answer idea for Europa"
                        )
                    ),
                    .init(
                        id: "iron_core", text: "A hollow iron cave",
                        picture: .init(
                            scene: .ironCave, label: "A hollow iron cave",
                            detail: "A hollow cave with iron walls"
                        )
                    ),
                ],
                correct: "deep_ocean",
                correctFeedback: "Ocean explorer! Evidence points to salty water beneath the ice.",
                retryFeedback: "Think about what Europa Clipper will search for with radar.",
                hint: "Scientists are looking for liquid water."
            ),
            make(
                ageBand: ageBand,
                prompt: "What is Europa’s chaos terrain?",
                choices: [
                    .init(
                        id: "chaos_blocks", text: "Broken and rotated blocks of icy crust",
                        picture: .init(
                            scene: .blocks, label: "Broken and rotated blocks of icy crust",
                            detail: "Schematic answer idea for Europa"
                        )
                    ),
                    .init(
                        id: "sand_dunes", text: "Smooth dunes made from hot sand",
                        picture: .init(
                            scene: .desert, label: "Smooth dunes made from hot sand",
                            detail: "Schematic answer idea for Europa"
                        )
                    ),
                    .init(
                        id: "green_forest", text: "A forest growing above the ice",
                        picture: .init(
                            scene: .forest, label: "A forest growing above the ice",
                            detail: "Schematic answer idea for Europa"
                        )
                    ),
                ],
                correct: "chaos_blocks",
                correctFeedback: "Puzzle solver! Chaos terrain is a jumble of broken icy blocks.",
                retryFeedback: "Think of a giant jigsaw puzzle made of ice.",
                hint: "The crust cracked, tilted and turned."
            ),
            make(
                ageBand: ageBand,
                prompt: "How close was Juno when it captured this Europa view?",
                choices: [
                    .init(
                        id: "juno_1521", text: "About 1,521 kilometres away",
                        picture: .init(
                            scene: .flybyDistance, label: "About 1,521 kilometres away",
                            detail: "Proposed Juno-to-Europa flyby distance"
                        )
                    ),
                    .init(
                        id: "juno_15210", text: "About 15,210 kilometres away",
                        picture: .init(
                            scene: .flybyDistance, label: "About 15,210 kilometres away",
                            detail: "Proposed Juno-to-Europa flyby distance"
                        )
                    ),
                    .init(
                        id: "juno_152100", text: "About 152,100 kilometres away",
                        picture: .init(
                            scene: .flybyDistance, label: "About 152,100 kilometres away",
                            detail: "Proposed Juno-to-Europa flyby distance"
                        )
                    ),
                ],
                correct: "juno_1521",
                correctFeedback: "Flyby ace! Juno was only about 1,521 kilometres from Europa.",
                retryFeedback: "Recheck the distance on Juno’s flashcard.",
                hint: "The answer is the smallest of the three distances."
            ),
        ]
    }

    private static func make(
        ageBand: AgeBand,
        prompt: String,
        choices: [QuizChoice],
        correct: String,
        correctFeedback: String,
        retryFeedback: String,
        hint: String
    ) -> QuizContent {
        QuizContent(
            prompt: prompt,
            choices: ageBand == .ages4To6 ? Array(choices.prefix(2)) : choices,
            correctChoiceID: correct,
            correctFeedback: correctFeedback,
            retryFeedback: retryFeedback,
            hint: hint
        )
    }

    private static func distanceQuizzes(
        for destinationID: String,
        ageBand: AgeBand
    ) -> [QuizContent] {
        let details: (name: String, au: String, lightTime: String)
        switch destinationID {
        case "mercury": details = ("Mercury", "0.39 AU", "3.2 minutes")
        case "mars": details = ("Mars", "1.52 AU", "12.7 minutes")
        default: details = ("Europa", "about 5.2 AU", "about 43 minutes")
        }

        let auChoices = [
            QuizChoice(
                id: "\(destinationID)-au", text: details.au,
                picture: .init(
                    scene: .distance, label: details.au,
                    detail: "Sun to \(details.name); 1 AU is the Sun-to-Earth reference")
            ),
            QuizChoice(
                id: "\(destinationID)-au-earth", text: "1 AU",
                picture: .init(
                    scene: .distance, label: "1 AU",
                    detail: "Sun to \(details.name); 1 AU is the Sun-to-Earth reference")
            ),
            QuizChoice(
                id: "\(destinationID)-au-neptune", text: "30 AU",
                picture: .init(
                    scene: .distance, label: "30 AU",
                    detail: "Sun to \(details.name); 1 AU is the Sun-to-Earth reference")
            ),
        ]
        let lightChoices = [
            QuizChoice(
                id: "\(destinationID)-light", text: details.lightTime,
                picture: .init(
                    scene: .duration, label: details.lightTime,
                    detail: "Sunlight travelling from the Sun to \(details.name)")
            ),
            QuizChoice(
                id: "\(destinationID)-light-short", text: "about 1 second",
                picture: .init(
                    scene: .duration, label: "about 1 second",
                    detail: "Sunlight travelling from the Sun to \(details.name)")
            ),
            QuizChoice(
                id: "\(destinationID)-light-long", text: "about 4 hours",
                picture: .init(
                    scene: .duration, label: "about 4 hours",
                    detail: "Sunlight travelling from the Sun to \(details.name)")
            ),
        ]

        return [
            make(
                ageBand: ageBand,
                prompt: "About how far is \(details.name) from the Sun?",
                choices: auChoices,
                correct: "\(destinationID)-au",
                correctFeedback: "AU ace! \(details.name)’s clue is \(details.au).",
                retryFeedback: "Try the AU number from the distance card.",
                hint: "One AU is the average Sun-to-Earth distance."
            ),
            make(
                ageBand: ageBand,
                prompt: "How long does sunlight take to reach \(details.name)?",
                choices: lightChoices,
                correct: "\(destinationID)-light",
                correctFeedback: "Light-speed win! The trip takes \(details.lightTime).",
                retryFeedback: "Farther worlds wait longer for sunlight.",
                hint: "Remember the number on the racing-sunlight card."
            ),
        ]
    }
}
