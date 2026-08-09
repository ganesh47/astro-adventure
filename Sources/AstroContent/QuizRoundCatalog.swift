import AstroGameCore

public enum QuizRoundCatalog {
    public static func quizzes(
        destinationID: String,
        ageBand: AgeBand
    ) -> [QuizContent] {
        switch destinationID {
        case SpaceTechnologyCatalog.destinationID:
            SpaceTechnologyCatalog.quizzes(ageBand: ageBand)
        case "mercury": mercury(for: ageBand) + distanceQuizzes(for: "mercury", ageBand: ageBand)
        case "mars": mars(for: ageBand) + distanceQuizzes(for: "mars", ageBand: ageBand)
        case "europa": europa(for: ageBand) + distanceQuizzes(for: "europa", ageBand: ageBand)
        default:
            SolarSystemExpansionCatalog.quizzes(
                destinationID: destinationID,
                ageBand: ageBand
            ) ?? []
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
                    .init(id: "sun", text: "Closest planet to the Sun"),
                    .init(id: "red_planet", text: "The rusty red planet"),
                    .init(id: "icy_moon", text: "An icy moon of Jupiter"),
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
                    .init(id: "caloris_1550", text: "1,550 kilometres"),
                    .init(id: "caloris_155", text: "155 kilometres"),
                    .init(id: "caloris_15500", text: "15,500 kilometres"),
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
                    .init(id: "thin_air", text: "Almost no atmosphere holds the heat"),
                    .init(id: "red_dust", text: "Red dust cools the whole planet"),
                    .init(id: "deep_ocean", text: "A deep ocean carries heat away"),
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
                    .init(id: "bright_hollows", text: "Bright, shallow pits in the surface"),
                    .init(id: "storm_clouds", text: "Giant spinning storm clouds"),
                    .init(id: "ice_mountains", text: "Floating mountains of ice"),
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
                    .init(id: "polar_shadow", text: "Inside permanently shadowed polar craters"),
                    .init(id: "sunny_plain", text: "Across the hottest sunny plains"),
                    .init(id: "thick_cloud", text: "Inside Mercury’s thick clouds"),
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
                    .init(id: "oxidation", text: "Rusty iron in rocks and dust"),
                    .init(id: "vegetation", text: "Forests of red plants"),
                    .init(id: "reflected_light", text: "Red light from Jupiter"),
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
                    .init(id: "half_earth", text: "About one-half"),
                    .init(id: "same_earth", text: "About the same size"),
                    .init(id: "double_earth", text: "About twice as wide"),
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
                    .init(id: "canyon_4000", text: "About 4,000 kilometres"),
                    .init(id: "canyon_400", text: "About 400 kilometres"),
                    .init(id: "canyon_40", text: "About 40 kilometres"),
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
                    .init(id: "olympus_600", text: "About 600 kilometres"),
                    .init(id: "olympus_60", text: "About 60 kilometres"),
                    .init(id: "olympus_6", text: "About 6 kilometres"),
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
                    .init(id: "seasonal_ice", text: "They grow in winter and shrink in spring"),
                    .init(id: "never_change", text: "They always stay exactly the same"),
                    .init(id: "fly_away", text: "They leave Mars and orbit the Sun"),
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
                    .init(id: "icy_moon", text: "An icy moon of Jupiter"),
                    .init(id: "red_planet", text: "A rusty planet near Earth"),
                    .init(id: "sun", text: "A tiny star beside the Sun"),
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
                    .init(id: "cracked_ice", text: "Water ice with cracks and ridges"),
                    .init(id: "red_dust", text: "Warm red desert sand"),
                    .init(id: "green_clouds", text: "Thick green clouds"),
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
                    .init(id: "deep_ocean", text: "A deep salty ocean"),
                    .init(id: "lava_desert", text: "A dry lava desert"),
                    .init(id: "iron_core", text: "A hollow iron cave"),
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
                    .init(id: "chaos_blocks", text: "Broken and rotated blocks of icy crust"),
                    .init(id: "sand_dunes", text: "Smooth dunes made from hot sand"),
                    .init(id: "green_forest", text: "A forest growing above the ice"),
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
                    .init(id: "juno_1521", text: "About 1,521 kilometres away"),
                    .init(id: "juno_15210", text: "About 15,210 kilometres away"),
                    .init(id: "juno_152100", text: "About 152,100 kilometres away"),
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
            QuizChoice(id: "\(destinationID)-au", text: details.au),
            QuizChoice(id: "\(destinationID)-au-earth", text: "1 AU"),
            QuizChoice(id: "\(destinationID)-au-neptune", text: "30 AU"),
        ]
        let lightChoices = [
            QuizChoice(id: "\(destinationID)-light", text: details.lightTime),
            QuizChoice(id: "\(destinationID)-light-short", text: "about 1 second"),
            QuizChoice(id: "\(destinationID)-light-long", text: "about 4 hours"),
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
