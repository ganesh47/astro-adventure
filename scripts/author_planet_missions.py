#!/usr/bin/env python3
"""Rebuild the reviewed planet mission JSON from authored, age-specific curriculum.

Copy, answer distractors, transfer prompts, and activities are authored below.
The helpers serialize these records and distribute correct answer positions;
they do not generate science copy. Image provenance comes from IMAGE_CREDITS.md.
Run from any directory: python3 scripts/author_planet_missions.py.
"""
import json, re
from pathlib import Path
ROOT=Path(__file__).resolve().parents[1]
BANDS=['ages4To6','ages7To9','ages10To12']
def age(s):
    parts=s.split('|') if isinstance(s,str) else s
    assert len(parts)==3, parts
    return dict(zip(BANDS,parts))
SOURCES={p:{'title':f'NASA Science: {p.title()} Facts','url':u,'reviewStatus':'reviewed'} for p,u in {
'mercury':'https://science.nasa.gov/mercury/facts/', 'venus':'https://science.nasa.gov/venus/venus-facts/', 'earth':'https://science.nasa.gov/earth/facts/', 'mars':'https://science.nasa.gov/mars/facts/', 'jupiter':'https://science.nasa.gov/jupiter/jupiter-facts/', 'saturn':'https://science.nasa.gov/saturn/facts/', 'uranus':'https://science.nasa.gov/uranus/facts/', 'neptune':'https://science.nasa.gov/neptune/neptune-facts/',
'planet':'https://science.nasa.gov/solar-system/planets/what-is-a-planet/', 'venus-spin':'https://spaceplace.nasa.gov/all-about-venus/en/', 'aurora':'https://spaceplace.nasa.gov/aurora/en/', 'titan':'https://science.nasa.gov/saturn/moons/titan/facts/', 'enceladus':'https://science.nasa.gov/saturn/moons/enceladus/', 'radio':'https://science.nasa.gov/learn/basics-of-space-flight/chapter2-3/', 'earth-observe':'https://spaceplace.nasa.gov/weather-forecasting/en/', 'cassini':'https://science.nasa.gov/mission/cassini/', 'juno':'https://science.nasa.gov/mission/juno/'}.items()}
for key,title in {'planet':'NASA Science: What Is a Planet?', 'venus-spin':'NASA Space Place: All About Venus', 'aurora':'NASA Space Place: What Is an Aurora?', 'titan':'NASA Science: Titan Facts', 'enceladus':'NASA Science: Enceladus', 'radio':'NASA Science: Spaceflight Reference Systems', 'earth-observe':'NASA Space Place: Forecasting Weather', 'cassini':'NASA Science: Cassini', 'juno':'NASA Science: Juno'}.items(): SOURCES[key]['title']=title
IMAGES={}
for line in (ROOT/'docs/IMAGE_CREDITS.md').read_text().splitlines():
    match=re.match(r'\| `([^`]+)\.jpg` \| ([^|]+) \| ([^|]+) \|',line)
    if match: IMAGES[match[1]]=(match[2].strip(),match[3].strip())
missions=[]
def card(cid,title,image,body,source):
    source_id,credit=IMAGES[image]
    return {'id':cid+'-card','conceptID':cid,'title':title,'body':age(body),'imageName':image,'imageCredit':credit,'imageSourceID':source_id,'source':SOURCES[source]}
def C(key,title,image,body,prompts,reviews,correct,wrong1,wrong2,source=None):
    return {'key':key,'title':title,'image':image,'body':body,'prompts':prompts,'reviews':reviews,'choices':[correct,wrong1,wrong2],'source':source}
def mission(planet,key,title,invitation,concepts,deep,family,activity_title,tasks):
    mid=planet+'-'+key
    cards=[]; questions=[]
    for i,c in enumerate(concepts):
        cid=mid+'-'+c['key']; src=c['source'] or planet
        cards.append(card(cid,c['title'],c['image'],c['body'],src))
        content={}; review={}
        for b,band in enumerate(BANDS):
            choices=[{'id':cid+f'-option-{j}','text':age(x)[band]} for j,x in enumerate(c['choices'])]
            if b==0: choices=choices[:2]
            for dest,prompts,offset in [(content,c['prompts'],0),(review,c['reviews'],1)]:
                correct_choice=choices[0]; rest=choices[1:]
                rest.insert((len(missions)+i+b+offset)%len(choices),correct_choice)
                dest[band]={'prompt':age(prompts)[band],'choices':rest,'correctChoiceID':correct_choice['id'],'correctFeedback':age(c['body'])[band],'retryFeedback':'Have another look. '+age(c['body'])[band],'hint':age(c['body'])[band]}
        questions.append({'id':cid+'-question','conceptID':cid,'source':SOURCES[src],'content':content,'reviewContent':review})
    activity={'id':mid+'-activity','family':family,'title':activity_title,'conceptID':cards[0]['conceptID'],'tasks':[]}
    for i,t in enumerate(tasks):
        tid=mid+f'-task-{i+1}'
        options=[{'id':tid+f'-option-{j}','label':age(label),'symbol':symbol,'outcome':age(outcome)} for j,(label,symbol,outcome) in enumerate(t['options'])]
        activity['tasks'].append({'id':tid,'prompt':age(t['prompt']),'imageName':t['image'],'options':options,'correctOptionID':options[t['correct']]['id'],'hint':age(t['hint']),'explanation':age(t['explanation'])})
    missions.append({'id':mid,'destinationID':planet,'revision':1,'title':title,'invitation':age(invitation),'requiredConceptIDs':[x['conceptID'] for x in cards],'cards':cards,'questions':questions,'activity':activity,'deepDive':card(mid+'-deeper',deep[0],deep[1],deep[2],deep[3] if len(deep)>3 else planet)})
def T(prompt,image,a,b,correct,explanation,hint=None,oa=None,ob=None):
    return {'prompt':prompt,'image':image,'options':[(a,'sparkle.magnifyingglass',oa or explanation),(b,'arrow.triangle.branch',ob or explanation)],'correct':correct,'explanation':explanation,'hint':hint or explanation}

mission('mercury','crater-detective','Crater Detective',
'Help us find dents on Mercury!|Read Mercury’s old impact clues like a space detective.|Use craters and rays to reconstruct Mercury’s collision history.',[
C('impacts','Rocky crash marks','mercury-caloris',
'Space rocks made many round dents on Mercury. We call the dents craters.|Asteroids and comets struck Mercury and dug impact craters. The rocky ground keeps their marks.|Impact craters preserve evidence of collisions. Mercury’s sparse exosphere and limited weathering leave many ancient scars visible.',
'What made these dents?|Which event can dig a crater on Mercury?|What process best explains Mercury’s impact craters?',
'Another round dent appears. What could have made it?|A new map shows a bowl with a raised rim. Which event fits?|An exposed crater has a rim and surrounding debris. Which origin fits both clues?',
'Space rocks hitting|A space rock striking the ground|A collision excavating the surface',
'Clouds landing|Rain clouds pressing on the ground|Rain carving a circular lake',
'Flowers growing|Trees growing in circles|Vegetation shaping the rim'),
C('rays','Bright trails from a crash','mercury-color',
'A big crash throws bits of rock outward. They can leave bright trails around a crater.|Bright crater rays are crushed rock thrown outward by an impact. Fresh small pieces reflect light well.|An impact ejects fragmented rock. Fine, freshly exposed particles can form reflective rays that darken as the space environment alters them.',
'Which trail came from the crash?|Why can rays around a fresh crater look bright?|Which mechanism explains reflective crater rays?',
'Rock bits land outside a new dent. What might we see?|A crater has bright streaks stretching outward. What is the clue telling us?|Why might one crater’s rays be brighter than another crater’s older rays?',
'Rock bits spread out|Crushed rock scattered around the crater|Fresh reflective ejecta',
'Water pours out|Water from a hidden lake|A permanent liquid-water river',
'A lamp turns on|Street lamps switch on|Artificial lights around the crater'),
C('caloris','Meet the Caloris Basin','mercury-caloris',
'Caloris is an enormous crash mark on Mercury. Its edges have rings of mountains.|The Caloris Basin is about 1,550 kilometres wide. A powerful ancient impact left mountain rings around it.|Caloris is a large impact basin roughly 1,550 kilometres across. Its surrounding rings record the enormous deformation caused by the collision.',
'Which clue belongs to Caloris?|What is Caloris: a storm or an impact basin?|What observation supports Caloris being an impact basin?',
'Our scout finds a huge dent with mountain rings. What is it?|Caloris has a depression and mountain rings. What kind of feature is it?|A broad depression is surrounded by mountain rings. Which Caloris interpretation fits?',
'A giant crash mark|A huge impact basin|A depression and rings created by a major impact',
'A cloud storm|A storm swirling in clouds|A storm system in a thick atmosphere',
'A blue ocean|A deep blue ocean|A basin filled by an Earth-like ocean')],
('Why do the colors look unusual?','mercury-color','Mercury’s rocks look mostly gray-brown to our eyes. This picture uses extra colors to help scientists.|MESSENGER combined camera filters to highlight different rocks. Enhanced color is a science tool, not Mercury’s everyday appearance.|Different wavelengths are combined in enhanced-color images to emphasize surface differences. A color pattern is evidence to investigate, not a direct mineral identification by itself.'),
'evidence','Read the crash clues',[
T('Find the crash clue.|Select the surface feature that records an impact.|Which pictured feature is evidence of a past collision?','mercury-caloris','Round basin|Round basin and rim|An excavated basin with a rim','Cloud stripe|Stripe in clouds|An atmospheric cloud band',0,'A basin is a crash clue.|An impact can excavate a basin and pile up a rim.|The basin and rim are consistent with excavation and displacement during an impact.'),
T('Which clue shows rock was thrown?|Which mark tells you material flew away from a crater?|Choose the clue that supports outward transport of impact debris.','mercury-color','Bright rays|Bright rays around a crater|Reflective rays extending from a crater','Blue lake|A blue lake|A lake inside the crater',0,'Rays spread out from the crash.|Bright rays can be bits of rock thrown outward.|Reflective ejecta can trace material deposited beyond the crater.')])

mission('mercury','heat-and-shadow','Heat and Shadow',
'Find a cold hiding place near the hot Sun.|Investigate why Mercury can be hot, cold, and icy.|Compare illumination and heat retention to explain Mercury’s temperature contrasts.',[
C('air','Missing a blanket of air','mercury-horizon',
'Mercury has almost no air to keep warmth in. Its nights can become very cold.|Mercury has a thin exosphere, not a thick atmosphere. It cannot spread or hold warmth like Earth’s air.|Mercury’s tenuous exosphere cannot efficiently redistribute or retain surface heat. Illumination therefore creates extreme temperature contrasts.',
'Why does Mercury lose warmth at night?|What helps explain Mercury’s cold nights?|Which property contributes to Mercury’s temperature extremes?',
'The Sun goes out of view. Why can the ground cool so much?|Our model turns Mercury away from sunlight. What is missing to hold the warmth?|Which comparison explains why Mercury’s nighttime surface cools strongly?',
'Almost no air|Almost no atmosphere to hold heat|A tenuous exosphere with little heat redistribution',
'Thick warm clouds|A thick atmosphere that traps heat|An efficient heat-trapping atmosphere',
'A warm ocean|A global warm ocean|Ocean circulation carrying warmth everywhere'),
C('shadow-ice','Ice in a dark crater','mercury-polar-ice',
'Some deep craters near Mercury’s poles stay in shadow. Ice can hide in those very cold places.|Permanently shadowed polar craters receive no direct sunlight. Evidence supports water ice surviving in these cold traps.|Mercury’s low axial tilt lets some polar crater floors remain permanently shadowed. These cold traps can preserve water ice despite the planet’s sunlit heat.',
'Where could ice hide?|Which Mercury place can protect water ice?|Which setting best explains Mercury’s polar ice?',
'We need a chilly hiding spot. Which place should our scout check?|Which crater floor is a better ice-search target?|An ice signal occurs close to a pole. Which illumination condition makes it plausible?',
'A dark polar crater|A permanently shadowed polar crater|A cold trap with no direct solar illumination',
'A hot sunny plain|A sunlit equatorial plain|A persistently illuminated equatorial plain',
'Inside hot clouds|Inside hot rain clouds|A thick cloud deck warmed by the Sun'),
C('not-hottest','Closest does not mean hottest','mercury-horizon',
'Mercury is closest to the Sun, but Venus is hotter. Venus has thick air that traps heat.|Venus is hotter than Mercury because its dense atmosphere traps heat. Distance is only one temperature clue.|Planetary temperature depends on both sunlight and atmospheric processes. Venus’s strong greenhouse warming makes it hotter than Mercury.',
'Which planet is hotter: Mercury or Venus?|Why is Venus hotter than Mercury?|Which explanation fits Venus being hotter despite its greater solar distance?',
'Two planet cards appear. Which one has the thick heat-trapping air?|A scout says “closest must mean hottest.” What Venus clue challenges that rule?|What extra factor must be considered before ranking temperatures by solar distance?',
'Venus|Venus’s thick atmosphere traps heat|Atmospheric greenhouse warming',
'Mercury|Mercury is closest, so it must be hottest|Solar distance alone determines temperature',
'Both are always the same|Every rocky planet has the same temperature|All rocky planets have identical atmospheres')],
('A thin exosphere','mercury-hollows','Tiny bits from Mercury’s ground can enter space around it. They do not make thick breathing air.|Solar wind and small impacts can knock atoms off Mercury’s surface. This creates a thin exosphere.|Mercury’s exosphere includes surface-derived atoms. It is too tenuous to behave like the dense, collisional atmosphere around Earth.'),
'classify','Sort sunny and shadowed places',[
T('Sort this bright sunny plain.|Does a sunlit equatorial plain belong in the hot-place or ice-hiding group?|Classify a persistently sunlit plain using its illumination.','mercury-horizon','Sunlit and warmer|Sunlit, strongly heated|Directly illuminated surface','Always dark|Permanently shadowed cold trap|A cold trap sheltered from direct sunlight',0,'The Sun warms this place.|Direct sunlight heats the exposed ground.|Direct illumination supplies solar energy to the surface.'),
T('Sort this dark polar crater.|Which group fits a crater floor that sunlight never reaches?|Classify a permanently shadowed polar crater as an ice-search environment.','mercury-polar-ice','Always dark|Permanently shadowed cold trap|A cold trap sheltered from direct sunlight','Sunlit and warmer|Sunlit, strongly heated|Directly illuminated surface',0,'Shade can help ice stay frozen.|Permanent shadow can protect water ice.|The lack of direct solar heating supports long-term preservation of water ice.')])

