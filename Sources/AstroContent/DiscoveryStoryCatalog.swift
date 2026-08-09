import AstroGameCore
import Foundation

public struct DiscoveryFact: Equatable, Sendable {
    public let value: String
    public let label: String

    public init(value: String, label: String) {
        self.value = value
        self.label = label
    }
}

public struct DiscoverySlide: Equatable, Identifiable, Sendable {
    public let id: String
    public let imageName: String
    public let title: String
    public let body: String
    public let narration: String
    public let credit: String
    public let sourceID: String
    public let facts: [DiscoveryFact]

    public init(
        id: String,
        imageName: String,
        title: String,
        body: String,
        narration: String,
        credit: String,
        sourceID: String,
        facts: [DiscoveryFact] = []
    ) {
        self.id = id
        self.imageName = imageName
        self.title = title
        self.body = body
        self.narration = narration
        self.credit = credit
        self.sourceID = sourceID
        self.facts = facts
    }
}

public enum DiscoveryStoryCatalog {
    public static func slides(
        destinationID: String,
        ageBand: AgeBand
    ) -> [DiscoverySlide] {
        switch destinationID {
        case SpaceTechnologyCatalog.destinationID:
            SpaceTechnologyCatalog.slides(ageBand: ageBand)
        case "mercury":
            mercurySlides(for: ageBand) + distanceSlides(for: "mercury", ageBand: ageBand)
        case "mars":
            marsSlides(for: ageBand) + distanceSlides(for: "mars", ageBand: ageBand)
        case "europa":
            europaSlides(for: ageBand) + distanceSlides(for: "europa", ageBand: ageBand)
        default:
            SolarSystemExpansionCatalog.slides(
                destinationID: destinationID,
                ageBand: ageBand
            ) ?? []
        }
    }

    private static func mercurySlides(for ageBand: AgeBand) -> [DiscoverySlide] {
        [
            slide(
                id: "mercury-colors",
                imageName: "mercury-color",
                title: "Mercury in surprising colors",
                body: copy(
                    for: ageBand,
                    junior:
                        "Mercury looks gray to our eyes. Special camera colors help us spot different kinds of rock.",
                    explorer:
                        "MESSENGER used special color filters to reveal differences between Mercury’s ancient rocks.",
                    scientist:
                        "Enhanced-color images combine several wavelengths. The colors help scientists map minerals and the ages of Mercury’s surface."
                ),
                credit:
                    "NASA/Johns Hopkins APL/Carnegie Institution of Washington",
                sourceID: "PIA12842"
            ),
            slide(
                id: "mercury-hollows",
                imageName: "mercury-hollows",
                title: "Mysterious bright hollows",
                body: copy(
                    for: ageBand,
                    junior:
                        "Mercury has shallow, bright pits called hollows. Scientists think some rock slowly escaped into space.",
                    explorer:
                        "MESSENGER discovered bright, shallow hollows unlike features seen on other planets. This view covers about 17 kilometres.",
                    scientist:
                        "Mercury’s hollows may form when volatile materials escape from exposed rock. This MESSENGER scene spans roughly 17 kilometres."
                ),
                credit:
                    "NASA/Johns Hopkins APL/Carnegie Institution of Washington",
                sourceID: "PIA19425"
            ),
            slide(
                id: "mercury-caloris",
                imageName: "mercury-caloris",
                title: "A giant crash mark",
                body: copy(
                    for: ageBand,
                    junior:
                        "A huge space rock once hit Mercury and made the enormous round Caloris Basin.",
                    explorer:
                        "Caloris is one of the largest impact basins in the solar system. It stretches about 1,550 kilometres across.",
                    scientist:
                        "The Caloris impact released tremendous energy and formed a basin roughly 1,550 kilometres wide, surrounded by rings of mountains."
                ),
                credit:
                    "NASA/Johns Hopkins APL/Carnegie Institution of Washington/Brown University",
                sourceID: "PIA10383"
            ),
            slide(
                id: "mercury-horizon",
                imageName: "mercury-horizon",
                title: "Hot days, freezing nights",
                body: copy(
                    for: ageBand,
                    junior:
                        "Mercury is close to the Sun, but its nights can be freezing because it has almost no air to hold warmth.",
                    explorer:
                        "Mercury has almost no atmosphere to spread heat around. Its sunny side can be extremely hot while night becomes bitterly cold.",
                    scientist:
                        "With only a very thin exosphere, Mercury cannot retain or circulate heat. Surface temperatures swing by hundreds of degrees."
                ),
                credit:
                    "NASA/Johns Hopkins APL/Carnegie Institution of Washington",
                sourceID: "PIA10176"
            ),
            slide(
                id: "mercury-polar-ice",
                imageName: "mercury-polar-ice",
                title: "Ice beside the hot Sun",
                body: copy(
                    for: ageBand,
                    junior:
                        "Some deep craters near Mercury’s poles never see sunlight. Water ice can stay frozen inside their shadows.",
                    explorer:
                        "Mercury is hot, yet permanently shadowed polar craters can remain colder than −173°C—cold enough to protect water ice.",
                    scientist:
                        "MESSENGER found evidence for water ice in permanently shadowed polar craters where maximum surface temperatures remain below about 100 kelvin."
                ),
                credit:
                    "NASA/Johns Hopkins APL/Carnegie Institution of Washington",
                sourceID: "PIA19247"
            ),
        ]
    }

