import AstroGameCore
import Foundation

enum SpaceTechnologyCatalog {
    static let destinationID = "space-technology-lab"

    static var lessons: [DestinationLesson] {
        let juniorQuiz = quizzes(ageBand: .ages4To6)[0]
        let explorerQuiz = quizzes(ageBand: .ages7To9)[0]
        let scientistQuiz = quizzes(ageBand: .ages10To12)[0]

        return [
            DestinationLesson(
                id: destinationID,
                displayName: "Space Technology Lab",
                kind: "technology lab",
                source: LearningSource(
                    title: "NASA Space Technology and Exploration",
                    url: URL(
                        string: "https://www.nasa.gov/learning-resources/for-kids-and-students/")!,
                    reviewStatus: "reviewed"
                ),
                content: AgeBandContentSet(
                    ages4To6: AgeBandLessonContent(
                        discoveryText:
                            "Meet the amazing machines that blast off, explore space, and help scientists discover the universe.",
                        readAloudText:
                            "Meet the amazing machines that blast off, explore space, and help scientists discover the universe.",
                        quiz: juniorQuiz
                    ),
                    ages7To9: AgeBandLessonContent(
                        discoveryText:
                            "Step inside a lab of rocket engines, orbiting spacecraft, giant antennas, telescopes, and robot explorers.",
                        quiz: explorerQuiz
                    ),
                    ages10To12: AgeBandLessonContent(
                        discoveryText:
                            "Investigate the propulsion, observatories, communications systems, habitats, and robots behind modern space science.",
                        quiz: scientistQuiz
                    )
                )
            )
        ]
    }