mission('mercury','speedy-year','Speedy Year',
'Watch Mercury spin and travel around the Sun.|Discover how a spin differs from a trip around the Sun.|Separate rotation, orbital period, and sunlight cycles using Mercury.',[
C('orbit','A quick trip around the Sun','mercury-color',
'Mercury travels around the Sun. It finishes a trip sooner than the other planets.|Mercury completes an orbit in about 88 Earth days—the shortest planetary year.|Mercury is the innermost planet. Its orbital period is about 88 Earth days, shorter than every other planet’s.',
'What does Mercury travel around?|What makes one Mercury year?|Which period defines Mercury’s 88-Earth-day year?',
'Our ship follows Mercury’s path. What is in the middle?|Which journey should we follow to count a Mercury year?|A model completes one circuit around the Sun. Which Mercury motion has finished?',
'The Sun|One trip around the Sun|One full orbit around the Sun',
'Jupiter|One spin in place|One full axial rotation',
'A cloud|One crater crossing|One spacecraft flyby'),
C('rotation','A spin is a different motion','mercury-horizon',
'Mercury also spins like a top. Spinning and travelling around the Sun are two different motions.|Mercury takes about 59 Earth days to rotate once. Its rotation takes a different time from its 88-day orbit.|Mercury’s rotation period is approximately 59 Earth days. Rotation describes turning about an axis; revolution describes its orbit about the Sun.',
'Which motion is a spin?|What does Mercury do during one rotation?|How does rotation differ from revolution?',
'Our model turns in place. Is that a spin or a trip?|Which arrow should show Mercury turning around its own axis?|A marker returns after the globe turns once. Which period did we measure?',
'Turn in place|Turn once around its own axis|The axial rotation period',
'Travel around the Sun|Travel once around the Sun|The orbital period',
'Grow bigger|Grow a new crater|A change in orbital distance'),
C('solar-day','Sunrise has its own clock','mercury-horizon',
'On Mercury, a spin is not the same as sunrise to sunrise. Its slow spin and moving orbit work together.|One full sunrise-to-sunrise cycle on Mercury takes about 176 Earth days. That is different from one 59-day rotation.|Mercury’s 3:2 spin-orbit resonance gives a solar day of about 176 Earth days. The Sun’s apparent motion depends on both rotation and orbital motion.',
'Are a spin and sunrise-to-sunrise always the same?|Why should we label rotation and solar day separately?|Why does Mercury’s solar day differ from its rotation period?',
'Our model has a spin clock and a sunrise clock. Must the two clocks always match?|Which label should describe the wait from one sunrise to the next?|An observer watches the Sun return to the same sky position. Which motions affect that interval?',
'No, the two clocks can differ|Sunrise-to-sunrise is the solar day|Both rotation and motion along the orbit',
'Yes, they always match|One crater crossing is the solar day|Only the diameter of the planet',
'Only moons can spin|A solar day measures a spacecraft trip|Only the planet’s surface color')],
('Small planet, large core','mercury-color','Mercury is our smallest planet. Inside its rocky outside is a large metal core.|Mercury is only a little larger than our Moon. Its metal core is unusually large compared with its rocky outer shell.|Mercury’s core occupies a large fraction of its radius. Comparing size and density helps scientists infer interior structure without seeing the core directly.'),
'experiment','Try the two-motion model',[
T('Show a spin.|Which model setting shows rotation?|Choose the setting that isolates axial rotation.','mercury-color','Turn in place|Turn the globe in place|Rotate about the axis','Circle the Sun|Move along the orbit|Revolve around the Sun',0,'A spin turns the world in place.|Turning about the axis models rotation.|This qualitative model separates rotation from translation along an orbit.',oa='The globe turns in place.|A surface marker turns with the globe.|Rotation changes which way a surface marker faces.',ob='The globe travels around the Sun.|The world moves along its orbital path.|Revolution changes the planet’s location around the Sun.'),
T('Show a year.|Which setting completes one orbit?|Choose the motion that defines a planetary year.','mercury-color','Circle the Sun|Move along the orbit|Revolve around the Sun','Turn in place|Turn the globe in place|Rotate about the axis',0,'A year is one trip around the Sun.|One orbit defines the planet’s year.|Orbital period is the time to complete one revolution; model timing is illustrative.',oa='The planet completes a trip.|One lap models one planetary year.|The globe changes its position along the orbit.',ob='The globe spins in place.|A spin models rotation, not a full year.|The marker turns without completing an orbit.')])

mission('venus','radar-explorer','Radar Explorer',
'Peek below Venus’s cloudy blanket!|Pick a tool that can reveal Venus’s hidden surface.|Investigate how radar can map terrain through an opaque cloud deck.',[
C('hidden-surface','Clouds hide the ground','venus-global',
'Thick clouds hide Venus’s rocky ground. An ordinary picture from above cannot show all the surface.|Venus has a thick global cloud layer. Visible-light cameras looking down mostly see clouds, not the ground.|Venus’s opaque cloud deck blocks visible views of its surface from orbit. The displayed golden map uses radar data and assigned colors.',
'What hides Venus’s ground?|Why is the rocky surface hard to photograph from orbit?|What limits visible-light surface imaging at Venus?',
'A camera looks down but sees a cloudy blanket. What is in the way?|Why should a bright cloud photograph not be treated as a surface map?|Why can a cloud image hide terrain that radar reveals?',
'Thick clouds|The thick cloud layer|The opaque atmosphere in visible wavelengths',
'A giant tree|Forests taller than the clouds|Dense vegetation blocking the view',
'A moon blanket|All of Venus is hidden behind its moon|A permanent eclipse by a natural moon'),
C('radar','Echoes make a map','venus-volcano',
'Radar sends radio waves and listens for echoes. Those echoes help us map Venus under its clouds.|Magellan sent radar waves toward Venus. Returning echoes revealed mountains, plains, and volcanoes beneath the clouds.|Radar measurements encode echo travel time and strength. Magellan used these observations to reconstruct terrain hidden from visible-light cameras.',
'Which tool can help us see below the clouds?|How did Magellan map hidden landforms?|Why is radar useful for Venus surface mapping?',
'Our mapper needs clues from the ground. Which tool should we choose?|A tool sends waves down and measures returning echoes. What is it?|An orbiter cannot see the surface in visible light. Which measurement supplies terrain information?',
'Radar echoes|Radar bouncing waves off the surface|Radar echo timing and strength',
'A leaf camera|A camera watching leaves|A camera measuring forest color',
'A rain scoop|A scoop collecting ocean rain|A sensor collecting liquid-water rainfall'),
C('volcanoes','A volcanic world','venus-volcano',
'Venus has mountains and volcanoes. Radar helped spacecraft discover their shapes.|Radar maps show many volcanic landforms, including broad volcanoes and lava-covered plains.|Magellan revealed extensive volcanic terrain. A radar landform records surface structure; evaluating recent activity needs additional evidence.',
'What landform did radar find?|Which terrain clue belongs to Venus?|What can a radar map establish about Venus?',
'The hidden map reveals a broad mountain built by lava. What kind of landform is it?|Which place should a radar explorer investigate for volcanic landforms?|What is supported by a radar image of a broad volcanic feature?',
'Volcanoes|Mountains and volcanoes|The presence and shape of volcanic terrain',
'Forests|Forests of tall trees|Confirmed forests under the cloud deck',
'Blue oceans|Earth-like blue oceans|Proof that every volcano is erupting now')],
('Map colors are a tool','venus-global','The gold on this Venus map is added to help us read it. It is not a photograph of golden ground.|Venus radar maps often use assigned colors to make terrain easier to compare. Scientists explain which measurements an image represents.|A rendered radar mosaic and a visible-light photograph represent different measurements. Assigned colors can encode terrain or emphasize features without depicting natural surface color.'),
'evidence','Choose the mapper’s evidence',[
T('Find the ground clue.|Which record tells us about the rocky ground beneath Venus’s clouds?|Select evidence that can constrain hidden surface landforms.','venus-global','Radar map|Radar surface map|Radar-derived terrain map','Cloud photo|Visible-light cloud photo|Visible-wavelength cloud-top image',0,'Radar echoes can reveal the ground.|The map uses echoes from beneath the cloud layer.|Radar observations provide surface information that visible cloud imagery cannot.'),
T('What does a volcano shape tell us?|What can a mapped volcano shape support?|Which claim is warranted by a mapped volcanic landform alone?','venus-volcano','A volcano is there|A volcanic landform exists|The mapped terrain has a volcanic landform','It erupts right now|Every volcano erupts right now|Every mapped volcano is currently erupting',0,'Its shape is a clue about the land.|A volcanic shape does not prove an eruption is happening today.|Morphology supports a volcanic interpretation; current activity requires further observations.')])

mission('venus','heat-trap-detective','Heat-Trap Detective',
'Find the planet with the thick warm blanket.|Compare planet atmospheres to solve a temperature puzzle.|Use atmospheric evidence to explain why Venus is hotter than nearer Mercury.',[
C('carbon-dioxide','A thick atmosphere','venus-global',
'Venus has very thick air. Much of that air is a gas called carbon dioxide.|Venus’s atmosphere is mostly carbon dioxide. Its surface pressure is far higher than Earth’s.|A dense carbon-dioxide atmosphere surrounds Venus. High pressure and greenhouse warming create surface conditions unlike Earth’s.',
'Which clue fits Venus’s air?|Which gas makes up most of Venus’s atmosphere?|Which atmospheric description fits Venus?',
'Which air clue should we add to our Venus exploration log?|Which atmosphere clue should accompany a Venus surface mission?|Which environment should engineers plan for at Venus’s surface?',
'Very thick air|Mostly carbon dioxide|Dense CO₂ with very high surface pressure',
'Almost no air|Almost no atmosphere|A Mercury-like tenuous exosphere',
'Breathing air like home|Air just like Earth’s|Earth-like surface pressure and composition'),
C('greenhouse','Heat does not escape easily','venus-volcano',
'Venus’s thick air makes it hard for warmth to escape. The ground becomes very hot.|Greenhouse gases absorb and re-emit outgoing heat radiation. Venus’s thick atmosphere produces powerful greenhouse warming.|Venus receives solar energy, while its dense atmosphere strongly impedes loss of infrared energy to space. This creates extreme greenhouse warming.',
'What does Venus’s thick air do to warmth?|How does Venus’s atmosphere help make it so hot?|Which energy process explains Venus’s high surface temperature?',
'Warmth tries to leave the ground. What does the thick atmosphere do?|Which explanation fits heat building up beneath Venus’s clouds?|Why does an atmosphere rich in infrared-absorbing gas change surface temperature?',
'Keeps more warmth in|Makes heat escape less easily|Reduces efficient loss of infrared energy to space',
'Turns warmth into ice|Freezes all the warmth into ice|Transforms all incoming sunlight into ice',
'Makes the Sun move|Pulls the Sun closer to Venus|Changes the Sun’s position instead of energy flow'),
C('temperature-compare','A surprising temperature winner','mercury-horizon',
'Mercury is nearer the Sun. Venus is hotter because of its thick heat-trapping air.|Comparing Mercury and Venus shows that distance alone cannot predict surface temperature. Venus’s atmosphere makes the difference.|Mercury’s sparse exosphere contrasts with Venus’s dense greenhouse atmosphere. Both incoming sunlight and outgoing energy matter in a temperature model.',
'Which is hotter: Venus or Mercury?|What makes Venus hotter than nearer Mercury?|Which comparison challenges a distance-only temperature model?',
'The nearer planet has little air. Can the farther planet still be hotter?|Which extra clue should we check before choosing the hotter planet?|Why can the order of average temperatures differ from the order of solar distances?',
'Venus can be hotter|Atmosphere and heat trapping|Different atmospheric greenhouse effects',
'Mercury must be hotter|Only distance from the Sun matters|Solar distance is the only relevant variable',
'Both must feel the same|Planet names control temperature|The names determine absorbed solar energy')],
('Surface conditions challenge explorers','venus-volcano','Venus’s ground is far too hot for people. Robot explorers need special protection.|Venus’s surface is around 465°C with crushing pressure. Landers must withstand both heat and pressure.|Engineering a Venus lander requires thermal protection and pressure tolerance. Atmospheric observations and radar mapping can also be made without landing.'),
'experiment','Try the atmosphere model',[
T('Keep more warmth in.|Which setting represents Venus’s heat-trapping atmosphere?|Choose the qualitative model with stronger infrared heat retention.','venus-global','Thick greenhouse air|Dense greenhouse atmosphere|Strong infrared absorption','Very thin air|Very sparse exosphere|Weak atmospheric infrared absorption',0,'Thick greenhouse air keeps more warmth near the ground.|More outgoing heat is absorbed and re-emitted by greenhouse gases.|This conceptual comparison changes atmospheric heat retention, not measured planetary temperatures.',oa='More warmth stays near the ground.|Heat escapes less easily in this model.|Stronger infrared absorption reduces efficient cooling.',ob='Warmth escapes more easily.|This atmosphere retains less heat.|Weaker infrared absorption permits more efficient cooling.'),
T('Change one thing in our model.|To compare air fairly, what should stay the same?|Which comparison isolates atmospheric heat retention?','venus-volcano','Same sunlight|Keep incoming sunlight the same|Hold incoming solar energy fixed','Change everything|Change sunlight and atmosphere together|Vary all model inputs at once',0,'Keep sunlight the same to test the air.|Changing one feature helps us compare its effect.|Holding incoming energy fixed makes the effect of changed heat retention easier to interpret.',oa='We compare two air settings fairly.|Only the atmosphere setting changes.|The comparison isolates the selected atmosphere variable.',ob='Many things change together.|We cannot tell which change caused the result.|Confounding variables prevent a clean attribution.')])