    private static func marsSlides(for ageBand: AgeBand) -> [DiscoverySlide] {
        [
            slide(
                id: "mars-size",
                imageName: "mars-comparison",
                title: "Earth’s smaller neighbour",
                body: copy(
                    for: ageBand,
                    junior:
                        "Mars is much smaller than Earth. About two Mars-sized balls could fit across Earth.",
                    explorer:
                        "Mars is about half Earth’s diameter. It has land, seasons, polar ice caps and weather, but a much thinner atmosphere.",
                    scientist:
                        "Mars is roughly 53 percent of Earth’s diameter and has about 38 percent of Earth’s surface gravity."
                ),
                credit: "NASA/JPL",
                sourceID: "PIA02570"
            ),
            slide(
                id: "mars-surface",
                imageName: "mars-landscape",
                title: "A robot’s view from the ground",
                body: copy(
                    for: ageBand,
                    junior:
                        "NASA’s Curiosity rover took many pictures and joined them together so we can look around Mars.",
                    explorer:
                        "Curiosity photographed this rocky landscape near Hidden Valley. Rovers are our robot explorers on the Martian surface.",
                    scientist:
                        "This 360-degree mosaic lets scientists study layers, sand and rock shapes around Curiosity’s route near Hidden Valley."
                ),
                credit: "NASA/JPL-Caltech",
                sourceID: "PIA18409"
            ),
            slide(
                id: "mars-olympus",
                imageName: "mars-olympus",
                title: "The solar system’s giant volcano",
                body: copy(
                    for: ageBand,
                    junior:
                        "Olympus Mons is a huge volcano on Mars. It is much taller than any mountain on Earth.",
                    explorer:
                        "Olympus Mons is about 600 kilometres wide. Its summit rises roughly 24 kilometres above the surrounding plains.",
                    scientist:
                        "Olympus Mons is a vast shield volcano about 600 kilometres in diameter, with a summit caldera around 24 kilometres above the surrounding plains."
                ),
                credit: "NASA/JPL",
                sourceID: "PIA02982"
            ),
            slide(
                id: "mars-canyons",
                imageName: "mars-canyons",
                title: "A canyon across a planet",
                body: copy(
                    for: ageBand,
                    junior:
                        "Mars has a giant canyon called Valles Marineris. It is much longer than any canyon on Earth.",
                    explorer:
                        "Valles Marineris stretches for about 4,000 kilometres—nearly a quarter of the way around Mars.",
                    scientist:
                        "Valles Marineris is a vast tectonic canyon system about 4,000 kilometres long, with landslides and layered walls."
                ),
                credit: "NASA/JPL/MSSS",
                sourceID: "PIA02005"
            ),
            slide(
                id: "mars-polar-cap",
                imageName: "mars-polar-cap",
                title: "A polar cap that changes",
                body: copy(
                    for: ageBand,
                    junior:
                        "Mars has icy caps at its north and south poles. They grow in winter and shrink when spring arrives.",
                    explorer:
                        "Hubble watched Mars’s north polar cap shrink between October 1996 and March 1997 as the northern spring warmed it.",
                    scientist:
                        "Mars’s polar caps contain water ice and seasonal carbon-dioxide frost. These Hubble views record the northern cap retreating across one Martian season."
                ),
                credit: "NASA/JPL/STScI",
                sourceID: "PIA01247"
            ),
        ]
    }

