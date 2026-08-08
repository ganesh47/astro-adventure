import AstroGameCore
import Foundation

enum SolarSystemExpansionCatalog {
    static var lessons: [DestinationLesson] {
        profiles.map { profile in
            let juniorQuiz = quizzes(for: profile, ageBand: .ages4To6)[0]
            let explorerQuiz = quizzes(for: profile, ageBand: .ages7To9)[0]
            let scientistQuiz = quizzes(for: profile, ageBand: .ages10To12)[0]

            return DestinationLesson(
                id: profile.id,
                displayName: profile.name,
                kind: profile.kind,
                source: LearningSource(
                    title: profile.sourceTitle,
                    url: profile.sourceURL,
                    reviewStatus: "reviewed"
                ),
                content: AgeBandContentSet(
                    ages4To6: AgeBandLessonContent(
                        discoveryText: profile.summary.junior,
                        readAloudText: profile.summary.junior,
                        quiz: juniorQuiz
                    ),
                    ages7To9: AgeBandLessonContent(
                        discoveryText: profile.summary.explorer,
                        quiz: explorerQuiz
                    ),
                    ages10To12: AgeBandLessonContent(
                        discoveryText: profile.summary.scientist,
                        quiz: scientistQuiz
                    )
                )
            )
        }
    }

    static func slides(destinationID: String, ageBand: AgeBand) -> [DiscoverySlide]? {
        guard let profile = profiles.first(where: { $0.id == destinationID }) else {
            return nil
        }

        return [
            card(
                profile: profile,
                id: "identity",
                imageName: profile.portrait.imageName,
                title: profile.id == "sun" || profile.id == "moon"
                    ? "Meet the \(profile.name)"
                    : "Meet \(profile.name)",
                body: profile.summary[ageBand],
                image: profile.portrait,
                facts: [
                    .init(value: profile.kindAnswer, label: "object type"),
                    .init(value: profile.diameter, label: "diameter"),
                ]
            ),
            card(
                profile: profile,
                id: "color",
                imageName: profile.portrait.imageName,
                title: "A world of \(profile.colorShort)",
                body: colorCopy(for: profile, ageBand: ageBand),
                image: profile.portrait,
                facts: [
                    .init(value: profile.colorShort, label: "color clue"),
                    .init(value: profile.colorMaterial, label: "color maker"),
                ]
            ),
            card(
                profile: profile,
                id: "shape",
                imageName: profile.portrait.imageName,
                title: "Gravity shapes a globe",
                body: shapeCopy(for: profile, ageBand: ageBand),
                image: profile.portrait,
                facts: [
                    .init(value: profile.shapeValue, label: "shape clue"),
                    .init(value: profile.diameter, label: "across"),
                ]
            ),
            card(
                profile: profile,
                id: "distance",
                imageName: profile.feature.imageName,
                title: "The AU distance ruler",
                body: distanceCopy(for: profile, ageBand: ageBand),
                image: profile.feature,
                facts: [
                    .init(value: profile.au, label: "from the Sun"),
                    .init(value: profile.distance, label: "average distance"),
                ]
            ),
            card(
                profile: profile,
                id: "light-time",
                imageName: profile.portrait.imageName,
                title: "Racing sunlight",
                body: lightCopy(for: profile, ageBand: ageBand),
                image: profile.portrait,
                facts: [
                    .init(value: profile.lightTime, label: "sunlight trip"),
                    .init(value: "299,792 km/s", label: "speed of light"),
                ]
            ),
            card(
                profile: profile,
                id: "motion",
                imageName: profile.feature.imageName,
                title: "Days and years",
                body: motionCopy(for: profile, ageBand: ageBand),
                image: profile.feature,
                facts: [
                    .init(value: profile.day, label: "one day"),
                    .init(value: profile.year, label: "one year or orbit"),
                ]
            ),
            card(
                profile: profile,
                id: "wonder",
                imageName: profile.feature.imageName,
                title: profile.wonderTitle,
                body: profile.wonder[ageBand],
                image: profile.feature,
                facts: [
                    .init(value: profile.wonderValue, label: profile.wonderLabel),
                    .init(value: profile.mission, label: "explorer mission"),
                ]
            ),
        ]
    }

    static func quizzes(destinationID: String, ageBand: AgeBand) -> [QuizContent]? {
        guard let profile = profiles.first(where: { $0.id == destinationID }) else {
            return nil
        }
        return quizzes(for: profile, ageBand: ageBand)
    }