mission('venus','backward-spinner','Backward Spinner',
'Make Venus spin the other way!|Explore Venus’s unusual spin and two different clocks.|Compare retrograde rotation, revolution, and the solar-day interval.',[
C('retrograde','The other way around','venus-global',
'Venus spins in the opposite direction to Earth and most planets.|Viewed from above the solar system’s north side, Venus rotates in the opposite direction to most planets.|Venus has retrograde rotation. The direction of its axial spin differs from most planets, although its orbital motion around the Sun remains prograde.',
'Which way does Venus spin compared with Earth?|What is unusual about Venus’s rotation?|Which statement describes retrograde rotation?',
'Two model globes spin in opposite directions. Which one can represent Venus?|Which motion does “backward spin” describe?|Does retrograde rotation mean Venus must orbit the Sun backward too?',
'The other way|Its spin is opposite to most planets|Axial spin is reversed, not its orbital direction',
'Exactly the same way|It does not spin at all|The planet has no axial rotation',
'It never moves|It orbits around Earth|The planet revolves around Earth'),
C('rotation-orbit','A spin takes longer than a year','venus-global',
'Venus turns very slowly. One full spin takes longer than one trip around the Sun.|Venus rotates once in about 243 Earth days and orbits the Sun in about 225 Earth days.|Venus’s axial rotation period exceeds its orbital period. These are separate motions, so a rotation can take longer than a year.',
'Which takes Venus longer: a spin or a Sun trip?|Which Venus clock lasts longer?|What does comparing 243 and 225 Earth days establish?',
'Venus finishes a Sun trip before a full spin. Which clock is slower?|Which label belongs on the longer Venus motion?|A Venus year ends before one full axial turn. Which period is longer?',
'One full spin|One full rotation|The axial rotation period',
'One Sun trip|One full orbit|The orbital period',
'Neither motion happens|Neither motion occurs|The planet is motionless'),
C('solar-clock','Sunrise has a different interval','venus-volcano',
'Venus can have a sunrise before one full spin ends. Its spin and Sun trip work together.|Sunrise to sunrise takes about 117 Earth days on Venus. That differs from its 243-day rotation period.|Venus’s retrograde spin and orbital motion combine to produce a solar day of roughly 117 Earth days. A solar day and a sidereal rotation period are different quantities.',
'Can sunrise and a full spin use different clocks?|Which clock measures sunrise to sunrise?|Why is Venus’s solar day shorter than its rotation period?',
'Our observer sees a new sunrise before a full spin. Is that possible?|Which interval should go on a sunrise-to-sunrise card?|An observer tracks the Sun, not a distant star. Which motions shape the measured interval?',
'Yes, they can differ|The solar-day clock|Combined retrograde spin and orbital motion',
'No, clocks must match|The volcano-age clock|Only the age of the volcanoes',
'Venus has no sunrise|The spacecraft-size clock|Only the spacecraft’s dimensions',source='venus-spin')],
('Earth-sized, very different','venus-global','Venus is almost as wide as Earth. Similar size does not mean the two worlds feel the same.|Venus and Earth are similar in size, but their atmospheres and surface conditions differ greatly.|Size is one comparison variable. Composition, atmospheric evolution, and energy balance help explain why nearly Earth-sized Venus has very different conditions.'),
'experiment','Try Venus’s two clocks',[
T('Make the Venus spin.|Which spin direction fits Venus compared with Earth?|Choose the retrograde spin setting while keeping the orbit direction unchanged.','venus-global','Reverse the spin|Spin opposite to Earth|Reverse axial rotation only','Match Earth’s spin|Spin in Earth’s direction|Use Earth-like prograde rotation',0,'Venus spins the other way.|Retrograde means the spin direction is reversed.|Retrograde axial rotation does not require a reversed orbit.',oa='The globe spins the other way.|The surface marker turns opposite to Earth’s.|The model displays retrograde rotation.',ob='The globe follows Earth’s spin.|This setting shows Earth-like spin direction.|The model displays prograde rotation.'),
T('Choose the sunrise clock.|Which clock follows the Sun returning to the same sky place?|Choose the observable that defines a solar day.','venus-volcano','Watch the Sun|Track sunrise to sunrise|Track the Sun’s apparent return','Count a full spin|Track one axial turn|Track one sidereal rotation',0,'The sunrise clock watches the Sun.|The Sun’s return defines a solar day.|Solar-day timing combines spin with orbital motion; animation speed is illustrative.',oa='The Sun returns to its sky place.|This models the solar-day interval.|The observer tracks the Sun’s apparent cycle.',ob='The globe completes a turn.|This measures rotation instead of the solar day.|The marker completes an axial rotation.')])

mission('earth','our-water-world','Our Water World',
'Find oceans, land, and our air blanket.|Discover the clues that make Earth our living home.|Compare Earth’s hydrosphere, atmosphere, and evidence of life.',[
C('oceans','A planet with oceans','earth-blue-marble',
'Blue oceans cover most of Earth. Earth has liquid water on its surface.|Oceans cover about 71 percent of Earth’s surface. Liquid water connects many habitats.|Earth’s global ocean covers roughly 71% of the surface. Stable surface liquid water is a key environmental difference from the other planets.',
'What covers most of Earth?|Which feature covers most of Earth’s surface?|Which observation describes Earth’s hydrosphere?',
'Our picture looks mostly blue. What could the blue show?|Which Earth clue belongs in the water group?|A globe shows extensive surface water. Which environmental feature is represented?',
'Oceans|Liquid-water oceans|A global liquid-water ocean',
'Dry sand|Dry sand everywhere|A uniformly dry sandy surface',
'Hot lava|A global lava sea|An exposed global magma ocean'),
C('atmosphere','Our blanket of air','earth-blue-marble',
'Air surrounds Earth. We breathe it, and clouds move through it.|Earth’s atmosphere is mostly nitrogen and oxygen. It supports breathing and helps regulate surface conditions.|Earth’s nitrogen-oxygen atmosphere provides an environment for life and participates in the planet’s energy balance and water cycle.',
'What surrounds Earth?|Which gases make up most of Earth’s air?|Which atmospheric composition fits Earth?',
'We look for the layer where clouds float. What is it?|Which air clue helps distinguish Earth from Venus?|Which comparison separates Earth’s atmosphere from Venus’s CO₂-dominated atmosphere?',
'Air|Mostly nitrogen and oxygen|Nitrogen and oxygen dominate',
'Solid stone|Mostly solid rock|A layer of solid silicate rock',
'Only carbon dioxide|Almost all carbon dioxide|Carbon dioxide dominates as on Venus'),
C('known-life','The home of known life','earth-blue-marble',
'Plants, animals, and people live on Earth. It is the only world where we know life exists.|Earth is the only planet with confirmed life. Scientists investigate other worlds without assuming they have life.|Confirmed life has been observed only on Earth. Potential habitability elsewhere is a scientific question, not a detection of living organisms.',
'Where do we know living things live?|Which world has confirmed life?|Which claim is supported by current evidence of life?',
'Our log has a real tree and animal picture. Which world is it from?|Only one world in our log has confirmed life. Which statement should remain verified?|Which statement separates a potentially habitable world from a confirmed inhabited world?',
'Earth|Earth has confirmed living things|Earth has confirmed life; habitability alone is not proof',
'Every planet|Every planet has proven life|Every potentially habitable environment is inhabited',
'No worlds|No life has ever been found|No planet has evidence of living organisms')],
('Many systems work together','earth-blue-marble','Earth’s water, air, rocks, and living things affect each other. A planet is full of connections.|Water, air, land, and life form interacting Earth systems. A change in one can affect the others.|Earth science studies linked systems: atmosphere, hydrosphere, geosphere, and biosphere. Observations over time help distinguish short changes from longer patterns.'),
'classify','Sort our home-world clues',[
T('Put an ocean in its group.|Does an ocean belong with water or rock?|Classify a surface ocean in an Earth-system group.','earth-blue-marble','Water|Water system|Hydrosphere','Rock|Rock system|Geosphere',0,'An ocean is liquid water.|The water group includes oceans.|Oceans are part of the hydrosphere.'),
T('Put a continent in its group.|Does rocky land belong with water or rock?|Classify exposed continental rock in an Earth-system group.','earth-blue-marble','Rock|Rock system|Geosphere','Water|Water system|Hydrosphere',0,'A continent has rocky land.|Rocky land belongs in the rock group.|The geosphere includes Earth’s solid rock and landforms.')])

mission('earth','season-tracker','Season Tracker',
'Tilt our Earth model and follow the sunlight.|Find out why seasons change in opposite hemispheres.|Use a fixed tilted axis to investigate seasonal sunlight patterns.',[
C('tilt','A tilted world','earth-blue-marble',
'Earth is tilted as it travels around the Sun. The tilt changes how sunlight reaches each half.|Earth’s tilted axis causes seasons. The tilt changes the sunlight angle and length of daylight during its orbit.|Earth’s axis is tilted about 23.4 degrees. As Earth orbits, this orientation produces seasonal differences in solar angle and daylight duration.',
'What helps make Earth’s seasons?|Which feature causes the yearly pattern of seasons?|Which mechanism drives Earth’s seasonal solar-energy pattern?',
'Our model Earth leans as it travels. Which clue should we keep?|A model shows a seasonal sunlight cycle. Which planet feature can cause that cycle?|Which variable explains opposite seasonal changes without requiring a change in solar output?',
'Earth’s tilt|The tilt of Earth’s axis|Axial tilt changing illumination',
'The Sun switching off|The Sun switching off each winter|The Sun ceasing emission in winter',
'Earth changing color|Earth changing its paint|Seasonal repainting of the surface'),
C('hemispheres','Two halves, opposite seasons','earth-blue-marble',
'When the north half tilts toward the Sun, it gets summer. The south half has winter.|The Northern and Southern Hemispheres have opposite seasons because one leans toward the Sun as the other leans away.|Opposite hemispheres experience different solar angles and daylight durations at the same orbital location. Northern summer coincides with southern winter.',
'North has summer. What can south have?|The Northern Hemisphere has summer. Which season can Australia have?|What follows when the Northern Hemisphere tilts toward the Sun?',
'Our north-half scout gets summer sunlight. Which season fits the south half?|A postcard shows northern summer. Which season should a southern postcard show?|What does opposite illumination imply about the Southern Hemisphere at northern summer solstice?',
'Winter|Winter in the Southern Hemisphere|Southern winter with less direct sunlight',
'The same summer|Summer everywhere on Earth|Identical summer illumination in both hemispheres',
'No seasons anywhere|Earth has no seasons|The seasonal cycle has stopped'),
C('sun-angle','Sunlight angle matters','earth-blue-marble',
'Sunlight aimed more directly at the ground warms it more than the same light spread out.|More direct sunlight concentrates energy on a smaller surface area. Slanting light spreads the same energy farther.|For otherwise equal incoming light, a lower solar angle distributes energy across a larger surface area. Illumination geometry helps explain seasonal heating.',
'Which sunlight is more direct?|Why can more direct sunlight heat a patch more?|How does sunlight angle affect energy per unit surface area?',
'Which beam could warm the same small patch more: straight-on or spread sideways?|Two equal beams cover different areas. Which patch gets more energy in each small part?|Holding beam energy fixed, which geometry delivers greater energy per surface area?',
'Light aimed straight at the patch|The more direct beam|A beam concentrated over a smaller area',
'Light spread far sideways|The more slanting beam|A beam spread over a larger area',
'A lamp with no light|A beam with no light at all|No incoming radiation')],
('One orbit, one year','earth-blue-marble','Earth takes about a year to travel around the Sun. Its tilt points almost the same way during that trip.|As Earth orbits, its axis stays oriented nearly the same way in space. This is why the favored hemisphere changes.|The axis keeps a nearly fixed orientation over one orbital year. A seasonal model must preserve that orientation while moving Earth around the Sun.'),
'experiment','Try the tilted-globe model',[
T('Give the north half summer sunlight.|Which model setting favors the Northern Hemisphere?|Select the orientation giving the Northern Hemisphere more direct sunlight.','earth-blue-marble','North toward Sun|North pole tilted toward the Sun|Northern axis toward solar illumination','North away|North pole tilted away from the Sun|Northern axis away from solar illumination',0,'North toward the Sun models northern summer.|North receives more direct sunlight in this setting.|The qualitative model changes illumination geometry, not a real-time weather forecast.',oa='North gets more direct light.|The north-half model favors summer illumination.|Northern solar angle and daylight are greater.',ob='North gets less direct light.|The north-half model favors winter illumination.|Northern solar angle and daylight are reduced.'),
T('Move to the other side of the Sun.|How should the tilted axis point after half an orbit?|Choose the model rule that preserves the axis orientation over the orbit.','earth-blue-marble','Keep its direction|Keep the tilt pointing the same way in space|Maintain a fixed axis orientation','Always aim north at Sun|Turn north toward the Sun at every position|Continuously reorient the axis toward the Sun',0,'Keep the tilt pointing the same way.|The other hemisphere becomes favored after half an orbit.|Fixed axis orientation lets orbital position change which hemisphere leans toward the Sun.',oa='The favored half changes.|The opposite hemisphere now receives summer illumination.|Seasonal illumination reverses between hemispheres.',ob='North always faces the Sun.|This would remove the normal alternating pattern.|A Sun-tracking axis does not model Earth’s yearly seasonal geometry.')])

