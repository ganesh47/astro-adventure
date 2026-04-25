# Solar System Curriculum

## Goal

Create implementation-ready solar system content for the Solar Passport loop. Each destination gives kids one clear observation, one low-pressure retrieval moment, and a later comparison hook. Copy is kid-friendly by default, with simpler read-aloud lines for ages 4-6 and deeper evidence language for ages 10-12.

## Age Bands

| Band | Copy target | Interaction target |
| --- | --- | --- |
| 4-6 | One sentence, read-aloud friendly, concrete object words | Point, match, choose between two icons |
| 7-9 | Two short facts, concrete comparisons, light vocabulary | Scan, choose from three answers, sort simple pairs |
| 10-12 | Evidence-based facts, cause/effect, optional numbers | Compare data cards, explain from a clue, plan a route |

## Content Contract

Each destination entry can be mapped into game data with these fields:

- `id`: stable lowercase identifier.
- `display_name`: player-facing name.
- `passport_role`: how this stop fits the Solar Passport.
- `core_idea`: the required science idea for the first pass.
- `age_band_copy`: player-facing copy by band.
- `scan_clue`: visible clue the player can observe in-scene.
- `retrieval_prompt`: short quiz or reflection prompt.
- `choices`: suggested answer choices when useful.
- `answer`: expected answer.
- `feedback`: correct and retry feedback.
- `revisit_hook`: later comparison or route-planning use.
- `glossary_tags`: glossary terms to unlock or review.
- `source_urls`: public review sources.
- `review_status`: `source-reviewed` or `needs-final-review`.

## Destination Content

### Sun

| Field | Content |
| --- | --- |
| `id` | `sun` |
| `display_name` | Sun |
| `passport_role` | Starting landmark and energy source for the solar system. |
| `core_idea` | The Sun is a star. Its gravity holds the solar system together, and its light warms the planets. |
| `age_band_copy.4_6` | The Sun is our star. It gives Earth light and warmth. |
| `age_band_copy.7_9` | The Sun is the star at the center of our solar system. Its gravity helps keep planets moving around it. |
| `age_band_copy.10_12` | The Sun contains most of the matter in the solar system. Gravity from the Sun keeps planets, dwarf planets, comets, and many small bodies in orbit. |
| `scan_clue` | Bright center object with planets arranged around it. |
| `retrieval_prompt` | What is the Sun? |
| `choices` | `["A star", "A planet", "A moon"]` |
| `answer` | A star |
| `feedback.correct` | Yes. The Sun is our local star, and the solar system is named for it. |
| `feedback.retry` | Look for the bright object at the center. Planets travel around this star. |
| `revisit_hook` | Use the Sun as the anchor when ordering destinations by distance. |
| `glossary_tags` | `["star", "gravity", "orbit", "solar system"]` |
| `source_urls` | `["https://science.nasa.gov/solar-system/solar-system-facts/"]` |
| `review_status` | `source-reviewed` |

### Mercury

| Field | Content |
| --- | --- |
| `id` | `mercury` |
| `display_name` | Mercury |
| `passport_role` | First planet stop and closest planet to the Sun. |
| `core_idea` | Mercury is the closest planet to the Sun and the smallest planet in the solar system. |
| `age_band_copy.4_6` | Mercury is the closest planet to the Sun. It is very small. |
| `age_band_copy.7_9` | Mercury is the smallest planet and the closest planet to the Sun. Its surface is rocky and covered with craters. |
| `age_band_copy.10_12` | Mercury is a small rocky planet with almost no air to hold heat steady, so its surface can be extremely hot in sunlight and extremely cold in darkness. |
| `scan_clue` | Small rocky world near the Sun with crater marks. |
| `retrieval_prompt` | Which clue tells you this is Mercury? |
| `choices` | `["Closest planet to the Sun", "Planet with giant rings", "Moon with icy cracks"]` |
| `answer` | Closest planet to the Sun |
| `feedback.correct` | Correct. Mercury is the planet nearest the Sun. |
| `feedback.retry` | Check the planet closest to the bright Sun marker. |
| `revisit_hook` | Compare Mercury with Mars as rocky planets, then contrast both with Jupiter as a giant planet. |
| `glossary_tags` | `["planet", "rocky planet", "crater", "orbit"]` |
| `source_urls` | `["https://science.nasa.gov/solar-system/planets/", "https://science.nasa.gov/solar-system/planets/planet-sizes-and-locations-in-our-solar-system/"]` |
| `review_status` | `source-reviewed` |