    private static func europaSlides(for ageBand: AgeBand) -> [DiscoverySlide] {
        [
            slide(
                id: "europa-world",
                imageName: "europa-global",
                title: "Jupiter’s icy moon",
                body: copy(
                    for: ageBand,
                    junior:
                        "Europa is a bright, icy moon that travels around giant Jupiter.",
                    explorer:
                        "Europa is one of Jupiter’s largest moons. Its bright surface is mostly water ice crossed by reddish lines.",
                    scientist:
                        "Europa is a Galilean moon with a young, water-ice surface. Long bands and ridges record movement in its icy shell."
                ),
                credit: "NASA/JPL-Caltech/University of Arizona",
                sourceID: "PIA16827"
            ),
            slide(
                id: "europa-cracks",
                imageName: "europa-closeup",
                title: "Ice that bends and breaks",
                body: copy(
                    for: ageBand,
                    junior:
                        "Europa’s ice is covered in cracks and ridges. The moon’s surface is always changing very slowly.",
                    explorer:
                        "Juno’s close-up view shows ridges, grooves and disrupted ice. Jupiter’s gravity squeezes and flexes Europa.",
                    scientist:
                        "Tidal forces from Jupiter stress Europa’s shell, producing intersecting lineae, ridges and areas of disrupted terrain."
                ),
                credit:
                    "NASA/JPL-Caltech/SwRI/MSSS; processing: Paul Schenk, CC BY 3.0",
                sourceID: "PIA25696"
            ),
            slide(
                id: "europa-chaos",
                imageName: "europa-chaos",
                title: "A jigsaw puzzle of ice",
                body: copy(
                    for: ageBand,
                    junior:
                        "Some pieces of Europa’s icy surface have broken, tilted and turned like pieces in a giant puzzle.",
                    explorer:
                        "Scientists call this chaos terrain. Galileo photographed broken and rotated ice blocks in a region about 300 kilometres across.",
                    scientist:
                        "Europa’s chaos terrain contains disrupted, rotated crustal blocks beside ridged plains. This reprocessed Galileo view spans about 300 kilometres."
                ),
                credit: "NASA/JPL-Caltech/SETI Institute",
                sourceID: "PIA23871"
            ),
            slide(
                id: "europa-ocean",
                imageName: "europa-ocean-concept",
                title: "Searching beneath the ice",
                body: copy(
                    for: ageBand,
                    junior:
                        "Scientists think a salty ocean may hide under Europa’s ice. A spacecraft will listen for clues below the surface.",
                    explorer:
                        "Europa Clipper will use radar to investigate the icy shell. Evidence suggests a deep, salty ocean lies underneath.",
                    scientist:
                        "Europa Clipper’s ice-penetrating radar will study the shell’s structure and search for interfaces that may reveal water beneath it."
                ),
                credit: "NASA/JPL-Caltech · Artist’s concept",
                sourceID: "PIA26106"
            ),
            slide(
                id: "europa-juno",
                imageName: "europa-juno",
                title: "Juno searches the edge",
                body: copy(
                    for: ageBand,
                    junior:
                        "NASA’s Juno spacecraft looked closely at Europa’s edge to search for icy eruptions. It did not spot one this time.",
                    explorer:
                        "Juno captured this view from 1,521 kilometres away in 2022. Scientists enhanced it to search for eruptions along Europa’s edge.",
                    scientist:
                        "During its 2022 flyby, Juno imaged Europa from 1,521 kilometres away. Contrast processing revealed topography but no active eruption."
                ),
                credit:
                    "NASA/JPL-Caltech/SwRI/MSSS; processing: Brian Swift, CC BY 3.0",
                sourceID: "PIA25694"
            ),
        ]
    }

    private static func slide(
        id: String,
        imageName: String,
        title: String,
        body: String,
        credit: String,
        sourceID: String
    ) -> DiscoverySlide {
        DiscoverySlide(
            id: id,
            imageName: imageName,
            title: title,
            body: body,
            narration: "\(title). \(body)",
            credit: credit,
            sourceID: sourceID,
            facts: facts(for: id)
        )
    }