mission('earth','eyes-in-orbit','Eyes in Orbit',
'Help our satellite spot clouds and glowing skies.|Choose observations that tell us about our changing home.|Match satellite measurements with weather and space-environment questions.',[
C('cloud-observe','Watch clouds from above','tech-satellite',
'Satellites can look down at clouds. Pictures taken again and again show clouds moving.|Weather satellites observe clouds over large areas. Comparing pictures over time helps track weather systems.|Repeated satellite observations help meteorologists follow cloud patterns and atmospheric changes. One image is an observation; a time sequence reveals motion.',
'What can a weather satellite watch?|Why do scientists compare cloud pictures taken at different times?|What extra information comes from a time sequence of cloud observations?',
'Two pictures show a cloud in different places. What can we notice?|Which change can repeated weather images help us follow?|How would repeated measurements improve a single cloud map?',
'Clouds moving|Movement of clouds and storms|Change and motion over time',
'Clouds made of rock|Rocks growing in the atmosphere|Proof that clouds are solid rock',
'A planet changing its name|The planet changing its name|A change in astronomical classification',source='earth-observe'),
C('aurora','Glowing polar skies','earth-aurora',
'Near Earth’s poles, the sky can glow in an aurora. Tiny particles make gases in the air shine.|Energetic particles guided by Earth’s magnetic field interact with atmospheric gases. They can produce glowing auroras near the poles.|Auroral light is emitted when energetic particles interact with atmospheric gases. Earth’s magnetic field guides many of these particles into polar regions.',
'What is an aurora?|What makes the polar sky glow in an aurora?|Which process produces auroral light?',
'Our polar camera sees glowing ribbons. What could they be?|Which clue connects an aurora to Earth’s air?|Which explanation links energetic particles, polar regions, and atmospheric light?',
'A glowing sky show|Particles making atmospheric gases glow|Energetic particles exciting atmospheric gases',
'A painted cloud|Paint added to every cloud|Pigment spreading through the upper atmosphere',
'A volcano in space|A volcano on the Sun’s surface falling to Earth|Molten lava falling from the Sun',source='aurora'),
C('measurements','Choose evidence for the question','tech-satellite',
'A scientist chooses a tool for a question. To follow clouds, we need cloud pictures.|Different instruments answer different questions. Repeated cloud images are useful for tracking a weather system.|An observing plan should match measurement to hypothesis. Cloud imaging tests cloud-motion questions; it does not directly measure deep interior structure.',
'Which record helps us follow clouds?|Which observation fits a cloud-motion question?|What makes an observing plan useful?',
'Mission Control wants to know where clouds went. Which record should we send?|Which data should we compare to track a storm?|What observation most directly tests a proposed cloud-motion direction?',
'Cloud pictures at two times|Repeated pictures of the clouds|Time-separated cloud-position measurements',
'A picture of our shoes|A picture of the satellite’s paint|Only the satellite’s exterior color',
'A planet-name list|A list of planet names|A catalog of unrelated planet names',source='earth-observe')],
('An observation is not the whole forecast','tech-satellite','One picture is a clue. Scientists use many clues to learn what weather may come next.|Forecasts combine observations with models of the atmosphere. A cloud picture is useful but cannot answer every weather question alone.|Weather forecasting integrates measurements and physical models. Predictions carry uncertainty, so a changing atmosphere requires repeated updates.','earth-observe'),
'evidence','Build a satellite observation plan',[
T('Find the weather record.|Select the record that helps follow a cloud system.|Choose evidence for measuring cloud motion.','tech-satellite','Cloud images over time|Two cloud maps at different times|A sequence of geolocated cloud maps','A rocket’s paint color|A photograph of rocket paint|A launch vehicle’s exterior color',0,'Pictures over time show change.|Cloud positions at two times reveal movement.|Time-separated observations allow motion to be estimated.'),
T('Find the aurora clue.|Which clue links a polar glow to Earth’s atmosphere?|Which evidence fits atmospheric auroral emission?','earth-aurora','Gases glowing|Light from gases high in the air|Emission from upper-atmosphere gases','A ring of rocks|Rocks in a ring around Earth|Reflected light from a rocky planetary ring',0,'Air gases can shine in an aurora.|Particles can make atmospheric gases emit light.|Excited atmospheric gases emit the observed auroral light.')])
mission('mars','rover-rock-hunt','Rover Rock Hunt',
'Help our robot find interesting rocks!|Choose rover observations that explain Mars’s rusty landscape.|Build a surface investigation using color, rock layers, and rover instruments.',[
C('rust','Why the ground looks red','mars-landscape',
'Many Mars rocks and dust contain rusty iron. That rust helps make Mars look red.|Iron minerals oxidize, or rust, in Martian rocks and dust. They give much of the surface its reddish color.|Oxidation changes iron-bearing minerals and contributes to Mars’s reddish dust. The planet is not uniformly red at every location.',
'What helps make Mars red?|Why does much of Mars look reddish?|Which process contributes to the reddish Martian surface?',
'Our rover finds rusty-colored dust. Which material clue fits?|Which comparison helps explain red dust without inventing red plants?|What chemical explanation fits iron-bearing minerals and a reddish dust coating?',
'Rusty iron|Rusty iron in rocks and dust|Oxidation of iron-bearing minerals',
'Red leaves|Forests of red plants|Seasonal red vegetation',
'Red paint from Jupiter|Red light sent by Jupiter|Reflected red illumination from Jupiter'),
C('layers','Read a rock’s pages','mars-landscape',
'Some Mars rocks have layers. A rover looks closely to learn how the layers formed.|Rock layers can record different episodes of deposition. Rovers examine their shapes and composition for clues.|Stratified rocks preserve sequences of deposition and alteration. Interpreting their history requires both morphology and compositional measurements.',
'Which rock clue should our rover study?|Why are rock layers useful to a rover scientist?|What makes layered rocks useful for reconstructing past conditions?',
'Our rover sees lines stacked in a rock. What should it inspect?|Which feature can preserve several parts of a place’s history?|What investigation could distinguish different depositional episodes?',
'The rock’s layers|Layers that can record past events|Layer geometry and composition',
'The rover’s stickers|The rover’s decorative stickers|Only the paint on the rover',
'The planet’s name|The spelling of Mars’s name|Only the planet’s name'),
C('rover-tools','A robot with science tools','tech-rover',
'A rover is a robot that moves on the ground. Cameras and other tools help it study rocks.|Rovers carry cameras and scientific instruments. They inspect nearby rocks and help scientists decide what to study next.|A rover combines mobility, imaging, and in-place measurements. Instrument choice depends on whether the question concerns shape, composition, or another property.',
'Which explorer can drive to a rock?|What makes a rover useful for studying nearby rocks?|Which observing strategy uses a rover’s strengths?',
'Our team needs a close look at a rock. Which robot should help?|Which plan brings instruments to several surface targets?|What method can compare neighboring rocks at close range?',
'A rover|A rover driving between rocks|Mobile in-place measurements',
'A cloud|A cloud floating above Mars|Only watching unrelated clouds',
'A fixed star|A distant star with no instruments|Observing a distant star instead of the targets')],
('A color clue needs more evidence','mars-comparison','A red rock is a clue, but color cannot tell us everything. Robots use more than one tool.|Two rocks can have similar colors and different histories. Composition and texture give extra evidence.|Color alone does not determine mineralogy or habitability. Scientists combine measurements and consider alternative explanations before drawing conclusions.'),
'evidence','Choose the rover’s next observation',[
T('Find a rock-history clue.|Which target helps investigate how material built up?|Select a target that preserves a sequence of surface processes.','mars-landscape','Layered rock|Rock with visible layers|A stratified rock outcrop','Robot sticker|Decorative rover sticker|A painted mission emblem',0,'Layers can hold old clues.|Layered rock can record repeated deposition.|Strata can preserve a sequence that imaging and compositional instruments investigate.'),
T('Get a closer look.|Which explorer can move to inspect the target?|Choose a method for close-range investigation of the outcrop.','tech-rover','Drive the rover|Move the rover to the rock|Acquire in-place rover observations','Wait for a star|Ask a distant star to move closer|Rely on unrelated stellar light',0,'A rover can carry tools to the rock.|Mobility lets the rover examine several nearby targets.|A rover can investigate local morphology and composition from close range.')])

mission('mars','ancient-water-detective','Ancient Water Detective',
'Find clues that water once flowed on Mars.|Read dry valleys and rock clues from Mars’s watery past.|Compare multiple observations supporting ancient liquid-water environments.',[
C('valleys','Channels from long ago','mars-canyons',
'Mars has old channels and valleys. Some tell us water flowed long ago.|Ancient river-valley networks show that flowing water shaped parts of Mars in the past.|Networks of channels and valleys provide geomorphic evidence for ancient flow. Their shapes and connections help distinguish plausible formation processes.',
'What may have flowed in an old river channel?|What can ancient river valleys tell us about Mars?|Which inference is supported by ancient connected river-valley networks?',
'Our map shows branches joining an old channel. Which story fits?|What conclusion can old connected river valleys support?|Why are connected channel networks more useful than a single red patch?',
'Water long ago|Liquid water flowed there in the past|Past surface flow shaped connected channels',
'Trees flying|Flying forests carved the ground|A flying forest carved every channel',
'Paint spreading|Red paint made all the valleys|Color alone produced the landforms'),
C('deltas','Where a river spread its load','mars-landscape',
'A river can leave a fan of sand and mud where it enters a lake. Old Mars deltas are clues about water.|Deltas form when flowing water deposits sediment as it enters quieter water. Ancient delta shapes help scientists search for past lake environments.|Deltaic deposits preserve sediment transport and deposition at water-body margins. Their geometry and layered sediment can support reconstructions of ancient lake settings.',
'What can leave a delta?|Why is an old delta a useful water clue?|Which process can create deltaic deposits?',
'What event can leave sand and mud where a channel meets a lake?|What process can leave sediment where a channel enters an old lake?|A fan-shaped deposit lies at an old channel mouth. Which process fits?',
'A river leaving sand and mud|A river depositing sediment near a lake|Sediment deposited as flow enters quieter water',
'A cloud turning to stone|A cloud becoming solid stone|Clouds transforming directly into bedrock',
'A spinning moon|A moon drawing shapes on the ground|Orbital motion drawing surface fans'),
C('minerals','Clues inside the rocks','mars-landscape',
'Some minerals form when water changes rock. Robots look for these clues on Mars.|Certain Martian minerals formed or changed in the presence of liquid water. They add evidence alongside landforms.|Water-altered minerals provide compositional evidence that complements geomorphology. Multiple independent clues strengthen an interpretation of a past aqueous environment.',
'Which rock clue can tell us about old water?|Why look at minerals as well as valleys?|How can mineral measurements strengthen an ancient-water interpretation?',
'Which rock clue adds evidence that water changed this place?|A valley map suggests water. Which extra evidence would help?|What makes agreement between channel geometry and water-altered minerals valuable?',
'A mineral made with water|Minerals changed by liquid water|Independent compositional evidence for aqueous alteration',
'A robot’s shiny paint|The rover’s shiny paint|Unrelated exterior paint color',
'A name on a map|A memorable place name|A location’s name without a measurement')],
('Water evidence is not proof of life','mars-landscape','Old water clues are exciting. They do not mean we have found living things on Mars.|A past wet environment may be interesting for habitability, but water evidence is not evidence that life lived there.|Habitability and the presence of life are different claims. Testing for past life requires suitable evidence and careful evaluation of nonbiological explanations.'),
'evidence','Build a water-evidence case',[
T('Choose an old water clue.|Which clue supports ancient flowing water?|Select morphological evidence for an ancient aqueous setting.','mars-landscape','Old channel and delta|Connected channel and delta deposit|Channel geometry with a deltaic deposit','Rover paint|Red paint on the rover|The rover’s exterior paint',0,'Channels and deltas can record water flow.|Their shapes fit transport and deposition by water.|Connected fluvial and deltaic landforms support a past-flow interpretation.'),
T('Add a second clue.|Which record adds different evidence for old water?|Choose an independent compositional line of evidence.','mars-landscape','Water-made minerals|Water-altered minerals|Minerals indicating aqueous alteration','Another place name|A second name on the map|An additional location name',0,'Some minerals tell a water story.|Minerals add clues from the rocks themselves.|Composition complements the shape evidence rather than merely repeating a map label.')])

mission('mars','landforms-and-seasons','Landforms and Seasons',
'Spot a giant mountain, canyon, and changing ice!|Compare Mars’s impressive landforms and seasonal polar caps.|Distinguish volcanic, tectonic, and seasonal processes using different observations.',[
C('volcano','Olympus Mons rises high','mars-olympus',
'Olympus Mons is a huge volcano on Mars. Lava built this broad mountain.|Olympus Mons is a broad shield volcano. Repeated lava flows built an enormous volcanic landform.|Olympus Mons is a vast shield volcano. Its broad shape reflects accumulated lava flows; stated heights depend on which base or reference level is used.',
'What kind of mountain is Olympus Mons?|What process built Olympus Mons?|Which process best explains a broad shield volcano?',
'Our map shows a very broad volcanic mountain. Which clue fits?|Which process belongs in a broad volcano’s history log?|An enormous shield volcano is mapped. Which formation explanation is appropriate?',
'A volcano|Repeated lava flows|Lava accumulation, with a defined height reference',
'A cloud tower|Clouds stacked into a mountain|Atmospheric clouds becoming permanent mountains',
'An ocean wave|A wave frozen into rock|A single liquid-ocean wave'),
C('canyon','A vast canyon system','mars-canyons',
'Valles Marineris is a huge canyon system on Mars. Its walls show many layers.|Valles Marineris stretches for roughly 4,000 kilometres. Crustal stretching and later erosion helped shape this vast canyon system.|Valles Marineris is a major tectonic canyon system modified by landslides and other processes. It should not be treated as merely a scaled-up river-carved Grand Canyon.',
'Which landform has deep canyon walls?|Which clue describes Valles Marineris?|Which interpretation best fits Valles Marineris?',
'Our scout sees a long, deep cut with layered walls. Which group fits?|Long, deep cuts with layered walls cross the map. What landform group fits?|Why should Earth’s Grand Canyon not be used as an identical formation model?',
'A canyon|A vast canyon system|A tectonic canyon modified by several processes',
'A tiny pond|A small shallow pond|A pond with no crustal deformation',
'A spinning cloud|A storm in the atmosphere|An atmospheric vortex with no surface relief'),
C('seasonal-ice','Ice changes with the seasons','mars-polar-cap',
'Mars’s polar ice caps grow in winter and shrink as warmer seasons arrive.|Mars’s caps contain water ice and seasonal carbon-dioxide frost. The seasonal cover grows and retreats.|Time-separated images reveal seasonal polar-cap changes. Carbon-dioxide frost contributes to growth and retreat around longer-lived water-ice deposits.',
'What can happen to Mars’s ice with the seasons?|Which observation fits seasonal polar-cap change?|Which process helps explain a changing cap boundary?',
'Our winter and spring pictures look different. What changed?|What could a retreating polar boundary tell us?|Images show growing winter frost and spring retreat. Which process fits?',
'Ice cover grows or shrinks|Frost grows in winter and retreats as it warms|Seasonal frost deposition and removal',
'Ice always stays the same|The cap is identical every season|An unchanging seasonal boundary',
'Ice flies to Jupiter|The whole cap leaves Mars|The entire cap entering an orbit around Jupiter')],
('Comparisons need a common ruler','mars-comparison','To compare mountain heights, start measuring from the same kind of place.|“Above nearby plains” and “from base to summit” are different height measures. A fair comparison says which one is used.|Planetary topography depends on a defined reference surface. Compare quantities with consistent units and reference levels rather than ranking mismatched height definitions.'),
'classify','File the landscape clues',[
T('Sort Olympus Mons.|Does Olympus Mons belong with volcanic mountains or seasonal frost?|Classify Olympus Mons by its main formation process.','mars-olympus','Volcano|Volcanic landform|Lava-built shield volcano','Seasonal ice|Seasonal polar frost|Seasonal CO₂ deposition',0,'Lava built the broad volcano.|Olympus Mons is a volcanic mountain.|Its broad shield morphology reflects lava accumulation.'),
T('Sort a cap that shrinks in spring.|Does a changing polar cap belong with frost or volcanic mountains?|Classify a seasonally retreating polar boundary.','mars-polar-cap','Seasonal ice|Seasonal polar frost|Seasonal CO₂ deposition','Volcano|Volcanic landform|Lava-built shield volcano',0,'Warmer seasons can shrink frost cover.|The changing boundary is a seasonal frost clue.|Seasonal condensation and sublimation can shift the cap boundary.')])

