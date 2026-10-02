import AstroGameCore

/// Continuous play spaces. Sources were reviewed against NASA before authoring the explanations.
/// Observations describe actions in an illustrative model, never calibrated physical measurements.
public enum ExplorationCatalog {
    public static let adventures: [ExplorationAdventure] = [mercury, mars, saturn]

    public static func adventure(destinationID: String) -> ExplorationAdventure? {
        adventures.first { $0.destinationID == destinationID }
    }

    /// Zero-based film pauses refer to the segment just watched, independently of the active goal.
    public static func filmObservation(
        destinationID: String, checkpoint: Int
    ) -> ExplorationText? {
        switch (destinationID, checkpoint) {
        case ("mercury", 0):
            ExplorationText(
                "Notice the round crater marks on Mercury. There are so many to explore!",
                "Look for craters in the spacecraft pictures. Enhanced colors help show differences across the surface.",
                "Notice Mercury's cratered surface. The enhanced colors emphasize surface differences rather than showing the colors our eyes would see."
            )
        case ("mercury", 1):
            ExplorationText(
                "Think about the polar craters that stay in shadow. They can be cold hiding places for ice.",
                "Notice the polar-shadow clue. Places that never receive direct sunlight can preserve ice even on Mercury.",
                "Compare permanently shadowed polar craters with sunlit terrain. Local illumination matters even though both places belong to the same planet near the Sun."
            )
        case ("mars", 0):
            ExplorationText(
                "Look at the rocky hills. This model makes them look extra tall so we can notice them.",
                "Notice Mars's rusty appearance and rocky terrain. The model exaggerates hill heights; real slopes look gentler.",
                "Notice the rocky terrain in this visualization. Its height exaggeration helps reveal features, so it is not a literal model of real slopes."
            )
        case ("mars", 1):
            ExplorationText(
                "Look at the huge, broad volcano. Its name is Olympus Mons!",
                "Notice the broad shape of Olympus Mons, the enormous volcano shown in this view.",
                "Observe the broad shield-volcano shape of Olympus Mons. Height comparisons depend on the reference surface used."
            )
        case ("saturn", 0):
            ExplorationText(
                "Look at the cloud pattern with six sides. The pictures show its colors changing!",
                "Notice Saturn's six-sided cloud pattern. These pictures compare its polar colors at different times.",
                "Observe the north-polar hexagon and the color comparison. These are atmospheric observations, not a solid six-sided surface."
            )
        case ("saturn", 1):
            ExplorationText(
                "Imagine many little icy pieces together. They make Saturn's rings!",
                "The rings look solid from far away. Think of many separate icy pieces travelling around Saturn.",
                "Interpret the continuous-looking rings as independently orbiting particles, mostly water ice. Their appearance does not make them a rigid hoop."
            )
        default:
            nil
        }
    }

