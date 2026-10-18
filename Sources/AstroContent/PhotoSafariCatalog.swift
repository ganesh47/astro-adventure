import AstroGameCore

/// All images are bundled, credited NASA assets already registered in the asset manifest.
public enum PhotoSafariCatalog {
    public static let safaris: [PhotoSafari] = [mercury, mars, saturn]

    public static func safari(destinationID: String) -> PhotoSafari? {
        safaris.first { $0.destinationID == destinationID }
    }

    private static let mercuryHorizon = photo(
        "mercury-horizon", "A rocky, cratered horizon", "PIA10176",
        "NASA/Johns Hopkins APL/Carnegie Institution of Washington",
        "MESSENGER spacecraft image of Mercury's cratered surface.")
    private static let caloris = photo(
        "mercury-caloris", "A giant crater outline", "PIA10383",
        "NASA/Johns Hopkins APL/Carnegie Institution of Washington/Brown University",
        "Annotated spacecraft mosaic. Dashed lines mark the Caloris basin; they are not on Mercury."
    )
    private static let hollows = photo(
        "mercury-hollows", "Bright patches on rocky ground", "PIA19425",
        "NASA/Johns Hopkins APL/Carnegie Institution of Washington",
        "MESSENGER spacecraft image showing bright areas around hollows on Mercury.")
    private static let rover = photo(
        "tech-rover", "A robot with wheels", "PIA24542", "NASA/JPL-Caltech/MSSS",
        "Perseverance and Ingenuity on Mars. This selfie combines 62 camera images.")
    private static let landscape = photo(
        "mars-landscape", "A wide, rocky landscape", "PIA18409", "NASA/JPL-Caltech",
        "A rover panorama stitched from camera images. Black gaps contain no image data.")
    private static let polarCap = photo(
        "mars-polar-cap", "A white cap on Mars", "PIA01247", "NASA/JPL/STScI",
        "Hubble image mosaics projected above Mars's north pole, comparing three dates in 1996–1997."
    )
    private static let rings = photo(
        "saturn-portrait", "Rings around Saturn", "PIA06193", "NASA/JPL/Space Science Institute",
        "A Cassini spacecraft view of Saturn and its rings.")
    private static let nightSaturn = photo(
        "saturn-earth-smiled", "A dark planet with glowing rings", "PIA17172",
        "NASA/JPL-Caltech/Space Science Institute",
        "The Day the Earth Smiled: a Cassini image mosaic from Saturn's shadow, July 19, 2013.")
    private static let earth = SpacePhoto(
        id: "earth-blue-marble", title: "Our blue and white home", imageName: "earth-blue-marble",
        credit: "NASA/NOAA/GSFC/Suomi NPP",
        sourceURL: "https://images.nasa.gov/details/GSFC_20171208_Archive_e001386",
        caption:
            "Blue Marble: a composite made from satellite observations, not a single camera exposure."
    )

    private static let mercury = PhotoSafari(
        id: "mercury-photo-safari", destinationID: "mercury", title: "Mercury Photo Safari",
        stops: [
            PhotoSafariStop(
                id: "mercury-photo-craters", title: "Round marks in the ground",
                clue: ExplorationText("Find the rocky ground covered in round crater marks."),
                hint: ExplorationText("Look for lots of round dips in the grey ground."),
                photos: [mercuryHorizon, rings], discoveryPhotoID: mercuryHorizon.id,
                fact: ExplorationText(
                    "Those round dips are craters! Space rocks hit Mercury and left marks.",
                    "Space-rock impacts made these craters. The camera helps us explore Mercury from far away.",
                    "Mercury's craters record impacts. This spacecraft image shows their shapes and overlapping edges; it is not a picture taken from the ground."
                )
            ),
            PhotoSafariStop(
                id: "mercury-photo-basin", title: "A really big crater",
                clue: ExplorationText("Find the giant round outline drawn on a rocky world."),
                hint: ExplorationText(
                    "Look for the big dashed circle. Scientists added it to the picture."),
                photos: [rover, caloris], discoveryPhotoID: caloris.id,
                fact: ExplorationText(
                    "A huge space-rock crash made this basin. The drawn circle helps us find it.",
                    "This is Mercury's Caloris impact basin. Scientists drew the dashed lines to help show its outline.",
                    "The annotated mosaic outlines the Caloris impact basin. The lines are explanatory graphics over real spacecraft images, not physical markings on Mercury."
                )
            ),
            PhotoSafariStop(
                id: "mercury-photo-hollows", title: "Bright little patches",
                clue: ExplorationText("Find bright little patches on rocky ground."),
                hint: ExplorationText("Look for pale patches beside small dark dips."),
                photos: [hollows, earth], discoveryPhotoID: hollows.id,
                fact: ExplorationText(
                    "The bright patches are near little dips called hollows. Mercury still has mysteries!",
                    "MESSENGER found shallow hollows with bright areas around them. Scientists are still investigating how they form.",
                    "These bright areas accompany Mercury's shallow hollows. Volatile loss is one explanation under investigation; the image alone does not establish the complete formation process."
                )
            ),
        ])