### Venus

| Field | Content |
| --- | --- |
| `id` | `venus` |
| `display_name` | Venus |
| `passport_role` | Heat and atmosphere comparison stop. |
| `core_idea` | Venus is the hottest planet because its thick atmosphere traps heat. |
| `age_band_copy.4_6` | Venus is very hot. Thick clouds wrap around it. |
| `age_band_copy.7_9` | Venus is not the closest planet to the Sun, but it is the hottest planet. Its thick air traps heat. |
| `age_band_copy.10_12` | Venus has a thick carbon dioxide atmosphere that causes a strong greenhouse effect, making it hotter than Mercury even though Mercury is closer to the Sun. |
| `scan_clue` | Bright cloudy planet with a heat shimmer or thermometer icon. |
| `retrieval_prompt` | Why is Venus the hottest planet? |
| `choices` | `["Thick air traps heat", "It has giant rings", "It is made of ice"]` |
| `answer` | Thick air traps heat |
| `feedback.correct` | Yes. Venus has a thick atmosphere that traps heat. |
| `feedback.retry` | Look for the thick cloud clue around Venus. Those clouds go with trapped heat. |
| `revisit_hook` | Compare Venus with Mercury: closer to the Sun does not always mean hotter. |
| `glossary_tags` | `["atmosphere", "greenhouse effect", "rocky planet"]` |
| `source_urls` | `["https://science.nasa.gov/solar-system/solar-system-facts/", "https://science.nasa.gov/solar-system/planets/"]` |
| `review_status` | `source-reviewed` |

### Earth

| Field | Content |
| --- | --- |
| `id` | `earth` |
| `display_name` | Earth |
| `passport_role` | Home base and life-support comparison stop. |
| `core_idea` | Earth is our home planet and the only world known to have life. |
| `age_band_copy.4_6` | Earth is our home. It has air, water, and life. |
| `age_band_copy.7_9` | Earth is the planet we live on. It has liquid water, air we can breathe, and one Moon. |
| `age_band_copy.10_12` | Earth is the only solar system world known to support life. Its liquid water, atmosphere, and distance from the Sun help make the surface livable. |
| `scan_clue` | Blue oceans, white clouds, green/brown land, one nearby Moon marker. |
| `retrieval_prompt` | What makes Earth special in our solar system so far? |
| `choices` | `["It is the only world known to have life", "It is the biggest planet", "It is the farthest planet"]` |
| `answer` | It is the only world known to have life |
| `feedback.correct` | Right. So far, Earth is the only place we know has life. |
| `feedback.retry` | Look for the home-world clue: oceans, air, and living things. |
| `revisit_hook` | Use Earth as the comparison point for distance, temperature, water, moons, and size. |
| `glossary_tags` | `["life", "atmosphere", "liquid water", "moon"]` |
| `source_urls` | `["https://science.nasa.gov/solar-system/solar-system-facts/", "https://science.nasa.gov/solar-system/planets/"]` |
| `review_status` | `source-reviewed` |

### Moon