    private static func quizzes(for profile: DestinationProfile, ageBand: AgeBand) -> [QuizContent]
    {
        let otherProfiles = profiles.filter { $0.id != profile.id }
        return [
            quiz(
                profile: profile,
                concept: "type",
                ageBand: ageBand,
                prompt: "What kind of space object is \(profile.name)?",
                correct: profile.kindAnswer,
                wrong: differentValues(
                    from: otherProfiles.map(\.kindAnswer),
                    excluding: profile.kindAnswer
                ),
                hint: "Look at the object-type badge on the first card."
            ),
            quiz(
                profile: profile,
                concept: "color",
                ageBand: ageBand,
                prompt: "Which color clue belongs to \(profile.name)?",
                correct: profile.colorAnswer,
                wrong: differentValues(
                    from: otherProfiles.map(\.colorAnswer),
                    excluding: profile.colorAnswer
                ),
                hint: "Remember the colors in the NASA portrait."
            ),
            quiz(
                profile: profile,
                concept: "shape",
                ageBand: ageBand,
                prompt: "Why is \(profile.name) round?",
                correct: "Gravity pulls material toward its center",
                wrong: [
                    "Space objects begin as perfect cubes",
                    "Sunlight carves every world into a ball",
                ],
                hint: "Gravity pulls inward from every direction."
            ),
            quiz(
                profile: profile,
                concept: "au",
                ageBand: ageBand,
                prompt: "About how far is \(profile.name) from the Sun?",
                correct: profile.au,
                wrong: differentValues(from: otherProfiles.map(\.au), excluding: profile.au),
                hint: "One AU is the average Sun-to-Earth distance."
            ),
            quiz(
                profile: profile,
                concept: "light",
                ageBand: ageBand,
                prompt: "How long does sunlight take to make this trip?",
                correct: profile.lightTime,
                wrong: differentValues(
                    from: otherProfiles.map(\.lightTime),
                    excluding: profile.lightTime
                ),
                hint: "Farther worlds wait longer for the same ray of sunlight."
            ),
            quiz(
                profile: profile,
                concept: "motion",
                ageBand: ageBand,
                prompt: "Which day-and-year clue matches \(profile.name)?",
                correct: profile.motionAnswer,
                wrong: differentValues(
                    from: otherProfiles.map(\.motionAnswer),
                    excluding: profile.motionAnswer
                ),
                hint: "A day is one spin; a year is one orbit."
            ),
            quiz(
                profile: profile,
                concept: "wonder",
                ageBand: ageBand,
                prompt: "Which amazing feature belongs to \(profile.name)?",
                correct: profile.wonderAnswer,
                wrong: differentValues(
                    from: otherProfiles.map(\.wonderAnswer),
                    excluding: profile.wonderAnswer
                ),
                hint: "Think back to the final wonder card."
            ),
        ]
    }

    private static func quiz(
        profile: DestinationProfile,
        concept: String,
        ageBand: AgeBand,
        prompt: String,
        correct: String,
        wrong: [String],
        hint: String
    ) -> QuizContent {
        let choices = [
            QuizChoice(id: "\(profile.id)-\(concept)-correct", text: correct),
            QuizChoice(id: "\(profile.id)-\(concept)-wrong-1", text: wrong[0]),
            QuizChoice(id: "\(profile.id)-\(concept)-wrong-2", text: wrong[1]),
        ]
        return QuizContent(
            prompt: prompt,
            choices: ageBand == .ages4To6 ? Array(choices.prefix(2)) : choices,
            correctChoiceID: "\(profile.id)-\(concept)-correct",
            correctFeedback: "Cosmic win! \(correct).",
            retryFeedback: "Good try, explorer. Revisit the matching flashcard clue.",
            hint: hint
        )
    }

    private static func differentValues(from values: [String], excluding value: String) -> [String]
    {
        var result: [String] = []
        for candidate in values where candidate != value && !result.contains(candidate) {
            result.append(candidate)
            if result.count == 2 { break }
        }
        return result
    }

    private static func card(
        profile: DestinationProfile,
        id: String,
        imageName: String,
        title: String,
        body: String,
        image: ImageSource,
        facts: [DiscoveryFact]
    ) -> DiscoverySlide {
        DiscoverySlide(
            id: "\(profile.id)-\(id)",
            imageName: imageName,
            title: title,
            body: body,
            narration: "\(title). \(body)",
            credit: image.credit,
            sourceID: image.sourceID,
            facts: facts
        )
    }