    private static let mercury = ExplorationAdventure(
        id: "mercury-crater-crew", destinationID: "mercury", title: "Mercury Crater Crew",
        welcome: ExplorationText(
            "Let's make crater patterns in our little Mercury model! Then our robot will explore the shadows.",
            "Join the crater crew! Make two impacts in a Mercury model, follow the scattered rock, and move a sensor into shadow.",
            "Explore an illustrative Mercury model. Compare impact patterns, trace ejecta, and investigate illumination with a portable sensor."
        ),
        goals: [
            ExplorationGoal(
                id: "mercury-two-impacts", title: "Make two crater patterns",
                invitation: ExplorationText(
                    "Try the small space rock and the big space rock. What marks do they make?",
                    "Use both space rocks in the model. Watch how their crater patterns differ.",
                    "Compare the two model impacts. Look at the crater and scattered material rather than memorizing a crater size."
                ),
                hint: ExplorationText(
                    "Find each space rock and give it a turn.",
                    "Try both impact sites. You can repeat either one.",
                    "Record both impact patterns before tracing material thrown outward."
                ),
                requiredObservations: ["impact.small", "impact.large"],
                suggestedTargetID: "mercury-small-impact", conceptID: "exploration-mercury-impacts",
                explanation: ExplorationText(
                    "A fast space rock can make a crater. Your little model made two different marks!",
                    "Impacts dig craters and throw material outward. Changing the rock changes the pattern in our simplified model.",
                    "Real impact craters depend on impactor size, speed, composition, and the target. Our two-size toy illustrates a comparison, not a numerical prediction."
                ),
                sourceURL: "https://www.nasa.gov/solar-system/asteroid-day-and-impact-craters/"
            ),
            ExplorationGoal(
                id: "mercury-trace-ejecta", title: "Follow the flying rock",
                invitation: ExplorationText(
                    "Follow the bright trail away from your craters.",
                    "Trace the scattered material. Where did its trail begin?",
                    "Follow the ejecta pattern back toward the impact that scattered it."
                ),
                hint: ExplorationText(
                    "Look for the bright trail between the crater sites.",
                    "After both impacts, explore the bright trail beside the craters.",
                    "The trail becomes available after both model impacts. Look for material extending from a crater."
                ),
                requiredObservations: ["mercury.ejecta.traced"],
                suggestedTargetID: "mercury-ejecta-trail", conceptID: "exploration-mercury-ejecta",
                explanation: ExplorationText(
                    "A crash throws rock away from the crater. Bright trails can show where some of it landed.",
                    "An impact crushes and scatters rock. On Mercury, reflective fragments can make bright rays around a crater.",
                    "Ejecta is material displaced by an impact. Mercury's bright crater rays contain reflective fragmented rock; exposure to the space environment darkens them over time."
                ),
                sourceURL: "https://science.nasa.gov/mercury/facts/"
            ),
            ExplorationGoal(
                id: "mercury-sun-and-shadow", title: "Move the warmth sensor",
                invitation: ExplorationText(
                    "Carry the sensor into sunshine. Then pick it up again and try the dark crater.",
                    "Measure the sunny ground, retrieve your sensor, and compare it with the shadowed crater.",
                    "Use the same model sensor at both sites. Compare illumination while keeping the instrument unchanged."
                ),
                hint: ExplorationText(
                    "Pick up the sensor before each move. Try the sunny spot and the dark crater.",
                    "The sensor kit is beside the crater field. Carry it to one site, collect it again, then visit the other.",
                    "Both sites need a recorded reading. Retrieve the portable sensor before placing it at the second location."
                ),
                requiredObservations: ["mercury.sensor.sunlit", "mercury.sensor.shadow"],
                suggestedTargetID: "mercury-sensor", conceptID: "exploration-mercury-shadow",
                explanation: ExplorationText(
                    "Sunny ground can get very hot. Some deep polar craters stay dark and cold enough for ice to last.",
                    "Our sensor compares sunlit ground with a permanently shadowed polar crater. Such cold places can preserve ice even on Mercury.",
                    "Permanently shadowed polar crater floors receive no direct sunlight and can preserve water ice. Ordinary temporary shade is different; our sensor shows a qualitative comparison."
                ),
                sourceURL: "https://science.nasa.gov/mercury/facts/"
            ),
        ],
        targets: [
            ExplorationTarget(
                id: "mercury-small-impact", name: "Small space rock", symbol: "circle.fill",
                verb: "Try impact", position: ExplorationPoint(0.28, 0.42),
                // The shared interaction's discrete settings are 0 = small, 1 = large.
                interaction: .impact(size: 0),
                response: ExplorationText(
                    "Plunk! Your model has a small crater.",
                    "The small impact made a crater and scattered material.",
                    "Small model impact recorded. Compare it with the larger pattern."
                )
            ),
            ExplorationTarget(
                id: "mercury-large-impact", name: "Big space rock", symbol: "circle.inset.filled",
                verb: "Try impact", position: ExplorationPoint(0.64, 0.43),
                interaction: .impact(size: 1),
                response: ExplorationText(
                    "Plunk! This model crater looks bigger.",
                    "The larger model rock made a different crater pattern.",
                    "Large model impact recorded. The toy keeps its comparison qualitative."
                )
            ),
            ExplorationTarget(
                id: "mercury-ejecta-trail", name: "Bright rock trail", symbol: "sparkles",
                verb: "Trace trail", position: ExplorationPoint(0.47, 0.55),
                interaction: .observe("mercury.ejecta.traced"),
                requiredObservations: ["impact.small", "impact.large"],
                response: ExplorationText(
                    "You followed the scattered rock back to a crater!",
                    "The trail connects scattered fragments with an impact crater.",
                    "Ejecta traced: the pattern records material displaced by an impact."
                )
            ),
            ExplorationTarget(
                id: "mercury-sensor", name: "Portable sensor", symbol: "thermometer.medium",
                verb: "Pick up sensor", position: ExplorationPoint(0.23, 0.70),
                interaction: .pickUp("mercury.sensor"),
                response: ExplorationText(
                    "Sensor ready! Where shall we carry it?",
                    "Your portable sensor is ready for another site.",
                    "Sensor retrieved. Earlier observations remain in your journal."
                )
            ),
            ExplorationTarget(
                id: "mercury-sunlit-sensor-site", name: "Sunny ground", symbol: "sun.max.fill",
                verb: "Place sensor", position: ExplorationPoint(0.43, 0.72),
                interaction: .place(item: "mercury.sensor", observation: "mercury.sensor.sunlit"),
                requiredObservations: ["mercury.ejecta.traced"],
                response: ExplorationText(
                    "The sunny spot gives a warm reading.",
                    "Sunlit ground gives the warmer reading in our model.",
                    "Sunlit-site observation recorded. Retrieve the sensor to compare the shadowed site."
                )
            ),
            ExplorationTarget(
                id: "mercury-shadow-sensor-site", name: "Dark polar crater",
                symbol: "moon.fill", verb: "Place sensor",
                position: ExplorationPoint(0.80, 0.60),
                interaction: .place(item: "mercury.sensor", observation: "mercury.sensor.shadow"),
                requiredObservations: ["mercury.ejecta.traced"],
                response: ExplorationText(
                    "Brr! This always-shadowed spot is colder.",
                    "The permanently shadowed crater gives a colder model reading.",
                    "Shadow-site observation recorded. This polar cold trap differs from temporary shade."
                )
            ),
        ],
        postcardTitle: "My crater crew discovery", videoLessonID: "mercury-video"
    )