| Field | Content |
| --- | --- |
| `id` | `moon` |
| `display_name` | Moon |
| `passport_role` | First natural satellite stop and Earth companion. |
| `core_idea` | The Moon is Earth's natural satellite. It orbits Earth and reflects sunlight. |
| `age_band_copy.4_6` | The Moon goes around Earth. It shines because sunlight bounces from it. |
| `age_band_copy.7_9` | The Moon is Earth's natural satellite. It has craters, and we see different shapes as it moves around Earth. |
| `age_band_copy.10_12` | Moon phases happen because we see different amounts of the Moon's sunlit half as it orbits Earth. The Moon does not make its own light. |
| `scan_clue` | Gray cratered body beside Earth, with a sunlight reflection cue. |
| `retrieval_prompt` | What does the Moon go around? |
| `choices` | `["Earth", "Jupiter", "The asteroid belt"]` |
| `answer` | Earth |
| `feedback.correct` | Yes. The Moon is Earth's natural satellite. |
| `feedback.retry` | Follow the Moon's path. It loops around Earth. |
| `revisit_hook` | Compare Earth's Moon with Europa: both are moons, but they orbit different planets. |
| `glossary_tags` | `["moon", "satellite", "phase", "crater", "reflect"]` |
| `source_urls` | `["https://science.nasa.gov/solar-system/solar-system-facts/"]` |
| `review_status` | `source-reviewed` |

### Mars

| Field | Content |
| --- | --- |
| `id` | `mars` |
| `display_name` | Mars |
| `passport_role` | Rocky planet comparison and rover-friendly mission stop. |
| `core_idea` | Mars is a rocky planet with red dust colored by rusty iron minerals. |
| `age_band_copy.4_6` | Mars is a rocky red planet. Dust makes it look red. |
| `age_band_copy.7_9` | Mars is the fourth planet from the Sun. It looks red because rusty iron minerals are mixed into its dust and rocks. |
| `age_band_copy.10_12` | Mars is a cold rocky planet with polar ice, canyons, volcanoes, and iron-rich dust that gives much of the surface a reddish color. |
| `scan_clue` | Red-orange rocky ground, dust trail, rover track, or two tiny moon markers. |
| `retrieval_prompt` | Why does Mars often look red? |
| `choices` | `["Rusty iron in dust and rocks", "Blue ocean water", "Bright ice rings"]` |
| `answer` | Rusty iron in dust and rocks |
| `feedback.correct` | Correct. Iron minerals in Martian dust and rock help make Mars look red. |
| `feedback.retry` | Check the dusty red surface clue. The color comes from iron minerals. |
| `revisit_hook` | Ask players to group Mercury, Venus, Earth, and Mars as rocky planets. |
| `glossary_tags` | `["rocky planet", "iron", "dust", "rover"]` |
| `source_urls` | `["https://science.nasa.gov/solar-system/planets/", "https://science.nasa.gov/solar-system/planets/planet-sizes-and-locations-in-our-solar-system/"]` |
| `review_status` | `source-reviewed` |

### Asteroid Belt

| Field | Content |
| --- | --- |
| `id` | `asteroid_belt` |
| `display_name` | Asteroid Belt |
| `passport_role` | Transition zone between rocky inner planets and outer giant planets. |
| `core_idea` | Most known main-belt asteroids orbit the Sun between Mars and Jupiter. |
| `age_band_copy.4_6` | The asteroid belt has many space rocks between Mars and Jupiter. |
| `age_band_copy.7_9` | The main asteroid belt is a wide region of rocky leftovers between Mars and Jupiter. Some pieces are tiny, and some are much bigger. |
| `age_band_copy.10_12` | The main asteroid belt contains many small rocky bodies. Jupiter's gravity helped stop material there from gathering into one planet. |
| `scan_clue` | Wide band of many small rocks between Mars and Jupiter, with Ceres as a larger marker. |
| `retrieval_prompt` | Where is the main asteroid belt? |
| `choices` | `["Between Mars and Jupiter", "Inside the Sun", "Beyond Neptune only"]` |
| `answer` | Between Mars and Jupiter |
| `feedback.correct` | Yes. The main asteroid belt is between Mars and Jupiter. |
| `feedback.retry` | Trace the route outward: Mars comes before the belt, and Jupiter comes after it. |
| `revisit_hook` | Use the belt as the checkpoint before the giant planets. |
| `glossary_tags` | `["asteroid", "asteroid belt", "dwarf planet", "gravity"]` |
| `source_urls` | `["https://science.nasa.gov/solar-system/asteroids/facts/", "https://science.nasa.gov/solar-system/solar-system-facts/"]` |
| `review_status` | `source-reviewed` |

### Jupiter