mission('jupiter','storm-scout','Storm Scout',
'Help us spot Jupiter’s stripes and swirls!|Read cloud bands and a giant storm on Jupiter.|Investigate atmospheric patterns using observations of cloud motion.',[
C('bands','Belts and zones','jupiter-global',
'Jupiter’s stripes are clouds. Winds stretch them around the giant planet.|Dark belts and light zones are cloud bands in Jupiter’s atmosphere. Neighboring bands can move in different directions.|Jupiter’s belts and zones are atmospheric structures shaped by circulation. Contrasting cloud properties and jet streams produce the banded appearance.',
'What are Jupiter’s stripes?|What makes the banded appearance on Jupiter?|Which interpretation fits Jupiter’s belts and zones?',
'A stripe moves in a sequence of pictures. What are we watching?|Which clues suggest the stripes are atmospheric features?|What does changing band motion tell us about the observed features?',
'Cloud bands|Cloud bands moved by winds|Atmospheric bands and circulation',
'Painted roads|Roads painted on solid ground|Permanent roads on a rocky surface',
'Forests in lines|Long strips of forest|Rows of vegetation on dry land'),
C('red-spot','A storm called the Great Red Spot','jupiter-red-spot',
'The Great Red Spot is a giant swirling storm on Jupiter.|The Great Red Spot is a long-lived atmospheric storm. Its size and appearance change as scientists observe it.|The Great Red Spot is a persistent anticyclonic vortex. Repeated images reveal changes in its dimensions and interactions with surrounding flows.',
'What is the Great Red Spot?|Which description fits Jupiter’s Great Red Spot?|What kind of feature is the Great Red Spot?',
'Our scout finds a huge swirl in the clouds. What is it?|Which target should we track to study a long-lived Jovian storm?|A red oval changes shape over time. Which atmospheric interpretation fits?',
'A giant storm|A swirling atmospheric storm|A persistent atmospheric vortex',
'A red mountain|A mountain made of red rock|An exposed solid mountain',
'A forest|A red forest on the ground|A region of surface vegetation'),
C('repeat-images','Follow the moving clouds','jupiter-global',
'One picture shows the clouds. More pictures show how they move.|Scientists compare Jupiter pictures taken at different times to track cloud motion and changing storms.|Tracking identifiable features across time-separated images constrains atmospheric motion. Interpretation must account for planetary rotation and viewing geometry.',
'How can we see clouds moving?|Which record helps measure cloud movement?|What observation is needed to infer cloud motion?',
'Our storm picture is still. What should we collect next?|Which set lets us compare a storm’s earlier and later shape?|Why does a single cloud photograph not establish a motion direction?',
'More pictures later|Images of the same region at several times|Time-separated observations with known geometry',
'Only one picture forever|Only one unchanging photograph|One image without a time comparison',
'A list of rock names|A list of unrelated rock names|An unrelated mineral-name catalog')],
('Image colors need interpretation','jupiter-red-spot','Some Jupiter pictures use stronger colors to make cloud details easy to spot.|Enhanced-color processing can emphasize Jupiter’s cloud patterns. Scientists record how images were made.|Juno images may use color enhancement to reveal structure. Displayed hues depend on filters and processing, so image metadata matters for physical interpretation.'),
'evidence','Follow a storm’s clues',[
T('Find the storm.|Which target is the Great Red Spot?|Select the atmospheric vortex in the image.','jupiter-red-spot','Cloud swirl|Large oval cloud swirl|A coherent atmospheric oval','Rock mountain|A rock mountain on the ground|An exposed rocky summit',0,'The spot is a swirling storm.|The Great Red Spot belongs to Jupiter’s atmosphere.|The oval is a long-lived atmospheric vortex.'),
T('Show if it moves.|Which record could show the swirl changing?|Choose observations that can constrain storm motion.','jupiter-global','Earlier and later images|Time-separated storm images|Calibrated images at multiple times','One title card|Only the planet’s title card|Only a destination label',0,'Two times let us compare.|Repeat images reveal changes in position and shape.|Temporal observations supply information absent from a label or one static frame.')])

mission('jupiter','moon-match','Moon Match',
'Match Jupiter’s moons to their special clues.|Meet an erupting moon, an icy moon, and a very large moon.|Compare Io, Europa, and Ganymede using distinct observations.',[
C('io','Io’s fiery clue','jupiter-global',
'Io is a moon of Jupiter with many active volcanoes.|Io is the solar system’s most volcanically active world. Jupiter’s tidal effects help heat its interior.|Io’s intense volcanism is driven by tidal heating within the Jovian moon system. An erupting plume is a different clue from Europa’s icy surface.',
'Which moon has many volcanoes?|Which clue belongs to Io?|Which process is central to Io’s intense volcanic activity?',
'A moon card shows an erupting volcano. Which moon fits?|Our mapper needs a volcanic moon target. Which should it choose?|Which Jovian moon is especially useful for studying tidal heating and volcanism?',
'Io|Io’s active volcanoes|Io and tidal heating',
'Europa’s ice shell|Europa’s quiet-looking ice shell|Europa’s surface ice alone',
'Earth’s Moon only|Earth’s only moon|The lunar near-side maria only'),
C('europa','Europa’s hidden-water clue','europa-global',
'Europa is covered in ice. Scientists have clues for an ocean underneath.|Europa’s icy shell and magnetic measurements support a salty ocean beneath the surface.|Multiple observations support a subsurface ocean beneath Europa’s icy shell. This is an evidence-based model; an ocean does not establish that life exists.',
'Which clue belongs to Europa?|What may be beneath Europa’s icy shell?|Which statement fits the evidence for Europa?',
'A moon has cracks in bright ice. Which hidden-water story should we investigate?|Which hidden feature could we investigate below a cracked icy shell?|Why is “ocean evidence” more careful than “life discovered”?',
'Ice with an ocean underneath|An ocean beneath an ice shell|Evidence for a subsurface ocean, without confirmed life',
'Hot bare lava everywhere|Only an exposed lava ocean|Confirmed inhabitants living on exposed lava',
'A star with no ice|A small star beside Jupiter|A self-luminous star rather than a moon'),
C('ganymede','A moon bigger than Mercury','jupiter-global',
'Ganymede is Jupiter’s biggest moon. It is even wider than planet Mercury.|Ganymede is the largest moon in our solar system. Its diameter exceeds Mercury’s, but it orbits Jupiter.|Ganymede’s size exceeds Mercury’s diameter. Its classification as a moon reflects its orbit around Jupiter, not a rule that moons must be smaller than planets.',
'Ganymede goes around Jupiter. Is it a moon or a star?|Why is large Ganymede still a moon?|What distinguishes Ganymede from Mercury despite its larger diameter?',
'Our large world goes around Jupiter. Is it a moon or a planet?|A moon is wider than Mercury. Which fact still makes it a moon?|Which observation resolves a size-based classification mistake?',
'A moon|It orbits Jupiter|Its primary orbit is around Jupiter',
'A star|It shines by making its own star light|It generates stellar fusion',
'It must be Mercury|All large moons become planets|Diameter alone makes it a planet')],
('A family with different histories','europa-global','Moons around the same planet can look very different. Each has its own story.|Io, Europa, Ganymede, and Callisto are Jupiter’s four Galilean moons. Comparing them reveals varied surfaces and histories.|Orbital interactions, composition, and interior structure contribute to the diversity of the Galilean satellites. A shared parent planet does not imply identical environments.'),
'classify','Match two moon dossiers',[
T('Match the volcano clue.|Which dossier fits many active volcanoes?|Match intense volcanism to the appropriate Galilean satellite.','jupiter-global','Io|Io, the volcanic moon|Io: intense tidal volcanism','Europa|Europa, the icy moon|Europa: an icy shell',0,'The volcano clue belongs to Io.|Io is extraordinarily volcanically active.|Io’s tidal heating drives widespread volcanic activity.'),
T('Match the icy-ocean clue.|Which dossier fits an icy shell and ocean evidence?|Match the subsurface-ocean evidence to the appropriate moon.','europa-global','Europa|Europa, the icy moon|Europa: an icy shell and ocean evidence','Io|Io, the volcanic moon|Io: intense tidal volcanism',0,'The ice clue belongs to Europa.|Europa’s observations support a hidden ocean.|Europa’s icy surface and magnetic evidence support a subsurface ocean model.')])

mission('jupiter','giant-planet-expedition','Giant-Planet Expedition',
'Plan a robot trip around giant Jupiter!|Choose a safe observing plan for a planet without solid ground.|Match an orbital investigation with Jupiter’s atmosphere and interior questions.',[
C('no-surface','No rocky place to land','jupiter-global',
'Jupiter has no solid ground like Earth’s surface. Our explorer should study it from space.|Jupiter is mostly gases and liquids. A spacecraft cannot land on an Earth-like solid surface there.|Jupiter lacks a true solid surface accessible to a lander. Increasing pressure and temperature make a deep atmospheric descent destructive.',
'Can our rover park on Jupiter’s ground?|Which plan fits Jupiter better: an orbiter or a ground rover?|Why is an orbital investigation suitable for Jupiter?',
'Our team needs a place for rover wheels. Is Jupiter’s cloud top a road?|Which vehicle can investigate Jupiter without needing rocky ground?|What hazard makes “land on the cloud top” a poor mission plan?',
'No rocky road to park on|An orbiter observing from space|No true solid surface and harsh deep conditions',
'A firm road on every cloud|A rover driving on cloud tops|Cloud tops form a stable rocky platform',
'A forest path|A bicycle on a forest track|Forests provide a safe landing site'),
C('gravity-evidence','Learn about the inside indirectly','jupiter-global',
'We cannot see straight into Jupiter. A robot can measure gravity to help scientists learn about the inside.|Juno’s gravity observations help scientists infer how mass is distributed inside Jupiter.|Small changes in spacecraft motion constrain Jupiter’s gravity field. Those measurements test interior models without directly photographing the deep interior.',
'What can help us learn about Jupiter’s inside?|Why measure Jupiter’s gravity from a spacecraft?|How can gravity data constrain an interior model?',
'Our camera cannot see the center. Which measurement could still help?|Which clue can reveal something about how Jupiter’s mass is arranged?|What links changes in spacecraft motion to interior structure?',
'Gravity clues|Gravity measurements|The gravity field responds to mass distribution',
'A painted cutaway only|A drawing without measurements|An illustration alone establishes composition',
'Counting cloud colors only|Only counting red pixels|Surface hue uniquely reveals the entire interior',source='juno'),
C('magnetic-field','Map an invisible field','jupiter-global',
'Jupiter has a strong magnetic field. A spacecraft tool can measure it even though our eyes cannot see it.|Juno carries a magnetometer to measure Jupiter’s magnetic field. Instruments can reveal invisible properties.|Magnetometer measurements constrain the strength and direction of Jupiter’s magnetic field. They complement imaging and gravity data.',
'Can a science tool find an invisible field?|What tool helps map Jupiter’s magnetic field?|Which measurement directly investigates Jupiter’s magnetosphere?',
'Our scout cannot see the field. Which tool should it use?|Which instrument belongs in a magnetic-field investigation?|Why is a magnetometer a better match than a visible-light camera for this question?',
'Yes, a field-measuring tool|A magnetometer|Magnetic-field strength and direction measurements',
'Only a picture of paint|Only a camera for paint colors|Only spacecraft paint reflectance',
'A water bucket|A bucket for rain|A collector for Earth-like ocean rainfall',source='juno')],
('Different measurements tell different stories','jupiter-global','A camera, gravity clues, and a magnetic tool each tell a different part of Jupiter’s story.|Juno combines several types of measurement. Agreement across instruments helps scientists refine explanations.|Interior and atmospheric models are constrained by multiple observations. Model uncertainty remains even when the measurements are precise.','juno'),
'evidence','Pack the giant-planet science kit',[
T('Choose our vehicle.|Which vehicle can study Jupiter without a rocky landing site?|Select a mission design suited to Jupiter’s environment.','jupiter-global','Orbiter|Orbiter with science instruments|An instrumented spacecraft in orbit','Ground rover|Rover driving on clouds|A wheeled rover on the cloud deck',0,'An orbiter does not need a road.|An orbital vehicle can observe from above the atmosphere.|Orbital measurements avoid requiring an accessible solid surface.'),
T('Choose a field tool.|Which instrument measures an invisible magnetic field?|Select an instrument that directly measures field strength and direction.','jupiter-global','Magnetic tool|Magnetometer|A magnetometer','Paint camera|Paint-color camera|A camera aimed at spacecraft paint',0,'A magnetic tool can measure the field.|A magnetometer is made for this question.|Magnetometers measure magnetic-field properties that a paint image does not.')])

mission('saturn','ring-builder','Ring Builder',
'Build a ring from tiny icy pieces!|Investigate the particles and gaps in Saturn’s rings.|Model a ring system as many independently orbiting particles.',[
C('particles','Many pieces, not one hoop','saturn-portrait',
'Saturn’s rings are made of many pieces of ice and rock. They are not one solid hoop.|Billions of particles make Saturn’s rings. Their sizes range from tiny grains to much larger chunks.|Saturn’s rings consist mainly of icy particles with rock and dust. A continuous-looking ring in a distant image is not a solid structure.',
'What are Saturn’s rings made of?|Why can the rings look smooth from far away?|Which physical model fits Saturn’s rings?',
'Our scout zooms in on a ring. What should it find?|Which construction kit represents a ring better than one solid band?|Why should a smooth image not be interpreted as a solid disk?',
'Many ice and rock pieces|Many separate particles|A collection of orbiting particles',
'One solid hoop|One solid metal hoop|A rigid connected annulus',
'A thick painted road|A painted highway in space|A road supported by solid pillars'),
C('orbits','Every piece follows an orbit','saturn-portrait',
'The ring pieces travel around Saturn. They do not all move as one stiff wheel.|Particles orbit Saturn at different distances. Different rings have different orbital speeds.|Ring particles follow individual orbits. Orbital speed varies with distance, so the system does not rotate like a single rigid wheel.',
'What do the ring pieces travel around?|Do all ring particles move as one stiff wheel?|Which motion model fits particles at different orbital distances?',
'Our ring kit has two rows of pieces. Which world do both rows travel around?|Which model should show pieces moving at different distances?|Why should an inner and outer ring not be glued into a rigid disk?',
'Saturn|They follow their own orbits|Independent orbits with distance-dependent speeds',
'Our spaceship only|They are glued into one wheel|Rigid-body rotation of a single solid structure',
'A nearby tree|They sit on branches|Stationary particles supported by branches'),
C('gaps','Spaces between the rings','saturn-earth-smiled',
'There are gaps and patterns in Saturn’s rings. Nearby moons can help shape them.|Gravity from Saturn’s moons helps create and maintain ring structures, including gaps and waves.|Gravitational interactions with moons produce resonances, waves, and gaps. Ring structure is evidence of a dynamic particle system.',
'What can help shape ring gaps?|How can a nearby moon affect ring particles?|Which mechanism can create structure within the rings?',
'A moon passes near a ring. Can its gravity change the particle paths?|Which clue could explain a patterned gap in the rings?|What connects moons’ orbits with waves and gaps in the particle disk?',
'A moon’s gravity|Gravity changing particle paths|Gravitational interactions and resonances',
'A moon’s paint|A moon painting the ring|Paint transferred between celestial bodies',
'A rope through space|Ropes holding every particle|Physical ropes connecting all particles')],
('Wide but remarkably thin','saturn-portrait','Saturn’s rings spread very far sideways but are thin from top to bottom.|The main rings span an enormous area while typically being only about ten metres thick. Thickness varies in local structures.|The main rings are geometrically thin compared with their radial extent. Local waves and structures mean a single typical thickness does not describe every location.'),
'classify','Sort the ring-building kit',[
T('Can ice pieces make a ring?|Which group should contain orbiting ice chunks?|Classify independently orbiting icy particles in the ring model.','saturn-portrait','Ring pieces|Suitable ring particles|Discrete ring material','Solid hoop|Rigid hoop model|A connected solid annulus',0,'Ice pieces can be ring particles.|Many orbiting pieces form the ring.|A particulate model fits the observed ring system.'),
T('Can one stiff hoop describe the real ring?|Which group should contain a single rigid hoop?|Classify a rigid hoop as a model of the physical rings.','saturn-portrait','Solid hoop|Poor ring-particle model|A misleading connected annulus','Ring pieces|Suitable ring particles|Discrete ring material',0,'The real ring is not one stiff hoop.|A rigid hoop misses the separate particles.|A connected structure cannot represent independent distance-dependent orbits.')])