    private static let mars = ExplorationAdventure(
        id: "mars-rover-expedition", destinationID: "mars", title: "Mars Rover Expedition",
        welcome: ExplorationText(
            "Our rover has a rock mystery! Visit two landmarks, uncover the rock, and play with a little river model.",
            "Scout the crater and outcrop, brush a layered rock, and use a photo to investigate an ancient-water model.",
            "Explore a stylized rover site, collect an image of rock layers, then compare it with a model of ancient sediment transport."
        ),
        goals: [
            ExplorationGoal(
                id: "mars-landmark-route", title: "Explore the rover route",
                invitation: ExplorationText(
                    "Take our rover to the crater and the big rock landmark.",
                    "Scout both landmarks before choosing the layered rock to inspect.",
                    "Visit both landmarks to establish the site context before collecting a close observation."
                ),
                hint: ExplorationText(
                    "Look for the crater on the left and the rock on the right.",
                    "Visit and explore both the crater landmark and the rock landmark.",
                    "Record both landmark visits. The nearby outcrop becomes available for close inspection."
                ),
                requiredObservations: ["mars.landmark.crater", "mars.landmark.rock"],
                suggestedTargetID: "mars-crater-landmark",
                conceptID: "exploration-mars-rover-route",
                explanation: ExplorationText(
                    "A rover is a moving robot. It can visit new places and look closely at rocks.",
                    "Rovers combine movement with cameras and other tools. Exploring a site helps scientists choose observations.",
                    "Rover mobility links close measurements to their geological context. Our short route is stylized; real exploration combines navigation and instrument observations."
                ),
                sourceURL: "https://science.nasa.gov/mission/msl-curiosity/science/"
            ),
            ExplorationGoal(
                id: "mars-layered-rock-photo", title: "Uncover a rock story",
                invitation: ExplorationText(
                    "Brush the dusty rock. Then take a picture of its stripes.",
                    "Brush the model outcrop, then photograph the newly visible layers.",
                    "Expose the model rock surface before imaging its layers. Collect a useful observation, rather than judging the rock by color alone."
                ),
                hint: ExplorationText(
                    "Brush first. The camera is ready beside the rock.",
                    "Visit both landmarks, use the brush at the outcrop, then use the camera.",
                    "The photo follows surface preparation. Observe the arrangement of layers before interpreting how they formed."
                ),
                requiredObservations: ["mars.rock.brushed", "mars.rock.photographed"],
                suggestedTargetID: "mars-layered-rock", conceptID: "exploration-mars-rock-layers",
                explanation: ExplorationText(
                    "You found layers in the rock! Layers can keep clues about what happened long ago.",
                    "Rock layers can record earlier deposits and changes. Your photo preserves their pattern for comparison.",
                    "Layer geometry is one geological observation. Scientists combine images with composition and context to distinguish possible histories; a striped rock alone does not prove a lake."
                ),
                sourceURL: "https://science.nasa.gov/mission/msl-curiosity/science/"
            ),
            ExplorationGoal(
                id: "mars-ancient-water-compare", title: "Try the old river model",
                invitation: ExplorationText(
                    "Run water through the little model. Then compare the sand it leaves with your rock picture.",
                    "Turn on the ancient-water model. Compare its deposited sediment with your layered-rock photo.",
                    "Run the ancient-water model, then compare its deposits with your observation. Separate a possible explanation from proof of a specific past environment."
                ),
                hint: ExplorationText(
                    "Start the little river. Then explore the picture beside it.",
                    "After taking your photo, run the water model and open the deposit comparison.",
                    "First observe flowing water in the model. Then use the comparison viewer to connect sediment deposition with the rock image."
                ),
                requiredObservations: ["mars.model.water", "mars.deposits.compared"],
                suggestedTargetID: "mars-water-model", conceptID: "exploration-mars-sediment",
                explanation: ExplorationText(
                    "Moving water carries sand. When it slows, sand can settle. Our model imagines Mars long ago.",
                    "Water can carry sediment into a lake and leave deposits as it slows. Some ancient Martian rocks preserve evidence of processes like these.",
                    "Delta deposits form where flow slows on entering a water body. Martian sedimentary observations support ancient-water interpretations; our toy demonstrates a process, not present-day rivers or evidence of life."
                ),
                sourceURL:
                    "https://science.nasa.gov/photojournal/how-a-delta-forms-where-river-meets-lake/"
            ),
        ],
        targets: [
            ExplorationTarget(
                id: "mars-crater-landmark", name: "Crater landmark", symbol: "circle.dashed",
                verb: "Explore landmark", position: ExplorationPoint(0.22, 0.60),
                interaction: .observe("mars.landmark.crater"),
                response: ExplorationText(
                    "The rover reached the crater landmark!",
                    "Crater landmark explored. The outcrop is another stop.",
                    "Crater-site context recorded before close rock inspection."
                )
            ),
            ExplorationTarget(
                id: "mars-rock-landmark", name: "Big rock landmark", symbol: "mountain.2.fill",
                verb: "Explore landmark", position: ExplorationPoint(0.64, 0.42),
                interaction: .observe("mars.landmark.rock"),
                response: ExplorationText(
                    "The rover found the big rock landmark!",
                    "Rock landmark explored. Look for the nearby dusty outcrop.",
                    "Outcrop context recorded. Explore the layered surface next."
                )
            ),
            ExplorationTarget(
                id: "mars-layered-rock", name: "Dusty layered rock", symbol: "paintbrush.fill",
                verb: "Brush rock", position: ExplorationPoint(0.70, 0.56),
                interaction: .observe("mars.rock.brushed"),
                requiredObservations: ["mars.landmark.crater", "mars.landmark.rock"],
                response: ExplorationText(
                    "Swish! Now we can see the rock's layers.",
                    "The model surface is brushed. Its layers are ready to photograph.",
                    "Model surface prepared. Layer geometry is visible for imaging."
                )
            ),
            ExplorationTarget(
                id: "mars-rock-camera", name: "Rock camera", symbol: "camera.fill",
                verb: "Take photo", position: ExplorationPoint(0.49, 0.69),
                interaction: .observe("mars.rock.photographed"),
                requiredObservations: ["mars.rock.brushed"],
                response: ExplorationText(
                    "Click! Your rock picture is saved.",
                    "Layer photo saved. Let's compare it with a little model.",
                    "Layer image collected. A process model can help explore possible explanations."
                )
            ),
            ExplorationTarget(
                id: "mars-water-model", name: "Ancient-water model", symbol: "drop.fill",
                verb: "Run water model", position: ExplorationPoint(0.33, 0.36),
                interaction: .adjust(
                    model: "mars.water", observations: ["mars.model.dry", "mars.model.water"]),
                requiredObservations: ["mars.rock.photographed"],
                response: ExplorationText(
                    "Watch the model carry sand and leave a little fan.",
                    "Water and sediment move through the ancient-Mars toy model.",
                    "Model flow illustrates sediment transport and deposition in an ancient-water setting."
                )
            ),
            ExplorationTarget(
                id: "mars-deposit-compare", name: "Deposit comparison",
                symbol: "photo.on.rectangle",
                verb: "Compare deposits", position: ExplorationPoint(0.78, 0.35),
                interaction: .adjust(
                    model: "mars.compare",
                    observations: ["mars.compare.photo", "mars.deposits.compared"]),
                requiredObservations: ["mars.rock.photographed", "mars.model.water"],
                response: ExplorationText(
                    "The picture and the model help tell a rock story.",
                    "Compare the model's deposits with your photograph of the layers.",
                    "Comparison recorded. Similar patterns suggest hypotheses; additional evidence tests them."
                )
            ),
        ],
        postcardTitle: "My rover's rock story", videoLessonID: "mars-video"
    )