| Field | Content |
| --- | --- |
| `id` | `jupiter` |
| `display_name` | Jupiter |
| `passport_role` | First giant planet and moon-system hub. |
| `core_idea` | Jupiter is the largest planet in the solar system and a gas giant. |
| `age_band_copy.4_6` | Jupiter is the biggest planet. It has stripes and many moons. |
| `age_band_copy.7_9` | Jupiter is the largest planet in our solar system. It is a gas giant with colorful cloud bands and a huge storm called the Great Red Spot. |
| `age_band_copy.10_12` | Jupiter is a gas giant with no solid surface like Earth's. Its strong gravity shapes many moons and helped shape the asteroid belt. |
| `scan_clue` | Huge striped planet with Great Red Spot marker and moon cluster. |
| `retrieval_prompt` | What kind of planet is Jupiter? |
| `choices` | `["Gas giant", "Small rocky planet", "Dwarf planet"]` |
| `answer` | Gas giant |
| `feedback.correct` | Right. Jupiter is the largest gas giant in our solar system. |
| `feedback.retry` | Look for the huge striped planet beyond the asteroid belt. |
| `revisit_hook` | Compare Jupiter and Saturn as gas giants, then compare them with Uranus and Neptune as ice giants. |
| `glossary_tags` | `["gas giant", "moon", "storm", "gravity"]` |
| `source_urls` | `["https://science.nasa.gov/solar-system/planets/", "https://science.nasa.gov/solar-system/solar-system-facts/"]` |
| `review_status` | `source-reviewed` |

### Europa

| Field | Content |
| --- | --- |
| `id` | `europa` |
| `display_name` | Europa |
| `passport_role` | Moon-vs-planet distinction and ocean-world curiosity stop. |
| `core_idea` | Europa is an icy moon of Jupiter, and evidence suggests it may have a salty ocean under its ice. |
| `age_band_copy.4_6` | Europa is a moon of Jupiter. It has lots of ice. |
| `age_band_copy.7_9` | Europa is one of Jupiter's moons. Its icy surface has cracks, and scientists think an ocean may be hidden below the ice. |
| `age_band_copy.10_12` | Europa's water-ice shell may cover a global salty ocean. Scientists study Europa because liquid water makes it an important place to search for possible life, though no life has been found there. |
| `scan_clue` | Icy cracked moon orbiting Jupiter, with hidden-ocean ping. |
| `retrieval_prompt` | Europa is a moon of which planet? |
| `choices` | `["Jupiter", "Earth", "Neptune"]` |
| `answer` | Jupiter |
| `feedback.correct` | Yes. Europa orbits Jupiter. |
| `feedback.retry` | Follow Europa's orbit path. It circles the giant striped planet. |
| `revisit_hook` | Compare Europa with Earth's Moon: both are moons, but Europa has an icy surface and orbits Jupiter. |
| `glossary_tags` | `["moon", "ice", "ocean world", "orbit", "evidence"]` |
| `source_urls` | `["https://science.nasa.gov/jupiter/jupiter-moons/europa/europa-facts/"]` |
| `review_status` | `source-reviewed` |

### Saturn

| Field | Content |
| --- | --- |
| `id` | `saturn` |
| `display_name` | Saturn |
| `passport_role` | Ring-system landmark and second gas giant. |
| `core_idea` | Saturn is the second-largest planet and has the most recognizable ring system. |
| `age_band_copy.4_6` | Saturn is a giant planet with bright rings. |
| `age_band_copy.7_9` | Saturn is the sixth planet from the Sun and the second-largest planet. Its rings are made of many icy and rocky pieces. |
| `age_band_copy.10_12` | Saturn is a gas giant. Its broad rings are made of countless particles of ice and rock, from tiny grains to large chunks. |
| `scan_clue` | Giant pale planet with wide rings. |
| `retrieval_prompt` | What feature makes Saturn easy to spot? |
| `choices` | `["Wide rings", "A red dusty surface", "One blue ocean"]` |
| `answer` | Wide rings |
| `feedback.correct` | Correct. Saturn's rings are its easiest landmark. |
| `feedback.retry` | Look for the giant planet wrapped by rings. |
| `revisit_hook` | Compare Saturn's rings with the fact that all four giant planets have rings, even if Saturn's are easiest to see. |
| `glossary_tags` | `["ring", "gas giant", "ice", "rock"]` |
| `source_urls` | `["https://science.nasa.gov/solar-system/planets/", "https://science.nasa.gov/solar-system/solar-system-facts/"]` |
| `review_status` | `source-reviewed` |