    private static func colorCopy(for profile: DestinationProfile, ageBand: AgeBand) -> String {
        switch ageBand {
        case .ages4To6:
            "\(profile.name) looks \(profile.colorShort). \(profile.colorCause)"
        case .ages7To9:
            "NASA images show \(profile.name) in \(profile.colorShort). \(profile.colorCause)"
        case .ages10To12:
            "The visible colors of \(profile.name) come from \(profile.colorMaterial.lowercased()). \(profile.colorScience)"
        }
    }

    private static func shapeCopy(for profile: DestinationProfile, ageBand: AgeBand) -> String {
        switch ageBand {
        case .ages4To6:
            "Gravity pulls from every side, helping \(profile.name) become round."
        case .ages7To9:
            "Gravity pulls material toward the center, shaping \(profile.name) into a globe. \(profile.shapeNote)"
        case .ages10To12:
            "Self-gravity drives large worlds toward hydrostatic equilibrium—a nearly spherical shape. \(profile.shapeNote)"
        }
    }

    private static func distanceCopy(for profile: DestinationProfile, ageBand: AgeBand) -> String {
        switch ageBand {
        case .ages4To6:
            "One AU is the distance from the Sun to Earth. \(profile.name)’s clue is \(profile.au)."
        case .ages7To9:
            "Astronomers use AU as a Solar System ruler. \(profile.name) is about \(profile.au), or \(profile.distance), from the Sun."
        case .ages10To12:
            "An astronomical unit is about 150 million kilometres. \(profile.name)’s average distance is \(profile.au), approximately \(profile.distance)."
        }
    }

    private static func lightCopy(for profile: DestinationProfile, ageBand: AgeBand) -> String {
        switch ageBand {
        case .ages4To6:
            "Light is the fastest traveller we know, but space is huge. The trip takes \(profile.lightTime)."
        case .ages7To9:
            "Sunlight races at almost 300,000 kilometres each second. It still needs \(profile.lightTime) to cover this distance."
        case .ages10To12:
            "At 299,792 kilometres per second, light crosses \(profile.name)’s average Sun-distance in \(profile.lightTime). This is also the minimum one-way radio delay."
        }
    }

    private static func motionCopy(for profile: DestinationProfile, ageBand: AgeBand) -> String {
        switch ageBand {
        case .ages4To6:
            "One spin makes a day. One trip around its partner makes a year or orbit. Here: \(profile.day) and \(profile.year)."
        case .ages7To9:
            "\(profile.name) spins once in \(profile.day). Its full orbit takes \(profile.year)."
        case .ages10To12:
            "The rotation period is \(profile.day), while the orbital period is \(profile.year). \(profile.motionNote)"
        }
    }