    private static let saturn = ExplorationAdventure(
        id: "saturn-ring-workshop", destinationID: "saturn", title: "Saturn Ring Workshop",
        welcome: ExplorationText(
            "Let's make a moving ring model! Carry icy pieces to two paths, watch them go, and peek from the side.",
            "Build a Saturn ring model from icy pieces. Compare two orbital paths and change your viewing angle.",
            "Construct a simplified particulate ring, observe different orbital motion, and investigate how viewing geometry changes its appearance."
        ),
        goals: [
            ExplorationGoal(
                id: "saturn-place-ring-pieces", title: "Build two icy paths",
                invitation: ExplorationText(
                    "Carry ice to the near path. Pick up the kit again and add ice to the far path.",
                    "Use the ice kit on both orbital paths. Retrieve the kit between placements.",
                    "Place icy particles in the inner and outer model orbits. The kit is reusable; both discoveries remain visible."
                ),
                hint: ExplorationText(
                    "The ice kit is on the left. Try both paths around Saturn.",
                    "Pick up the kit before each placement. Add pieces to the inner and outer paths.",
                    "Retrieve the kit after the first placement, then populate the other orbital path."
                ),
                requiredObservations: ["saturn.ring.inner", "saturn.ring.outer"],
                suggestedTargetID: "saturn-ice-kit", conceptID: "exploration-saturn-particles",
                explanation: ExplorationText(
                    "Saturn's rings contain many icy pieces. They are not one solid hoop.",
                    "The rings are mostly icy particles, with other material too. Many separate pieces together make the ring system.",
                    "Saturn's rings consist largely of water-ice particles with rock and dust. Our sparse model represents a particle system, not a rigid structure or its true scale."
                ),
                sourceURL: "https://science.nasa.gov/saturn/facts/"
            ),
            ExplorationGoal(
                id: "saturn-watch-orbits", title: "Watch the pieces travel",
                invitation: ExplorationText(
                    "Start the ring model. Watch the near pieces and the far pieces go around.",
                    "Start the motion model and follow a piece on each path.",
                    "Observe both model orbits. Compare their motion instead of treating the ring as one rotating wheel."
                ),
                hint: ExplorationText(
                    "Add ice to both paths, then start the motion model.",
                    "Both paths need icy pieces. The motion control is above the rings.",
                    "Populate both orbits before activating motion. Follow the inner and outer particle patterns."
                ),
                requiredObservations: ["saturn.motion.watched"],
                suggestedTargetID: "saturn-watch-motion", conceptID: "exploration-saturn-orbits",
                explanation: ExplorationText(
                    "Each piece travels around Saturn. Nearer pieces go around faster than farther pieces.",
                    "Ring particles follow separate orbits. The inner particles move faster; the rings do not turn like a stiff wheel.",
                    "Orbital motion depends on distance from Saturn. Inner ring particles orbit faster than outer particles; our animation preserves that relationship without predicting measured speeds."
                ),
                sourceURL: "https://science.nasa.gov/mission/cassini/science/rings/"
            ),
            ExplorationGoal(
                id: "saturn-view-ring-edge", title: "Peek from the side",
                invitation: ExplorationText(
                    "Turn your view sideways. What happens to the ring's shape?",
                    "Switch to an edge view and compare it with the open ring view.",
                    "Change the model's viewing angle. Distinguish a change in appearance from a change in the ring itself."
                ),
                hint: ExplorationText(
                    "After watching the pieces, try the view control on the right.",
                    "Watch the moving ring first. Then use the view control to see it edge-on.",
                    "The edge view becomes available after motion is observed. Switching back does not erase the discovery."
                ),
                requiredObservations: ["saturn.view.edge"],
                suggestedTargetID: "saturn-edge-view", conceptID: "exploration-saturn-view",
                explanation: ExplorationText(
                    "The ring looks like a thin line from the side. The icy pieces are still there!",
                    "Saturn's main rings are very thin compared with their width. An edge view changes what we see, not whether the rings exist.",
                    "The main rings have a small vertical extent compared with their radial extent. Viewing geometry changes their apparent shape; a narrow appearance does not imply that the particles vanished."
                ),
                sourceURL: "https://science.nasa.gov/saturn/facts/"
            ),
        ],
        targets: [
            ExplorationTarget(
                id: "saturn-ice-kit", name: "Icy-piece kit", symbol: "snowflake",
                verb: "Pick up ice", position: ExplorationPoint(0.21, 0.71),
                interaction: .pickUp("saturn.ice"),
                response: ExplorationText(
                    "Icy pieces ready! Choose a path.",
                    "The reusable kit is ready for another orbital path.",
                    "Ice kit retrieved. Previously added particle observations remain recorded."
                )
            ),
            ExplorationTarget(
                id: "saturn-inner-orbit", name: "Near orbital path", symbol: "circle",
                verb: "Place ice", position: ExplorationPoint(0.48, 0.53),
                interaction: .place(item: "saturn.ice", observation: "saturn.ring.inner"),
                response: ExplorationText(
                    "Icy pieces joined the near path!",
                    "The inner orbit now has icy particles in our model.",
                    "Inner-orbit particles added. Retrieve the kit to populate the outer orbit."
                )
            ),
            ExplorationTarget(
                id: "saturn-outer-orbit", name: "Far orbital path", symbol: "circle.dashed",
                verb: "Place ice", position: ExplorationPoint(0.76, 0.54),
                interaction: .place(item: "saturn.ice", observation: "saturn.ring.outer"),
                response: ExplorationText(
                    "Icy pieces joined the far path!",
                    "The outer orbit now has icy particles in our model.",
                    "Outer-orbit particles added. Both populated paths support a motion comparison."
                )
            ),
            ExplorationTarget(
                id: "saturn-watch-motion", name: "Ring motion control", symbol: "play.circle.fill",
                verb: "Watch motion", position: ExplorationPoint(0.63, 0.34),
                interaction: .adjust(
                    model: "saturn.motion",
                    observations: ["saturn.motion.paused", "saturn.motion.watched"]),
                requiredObservations: ["saturn.ring.inner", "saturn.ring.outer"],
                response: ExplorationText(
                    "Follow a near piece and a far piece!",
                    "Watch separate orbital paths instead of one turning hoop.",
                    "Motion comparison available. Track the differently moving inner and outer particles."
                )
            ),
            ExplorationTarget(
                id: "saturn-edge-view", name: "Ring view control", symbol: "view.3d",
                verb: "Change view", position: ExplorationPoint(0.84, 0.69),
                interaction: .adjust(
                    model: "saturn.view", observations: ["saturn.view.face", "saturn.view.edge"]),
                requiredObservations: ["saturn.motion.watched"],
                response: ExplorationText(
                    "Look from another side. The ring is still there!",
                    "Changing the viewpoint changes the ring's apparent shape.",
                    "Viewing geometry changed; the model's ring particles remain present."
                )
            ),
        ],
        postcardTitle: "My moving icy rings", videoLessonID: "saturn-video"
    )
}