mission('saturn','two-moon-mysteries','Two Moon Mysteries',
'Match a lake moon and a spray moon!|Compare Titan’s surface liquids with Enceladus’s icy plumes.|Separate surface methane lakes from evidence for a subsurface water ocean.',[
C('titan-lakes','Titan’s unusual lakes','saturn-portrait',
'Titan is a moon of Saturn with lakes. They hold liquid methane and ethane, not water like our lakes.|Titan is cold enough for liquid methane and ethane to form rivers, lakes, and seas at its surface.|Titan’s hydrocarbon liquids form a surface cycle of evaporation, clouds, rainfall, and flow. Similar landform shapes can involve different chemistry from Earth’s water cycle.',
'What fills Titan’s lakes?|How are Titan’s lakes different from Earth’s?|Which comparison distinguishes Titan’s surface liquids from Earth’s?',
'Our lake-moon card says “very cold.” Which lake liquid fits Titan?|A river shape looks familiar. What should we check before calling it water?|What explains familiar river morphology with unfamiliar surface chemistry?',
'Methane and ethane|Liquid methane and ethane|Surface hydrocarbon liquids rather than liquid water',
'Warm water like home|Warm liquid water like Earth’s|Earth-like warm surface water oceans',
'Melted iron|Molten iron across the surface|A global surface ocean of molten iron',source='titan'),
C('plumes','Enceladus sprays icy clues','saturn-earth-smiled',
'Enceladus is an icy moon that sprays water vapor and ice into space.|Jets from Enceladus carry water vapor and ice particles. Cassini sampled material from these plumes.|Enceladus’s south-polar plumes eject water vapor, ice, and other material. Sampling provides compositional evidence about processes below the surface.',
'What does Enceladus spray?|What could a spacecraft collect from an Enceladus plume?|Which investigation is enabled by Enceladus’s plumes?',
'Our scout spots icy jets. Which material could it study?|A scout flies through Enceladus’s jet. Which material should it investigate?|Why can a plume be valuable even without drilling through the ice?',
'Water vapor and ice|Water vapor and icy particles|Ejected material accessible to spacecraft sampling',
'Leaves and flowers|Leaves from a forest|Material from a confirmed surface forest',
'Only red paint|Only artificial red paint|Pigment from a painted surface',source='enceladus'),
C('ocean-evidence','An ocean under the ice','saturn-earth-smiled',
'Scientists have strong clues for an ocean under Enceladus’s ice. That does not mean they found living things.|Plume composition, gravity, and the moon’s wobble support a global water ocean beneath Enceladus’s ice.|Several measurements support a subsurface saltwater ocean. Suitable ingredients and energy sources are habitability clues, not a detection of life.',
'Where may Enceladus’s ocean hide?|Which description fits Enceladus’s water-ocean evidence?|What claim is supported by Enceladus’s observations?',
'The outside is icy but jets bring water-rich material out. Where should we investigate?|Which water environment is supported by plume material and gravity clues?|Why should an ocean-world dossier separate habitability from life detection?',
'Under the ice|An ocean beneath an icy shell|A subsurface ocean supported by multiple measurements',
'In a warm forest|A warm surface ocean with forests|Confirmed forests around warm surface water',
'Inside the Sun|A water ocean inside the Sun|A solar ocean unrelated to the moon',source='enceladus')],
('Moon clues inside Saturn’s portrait','saturn-portrait','This picture shows Saturn, not a close-up of its moons. Our moon clues come from spacecraft measurements.|A planet portrait introduces the Saturn system. Titan and Enceladus facts here come from separate moon observations, not visible details in this portrait.|Images and claims must match their evidence. A contextual Saturn photograph does not itself reveal Titan’s lake chemistry or Enceladus’s ocean; those claims use moon-specific data.','titan'),
'classify','Match the lake and plume dossiers',[
T('Match methane lakes.|Which moon dossier contains surface methane lakes?|Classify surface hydrocarbon lakes in the Saturn system.','saturn-portrait','Titan|Titan’s surface lakes|Titan: liquid methane and ethane','Enceladus|Enceladus’s icy jets|Enceladus: water-rich plumes',0,'Methane lakes belong to Titan.|Titan’s surface liquids are mainly methane and ethane.|Titan’s hydrocarbon surface cycle differs from Enceladus’s plume activity.'),
T('Match icy water jets.|Which moon dossier contains water-rich plumes?|Classify water-vapor and ice plumes in the Saturn system.','saturn-earth-smiled','Enceladus|Enceladus’s icy jets|Enceladus: water-rich plumes','Titan|Titan’s surface lakes|Titan: liquid methane and ethane',0,'The icy jets belong to Enceladus.|Enceladus ejects water-rich material into space.|Its plume composition provides access to evidence from beneath the ice.')])

mission('saturn','cassini-detective','Cassini Detective',
'Choose clues for our Saturn robot explorer!|Use Cassini’s discoveries to plan ring and moon observations.|Match questions about the Saturn system with appropriate measurements.',[
C('orbiter','A long look from orbit','saturn-earth-smiled',
'Cassini was a robot spacecraft that travelled around Saturn. It studied the planet, rings, and moons.|Cassini orbited Saturn and repeatedly observed its rings and moons. Repeat encounters revealed changes and varied viewpoints.|Cassini’s orbital tour enabled diverse observations across the Saturn system. A repeated observing campaign supplies temporal and geometric information unavailable in one flyby.',
'What kind of explorer was Cassini?|Why were repeated observations useful at Saturn?|What advantage did an orbital tour provide?',
'Our robot circles Saturn instead of parking on a cloud. What is it doing?|Which mission plan offers several looks at changing rings and moons?|How can repeated encounters improve a one-pass investigation?',
'Travelling in orbit|Orbiting and observing the Saturn system|Repeated observations with varied times and geometries',
'Driving on cloud roads|Driving a rover on cloud tops|Driving on a solid cloud-top road',
'Living in a tree|Growing a forest on Saturn|Planting a forest inside the rings',source='cassini'),
C('ring-measure','Ask a ring question','saturn-portrait',
'To look for ring gaps, take pictures of the rings. Choose the tool that fits the question.|Ring images help scientists map structures and compare how they change. Observing geometry affects what a picture reveals.|A ring-structure investigation compares images with known viewing geometry and time. Suitable measurements must match the spatial or dynamical question.',
'Which picture helps us find ring gaps?|Which record would help map changing ring structures?|What observing plan fits a ring-gap investigation?',
'Mission Control asks where a gap is. Which target should our camera face?|Which two images would help follow a ring pattern?|Which ring record can we compare fairly across observing passes?',
'Pictures of the rings|Repeated ring images|Ring images with times and viewing geometry',
'Pictures of our boots|Only a picture of a scientist’s boots|Only a clothing photograph',
'A list of Mars rocks|A list of unrelated Mars rocks|A catalog of Martian mineral names',source='cassini'),
C('plume-measure','Ask a plume question','saturn-earth-smiled',
'To learn what an icy spray contains, a robot can sample its tiny pieces.|Cassini measured particles and gases associated with Enceladus’s plume. Composition helps answer what the material contains.|Instruments measuring plume particles and gases address composition questions. A contextual picture alone cannot determine the complete chemical inventory.',
'How can a robot learn what the spray contains?|Which observation best investigates plume composition?|What measurement directly tests the composition of an Enceladus plume?',
'Our team asks what is in the jets. Which tool should we send?|What data adds more than a distant picture of the plume?|Which evidence is most direct for the chemistry of ejected material?',
'Sample tiny pieces|Measure plume gases and particles|Compositional measurements of plume material',
'Name the picture|Only give the picture a new title|A new descriptive image title',
'Count planet names|Only count planet names|The number of destination labels',source='enceladus')],
('The Huygens landing','saturn-portrait','Cassini carried another robot, Huygens. Huygens landed on Titan, a moon with solid ground.|The Cassini-Huygens mission combined a Saturn orbiter with a probe that descended to Titan in 2005.|Cassini’s orbital observations and Huygens’s atmospheric descent and surface measurements provided complementary evidence. A moon landing is different from attempting to land on Saturn itself.','cassini'),
'evidence','Match the tool to the question',[
T('Find ring gaps.|Which evidence fits a question about ring structure?|Choose measurements for mapping a ring gap.','saturn-portrait','Ring images|Pictures of the rings|Images with ring geometry and time','Boot photograph|A photograph of boots|Unrelated clothing imagery',0,'Point the camera at the rings.|Ring images show spatial structures.|Relevant imaging can locate and compare gaps.'),
T('Find what a plume contains.|Which evidence fits a question about plume material?|Choose a measurement that tests plume chemistry.','saturn-earth-smiled','Gas and particle samples|Measurements of plume gases and particles|Compositional data from ejected material','A new planet name|A new name for Saturn|An unrelated naming decision',0,'Sample the plume material.|Gas and particle measurements reveal composition.|A chemical measurement tests composition more directly than a name or contextual portrait.')])
mission('uranus','sideways-seasons','Sideways Seasons',
'Tip our Uranus model onto its side!|Explore how Uranus’s tilt changes the sunlight at its poles.|Model extreme axial tilt and seasonal illumination over a long orbit.',[
C('tilt','A world tipped sideways','uranus-global',
'Uranus is tipped almost onto its side. It still spins as it travels around the Sun.|Uranus’s axis is tilted about 98 degrees. It appears to roll around the Sun, although it is spinning in space.|Uranus has an axial tilt near 98 degrees. Its unusual spin orientation produces a very different illumination geometry from Earth’s.',
'Which model fits Uranus?|What is unusual about Uranus’s axis?|Which property most directly explains Uranus’s unusual illumination?',
'Which model should go in our Uranus exploration log?|Which tilt should we use for a Uranus season experiment?|Why should an Earth-like axis not be substituted in a Uranus seasonal model?',
'A sideways globe|A nearly sideways axis|Extreme axial tilt near 98 degrees',
'A globe standing upright|An almost upright axis|An axis nearly perpendicular to the orbital plane',
'A cube with no spin|A cube that never rotates|A nonrotating cubic body'),
C('polar-light','Long polar daylight and darkness','uranus-clouds',
'A Uranus pole can face the Sun for a very long time. The other pole can stay in darkness.|Because Uranus is strongly tilted, a pole can receive prolonged sunlight while the opposite polar region has prolonged darkness.|Uranus’s extreme obliquity produces long intervals of polar illumination and darkness. The exact daylight pattern depends on latitude and orbital phase.',
'One pole faces the Sun. What happens at the other?|Which pattern fits a strongly tilted Uranus?|How does extreme tilt affect polar illumination?',
'Our light shines on the north end. What should we check at the south end?|Which clue would show opposite polar conditions?|What prediction follows when a pole points approximately toward the Sun?',
'The other can be dark|One pole is lit while the other is dark|Prolonged illumination at one pole and darkness at the other',
'Both always get the same light|Both poles always have identical daylight|Identical illumination at both poles at all phases',
'The Sun turns off|The Sun switches off for all planets|A cessation of the Sun’s energy production'),
C('long-year','Seasons over a long orbit','uranus-global',
'Uranus takes a very long time to go around the Sun. Its seasons last much longer than Earth’s.|A Uranus orbit takes about 84 Earth years. Its long year and extreme tilt make its seasons very different from ours.|Uranus’s roughly 84-year orbital period sets a long seasonal timescale. Seasonal illumination evolves as its fixed tilted axis moves through the orbit.',
'Are Uranus seasons short like ours or much longer?|Why do Uranus’s seasons last so long?|Which time scale governs Uranus’s slow seasonal progression?',
'A Uranus year takes a long time. Are its seasons short like ours or much longer?|Which orbit clue explains why a Uranus season takes many Earth years?|Which clue explains slow seasonal progression through an 84-year orbit?',
'Much longer|Its Sun trip lasts about 84 Earth years|Its long orbital period changes seasonal illumination slowly',
'Only a few seconds|Its Sun trip lasts a few seconds|A seconds-long orbital period',
'It never has seasons|It has no tilt and no seasons|An untilted axis producing no seasonal geometry')],
('A model is a simplified question','uranus-clouds','Our tilted-globe model shows sunlight patterns. It does not tell us every detail of Uranus’s weather.|A sunlight model helps isolate tilt and orbital position. Winds, clouds, and the atmosphere make real weather more complex.|Qualitative illumination models are useful for causal comparison but do not predict measured temperatures or atmospheric circulation. A physical weather model needs additional variables and observations.'),
'experiment','Try the sideways-sunlight model',[
T('Give Uranus its sideways tilt.|Which axis setting represents Uranus?|Choose the extreme-tilt setting for the illumination model.','uranus-global','Sideways axis|Axis tipped nearly sideways|Extreme obliquity','Upright axis|Axis nearly upright|Low obliquity',0,'A sideways axis fits Uranus.|The extreme tilt changes which polar region faces the Sun.|The setting changes illumination geometry without assigning measured temperatures.',oa='A pole can face the light.|The polar region can receive prolonged illumination.|Extreme tilt creates strong polar seasonal contrasts.',ob='The poles are not aimed toward the light.|This removes the distinctive sideways geometry.|Low tilt reduces the extreme seasonal contrast.'),
T('Move along the orbit.|Which axis rule models a Uranus year?|Choose the rule that lets orbital phase change the lit polar region.','uranus-clouds','Keep the axis direction|Keep the axis fixed in space|Preserve axis orientation','Aim one pole at Sun forever|Always point the same pole at the Sun|Continuously track the Sun with the axis',0,'Keep the axis direction as the planet travels.|Changing orbital position then changes the favored polar region.|The model preserves orientation so phase, rather than artificial axis tracking, controls illumination.',oa='The favored polar region changes.|Opposite orbital positions favor different poles.|Seasonal illumination evolves through the orbit.',ob='One pole is always aimed at the Sun.|This prevents the modeled polar seasons from switching.|Sun-tracking orientation is not the fixed-axis seasonal model.')])