    static func slides(ageBand: AgeBand) -> [DiscoverySlide] {
        [
            card(
                id: "rocket-engine",
                imageName: "tech-engine",
                title: "Engines make mighty thrust",
                body: copy(
                    ageBand,
                    junior:
                        "A rocket engine shoots super-hot gas backward. That pushes the rocket forward—whoosh!",
                    explorer:
                        "Rocket engines burn fuel with an oxidizer. Expanding gas races through a nozzle, and the equal push in the other direction creates thrust.",
                    scientist:
                        "A chemical rocket converts propellant energy into fast exhaust. The bell-shaped nozzle accelerates that gas, producing thrust through Newton’s third law."
                ),
                credit: "NASA/Stennis Space Center",
                sourceID: "SSC-2015-00064",
                facts: [
                    .init(value: "9,600 mph", label: "RS-25 exhaust"),
                    .init(value: "Thrust", label: "forward push"),
                ]
            ),
            card(
                id: "launch-vehicle",
                imageName: "tech-launch",
                title: "Launch vehicles carry missions",
                body: copy(
                    ageBand,
                    junior:
                        "A launch vehicle is the whole rocket that carries a spacecraft or satellite away from Earth.",
                    explorer:
                        "A launch vehicle combines engines, tanks, guidance computers, and stages. Its precious passenger—the payload—rides toward space.",
                    scientist:
                        "Launch vehicles integrate propulsion, structures, avionics, and staged flight to accelerate a payload through the atmosphere and toward its required orbit."
                ),
                credit: "NASA/Joel Kowsky",
                sourceID: "NHQ202211160028",
                facts: [
                    .init(value: "Payload", label: "space passenger"),
                    .init(value: "SLS + Orion", label: "Artemis I"),
                ]
            ),
            card(
                id: "boosters-and-stages",
                imageName: "tech-boosters",
                title: "Boosters give an extra shove",
                body: copy(
                    ageBand,
                    junior:
                        "Boosters help a heavy rocket leap off the launch pad. Empty pieces can drop away so the rest is lighter.",
                    explorer:
                        "SLS solid rocket boosters provide most of the push at liftoff. Used stages separate so later engines move less mass.",
                    scientist:
                        "The two SLS solid rocket boosters provide about 75 percent of liftoff thrust. Staging discards empty hardware and improves vehicle efficiency."
                ),
                credit: "NASA/Northrop Grumman",
                sourceID: "20220721 FSB2 1",
                facts: [
                    .init(value: "~75%", label: "SLS liftoff thrust"),
                    .init(value: "Stages", label: "shed empty mass"),
                ]
            ),
            card(
                id: "space-station",
                imageName: "tech-iss",
                title: "The ISS is a flying laboratory",
                body: copy(
                    ageBand,
                    junior:
                        "Astronauts live and do experiments on the International Space Station while it zooms around Earth.",
                    explorer:
                        "The ISS circles Earth about every 90 minutes, so its crew sees roughly 16 sunrises and sunsets each day.",
                    scientist:
                        "The International Space Station is a continuously crewed microgravity laboratory. It completes about 16 Earth orbits per day and supports research from many nations."
                ),
                credit: "NASA",
                sourceID: "iss072e316172",
                facts: [
                    .init(value: "~90 min", label: "one orbit"),
                    .init(value: "16", label: "orbits each day"),
                ]
            ),
            card(
                id: "satellites",
                imageName: "tech-satellite",
                title: "Satellites are orbiting helpers",
                body: copy(
                    ageBand,
                    junior:
                        "Satellites circle worlds. They can watch clouds, make maps, carry messages, and study space.",
                    explorer:
                        "Artificial satellites balance forward speed with gravity to stay in orbit. Antennas share data, while solar panels often supply power.",
                    scientist:
                        "Satellites use instruments to observe Earth or the cosmos. Their antennas exchange data with ground stations and their power commonly comes from solar arrays and batteries."
                ),
                credit: "NASA/Goddard Space Flight Center",
                sourceID: "GSFC_20171208_Archive_e001696",
                facts: [
                    .init(value: "Orbit", label: "repeating path"),
                    .init(value: "2 basics", label: "power + antenna"),
                ]
            ),
            card(
                id: "spacesuits",
                imageName: "tech-spacesuit",
                title: "A spacesuit is a tiny spacecraft",
                body: copy(
                    ageBand,
                    junior:
                        "A spacesuit gives an astronaut air, keeps the right temperature, and protects their body outside a spacecraft.",
                    explorer:
                        "A spacesuit supplies oxygen, removes carbon dioxide, controls temperature, and shields an astronaut during a spacewalk.",
                    scientist:
                        "The Extravehicular Mobility Unit is effectively a one-person spacecraft with pressure, oxygen, cooling, communications, and protective layers."
                ),
                credit: "NASA",
                sourceID: "iss054e022823",
                facts: [
                    .init(value: "EMU", label: "NASA spacesuit"),
                    .init(value: "1 person", label: "mini spacecraft"),
                ]
            ),
            card(
                id: "radio-astronomy",
                imageName: "tech-radio",
                title: "Radio dishes hear invisible light",
                body: copy(
                    ageBand,
                    junior:
                        "Space sends radio waves our eyes cannot see. A giant dish gathers them like a huge listening ear.",
                    explorer:
                        "Radio telescopes collect faint radio waves from planets, stars, gas clouds, and galaxies. Computers turn those signals into discoveries.",
                    scientist:
                        "A radio telescope’s curved reflector concentrates long-wavelength electromagnetic radiation onto a receiver. Multiple dishes can combine their measurements."
                ),
                credit: "NASA/JPL-Caltech",
                sourceID: "PIA25136",
                facts: [
                    .init(value: "34 m", label: "DSS-53 dish"),
                    .init(value: "Radio", label: "invisible light"),
                ]
            ),
            card(
                id: "deep-space-network",
                imageName: "tech-dsn",
                title: "The Deep Space Network calls robots",
                body: copy(
                    ageBand,
                    junior:
                        "Huge antennas send messages to faraway spacecraft and catch their very quiet replies.",
                    explorer:
                        "NASA’s Deep Space Network has antenna sites around Earth. As our planet turns, another site can keep talking with a distant mission.",
                    scientist:
                        "Three Deep Space Network complexes, spaced roughly 120 degrees apart in longitude, provide continuous tracking, commands, and science-data reception."
                ),
                credit: "NASA/JPL-Caltech",
                sourceID: "PIA26147",
                facts: [
                    .init(value: "3 sites", label: "around Earth"),
                    .init(value: "70 m", label: "largest dishes"),
                ]
            ),
            card(
                id: "space-telescopes",
                imageName: "tech-telescope",
                title: "Telescopes reveal hidden light",
                body: copy(
                    ageBand,
                    junior:
                        "Space telescopes float above Earth’s clouds. Their special eyes can spot light people cannot see.",
                    explorer:
                        "Above the atmosphere, Hubble sees crisp visible, ultraviolet, and near-infrared light. Webb specializes in infrared light.",
                    scientist:
                        "Space observatories avoid atmospheric blur and blocked wavelengths. Hubble spans ultraviolet to near-infrared, while Webb probes deeper into infrared."
                ),
                credit: "NASA",
                sourceID: "GSFC_20171208_Archive_e002151",
                facts: [
                    .init(value: "2.4 m", label: "Hubble mirror"),
                    .init(value: "Infrared", label: "Webb specialty"),
                ]
            ),
            card(
                id: "robot-explorers",
                imageName: "tech-rover",
                title: "Robots scout other worlds",
                body: copy(
                    ageBand,
                    junior:
                        "Rovers drive, landers stay in one place, and orbiters fly around a world. They explore places too far away for people.",
                    explorer:
                        "Robotic explorers carry cameras and science tools. Perseverance can make some driving choices because messages take minutes to cross space.",
                    scientist:
                        "Orbiters survey globally, landers investigate one site, and rovers travel across terrain. Onboard autonomy helps robots work despite communication delays."
                ),
                credit: "NASA/JPL-Caltech/MSSS",
                sourceID: "PIA24542",
                facts: [
                    .init(value: "62 photos", label: "rover selfie"),
                    .init(value: "Autonomy", label: "thinks onboard"),
                ]
            ),
        ]
    }