    private static let profiles: [DestinationProfile] = [
        DestinationProfile(
            id: "sun", name: "Sun", kind: "star", kindAnswer: "A star",
            sourceTitle: "NASA Science: Sun Facts",
            sourceURL: URL(string: "https://science.nasa.gov/sun/facts/")!,
            portrait: .init(
                imageName: "sun-full-disk", sourceID: "GSFC_20171208_Archive_e002035",
                credit: "NASA/SDO"
            ),
            feature: .init(
                imageName: "sun-prominence", sourceID: "PIA22661",
                credit: "NASA/GSFC/Solar Dynamics Observatory"
            ),
            summary: .init(
                junior:
                    "The Sun is our star—a giant glowing ball that lights and warms every world.",
                explorer:
                    "The Sun is a 4.5-billion-year-old yellow dwarf star whose gravity holds the Solar System together.",
                scientist:
                    "The Sun is a G-type main-sequence star containing about 99.8% of the Solar System’s mass."
            ),
            colorShort: "white, gold and orange", colorMaterial: "glowing plasma",
            colorCause:
                "Its many colors blend into white light, while our air can make it look yellow.",
            colorScience:
                "NASA often assigns colors to invisible wavelengths so solar activity is easier to study.",
            colorAnswer: "White light, often pictured gold or orange",
            shapeValue: "Almost spherical",
            shapeNote: "Different latitudes rotate at different speeds because the Sun is plasma.",
            diameter: "1.4 million km", au: "0 AU", distance: "the Solar System’s center",
            lightTime: "8.3 min to Earth", day: "≈25 days at equator",
            year: "≈230 million years around our galaxy",
            motionNote: "The poles rotate more slowly than the equator.",
            motionAnswer: "A ≈25-day equator spin; a ≈230-million-year galactic orbit",
            wonderTitle: "Loops of glowing plasma",
            wonder: .init(
                junior: "The Sun can stretch giant glowing loops high above its surface.",
                explorer:
                    "Magnetic fields lift solar prominences into enormous arches of hot plasma.",
                scientist:
                    "Prominences trace magnetic field lines through the corona and can erupt into space weather."
            ),
            wonderValue: "4.5 billion yr", wonderLabel: "star age",
            mission: "Solar Dynamics Observatory",
            wonderAnswer: "Magnetic loops and solar prominences"
        ),
        DestinationProfile(
            id: "venus", name: "Venus", kind: "planet", kindAnswer: "A rocky planet",
            sourceTitle: "NASA Science: Venus Facts",
            sourceURL: URL(string: "https://science.nasa.gov/venus/venus-facts/")!,
            portrait: .init(imageName: "venus-global", sourceID: "PIA00271", credit: "NASA/JPL"),
            feature: .init(imageName: "venus-volcano", sourceID: "PIA00272", credit: "NASA/JPL"),
            summary: .init(
                junior:
                    "Venus is a rocky planet wrapped in thick clouds—and it is the hottest planet.",
                explorer:
                    "Venus is nearly Earth-sized, but its thick carbon-dioxide atmosphere traps tremendous heat.",
                scientist:
                    "Venus is an Earth-sized terrestrial planet with a dense CO₂ atmosphere and runaway greenhouse warming."
            ),
            colorShort: "cream and golden yellow", colorMaterial: "sulfuric-acid clouds",
            colorCause: "Thick pale clouds hide the rocky surface below.",
            colorScience:
                "Radar maps use assigned colors because visible cameras cannot see through the global cloud deck.",
            colorAnswer: "Cream and golden clouds",
            shapeValue: "Nearly spherical", shapeNote: "Venus is only slightly smaller than Earth.",
            diameter: "12,104 km", au: "0.72 AU", distance: "108 million km",
            lightTime: "6 min", day: "243 Earth days", year: "225 Earth days",
            motionNote:
                "Venus rotates backward compared with most planets, so its day is longer than its year.",
            motionAnswer: "A 243-day backward spin; a 225-day year",
            wonderTitle: "A hidden volcanic world",
            wonder: .init(
                junior:
                    "Radar lets spacecraft peek through Venus’s clouds and find mountains and volcanoes.",
                explorer:
                    "Magellan mapped volcanoes such as Ushas Mons by bouncing radar through the clouds.",
                scientist:
                    "Magellan radar revealed widespread volcanic landforms beneath Venus’s opaque atmosphere."
            ),
            wonderValue: "≈465°C", wonderLabel: "surface heat", mission: "Magellan",
            wonderAnswer: "Volcanoes hidden beneath thick clouds"
        ),
        DestinationProfile(
            id: "earth", name: "Earth", kind: "planet", kindAnswer: "A rocky planet",
            sourceTitle: "NASA Science: Earth Facts",
            sourceURL: URL(string: "https://science.nasa.gov/earth/facts/")!,
            portrait: .init(
                imageName: "earth-blue-marble", sourceID: "GSFC_20171208_Archive_e001386",
                credit: "NASA/NOAA/GSFC/Suomi NPP"
            ),
            feature: .init(imageName: "earth-aurora", sourceID: "STS047-20-015", credit: "NASA"),
            summary: .init(
                junior:
                    "Earth is our blue home, with oceans, clouds, land and every life-form we know.",
                explorer:
                    "Earth is the largest rocky planet and the only known world with liquid water across its surface.",
                scientist:
                    "Earth is a differentiated terrestrial planet with a nitrogen-oxygen atmosphere, active geology and a global ocean."
            ),
            colorShort: "blue, white, green and brown", colorMaterial: "oceans, clouds and land",
            colorCause: "Blue oceans, white clouds and colorful continents make a changing marble.",
            colorScience:
                "Water, vegetation, minerals, ice and atmospheric scattering produce Earth’s visible palette.",
            colorAnswer: "Blue oceans and white clouds",
            shapeValue: "Slightly squashed sphere",
            shapeNote: "Earth bulges a little at the equator as it spins.",
            diameter: "12,756 km", au: "1 AU", distance: "150 million km",
            lightTime: "8.3 min", day: "23.9 hours", year: "365.25 days",
            motionNote: "Earth’s 23.5-degree tilt creates the seasons.",
            motionAnswer: "A 23.9-hour day; a 365.25-day year",
            wonderTitle: "A living water world",
            wonder: .init(
                junior:
                    "Earth is the only place where we know life exists, and most of its surface is ocean.",
                explorer:
                    "Liquid oceans cover about 71% of Earth, while its magnetic field helps shield the atmosphere.",
                scientist:
                    "Earth’s hydrosphere, atmosphere, magnetic field and plate tectonics support a uniquely active biosphere."
            ),
            wonderValue: "71%", wonderLabel: "ocean cover", mission: "Suomi NPP",
            wonderAnswer: "Surface oceans and known life"
        ),
        DestinationProfile(
            id: "moon", name: "Moon", kind: "moon", kindAnswer: "A moon",
            sourceTitle: "NASA Science: Moon Facts",
            sourceURL: URL(string: "https://science.nasa.gov/moon/facts/")!,
            portrait: .init(
                imageName: "moon-nearside", sourceID: "PIA00302", credit: "NASA/JPL/USGS"),
            feature: .init(imageName: "moon-earth", sourceID: "PIA00405", credit: "NASA/JPL/USGS"),
            summary: .init(
                junior:
                    "The Moon is Earth’s rocky companion, covered with craters and dark plains.",
                explorer:
                    "Earth’s only natural moon preserves billions of years of impact craters and ancient lava plains.",
                scientist:
                    "The Moon is a differentiated rocky satellite whose airless surface records early Solar System impacts."
            ),
            colorShort: "gray, charcoal and bright white", colorMaterial: "rock, dust and sunlight",
            colorCause: "Dark lava plains and brighter cratered highlands make its familiar face.",
            colorScience:
                "Basalt-rich maria are darker than the older, anorthosite-rich lunar highlands.",
            colorAnswer: "Gray rock with dark lava plains",
            shapeValue: "Nearly spherical", shapeNote: "Its gravity is about one-sixth of Earth’s.",
            diameter: "3,475 km", au: "≈1 AU", distance: "travels beside Earth",
            lightTime: "8.3 min from Sun", day: "27.3 Earth days", year: "27.3 days around Earth",
            motionNote: "Synchronous rotation keeps nearly the same lunar side facing Earth.",
            motionAnswer: "A 27.3-day spin and 27.3-day orbit",
            wonderTitle: "A face locked toward Earth",
            wonder: .init(
                junior:
                    "The Moon spins once while it goes around Earth once, so we usually see the same side.",
                explorer:
                    "The Moon is tidally locked: its rotation and orbit take the same amount of time.",
                scientist:
                    "Synchronous rotation is the result of tidal interactions that matched the Moon’s spin to its orbital period."
            ),
            wonderValue: "1.3 sec", wonderLabel: "light to Earth", mission: "Clementine",
            wonderAnswer: "It keeps nearly the same face toward Earth"
        ),
        DestinationProfile(
            id: "jupiter", name: "Jupiter", kind: "planet", kindAnswer: "A gas giant",
            sourceTitle: "NASA Science: Jupiter Facts",
            sourceURL: URL(string: "https://science.nasa.gov/jupiter/jupiter-facts/")!,
            portrait: .init(
                imageName: "jupiter-global", sourceID: "PIA22946",
                credit: "NASA/JPL-Caltech/SwRI/MSSS"
            ),
            feature: .init(
                imageName: "jupiter-red-spot", sourceID: "PIA21395",
                credit: "NASA/JPL-Caltech/SwRI/MSSS"
            ),
            summary: .init(
                junior: "Jupiter is the biggest planet—a giant ball of gas with colorful stripes.",
                explorer:
                    "Jupiter is a hydrogen-and-helium gas giant more than 11 times wider than Earth.",
                scientist:
                    "Jupiter is the Solar System’s most massive planet, with a deep hydrogen-helium atmosphere and powerful magnetosphere."
            ),
            colorShort: "cream, orange, brown and white", colorMaterial: "striped cloud layers",
            colorCause: "Fast winds stretch different clouds into bright and dark bands.",
            colorScience:
                "Ammonia ice, hazes and deeper compounds form belts, zones and richly colored storms.",
            colorAnswer: "Cream, orange and brown cloud bands",
            shapeValue: "Noticeably flattened",
            shapeNote: "Its rapid spin makes the equator bulge.",
            diameter: "139,820 km", au: "5.2 AU", distance: "778 million km",
            lightTime: "43 min", day: "9.9 hours", year: "11.9 Earth years",
            motionNote: "Jupiter has the shortest day of any planet.",
            motionAnswer: "A 9.9-hour day; an 11.9-year orbit",
            wonderTitle: "The Great Red Spot",
            wonder: .init(
                junior: "Jupiter has a giant swirling storm called the Great Red Spot.",
                explorer:
                    "The Great Red Spot is a long-lived storm wider than Earth, with winds circling its center.",
                scientist:
                    "The Great Red Spot is an anticyclonic vortex embedded in Jupiter’s turbulent southern atmosphere."
            ),
            wonderValue: ">Earth", wonderLabel: "storm width", mission: "Juno",
            wonderAnswer: "The giant Great Red Spot storm"
        ),
        DestinationProfile(
            id: "saturn", name: "Saturn", kind: "planet", kindAnswer: "A gas giant",
            sourceTitle: "NASA Science: Saturn Facts",
            sourceURL: URL(string: "https://science.nasa.gov/saturn/facts/")!,
            portrait: .init(
                imageName: "saturn-portrait", sourceID: "PIA06193",
                credit: "NASA/JPL/Space Science Institute"
            ),
            feature: .init(
                imageName: "saturn-earth-smiled", sourceID: "PIA17172",
                credit: "NASA/JPL-Caltech/Space Science Institute"
            ),
            summary: .init(
                junior: "Saturn is a pale golden giant surrounded by bright rings.",
                explorer:
                    "Saturn is the second-largest planet, a hydrogen-helium gas giant with an enormous ring system.",
                scientist:
                    "Saturn is a low-density gas giant whose atmosphere, magnetosphere, rings and moons form a complex planetary system."
            ),
            colorShort: "pale gold, cream and gray", colorMaterial: "clouds and icy rings",
            colorCause:
                "Gentle cloud bands wrap the planet while icy ring pieces shine in sunlight.",
            colorScience:
                "Ammonia clouds and atmospheric haze mute Saturn’s bands; water-ice particles brighten the rings.",
            colorAnswer: "Pale gold clouds and bright icy rings",
            shapeValue: "Very flattened",
            shapeNote: "Saturn’s fast spin and low density create a large equatorial bulge.",
            diameter: "120,500 km", au: "9.5 AU", distance: "1.4 billion km",
            lightTime: "80 min", day: "10.7 hours", year: "29.4 Earth years",
            motionNote: "Its 26.7-degree tilt gives Saturn seasons.",
            motionAnswer: "A 10.7-hour day; a 29.4-year orbit",
            wonderTitle: "Billions of ring pieces",
            wonder: .init(
                junior: "Saturn’s rings are made of countless pieces of ice and rock.",
                explorer:
                    "The rings stretch hundreds of thousands of kilometres but are remarkably thin.",
                scientist:
                    "Billions of orbiting ice-and-rock particles form ringlets, waves and gaps shaped by Saturn’s moons."
            ),
            wonderValue: "≈10 m", wonderLabel: "main-ring thickness", mission: "Cassini",
            wonderAnswer: "A vast system of icy rings"
        ),
        DestinationProfile(
            id: "uranus", name: "Uranus", kind: "planet", kindAnswer: "An ice giant",
            sourceTitle: "NASA Science: Uranus Facts",
            sourceURL: URL(string: "https://science.nasa.gov/uranus/facts/")!,
            portrait: .init(
                imageName: "uranus-global", sourceID: "PIA18182", credit: "NASA/JPL-Caltech"),
            feature: .init(imageName: "uranus-clouds", sourceID: "PIA02963", credit: "NASA/STScI"),
            summary: .init(
                junior: "Uranus is a blue-green ice giant that rolls around the Sun on its side.",
                explorer:
                    "Uranus is an ice giant rich in water, ammonia and methane, with a dramatically tilted axis.",
                scientist:
                    "Uranus is an ice giant with a hydrogen-helium atmosphere, methane absorption and an axial tilt near 98 degrees."
            ),
            colorShort: "pale blue-green", colorMaterial: "methane gas and haze",
            colorCause: "Methane absorbs red light, leaving more blue-green light for us to see.",
            colorScience:
                "Atmospheric methane absorption and aerosols shape Uranus’s subtle cyan appearance.",
            colorAnswer: "Pale blue-green",
            shapeValue: "Slightly flattened",
            shapeNote: "It is nearly round but rotates with its axis tipped almost sideways.",
            diameter: "50,724 km", au: "19.2 AU", distance: "2.9 billion km",
            lightTime: "2 hr 40 min", day: "17.2 hours", year: "84 Earth years",
            motionNote: "Its extreme tilt creates seasons unlike those on any other planet.",
            motionAnswer: "A 17.2-hour day; an 84-year orbit",
            wonderTitle: "The planet on its side",
            wonder: .init(
                junior: "Uranus is tipped so far over that it seems to roll around the Sun.",
                explorer:
                    "Uranus’s axis is tilted about 98 degrees, possibly because of an ancient collision.",
                scientist:
                    "A 97.8-degree obliquity produces extreme seasonal illumination over Uranus’s 84-year orbit."
            ),
            wonderValue: "97.8°", wonderLabel: "axis tilt", mission: "Voyager 2",
            wonderAnswer: "It rotates almost completely on its side"
        ),
        DestinationProfile(
            id: "neptune", name: "Neptune", kind: "planet", kindAnswer: "An ice giant",
            sourceTitle: "NASA Science: Neptune Facts",
            sourceURL: URL(string: "https://science.nasa.gov/neptune/neptune-facts/")!,
            portrait: .init(imageName: "neptune-global", sourceID: "PIA00046", credit: "NASA/JPL"),
            feature: .init(
                imageName: "neptune-storm", sourceID: "ARC-1989-AC89-7044", credit: "NASA/JPL"),
            summary: .init(
                junior: "Neptune is a cold blue ice giant and the farthest planet from the Sun.",
                explorer:
                    "Neptune is the eighth planet, an ice giant with dark storms and the fastest planetary winds.",
                scientist:
                    "Neptune is a remote ice giant whose methane-bearing atmosphere drives powerful jets and transient vortices."
            ),
            colorShort: "blue", colorMaterial: "methane, haze and clouds",
            colorCause: "Methane absorbs red light, while haze and clouds change the shade we see.",
            colorScience:
                "Methane absorption contributes to the blue appearance, while aerosols and image processing affect the displayed hue.",
            colorAnswer: "Blue with bright white clouds",
            shapeValue: "Slightly flattened",
            shapeNote: "Fast rotation makes Neptune bulge slightly at its equator.",
            diameter: "49,244 km", au: "30 AU", distance: "4.5 billion km",
            lightTime: "4 hr 10 min", day: "16.1 hours", year: "165 Earth years",
            motionNote: "Neptune has completed only one full orbit since its 1846 discovery.",
            motionAnswer: "A 16.1-hour day; a 165-year orbit",
            wonderTitle: "The fastest planetary winds",
            wonder: .init(
                junior: "Neptune’s clouds can race faster than a jet airplane.",
                explorer:
                    "Neptune’s winds can exceed 2,000 kilometres per hour and whip around giant storms.",
                scientist:
                    "Supersonic zonal winds and changing dark vortices make Neptune’s atmosphere unusually dynamic."
            ),
            wonderValue: ">2,000 km/h", wonderLabel: "wind speed", mission: "Voyager 2",
            wonderAnswer: "The fastest winds measured on a planet"
        ),
        DestinationProfile(
            id: "pluto", name: "Pluto", kind: "dwarf planet", kindAnswer: "A dwarf planet",
            sourceTitle: "NASA Science: Pluto Facts",
            sourceURL: URL(string: "https://science.nasa.gov/dwarf-planets/pluto/facts/")!,
            portrait: .init(
                imageName: "pluto-global", sourceID: "PIA20658",
                credit: "NASA/Johns Hopkins APL/Southwest Research Institute"
            ),
            feature: .init(
                imageName: "pluto-heart", sourceID: "PIA19718",
                credit: "NASA/Johns Hopkins APL/Southwest Research Institute"
            ),
            summary: .init(
                junior: "Pluto is a small, icy dwarf planet with a giant heart-shaped plain.",
                explorer:
                    "Pluto is a complex Kuiper Belt dwarf planet with mountains, glaciers, haze and five moons.",
                scientist:
                    "Pluto is a differentiated dwarf planet in the Kuiper Belt, with volatile ices, active geology and a thin atmosphere."
            ),
            colorShort: "tan, white and rusty red",
            colorMaterial: "nitrogen ice and reddish tholins",
            colorCause:
                "Different frozen materials and reddish chemicals paint its surprisingly varied surface.",
            colorScience:
                "Nitrogen, methane and carbon-monoxide ices contrast with radiation-processed organic tholins.",
            colorAnswer: "Tan, white and rusty red",
            shapeValue: "Nearly spherical",
            shapeNote: "Pluto is round enough for gravity to classify it as a dwarf planet.",
            diameter: "2,377 km", au: "≈39 AU", distance: "5.9 billion km",
            lightTime: "≈5.5 hours", day: "6.4 Earth days", year: "248 Earth years",
            motionNote: "Its orbit is more tilted and stretched than the eight planets’ orbits.",
            motionAnswer: "A 6.4-day spin; a 248-year orbit",
            wonderTitle: "A heart made of ice",
            wonder: .init(
                junior: "Pluto’s bright heart is a huge plain of frozen nitrogen.",
                explorer:
                    "Sputnik Planitia, the heart’s western half, is a slowly moving nitrogen-ice glacier.",
                scientist:
                    "Convection and glacial flow renew the nitrogen-ice surface of Sputnik Planitia within Tombaugh Regio."
            ),
            wonderValue: "≈1,000 km", wonderLabel: "heart width", mission: "New Horizons",
            wonderAnswer: "A heart-shaped nitrogen-ice plain"
        ),
        DestinationProfile(
            id: "ceres", name: "Ceres", kind: "dwarf planet", kindAnswer: "A dwarf planet",
            sourceTitle: "NASA Science: Ceres Facts",
            sourceURL: URL(string: "https://science.nasa.gov/dwarf-planets/ceres/facts/")!,
            portrait: .init(
                imageName: "ceres-map", sourceID: "PIA20351",
                credit: "NASA/JPL-Caltech/UCLA/MPS/DLR/IDA"
            ),
            feature: .init(
                imageName: "ceres-occator", sourceID: "PIA21398",
                credit: "NASA/JPL-Caltech/UCLA/MPS/DLR/IDA"
            ),
            summary: .init(
                junior:
                    "Ceres is a small dwarf planet hiding among the asteroids between Mars and Jupiter.",
                explorer:
                    "Ceres is the largest object in the asteroid belt and the closest dwarf planet to the Sun.",
                scientist:
                    "Ceres is a water-rich dwarf planet comprising about one-quarter of the asteroid belt’s total mass."
            ),
            colorShort: "charcoal gray with bright spots",
            colorMaterial: "dark rock, ice and salts",
            colorCause: "Most of Ceres is dark, but salty deposits shine inside some craters.",
            colorScience:
                "Hydrated minerals and sodium-carbonate-rich deposits create subtle colors and bright faculae.",
            colorAnswer: "Dark gray with brilliant white spots",
            shapeValue: "Nearly spherical",
            shapeNote: "Gravity made Ceres round, but it never grew into a full-sized planet.",
            diameter: "≈940 km", au: "2.8 AU", distance: "414 million km",
            lightTime: "22 min", day: "9 hours", year: "4.6 Earth years",
            motionNote: "Its small four-degree tilt means Ceres has only mild seasons.",
            motionAnswer: "A 9-hour day; a 4.6-year orbit",
            wonderTitle: "Salt that shines from space",
            wonder: .init(
                junior: "Bright white salt spots sparkle inside Ceres’s Occator Crater.",
                explorer:
                    "Briny water once reached the surface and left reflective salts in Occator Crater.",
                scientist:
                    "Sodium-carbonate-rich faculae indicate geologically recent brine activity within Occator Crater."
            ),
            wonderValue: "92 km", wonderLabel: "Occator width", mission: "Dawn",
            wonderAnswer: "Bright salt deposits in Occator Crater"
        ),
    ]
}

private struct AgeCopy {
    let junior: String
    let explorer: String
    let scientist: String

    subscript(ageBand: AgeBand) -> String {
        switch ageBand {
        case .ages4To6: junior
        case .ages7To9: explorer
        case .ages10To12: scientist
        }
    }
}

private struct ImageSource {
    let imageName: String
    let sourceID: String
    let credit: String
}

private struct DestinationProfile {
    let id: String
    let name: String
    let kind: String
    let kindAnswer: String
    let sourceTitle: String
    let sourceURL: URL
    let portrait: ImageSource
    let feature: ImageSource
    let summary: AgeCopy
    let colorShort: String
    let colorMaterial: String
    let colorCause: String
    let colorScience: String
    let colorAnswer: String
    let shapeValue: String
    let shapeNote: String
    let diameter: String
    let au: String
    let distance: String
    let lightTime: String
    let day: String
    let year: String
    let motionNote: String
    let motionAnswer: String
    let wonderTitle: String
    let wonder: AgeCopy
    let wonderValue: String
    let wonderLabel: String
    let mission: String
    let wonderAnswer: String
}