    private static func facts(for slideID: String) -> [DiscoveryFact] {
        switch slideID {
        case "mercury-colors":
            [
                .init(value: "1st", label: "planet from Sun"),
                .init(value: "4,880 km", label: "diameter"),
            ]
        case "mercury-caloris":
            [
                .init(value: "1,550 km", label: "basin width"),
                .init(value: "88 days", label: "one Mercury year"),
            ]
        case "mercury-hollows":
            [
                .init(value: "17 km", label: "image width"),
                .init(value: "2015", label: "MESSENGER view"),
            ]
        case "mercury-horizon":
            [
                .init(value: "430°C", label: "hot daytime"),
                .init(value: "−180°C", label: "cold nighttime"),
            ]
        case "mercury-polar-ice":
            [
                .init(value: "<−173°C", label: "cold crater"),
                .init(value: "H₂O", label: "hidden ice"),
            ]
        case "mars-size":
            [
                .init(value: "53%", label: "of Earth’s diameter"),
                .init(value: "38%", label: "of Earth’s gravity"),
            ]
        case "mars-surface":
            [
                .init(value: "360°", label: "rover panorama"),
                .init(value: "2", label: "small moons"),
            ]
        case "mars-canyons":
            [
                .init(value: "≈4,000 km", label: "canyon length"),
                .init(value: "¼", label: "around Mars"),
            ]
        case "mars-olympus":
            [
                .init(value: "600 km", label: "volcano width"),
                .init(value: "24 km", label: "summit height"),
            ]
        case "mars-polar-cap":
            [
                .init(value: "1996–97", label: "Hubble views"),
                .init(value: "2", label: "kinds of ice"),
            ]
        case "europa-world":
            [
                .init(value: "3,122 km", label: "diameter"),
                .init(value: "3.5 days", label: "orbit of Jupiter"),
            ]
        case "europa-cracks":
            [
                .init(value: "671,000 km", label: "from Jupiter"),
                .init(value: "1", label: "icy shell"),
            ]
        case "europa-ocean":
            [
                .init(value: "2024", label: "Clipper launched"),
                .init(value: "49", label: "planned flybys"),
            ]
        case "europa-chaos":
            [
                .init(value: "300 km", label: "image width"),
                .init(value: "1998", label: "Galileo flyby"),
            ]
        case "europa-juno":
            [
                .init(value: "1,521 km", label: "Juno distance"),
                .init(value: "2022", label: "close flyby"),
            ]
        default:
            []
        }
    }

    private static func copy(
        for ageBand: AgeBand,
        junior: String,
        explorer: String,
        scientist: String
    ) -> String {
        switch ageBand {
        case .ages4To6:
            junior
        case .ages7To9:
            explorer
        case .ages10To12:
            scientist
        }
    }

    private static func distanceSlides(
        for destinationID: String,
        ageBand: AgeBand
    ) -> [DiscoverySlide] {
        let details:
            (
                name: String, image: String, credit: String, sourceID: String,
                au: String, distance: String, lightTime: String
            )
        switch destinationID {
        case "mercury":
            details = (
                "Mercury", "mercury-color",
                "NASA/Johns Hopkins APL/Carnegie Institution of Washington", "PIA12842",
                "0.39 AU", "58 million km", "3.2 min"
            )
        case "mars":
            details = (
                "Mars", "mars-comparison", "NASA/JPL", "PIA02570",
                "1.52 AU", "228 million km", "12.7 min"
            )
        default:
            details = (
                "Europa", "europa-global", "NASA/JPL-Caltech/University of Arizona",
                "PIA16827", "≈5.2 AU", "≈778 million km", "≈43 min"
            )
        }

        let distanceBody = copy(
            for: ageBand,
            junior:
                "One AU is the distance from the Sun to Earth. \(details.name)’s clue is \(details.au).",
            explorer:
                "Astronomers use AU as a Solar System ruler. \(details.name) is about \(details.au), or \(details.distance), from the Sun.",
            scientist:
                "An astronomical unit is about 150 million kilometres. \(details.name)’s average solar distance is \(details.au), approximately \(details.distance)."
        )
        let lightBody = copy(
            for: ageBand,
            junior:
                "Light is the fastest traveller we know, but space is huge. Sunlight needs \(details.lightTime) to reach \(details.name).",
            explorer:
                "Sunlight races at almost 300,000 kilometres each second. It still takes \(details.lightTime) to reach \(details.name).",
            scientist:
                "At 299,792 kilometres per second, light crosses \(details.name)’s average solar distance in \(details.lightTime)—also the minimum one-way radio delay."
        )

        return [
            DiscoverySlide(
                id: "\(destinationID)-distance",
                imageName: details.image,
                title: "The AU distance ruler",
                body: distanceBody,
                narration: "The AU distance ruler. \(distanceBody)",
                credit: details.credit,
                sourceID: details.sourceID,
                facts: [
                    .init(value: details.au, label: "from the Sun"),
                    .init(value: details.distance, label: "average distance"),
                ]
            ),
            DiscoverySlide(
                id: "\(destinationID)-light-time",
                imageName: details.image,
                title: "Racing sunlight",
                body: lightBody,
                narration: "Racing sunlight. \(lightBody)",
                credit: details.credit,
                sourceID: details.sourceID,
                facts: [
                    .init(value: details.lightTime, label: "sunlight trip"),
                    .init(value: "299,792 km/s", label: "speed of light"),
                ]
            ),
        ]
    }
}