### Uranus

| Field | Content |
| --- | --- |
| `id` | `uranus` |
| `display_name` | Uranus |
| `passport_role` | Ice giant and tilted-planet comparison stop. |
| `core_idea` | Uranus is an ice giant that rotates on its side compared with the other planets. |
| `age_band_copy.4_6` | Uranus is a cold blue-green planet. It spins tipped over. |
| `age_band_copy.7_9` | Uranus is an ice giant. It is tilted so much that it seems to spin on its side. |
| `age_band_copy.10_12` | Uranus is an ice giant with a large axial tilt. That sideways tilt gives it extreme seasons as it travels around the Sun. |
| `scan_clue` | Blue-green planet with sideways axis marker. |
| `retrieval_prompt` | What is unusual about Uranus? |
| `choices` | `["It spins tipped on its side", "It is closest to the Sun", "It is Earth's moon"]` |
| `answer` | It spins tipped on its side |
| `feedback.correct` | Yes. Uranus is tilted far over compared with the other planets. |
| `feedback.retry` | Look for the sideways spin marker on the blue-green planet. |
| `revisit_hook` | Compare Uranus and Neptune as ice giants, then sort gas giants and ice giants. |
| `glossary_tags` | `["ice giant", "axis", "tilt", "season"]` |
| `source_urls` | `["https://science.nasa.gov/solar-system/planets/", "https://science.nasa.gov/solar-system/planets/planet-sizes-and-locations-in-our-solar-system/"]` |
| `review_status` | `source-reviewed` |

### Neptune

| Field | Content |
| --- | --- |
| `id` | `neptune` |
| `display_name` | Neptune |
| `passport_role` | Farthest planet and outer ice giant. |
| `core_idea` | Neptune is the eighth and farthest planet from the Sun. It is an ice giant. |
| `age_band_copy.4_6` | Neptune is a faraway blue planet. It is very cold. |
| `age_band_copy.7_9` | Neptune is the farthest planet from the Sun. It is a cold ice giant with strong winds and storms. |
| `age_band_copy.10_12` | Neptune is an ice giant about 2.8 billion miles from the Sun on average. Its atmosphere has fast winds and dark storm systems. |
| `scan_clue` | Deep blue planet farthest from the Sun, with wind or storm streaks. |
| `retrieval_prompt` | Which planet is farthest from the Sun? |
| `choices` | `["Neptune", "Mercury", "Earth"]` |
| `answer` | Neptune |
| `feedback.correct` | Correct. Neptune is the farthest of the eight planets. |
| `feedback.retry` | Follow the planet path all the way outward. Neptune is the last planet stop. |
| `revisit_hook` | Use Neptune as the boundary before the Pluto and Kuiper Belt preview. |
| `glossary_tags` | `["ice giant", "atmosphere", "storm", "distance"]` |
| `source_urls` | `["https://science.nasa.gov/solar-system/planets/", "https://science.nasa.gov/solar-system/planets/planet-sizes-and-locations-in-our-solar-system/"]` |
| `review_status` | `source-reviewed` |

### Pluto/Kuiper Preview