    private static let mars = PhotoSafari(
        id: "mars-photo-safari", destinationID: "mars", title: "Mars Photo Safari",
        stops: [
            PhotoSafariStop(
                id: "mars-photo-rover", title: "Meet a real space robot",
                clue: ExplorationText("Find the robot with wheels on Mars."),
                hint: ExplorationText("Look for wheels, a tall camera mast, and a robot body."),
                photos: [mercuryHorizon, rover], discoveryPhotoID: rover.id,
                fact: ExplorationText(
                    "This robot is Perseverance! It took a selfie on Mars. A little helicopter is nearby.",
                    "Perseverance explores Mars with wheels, cameras, and science tools. Its selfie also shows the Ingenuity helicopter.",
                    "Perseverance's April 2021 selfie includes Ingenuity. The rover assembled the view from 62 camera images; the camera arm is omitted by the mosaic process."
                )
            ),
            PhotoSafariStop(
                id: "mars-photo-landscape", title: "Look around on Mars",
                clue: ExplorationText(
                    "Find the wide picture of rocky ground stretching to the horizon."),
                hint: ExplorationText(
                    "Look for a long strip of ground with rocks and rover parts."),
                photos: [landscape, rings], discoveryPhotoID: landscape.id,
                fact: ExplorationText(
                    "A rover took pictures all around itself. Together they make a big rocky view!",
                    "A panorama joins many camera pictures into one wide view. The rocks help scientists study the rover's surroundings.",
                    "This Mars rover panorama stitches multiple camera frames together. The black areas are gaps in the mosaic, not holes in the Martian landscape."
                )
            ),
            PhotoSafariStop(
                id: "mars-photo-ice", title: "A chilly white cap",
                clue: ExplorationText("Find the pictures of Mars wearing a white polar cap."),
                hint: ExplorationText("Look for three round views with a bright white middle."),
                photos: [nightSaturn, polarCap], discoveryPhotoID: polarCap.id,
                fact: ExplorationText(
                    "Mars has ice near its poles! These pictures show its bright cap at different times.",
                    "These Hubble views compare Mars's north polar cap at different times. Its seasonal ice changes through the year.",
                    "These projected Hubble mosaics compare Mars's north polar cap in 1996–1997. Seasonal carbon-dioxide frost changes over the polar region, which also contains water ice."
                )
            ),
        ])

    private static let saturn = PhotoSafari(
        id: "saturn-photo-safari", destinationID: "saturn", title: "Saturn Photo Safari",
        stops: [
            PhotoSafariStop(
                id: "saturn-photo-rings", title: "A planet wearing rings",
                clue: ExplorationText("Find the planet with rings wrapped around it."),
                hint: ExplorationText("Look for a wide band around the planet, like a hoop."),
                photos: [rings, earth], discoveryPhotoID: rings.id,
                fact: ExplorationText(
                    "You found Saturn! Its rings are made of lots of separate icy pieces.",
                    "Saturn's rings look like a hoop from far away, but they contain many separate particles, mostly ice.",
                    "Cassini photographed Saturn's ring system. Its continuous appearance comes from many separately orbiting particles, largely water ice, rather than a solid hoop."
                )
            ),
            PhotoSafariStop(
                id: "saturn-photo-shadow", title: "A glowing space portrait",
                clue: ExplorationText("Find the dark planet surrounded by glowing rings."),
                hint: ExplorationText(
                    "Look for Saturn's dark round shape inside the bright rings."),
                photos: [rover, nightSaturn], discoveryPhotoID: nightSaturn.id,
                fact: ExplorationText(
                    "Cassini looked back from Saturn's shadow. Sunlight helped the rings shine!",
                    "Cassini made this view while in Saturn's shadow. The backlit rings look bright around the dark planet.",
                    "This 2013 Cassini mosaic views Saturn from its shadow. Backlighting reveals faint ring structures; the composite combines spacecraft observations rather than showing a simulation."
                )
            ),
            PhotoSafariStop(
                id: "saturn-photo-home", title: "Wave hello to home",
                clue: ExplorationText("Which picture shows our blue and white home planet?"),
                hint: ExplorationText("Look for blue oceans and white clouds."),
                photos: [earth, mercuryHorizon], discoveryPhotoID: earth.id,
                fact: ExplorationText(
                    "That's Earth, our home! Space pictures help us see our world in a new way.",
                    "Earth's oceans and clouds stand out from space. The Blue Marble combines satellite observations into one view.",
                    "The Blue Marble is a composite of satellite observations. Its oceans and clouds provide a familiar comparison with the distant worlds in our space-photo collection."
                )
            ),
        ])

    private static func photo(
        _ name: String, _ title: String, _ nasaID: String, _ credit: String, _ caption: String
    ) -> SpacePhoto {
        SpacePhoto(
            id: name, title: title, imageName: name, credit: credit,
            sourceURL: "https://images.nasa.gov/details/\(nasaID)", caption: caption)
    }
}