mission('uranus','blue-green-clues','Blue-Green Clues',
'Find the gas that helps make Uranus blue-green!|Explore color clues without mistaking an ice giant for a frozen ball.|Separate atmospheric light absorption from interior composition and image processing.',[
C('methane','Methane changes the light','uranus-global',
'Uranus has methane gas in its air. The gas absorbs some red light, leaving more blue-green light to see.|Methane absorbs red wavelengths from sunlight. The reflected light helps give Uranus a blue-green appearance.|Methane absorption removes some red light from the spectrum emerging from Uranus’s atmosphere. Haze and clouds also affect the observed color.',
'Which gas helps make Uranus blue-green?|Why does methane affect Uranus’s color?|Which light interaction contributes to Uranus’s visible color?',
'Our light model loses some red. Which atmospheric gas fits?|Which color clue would support methane absorption?|What should we infer when an atmosphere preferentially absorbs red wavelengths?',
'Methane|Methane absorbing red light|Selective absorption of red wavelengths by methane',
'Blue paint|Blue paint covering the clouds|An artificial pigment coating the atmosphere',
'Blue trees|Blue leaves on every cloud|A photosynthetic forest on the cloud deck'),
C('ice-giant','Ice giant does not mean ice cube','uranus-global',
'Uranus is called an ice giant, but it is not a giant frozen ice cube. Deep inside, materials are hot.|Uranus contains much water, methane, and ammonia in hot, dense fluid form. “Ice giant” describes materials, not a frozen surface.|The term ice giant refers to a composition rich in substances historically classified as planetary ices. High interior pressure and temperature produce hot dense fluids.',
'Is Uranus one big frozen ice cube?|What does “ice giant” mean here?|Why is the term ice giant not evidence for an exposed frozen surface?',
'Our model has cold clouds and a hot inside. Is it one frozen ice cube?|Which interior description fits Uranus better than a solid snowball?|How can materials called planetary ices exist as hot interior fluids?',
'No, the inside is hot|Hot, dense water-rich fluids inside|Composition terminology differs from present physical state',
'Yes, all of it is frozen|A completely frozen cube|The whole planet is a solid ice cube',
'It is a small star|A star producing its own fusion energy|Stellar fusion defines the planet’s interior'),
C('image-interpret','A photograph and a color map','uranus-clouds',
'Some pictures use added colors to show details. We need to ask what the picture is showing.|An enhanced-color image can reveal clouds more clearly. Its displayed colors may differ from a natural-color view.|Filters, processing, and assigned colors affect astronomical images. Physical interpretation must distinguish measured light from display choices.',
'Can a picture use extra colors for clues?|Why might scientists enhance an image’s colors?|What should accompany a claim based on displayed image color?',
'Could a science picture use extra colors to highlight details?|Why might two science records use enhanced display colors?|Why is an image-processing note relevant to atmospheric interpretation?',
'Yes, colors can highlight details|To make measured patterns easier to compare|Filter and image-processing information',
'No, every picture is eye-color|Every displayed image is exactly natural color|The assumption that all displays reproduce naked-eye colors',
'The colors rename the planet|The colors turn the planet into a star|A naming change instead of measurement metadata')],
('An atmosphere above hot fluids','uranus-global','Uranus has no rocky road for a rover. Its cloudy outside lies above hot, dense materials.|Like Neptune, Uranus lacks an accessible solid surface. A mission would investigate from orbit, flyby, or atmospheric measurements.|Interior models of Uranus remain uncertain. Gravity, magnetic, and atmospheric observations offer complementary constraints on its layered structure.'),
'experiment','Try the light-and-color model',[
T('Let methane change our light.|Which setting removes some red light in this simple model?|Choose selective red-light absorption.','uranus-global','Add methane absorption|Absorb some red light|Enable methane red-wavelength absorption','No methane absorption|Keep all color channels in this model|Disable selective methane absorption',0,'Methane takes away some red light.|The model leaves relatively more blue-green light.|This qualitative filter illustrates selective absorption, not a calibrated planetary spectrum.',oa='Less red light remains.|Blue-green light makes up a larger share of the reflected model light.|Relative red intensity is reduced.',ob='More red light remains.|The model has no methane red-light filtering.|The selected model omits selective red absorption.'),
T('Check a science-color map.|How should we label an enhanced-color view?|Choose the interpretation that distinguishes display colors from natural appearance.','uranus-clouds','Science color map|Enhanced or assigned-color view|Processed display with stated filters','Exact eye-color view|Always the color our eyes would see|Unqualified natural-color rendering',0,'Extra colors help us see details.|An enhanced view needs a clear label.|Display choices must not be confused with direct visible appearance.',oa='Patterns stand out in added colors.|The display highlights measured differences.|Assigned colors emphasize selected image information.',ob='The display claims natural appearance.|That claim needs a suitable natural-color method.|A natural-color claim cannot be assumed from enhancement.')])

mission('uranus','hidden-rings','Hidden Rings',
'Look for a quiet ring system around Uranus!|Investigate why faint rings can be hard to spot.|Match remote observations with Uranus’s faint ring and moon system.',[
C('faint-rings','Saturn is not alone','uranus-global',
'Uranus has rings too. They are much harder to see than Saturn’s bright rings.|Uranus has a system of faint rings. A planet need not have Saturn-like bright rings to have orbiting ring material.|Uranus’s narrow, faint rings demonstrate that giant-planet ring systems differ in brightness and structure. Ring presence cannot be inferred from one low-contrast portrait alone.',
'Can Uranus have rings too?|Why might Uranus’s rings be missed in a casual picture?|Which inference is safe about a portrait that does not clearly show rings?',
'Can another giant planet, Uranus, have rings too?|Which clue should we investigate rather than assume from brightness?|A single portrait hides a known faint ring. Which explanation fits?',
'Yes, Uranus has rings|Its rings are faint and hard to see|Low contrast can hide a real ring system',
'No, only Saturn has rings|Only Saturn can have any rings|A faint image proves there are no rings',
'Rings are made of trees|Rings must be forests|Vegetation creates all giant-planet rings'),
C('observation','Choose a useful view','uranus-clouds',
'A science telescope can gather faint light. Better observations help reveal hard-to-see features.|Telescopes using suitable observations can reveal faint planetary features. A different view may show information a simple portrait misses.|Wavelength, exposure, and viewing geometry affect detectability. A well-designed observation can reveal ring structure that is absent in an unsuitable image.',
'Which tool helps study faint features?|What tool could show a feature missed in a casual portrait?|What controls whether a faint feature is detectable?',
'Our quick picture misses a ring. Which tool can investigate more carefully?|What should we change before deciding a hidden feature does not exist?|Why can two observations of the same planet reveal different structures?',
'A science telescope|A telescope with a suitable observation|Wavelength, exposure, and viewing geometry',
'A pretend drawing only|A drawing with no observations|An illustration without measured data',
'A planet-name sticker|A sticker with the planet’s name|The spelling of the destination label'),
C('moons-versus-rings','Moon or ring particle?','uranus-global',
'A moon is a world travelling around a planet. A ring contains many smaller pieces in orbit.|Uranus has both moons and rings. Separate moon bodies and a ring’s many particles are different parts of the system.|Moons and ring particles both orbit the planet, but their sizes and collective structures differ. Classification should use observations rather than ring visibility alone.',
'Which group has many little pieces?|How do a moon and a ring differ?|Which distinction describes a moon versus a particulate ring?',
'Our dossier shows one moon and many ring grains. Which is the ring?|Which group should hold a swarm of small orbiting particles?|Why does sharing a parent planet not make a moon and a ring equivalent?',
'The ring|A ring has many particles|A ring is a collective particulate structure',
'One moon only|A ring is one large moon|A ring is a single satellite body',
'The Sun|The Sun is Uranus’s ring|The central star is the ring system')],
('Context is part of an image','uranus-global','This planet picture introduces Uranus. Some ring details need other science observations.|A portrait can hide faint features. We should say when a fact comes from separate observations rather than pretending it is visible in every picture.|A null visual impression is not automatically a measured nondetection. Detectability limits and the observing method determine what absence in an image can mean.'),
'evidence','Investigate the faint-feature dossier',[
T('Pick an observation for a faint ring.|Which record can investigate a hard-to-see ring?|Choose measured evidence for faint ring structure.','uranus-clouds','Suitable telescope view|A carefully planned telescope observation|An observation with suitable sensitivity and geometry','Only a sticker|A planet-name sticker|An unrelated destination label',0,'A telescope observation can gather faint clues.|A suitable observing setup may reveal the structure.|Sensitivity and viewing geometry matter for detecting a faint feature.'),
T('What does one unclear picture prove?|Does a portrait with no clear ring prove there are no rings?|Which inference follows from an unsuitable low-contrast image?','uranus-global','We need a better view|It may need a better observation|The image may not constrain ring presence','There are no rings|It proves rings cannot exist|The ring system is physically absent',0,'An unclear view may hide something real.|A faint ring can be present without appearing clearly.|A failure to see a feature requires a detectability assessment before it becomes a nondetection.')])

mission('neptune','wind-and-weather','Wind and Weather',
'Follow Neptune’s racing clouds and changing storms!|Compare weather clues on the farthest planet.|Use repeated observations to investigate a dynamic ice-giant atmosphere.',[
C('winds','Very fast winds','neptune-global',
'Neptune has very fast winds. They carry clouds around the planet.|Neptune’s winds can exceed 2,000 kilometres per hour. Its atmosphere is highly active despite being far from the Sun.|Neptune has extremely fast atmospheric winds, with measured speeds exceeding 2,000 km/h. Solar distance alone does not determine atmospheric activity.',
'What can carry Neptune’s clouds?|What surprising weather clue belongs to Neptune?|Which observation challenges the idea that distant planets must have still atmospheres?',
'Our cloud changes position. What may be moving it?|A distant planet has rapidly moving clouds. Which explanation fits?|What evidence would test whether a remote atmosphere has strong circulation?',
'Fast winds|Fast atmospheric winds|Rapid tracked cloud motion',
'Paint rollers|Road vehicles on cloud tops|Movement of solid roads on a surface',
'No movement ever|Clouds never move on distant planets|A complete absence of atmospheric motion'),
C('dark-storms','Dark spots can change','neptune-storm',
'Neptune can have dark storm spots. Spots can change or disappear as scientists watch.|Neptune’s dark vortices are atmospheric storms. Unlike permanent landforms, they can evolve and disappear.|Dark vortices are transient atmospheric structures. Time-series observations distinguish their evolution from a fixed marking on a solid surface.',
'What can a dark spot on Neptune be?|Why should we keep observing a dark storm spot?|What distinguishes a dark vortex from a permanent surface marking?',
'Our older and newer pictures show a changed spot. What might it be?|A dark spot grows and fades. What interpretation fits?|A feature changes dimensions and later vanishes. Which interpretation fits?',
'A changing storm|An evolving atmospheric storm|A transient atmospheric vortex',
'A permanent painted road|A permanent road painted on rock|A fixed rocky road on a solid surface',
'A growing forest|A forest growing in the clouds|A surface forest expanding into the atmosphere'),
C('cloud-tracking','A fair cloud comparison','neptune-global',
'Take another picture to see how a cloud changed. One picture cannot show all its movement.|Comparing cloud positions over time helps track motion. The planet’s own rotation also changes the view.|Cloud tracking requires known times and viewing geometry. Scientists distinguish apparent changes caused by rotation from motion within the atmosphere.',
'What helps us follow a cloud?|What must we know when comparing cloud positions?|Which information supports a fair atmospheric-motion comparison?',
'Which picture record should we keep to track the cloud?|Which record can help separate cloud motion from the planet turning?|Why are time stamps and viewing geometry needed for tracked feature speeds?',
'Pictures at different times|Times and comparable views|Time interval, rotation, and viewing geometry',
'Only a planet-name list|Only a list of planet names|An unrelated list of destination labels',
'A new paint color|Only a decorative border color|Only the display’s border color')],
('Cold outside does not mean inactive','neptune-storm','Neptune is far from the Sun, but its clouds and storms are busy.|Neptune’s internal heat and atmospheric processes contribute to its weather. Distance from sunlight is only part of the story.|Atmospheric circulation depends on multiple energy sources and physical processes. A qualitative comparison should not reduce all wind behavior to solar distance.'),
'evidence','Read the moving-weather record',[
T('Choose a wind clue.|Which record supports moving atmospheric clouds?|Select evidence of atmospheric motion.','neptune-global','Cloud positions change|A cloud moves between dated images|Tracked cloud displacement over a known interval','A planet label|The planet’s printed name|An unchanged text label',0,'Changing positions are motion clues.|Dated images let us compare a cloud’s location.|Tracked features constrain motion when time and viewing geometry are known.'),
T('Choose a changing-storm clue.|Which record supports a storm evolving?|Select evidence of a transient atmospheric feature.','neptune-storm','Spot shape changes|A dark spot changes shape over time|A dated sequence showing vortex evolution','A fixed logo|A logo in the screen border|A fixed decorative screen emblem',0,'Storm spots can change.|A changing dark feature can be an evolving vortex.|Time-dependent morphology supports an atmospheric rather than decorative interpretation.')])