| Field | Content |
| --- | --- |
| `id` | `pluto_kuiper_preview` |
| `display_name` | Pluto/Kuiper Preview |
| `passport_role` | Optional preview beyond the eight planets. |
| `core_idea` | Pluto is a dwarf planet in the Kuiper Belt, a distant region of icy bodies beyond Neptune. |
| `age_band_copy.4_6` | Pluto is a small icy world far beyond Neptune. |
| `age_band_copy.7_9` | Pluto is a dwarf planet. It travels in the Kuiper Belt, a faraway region with many icy objects. |
| `age_band_copy.10_12` | Pluto was reclassified as a dwarf planet in 2006. It is one of many icy worlds in the Kuiper Belt beyond Neptune's orbit. |
| `scan_clue` | Small icy world beyond Neptune, with a wider belt of distant icy objects. |
| `retrieval_prompt` | What is Pluto called today? |
| `choices` | `["Dwarf planet", "Gas giant", "Star"]` |
| `answer` | Dwarf planet |
| `feedback.correct` | Yes. Pluto is a dwarf planet in the distant Kuiper Belt region. |
| `feedback.retry` | Look for the small icy world beyond Neptune. It is not one of the eight planets. |
| `revisit_hook` | Preview future missions about dwarf planets, comets, and icy leftovers from solar system formation. |
| `glossary_tags` | `["dwarf planet", "Kuiper Belt", "ice", "orbit"]` |
| `source_urls` | `["https://science.nasa.gov/solar-system/planets/", "https://science.nasa.gov/solar-system/solar-system-facts/", "https://science.nasa.gov/solar-system/planets/planet-sizes-and-locations-in-our-solar-system/"]` |
| `review_status` | `source-reviewed` |

## Progression Map

| Mission beat | Destinations | Player action | Learning purpose |
| --- | --- | --- | --- |
| Inner system scan | Sun, Mercury, Venus, Earth, Moon, Mars | Match visible clues to names | Observe concrete features before new vocabulary. |
| Rocky planet sort | Mercury, Venus, Earth, Mars | Sort as rocky planets | Build a reusable category. |
| Home and moon compare | Earth, Moon, Europa | Decide planet or moon | Separate "planet" from "moon" using orbit clues. |
| Belt crossing | Mars, Asteroid Belt, Jupiter | Pick the next route marker | Place the asteroid belt between Mars and Jupiter. |
| Giant planet sort | Jupiter, Saturn, Uranus, Neptune | Sort gas giants and ice giants | Compare outer planet categories. |
| Outer preview | Neptune, Pluto/Kuiper Preview | Choose "planet" or "dwarf planet" | Introduce objects beyond the eight planets without overloading first play. |

## Sample Retrieval Items

| Item id | Age band | Prompt | Choices | Answer | Feedback | Source |
| --- | --- | --- | --- | --- | --- | --- |
| `q_sun_star_01` | 4-6 | What is the Sun? | Star; Planet | Star | The Sun is our star. | https://science.nasa.gov/solar-system/solar-system-facts/ |
| `q_venus_heat_01` | 7-9 | Why is Venus so hot? | Thick air traps heat; It has rings; It is made of ice | Thick air traps heat | Venus has thick air that traps heat. | https://science.nasa.gov/solar-system/solar-system-facts/ |
| `q_moon_orbit_01` | 4-6 | What does the Moon go around? | Earth; Jupiter | Earth | The Moon travels around Earth. | https://science.nasa.gov/solar-system/solar-system-facts/ |
| `q_mars_red_01` | 7-9 | What gives Mars its red color? | Iron-rich dust and rocks; Ocean water; Saturn's rings | Iron-rich dust and rocks | Iron minerals help make Mars look red. | https://science.nasa.gov/solar-system/planets/ |
| `q_belt_location_01` | 7-9 | Where is the main asteroid belt? | Between Mars and Jupiter; Between Earth and Moon; Inside Saturn's rings | Between Mars and Jupiter | The main asteroid belt sits between Mars and Jupiter. | https://science.nasa.gov/solar-system/asteroids/facts/ |
| `q_europa_moon_01` | 7-9 | Europa is a moon of which planet? | Jupiter; Venus; Neptune | Jupiter | Europa orbits Jupiter. | https://science.nasa.gov/jupiter/jupiter-moons/europa/europa-facts/ |
| `q_outer_sort_01` | 10-12 | Which pair are ice giants? | Uranus and Neptune; Mercury and Mars; Jupiter and Saturn | Uranus and Neptune | Uranus and Neptune are ice giants. | https://science.nasa.gov/solar-system/planets/ |
| `q_pluto_type_01` | 10-12 | What is Pluto classified as today? | Dwarf planet; Gas giant; Star | Dwarf planet | Pluto is classified as a dwarf planet. | https://science.nasa.gov/solar-system/planets/ |