    static func quizzes(ageBand: AgeBand) -> [QuizContent] {
        [
            quiz(
                ageBand: ageBand,
                prompt: "What makes a rocket move forward?",
                choices: [
                    .init(id: "tech_thrust", text: "Fast exhaust pushes backward"),
                    .init(id: "tech_solar_pull", text: "Sunlight pulls it upward"),
                    .init(id: "tech_cloud_bounce", text: "Clouds bounce it into space"),
                ],
                correct: "tech_thrust",
                success: "Thrust master! Backward exhaust creates a forward push.",
                retry: "Think about the hot gas rushing from the engine nozzle.",
                hint: "Every action has an equal push in the other direction."
            ),
            quiz(
                ageBand: ageBand,
                prompt: "What is the payload on a launch vehicle?",
                choices: [
                    .init(id: "tech_payload", text: "The mission carried to space"),
                    .init(id: "tech_launch_smoke", text: "The cloud beside the launch pad"),
                    .init(id: "tech_empty_tank", text: "Only an empty fuel tank"),
                ],
                correct: "tech_payload",
                success:
                    "Cargo captain! The payload is the spacecraft, satellite, or other mission cargo.",
                retry: "Look for the rocket’s important passenger.",
                hint: "Orion was the payload on the Artemis I SLS launch."
            ),
            quiz(
                ageBand: ageBand,
                prompt: "Why do used rocket stages separate?",
                choices: [
                    .init(id: "tech_stage_mass", text: "To stop carrying empty mass"),
                    .init(id: "tech_stage_color", text: "To change the rocket’s color"),
                    .init(id: "tech_stage_sound", text: "To make the rocket quieter"),
                ],
                correct: "tech_stage_mass",
                success:
                    "Stage strategist! Dropping empty hardware makes the remaining vehicle lighter.",
                retry: "Imagine carrying empty backpacks during a race.",
                hint: "Less mass is easier for the next engine to accelerate."
            ),
            quiz(
                ageBand: ageBand,
                prompt: "About how long does the ISS take to orbit Earth?",
                choices: [
                    .init(id: "tech_iss_90", text: "About 90 minutes"),
                    .init(id: "tech_iss_90_days", text: "About 90 days"),
                    .init(id: "tech_iss_9_years", text: "About 9 years"),
                ],
                correct: "tech_iss_90",
                success: "Orbit expert! The ISS races around Earth in about 90 minutes.",
                retry: "The station can circle Earth many times in one day.",
                hint: "It completes roughly 16 orbits every day."
            ),
            quiz(
                ageBand: ageBand,
                prompt: "Which two things do most artificial satellites need?",
                choices: [
                    .init(id: "tech_satellite_parts", text: "A power source and an antenna"),
                    .init(id: "tech_satellite_wings", text: "Feathers and flapping wings"),
                    .init(id: "tech_satellite_sails", text: "A sailboat mast and anchor"),
                ],
                correct: "tech_satellite_parts",
                success:
                    "Satellite specialist! Power runs the spacecraft and antennas share information.",
                retry: "Think about energy and talking with Earth.",
                hint: "Solar panels can provide one of the two."
            ),
            quiz(
                ageBand: ageBand,
                prompt: "Why is a spacesuit like a tiny spacecraft?",
                choices: [
                    .init(id: "tech_suit_life", text: "It provides life support and protection"),
                    .init(id: "tech_suit_wings", text: "It has wings for flying to planets"),
                    .init(id: "tech_suit_room", text: "It has bedrooms for a whole crew"),
                ],
                correct: "tech_suit_life",
                success: "Spacewalk star! A suit brings pressure, oxygen, cooling, and protection.",
                retry: "An astronaut needs air and safe temperature outside.",
                hint: "The suit keeps one person alive in the vacuum of space."
            ),
            quiz(
                ageBand: ageBand,
                prompt: "What does a radio telescope collect?",
                choices: [
                    .init(id: "tech_radio_waves", text: "Invisible radio waves from space"),
                    .init(id: "tech_radio_rain", text: "Raindrops from nearby clouds"),
                    .init(id: "tech_radio_rocks", text: "Rocks that fall beside the dish"),
                ],
                correct: "tech_radio_waves",
                success:
                    "Cosmic listener! Radio waves are invisible light carrying clues from space.",
                retry: "The dish gathers a kind of light our eyes cannot see.",
                hint: "It is right there in the name: radio astronomy."
            ),
            quiz(
                ageBand: ageBand,
                prompt: "Why does the Deep Space Network use three sites around Earth?",
                choices: [
                    .init(id: "tech_dsn_rotation", text: "To stay in touch as Earth rotates"),
                    .init(id: "tech_dsn_weather", text: "To make identical weather everywhere"),
                    .init(id: "tech_dsn_gravity", text: "To turn off Earth’s gravity"),
                ],
                correct: "tech_dsn_rotation",
                success: "Signal secured! Another antenna site can take over as Earth turns.",
                retry: "Remember that Earth keeps spinning beneath the antennas.",
                hint: "The three sites are spread around the globe."
            ),
            quiz(
                ageBand: ageBand,
                prompt: "What is a big advantage of a telescope in space?",
                choices: [
                    .init(id: "tech_telescope_air", text: "It observes above Earth’s atmosphere"),
                    .init(id: "tech_telescope_near", text: "It moves every star closer"),
                    .init(id: "tech_telescope_day", text: "It makes a day last one year"),
                ],
                correct: "tech_telescope_air",
                success:
                    "Telescope triumph! Space avoids atmospheric blur and blocked wavelengths.",
                retry: "Think about clouds and moving air above a ground telescope.",
                hint: "Hubble orbits above the atmosphere."
            ),
            quiz(
                ageBand: ageBand,
                prompt: "Which robot can travel across another world’s surface?",
                choices: [
                    .init(id: "tech_rover_drive", text: "A rover"),
                    .init(id: "tech_orbiter_stay", text: "An orbiter parked on the ground"),
                    .init(id: "tech_dish_drive", text: "A radio dish"),
                ],
                correct: "tech_rover_drive",
                success: "Rover ready! Wheels let a rover investigate more than one spot.",
                retry: "Choose the explorer built to drive.",
                hint: "Perseverance is this kind of Mars robot."
            ),
        ]
    }

    private static func card(
        id: String,
        imageName: String,
        title: String,
        body: String,
        credit: String,
        sourceID: String,
        facts: [DiscoveryFact]
    ) -> DiscoverySlide {
        DiscoverySlide(
            id: "technology-\(id)",
            imageName: imageName,
            title: title,
            body: body,
            narration: body,
            credit: credit,
            sourceID: sourceID,
            facts: facts
        )
    }

    private static func copy(
        _ ageBand: AgeBand,
        junior: String,
        explorer: String,
        scientist: String
    ) -> String {
        switch ageBand {
        case .ages4To6: junior
        case .ages7To9: explorer
        case .ages10To12: scientist
        }
    }

    private static func quiz(
        ageBand: AgeBand,
        prompt: String,
        choices: [QuizChoice],
        correct: String,
        success: String,
        retry: String,
        hint: String
    ) -> QuizContent {
        QuizContent(
            prompt: prompt,
            choices: ageBand == .ages4To6 ? Array(choices.prefix(2)) : choices,
            correctChoiceID: correct,
            correctFeedback: success,
            retryFeedback: retry,
            hint: hint
        )
    }
}