mission('neptune','the-distant-sun','The Distant Sun',
'Follow light on its long trip to Neptune!|Compare sunlight travel and messages from spacecraft.|Keep solar-distance and Earth-spacecraft signal routes separate.',[
C('distance','The farthest planet','neptune-global',
'Neptune is the farthest of our eight planets from the Sun. Space between worlds is enormous.|Neptune’s average distance from the Sun is about 30 times Earth’s. Astronomers call that about 30 AU.|Neptune’s average solar distance is approximately 30 astronomical units. This is a Sun-to-Neptune distance, not a fixed Earth-to-Neptune separation.',
'Which planet is farthest from the Sun?|What does about 30 AU describe here?|Which route is described by Neptune’s average distance of about 30 AU?',
'Our solar-system trail ends at the eighth planet. Which world is it?|Which starting point belongs on Neptune’s solar-distance ruler?|Our Neptune distance label says about 30 AU. Which route was averaged?',
'Neptune|The distance from the Sun|Sun to Neptune, averaged over its orbit',
'Earth|The distance from a classroom|A classroom to a nearby city',
'Mercury|A fixed distance from Earth|An unchanging Earth-to-Neptune separation'),
C('sunlight','Light still needs travel time','neptune-global',
'Light is very fast, but Neptune is very far away. Sunlight takes hours to get there.|Sunlight takes roughly four hours to reach Neptune, compared with about eight minutes to Earth.|Using average orbital distance, sunlight needs about 4.2 hours to reach Neptune. Light has a finite speed even across a very large distance.',
'Does sunlight reach Neptune right away?|Why does sunlight take longer to reach Neptune than Earth?|Which quantity explains longer light travel time at fixed light speed?',
'After light leaves the Sun, does it arrive at Neptune right away?|Sun-to-Earth and Sun-to-Neptune rays have the same speed. Why is Neptune’s trip longer?|What happens to travel time when distance increases while propagation speed stays constant?',
'No, the trip takes hours|Neptune is much farther from the Sun|Greater path length produces greater travel time',
'Yes, it takes no time|Neptune turns light completely off|The planet switches the speed of light to zero',
'Only moonlight takes time|Light becomes slower only because of a planet’s name|The destination name determines propagation speed'),
C('radio-route','A message has its own route','tech-dsn',
'A spacecraft sends a radio message to Earth. That path is different from sunlight travelling from the Sun.|Radio waves and visible light travel at the same speed in space. A radio delay uses the distance between Earth and the spacecraft.|One-way light time for spacecraft communication is based on Earth-spacecraft separation. It varies as both move and is not the Sun-to-planet sunlight time.',
'Where does our robot send its message?|Which distance determines a message’s delay to Earth?|Why is solar light time not a fixed radio delay to Earth?',
'The robot calls Earth, not the Sun. Which path should we follow?|Which route should Mission Control measure before predicting a reply?|What changes in the communication calculation as Earth and the spacecraft move?',
'To Earth|Earth-to-spacecraft distance|Earth-spacecraft separation changes with geometry',
'Only to the Sun|Only Sun-to-planet distance|The solar orbital distance is always the complete route',
'To a cloud’s paint|Only the spacecraft’s paint color|Exterior paint controls radio propagation speed',source='radio')],
('Dim sunlight still reaches Neptune','neptune-global','The Sun looks much smaller and dimmer from Neptune than from Earth. It is still the same star.|At Neptune, sunlight is much weaker because its energy spreads over a larger area as it travels outward.|For an ideal point source, illumination decreases with the square of distance. The qualitative model shows weaker sunlight farther away without predicting local weather.'),
'experiment','Try the light-travel model',[
T('Make the light trip longer.|Which setting gives the same-speed light a longer journey?|Choose the setting with the greater light-path length.','neptune-global','Farther target|Increase the target distance|Increase path length at fixed light speed','Nearer target|Decrease the target distance|Decrease path length at fixed light speed',0,'A longer path takes more time.|With the same speed, a farther target has a longer travel time.|The model compares qualitative distances; the moving marker is not to scale.',oa='The traveller has farther to go.|The trip takes longer at the same speed.|Increasing path length increases travel time.',ob='The traveller has less distance to go.|The trip takes less time at the same speed.|Decreasing path length decreases travel time.'),
T('Follow a robot’s call to Earth.|Which route should show a spacecraft message?|Choose the route used for Earth-spacecraft one-way light time.','tech-dsn','Robot to Earth|Spacecraft-to-Earth route|Earth-spacecraft separation','Sun to planet|Sun-to-planet route|Solar distance',0,'A call to Earth follows the robot-Earth path.|The radio delay depends on Earth and spacecraft positions.|Communication light time uses the relevant endpoints, not the average solar-distance shortcut.',oa='The message travels toward Earth.|The selected endpoints match the communication question.|The path represents an Earth-spacecraft signal route.',ob='Sunlight travels toward the planet.|This route answers a sunlight question.|Solar-distance light time is a different endpoint calculation.')])

mission('neptune','tritons-backward-orbit','Triton’s Backward Orbit',
'Follow a moon moving the unusual way!|Investigate Triton’s backward orbit and icy jets.|Use orbital direction and surface observations to examine a capture hypothesis.',[
C('retrograde-orbit','A moon goes the other way','neptune-global',
'Triton is Neptune’s largest moon. It travels around Neptune opposite to the planet’s spin direction.|Triton has a retrograde orbit: it circles Neptune opposite to Neptune’s rotation. Orbit and spin are different motions.|Triton is the only large solar-system moon with a retrograde orbit about its planet. This refers to orbital direction relative to Neptune’s rotation.',
'Which way does Triton travel compared with Neptune’s spin?|What does Triton’s retrograde orbit mean?|Which motion is described as retrograde for Triton?',
'Our moon arrow circles opposite to Neptune’s spin arrow. What does that show?|Which arrow should change to represent Triton’s unusual motion?|Why is reversing a moon’s own spin not enough to model a retrograde orbit?',
'The opposite way|Its orbit is opposite to Neptune’s spin|Orbital revolution opposite to the planet’s rotation',
'Exactly the same way|It has no orbit at all|No orbital motion around Neptune',
'It travels around Earth|It orbits Earth instead of Neptune|A primary orbit around Earth'),
C('capture','A clue about Triton’s history','neptune-global',
'Triton’s unusual path is a clue. Scientists think Neptune may have captured it long ago.|The retrograde orbit suggests Triton may once have been an independent object that Neptune captured.|Triton’s orbital direction supports a capture origin rather than simple formation in a prograde circumplanetary disk. It is evidence for a hypothesis, not a witnessed ancient event.',
'What might Triton’s unusual path tell us?|Which history is suggested by Triton’s orbit?|How should Triton’s proposed capture history be described?',
'Our detective finds a backward orbit. Could it be a clue to an old capture?|Which careful sentence belongs in a Triton history log?|Why is “the orbit supports capture” preferable to “we watched Neptune capture it”?',
'It may have been captured|Its orbit suggests an ancient capture|A hypothesis supported by orbital evidence',
'We watched it happen yesterday|The capture was watched yesterday|A directly witnessed ancient event',
'The moon is made of paint|Its name proves its history|A conclusion based only on the name'),
C('icy-jets','A cold moon with surprising jets','neptune-storm',
'Triton is very cold, but Voyager 2 saw jets spraying icy material upward.|Voyager 2 found geyser-like plumes on Triton. A cold surface can still have active processes.|Triton’s observed plumes demonstrate surface activity in a very cold environment. Mechanisms are investigated using observations and physical models.',
'Can a very cold moon still have jets?|What did Voyager 2 observe on Triton?|Which observation challenges the assumption that cold surfaces must be inactive?',
'Our moon card shows icy material sprayed upward. Can the moon still be cold?|Which feature should go in Triton’s activity dossier?|What inference follows from plumes observed on a very cold moon?',
'Yes, icy jets were seen|Geyser-like plumes of icy material|Active surface processes can occur despite low temperature',
'No, cold means nothing happens|Only warm forests|Cold environments cannot exhibit any activity',
'Only if it is Earth|Earth-like ocean beaches|The moon must have Earth-like surface oceans')],
('A Neptune portrait is context','neptune-global','This picture shows Neptune. Triton’s moon clues come from separate observations by Voyager and telescopes.|The Neptune image introduces the system; it is not a close-up of Triton’s jets. We keep the observation source with each claim.|Context images are useful, but visible details must not be invented. Triton’s orbital and plume claims rely on moon-specific observations, not Neptune’s cloud portrait.'),
'evidence','Build Triton’s history dossier',[
T('Find the backward-orbit clue.|Which record supports a retrograde orbit?|Select evidence for Triton’s orbital direction relative to Neptune’s spin.','neptune-global','Opposite direction arrows|Orbit and spin arrows pointing opposite ways|Measured orbital motion opposite to Neptune’s rotation','A blue planet color|Neptune’s blue color|Atmospheric methane color alone',0,'The arrows show different directions.|Orbital direction, not color, is the relevant clue.|Relative angular-momentum direction supports the retrograde classification.'),
T('Write a careful history note.|Which note keeps evidence and an old event separate?|Choose an evidence-based statement about Triton’s origin.','neptune-global','May have been captured|Orbit suggests an ancient capture|Orbital evidence supports a capture hypothesis','We saw the old capture|We watched the ancient capture happen|The ancient capture was directly observed',0,'The old capture is a science idea supported by clues.|We have orbital evidence, not a recording of the ancient event.|A hypothesis can be supported without its historical event being witnessed.')])

# Context photographs must not be mistaken for direct pictures of other landforms or moons.
CONTEXT = {
    'mars-ancient-water-detective-valleys': 'This rover picture introduces Mars.|This rover panorama is context for Mars, not a river-valley photograph.|The rover panorama is contextual imagery; the river-valley evidence comes from separate orbital observations.',
    'mars-ancient-water-detective-deltas': 'This rover picture introduces Mars.|This rover panorama is context, not a close-up of an ancient delta.|The panorama supplies Martian context, rather than depicting the deltaic evidence described here.',
    'jupiter-moon-match-io': 'Jupiter is pictured here; Io is one of its moons.|The picture shows Jupiter, not a close-up of Io.|This Jupiter portrait introduces the moon system; Io’s volcanism is established by separate moon observations.',
    'jupiter-moon-match-ganymede': 'Jupiter is pictured here; Ganymede is its moon.|The portrait shows Jupiter, not Ganymede.|This planet portrait supplies context; Ganymede’s size and orbit use satellite-specific measurements.',
    'saturn-two-moon-mysteries-titan-lakes': 'Saturn is pictured here; Titan is its moon.|The portrait shows Saturn; the lake evidence comes from Titan observations.|This Saturn portrait provides system context rather than a view of Titan’s hydrocarbon lakes.',
    'saturn-two-moon-mysteries-plumes': 'Saturn is pictured here; Enceladus is its moon.|The image shows Saturn, not the Enceladus plume.|This contextual Saturn image does not depict the plume; the claim uses Enceladus observations.',
    'saturn-two-moon-mysteries-ocean-evidence': 'Saturn is pictured here; Enceladus is its moon.|The image is Saturn-system context, not a photograph of a hidden ocean.|The Saturn image supplies context; the inferred ocean is supported by moon-specific measurements.',
    'saturn-cassini-detective-plume-measure': 'This is a Saturn picture, not a spray sample.|The image gives Saturn-system context; samples came from plume observations.|This Saturn photograph supplies context rather than direct chemical evidence about the plume.',
    'neptune-tritons-backward-orbit-retrograde-orbit': 'Neptune is pictured here; Triton is its moon.|The picture shows Neptune, not Triton’s orbital path.|The Neptune portrait supplies context; the orbital direction comes from tracking Triton.',
    'neptune-tritons-backward-orbit-capture': 'Neptune is pictured here; Triton is its moon.|The portrait shows Neptune; the capture clue is Triton’s orbit.|This context image is not an observation of the ancient capture event.',
    'neptune-tritons-backward-orbit-icy-jets': 'Neptune is pictured here, not Triton’s jets.|This storm picture shows Neptune; the icy-jet evidence comes from Triton observations.|The image depicts Neptune’s atmosphere, not Triton’s plumes; the plume claim uses Voyager observations of the moon.',
}
for record in missions:
    for clue in record['cards']:
        if clue['conceptID'] in CONTEXT:
            prefix=age(CONTEXT[clue['conceptID']])
            clue['body']={band:prefix[band]+' '+clue['body'][band] for band in BANDS}
        if clue['conceptID']=='mars-ancient-water-detective-valleys':
            clue['imageName']='mars-landscape'
            clue['imageSourceID'],clue['imageCredit']=IMAGES['mars-landscape']

# Moon volcanism and rover geology use the narrower reviewed mission references.
SPECIFIC_SOURCES = {
    'jupiter-moon-match-io': {'title': 'NASA Science: Io', 'url': 'https://science.nasa.gov/jupiter/jupiter-moons/io/', 'reviewStatus': 'reviewed'},
    'mars-rover-rock-hunt-layers': {'title': 'NASA Science: Curiosity Rover Science', 'url': 'https://science.nasa.gov/mission/msl-curiosity/science/', 'reviewStatus': 'reviewed'},
    'mars-rover-rock-hunt-rover-tools': {'title': 'NASA Science: Curiosity Rover Science', 'url': 'https://science.nasa.gov/mission/msl-curiosity/science/', 'reviewStatus': 'reviewed'},
    'mars-ancient-water-detective-minerals': {'title': 'NASA Science: Curiosity Rover Science', 'url': 'https://science.nasa.gov/mission/msl-curiosity/science/', 'reviewStatus': 'reviewed'},
}
for record in missions:
    for clue, question in zip(record['cards'], record['questions']):
        if clue['conceptID'] in SPECIFIC_SOURCES:
            clue['source'] = question['source'] = SPECIFIC_SOURCES[clue['conceptID']]

# Stable setting IDs let the UI render a corresponding qualitative diagram.
SETTINGS={
'mercury-speedy-year':[('rotate','orbit'),('orbit','rotate')],
'venus-heat-trap-detective':[('thick-air','thin-air'),('fixed-sunlight','change-all')],
'venus-backward-spinner':[('retrograde','prograde'),('solar-cycle','axial-turn')],
'earth-season-tracker':[('north-toward','north-away'),('fixed-axis','sun-tracking-axis')],
'uranus-sideways-seasons':[('sideways','upright'),('fixed-axis','sun-tracking-axis')],
'uranus-blue-green-clues':[('methane','no-methane'),('color-map','natural-view')],
'neptune-the-distant-sun':[('far','near'),('radio-route','sunlight-route')],
}
for m in missions:
    if m['id'] in SETTINGS:
        for task,settings in zip(m['activity']['tasks'],SETTINGS[m['id']]):
            correct=task['options'].index(next(o for o in task['options'] if o['id']==task['correctOptionID']))
            for option,key in zip(task['options'],settings): option['id']=task['id']+'-'+key
            task['correctOptionID']=task['options'][correct]['id']
# Correct placement is varied for activities too; settings retain their semantic IDs.
for mission_index, record in enumerate(missions):
    for task_index, task in enumerate(record['activity']['tasks']):
        if (mission_index + task_index) % 2:
            task['options'].reverse()
# Source URLs are verified, and contextual images keep their existing reviewed credits.
SOURCES['earth-observe']['title']='NASA Space Place: What Is a Satellite?'
SOURCES['earth-observe']['url']='https://spaceplace.nasa.gov/satellite/en/'
assert len(missions)==24
out=ROOT/'Sources/AstroContent/Resources/planet-missions.json'
out.write_text(json.dumps(missions,ensure_ascii=False,indent=2)+'\n')
print(f'Authored {len(missions)} missions, {sum(len(m["cards"])+1 for m in missions)} cards, {sum(len(m["questions"])*3 for m in missions)} initial and review quiz variants each.')
