import AstroGameCore
import Foundation

public enum PlanetMissionCatalogError: Error, Equatable {
    case missingBundledCatalog
    case duplicateID(String)
    case invalidMission(String)
    case invalidSource(String)
    case invalidImage(String)
    case invalidQuiz(questionID: String, ageBand: AgeBand)
    case incompletePlanetCoverage
}

/// Bundled, reviewed curriculum. Loading is explicit so a corrupt catalog is never silently empty.
public enum PlanetMissionCatalog {
    public static let planetIDs = [
        "mercury", "venus", "earth", "mars", "jupiter", "saturn", "uranus", "neptune",
    ]

    public static func bundled() throws -> [PlanetMission] {
        guard let url = Bundle.module.url(forResource: "planet-missions", withExtension: "json")
        else { throw PlanetMissionCatalogError.missingBundledCatalog }
        return try decode(Data(contentsOf: url))
    }

    public static func missions(destinationID: String) throws -> [PlanetMission] {
        try bundled().filter { $0.destinationID == destinationID }
    }

    public static func decode(_ data: Data) throws -> [PlanetMission] {
        let missions = try JSONDecoder().decode([PlanetMission].self, from: data)
        try validate(missions)
        return missions
    }

    public static func validate(_ missions: [PlanetMission]) throws {
        var ids = Set<String>()
        func insert(_ id: String) throws {
            guard !id.isEmpty, ids.insert(id).inserted else {
                throw PlanetMissionCatalogError.duplicateID(id)
            }
        }
        for mission in missions {
            try insert(mission.id)
            guard planetIDs.contains(mission.destinationID), mission.revision > 0,
                !mission.title.isEmpty, complete(mission.invitation),
                mission.requiredConceptIDs.count == 3,
                Set(mission.requiredConceptIDs).count == 3,
                mission.cards.count == 3, mission.questions.count == 3,
                mission.cards.map(\.conceptID) == mission.requiredConceptIDs,
                mission.questions.map(\.conceptID) == mission.requiredConceptIDs,
                mission.requiredConceptIDs.contains(mission.activity.conceptID),
                !mission.requiredConceptIDs.contains(mission.deepDive.conceptID)
            else { throw PlanetMissionCatalogError.invalidMission(mission.id) }
            for conceptID in mission.requiredConceptIDs { try insert(conceptID) }
            try insert(mission.deepDive.conceptID)
            for card in mission.cards + [mission.deepDive] {
                try insert(card.id)
                guard !card.title.isEmpty, complete(card.body) else {
                    throw PlanetMissionCatalogError.invalidMission(mission.id)
                }
                try validate(card.source, context: card.id)
                try validateImage(card)
            }
            for question in mission.questions {
                try insert(question.id)
                try validate(question.source, context: question.id)
                for band in AgeBand.allCases {
                    try validate(question.content[band], questionID: question.id, ageBand: band)
                    try validate(
                        question.reviewContent[band], questionID: question.id, ageBand: band)
                    guard question.content[band].prompt != question.reviewContent[band].prompt
                    else {
                        throw PlanetMissionCatalogError.invalidQuiz(
                            questionID: question.id, ageBand: band)
                    }
                }
            }
            try insert(mission.activity.id)
            guard !mission.activity.title.isEmpty, !mission.activity.tasks.isEmpty,
                mission.activity.family != .classify || mission.activity.tasks.count >= 2
            else { throw PlanetMissionCatalogError.invalidMission(mission.id) }
            for task in mission.activity.tasks {
                try insert(task.id)
                guard complete(task.prompt), complete(task.hint), complete(task.explanation),
                    approvedImages[task.imageName] != nil, task.options.count == 2,
                    task.options.contains(where: { $0.id == task.correctOptionID })
                else { throw PlanetMissionCatalogError.invalidMission(mission.id) }
                for option in task.options {
                    try insert(option.id)
                    guard complete(option.label), complete(option.outcome), !option.symbol.isEmpty
                    else {
                        throw PlanetMissionCatalogError.invalidMission(mission.id)
                    }
                }
            }
        }
        guard missions.count == 24,
            planetIDs.allSatisfy({ planetID in
                missions.filter { $0.destinationID == planetID }.count == 3
            })
        else { throw PlanetMissionCatalogError.incompletePlanetCoverage }
    }

    private static func complete(_ text: AgeBandText) -> Bool {
        AgeBand.allCases.allSatisfy {
            !text[$0].trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        }
    }

    private static func validate(_ source: LearningSource, context: String) throws {
        let host = source.url.host ?? ""
        guard !source.title.isEmpty, source.reviewStatus == "reviewed",
            source.url.scheme == "https", host == "nasa.gov" || host.hasSuffix(".nasa.gov")
        else { throw PlanetMissionCatalogError.invalidSource(context) }
    }

    private static func validate(
        _ quiz: QuizContent, questionID: String, ageBand: AgeBand
    ) throws {
        let count = ageBand == .ages4To6 ? 2 : 3
        guard !quiz.prompt.isEmpty, !quiz.correctFeedback.isEmpty,
            !quiz.retryFeedback.isEmpty, !quiz.hint.isEmpty,
            quiz.choices.count == count,
            Set(quiz.choices.map(\.id)).count == count,
            Set(quiz.choices.map(\.text)).count == count,
            quiz.choices.allSatisfy({ !$0.id.isEmpty && !$0.text.isEmpty }),
            quiz.choices.contains(where: { $0.id == quiz.correctChoiceID })
        else {
            throw PlanetMissionCatalogError.invalidQuiz(questionID: questionID, ageBand: ageBand)
        }
    }