## Glossary

| Term | Kid-facing definition | Use when |
| --- | --- | --- |
| Asteroid | A rocky object that travels around the Sun. Many are much smaller than planets. | Asteroid Belt, small-body scans |
| Asteroid belt | A region with many asteroids between Mars and Jupiter. | Belt crossing, route map |
| Atmosphere | The layer of gases around a planet or moon. | Venus, Earth, Mars, Neptune |
| Axis | An invisible line an object spins around. | Uranus tilt explanation |
| Crater | A bowl-shaped mark made when a space rock hits a surface. | Mercury, Moon, Mars |
| Dwarf planet | A round world that orbits the Sun but is not one of the eight planets. | Pluto/Kuiper preview, Ceres mention |
| Evidence | A clue or measurement that helps scientists decide what is probably true. | Europa ocean, comparison prompts |
| Gas giant | A very large planet made mostly of hydrogen and helium, without a solid surface like Earth's. | Jupiter, Saturn |
| Gravity | The pull that objects have on each other. | Sun, orbits, moons, asteroid belt |
| Greenhouse effect | Warming that happens when an atmosphere traps heat. | Venus deeper copy |
| Ice giant | A large outer planet with lots of materials scientists call ices, such as water, methane, and ammonia. | Uranus, Neptune |
| Kuiper Belt | A distant region beyond Neptune with many icy bodies. | Pluto/Kuiper preview |
| Life | Living things, such as plants, animals, and microbes. Earth is the only world known to have life so far. | Earth, Europa caution |
| Liquid water | Water in its flowing form, not ice or vapor. | Earth, Europa |
| Moon | A natural object that travels around a planet or dwarf planet. | Earth's Moon, Europa |
| Ocean world | A world that has, or may have, a large ocean. The ocean can be on the surface or hidden under ice. | Europa, Earth comparison |
| Orbit | The path one object follows around another object in space. | Planets, moons, dwarf planets |
| Phase | A shape we see on the Moon as different parts of its sunlit side face Earth. | Moon |
| Planet | A large round world that orbits the Sun and has cleared most other objects from its path. | Planet sorting |
| Reflect | To bounce light from one surface to another. | Moon copy |
| Ring | A band of ice, rock, or dust orbiting a planet. | Saturn, giant planet comparison |
| Rocky planet | A planet with a solid rocky surface. Mercury, Venus, Earth, and Mars are rocky planets. | Inner planet sort |
| Rover | A robot vehicle that explores the surface of another world. | Mars mission play |
| Satellite | An object that orbits a planet or dwarf planet. A moon is a natural satellite. | Moon/Earth, Europa/Jupiter |
| Solar system | The Sun and the objects that orbit it, including planets, moons, dwarf planets, asteroids, and comets. | Opening map |
| Star | A huge glowing ball of gas that makes light and heat. | Sun |
| Storm | Moving air and clouds that make rough weather. Some giant planets have huge storms. | Jupiter, Neptune |
| Tilt | How far an object's spin axis leans. | Uranus |

## Source Notes

- NASA Solar System facts are the general source for solar system structure, formation, moons, rings, Venus heat, Earth life, and Kuiper Belt framing: https://science.nasa.gov/solar-system/solar-system-facts/
- NASA planet overview is the general source for planet order, planet categories, dwarf planet framing, and short planet facts: https://science.nasa.gov/solar-system/planets/
- NASA planet sizes and locations provides distance/order reference values for route and map UI: https://science.nasa.gov/solar-system/planets/planet-sizes-and-locations-in-our-solar-system/
- NASA asteroid facts are the source for the main asteroid belt location and Jupiter-gravity formation note: https://science.nasa.gov/solar-system/asteroids/facts/
- NASA Europa facts are the source for Europa as Jupiter's icy moon and the evidence for a possible salty ocean under ice: https://science.nasa.gov/jupiter/jupiter-moons/europa/europa-facts/