    private static func validateImage(_ card: MissionCard) throws {
        guard let approved = approvedImages[card.imageName],
            approved.sourceID == card.imageSourceID, approved.credit == card.imageCredit
        else { throw PlanetMissionCatalogError.invalidImage(card.id) }
    }

    // Existing reviewed assets; keep aligned with docs/IMAGE_CREDITS.md. No media is fetched at runtime.
    private static let approvedImages: [String: (sourceID: String, credit: String)] = [
        "mercury-color": (
            "PIA12842",
            "NASA/Johns Hopkins University Applied Physics Laboratory/Carnegie Institution of Washington"
        ),
        "mercury-caloris": (
            "PIA10383",
            "NASA/Johns Hopkins University Applied Physics Laboratory/Carnegie Institution of Washington/Brown University"
        ),
        "mercury-horizon": (
            "PIA10176",
            "NASA/Johns Hopkins University Applied Physics Laboratory/Carnegie Institution of Washington"
        ),
        "mercury-hollows": (
            "PIA19425",
            "NASA/Johns Hopkins University Applied Physics Laboratory/Carnegie Institution of Washington"
        ),
        "mercury-polar-ice": (
            "PIA19247",
            "NASA/Johns Hopkins University Applied Physics Laboratory/Carnegie Institution of Washington"
        ),
        "mars-comparison": ("PIA02570", "NASA/JPL"),
        "mars-landscape": ("PIA18409", "NASA/JPL-Caltech"),
        "mars-canyons": ("PIA02005", "NASA/JPL/MSSS"),
        "mars-olympus": ("PIA02982", "NASA/JPL"),
        "mars-polar-cap": ("PIA01247", "NASA/JPL/STScI"),
        "europa-global": ("PIA16827", "NASA/JPL-Caltech/University of Arizona"),
        "europa-closeup": (
            "PIA25696",
            "Image data: NASA/JPL-Caltech/SwRI/MSSS; image processing: Paul Schenk, CC BY 3.0"
        ),
        "europa-ocean-concept": ("PIA26106", "NASA/JPL-Caltech; artist’s concept"),
        "europa-chaos": ("PIA23871", "NASA/JPL-Caltech/SETI Institute"),
        "europa-juno": (
            "PIA25694",
            "Image data: NASA/JPL-Caltech/SwRI/MSSS; image processing: Brian Swift, CC BY 3.0"
        ),
        "sun-full-disk": ("GSFC_20171208_Archive_e002035", "NASA/Solar Dynamics Observatory"),
        "sun-prominence": ("PIA22661", "NASA/GSFC/Solar Dynamics Observatory"),
        "venus-global": ("PIA00271", "NASA/JPL"),
        "venus-volcano": ("PIA00272", "NASA/JPL"),
        "earth-blue-marble": ("GSFC_20171208_Archive_e001386", "NASA/NOAA/GSFC/Suomi NPP"),
        "earth-aurora": ("STS047-20-015", "NASA"),
        "moon-nearside": ("PIA00302", "NASA/JPL/USGS"),
        "moon-earth": ("PIA00405", "NASA/JPL/USGS"),
        "jupiter-global": (
            "PIA22946",
            "Enhanced image: Kevin M. Gill (CC BY); image data: NASA/JPL-Caltech/SwRI/MSSS"
        ),
        "jupiter-red-spot": (
            "PIA21395",
            "Enhanced image: Kevin M. Gill (CC BY); image data: NASA/JPL-Caltech/SwRI/MSSS"
        ),
        "saturn-portrait": ("PIA06193", "NASA/JPL/Space Science Institute"),
        "saturn-earth-smiled": ("PIA17172", "NASA/JPL-Caltech/Space Science Institute"),
        "uranus-global": ("PIA18182", "NASA/JPL-Caltech"),
        "uranus-clouds": ("PIA02963", "NASA/JPL/STScI"),
        "neptune-global": ("PIA00046", "NASA/JPL"),
        "neptune-storm": ("ARC-1989-AC89-7044", "NASA/JPL"),
        "pluto-global": (
            "PIA20658",
            "NASA/Johns Hopkins University Applied Physics Laboratory/Southwest Research Institute"
        ),
        "pluto-heart": (
            "PIA19718",
            "NASA/Johns Hopkins University Applied Physics Laboratory/Southwest Research Institute"
        ),
        "ceres-map": ("PIA20351", "NASA/JPL-Caltech/UCLA/MPS/DLR/IDA"),
        "ceres-occator": ("PIA21398", "NASA/JPL-Caltech/UCLA/MPS/DLR/IDA"),
        "tech-engine": ("SSC-2015-00064", "NASA/Stennis Space Center"),
        "tech-launch": ("NHQ202211160028", "NASA/Joel Kowsky"),
        "tech-boosters": ("20220721 FSB2 1", "NASA/Northrop Grumman"),
        "tech-iss": ("iss072e316172", "NASA"),
        "tech-satellite": ("GSFC_20171208_Archive_e001696", "NASA/Goddard Space Flight Center"),
        "tech-spacesuit": ("iss054e022823", "NASA"),
        "tech-radio": ("PIA25136", "NASA/JPL-Caltech"),
        "tech-dsn": ("PIA26147", "NASA/JPL-Caltech"),
        "tech-telescope": ("GSFC_20171208_Archive_e002151", "NASA"),
        "tech-rover": ("PIA24542", "NASA/JPL-Caltech/MSSS"),
    ]
}
