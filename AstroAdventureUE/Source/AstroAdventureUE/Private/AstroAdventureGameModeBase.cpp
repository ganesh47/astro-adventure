#include "AstroAdventureGameModeBase.h"

#include "AstroAdventurePlayerController.h"
#include "AstroDestinationActor.h"
#include "AstroLearningLibrary.h"
#include "AstroMissionHUD.h"
#include "AstroPlayerPawn.h"
#include "AstroProgressSaveGame.h"
#include "Algo/Count.h"
#include "Components/LightComponent.h"
#include "Components/PointLightComponent.h"
#include "Components/SkyLightComponent.h"
#include "Components/StaticMeshComponent.h"
#include "Engine/DirectionalLight.h"
#include "Engine/PointLight.h"
#include "Engine/PostProcessVolume.h"
#include "Engine/SkyLight.h"
#include "Engine/StaticMeshActor.h"
#include "Engine/World.h"
#include "GameFramework/PlayerStart.h"
#include "Kismet/GameplayStatics.h"
#include "Kismet/KismetSystemLibrary.h"
#include "Materials/MaterialInstanceDynamic.h"
#include "Materials/MaterialInterface.h"

const TCHAR* AAstroAdventureGameModeBase::SaveSlotName = TEXT("AstroAdventureM0Progress");

namespace
{
UMaterialInterface* GetRuntimeColorMaterial()
{
    if (UMaterialInterface* BasicShapeMaterial = LoadObject<UMaterialInterface>(nullptr, TEXT("/Engine/BasicShapes/BasicShapeMaterial.BasicShapeMaterial")))
    {
        return BasicShapeMaterial;
    }

    return LoadObject<UMaterialInterface>(nullptr, TEXT("/Engine/EngineMaterials/EmissiveMeshMaterial.EmissiveMeshMaterial"));
}

void ApplyRuntimeColor(AStaticMeshActor* Actor, const FLinearColor& Color, const float EmissiveStrength)
{
    if (!Actor || !Actor->GetStaticMeshComponent())
    {
        return;
    }

    UStaticMeshComponent* MeshComponent = Actor->GetStaticMeshComponent();
    UMaterialInstanceDynamic* Material = MeshComponent->CreateDynamicMaterialInstance(0, GetRuntimeColorMaterial());
    if (!Material)
    {
        Material = MeshComponent->CreateAndSetMaterialInstanceDynamic(0);
    }
    if (!Material)
    {
        return;
    }

    const FLinearColor ClampedColor = Color.GetClamped(0.0f, 1.0f);
    Material->SetVectorParameterValue(TEXT("Color"), ClampedColor);
    Material->SetVectorParameterValue(TEXT("BaseColor"), ClampedColor);
    Material->SetVectorParameterValue(TEXT("Base Color"), ClampedColor);
    Material->SetVectorParameterValue(TEXT("ShapeColor"), ClampedColor);
    Material->SetVectorParameterValue(TEXT("Tint"), ClampedColor);
    Material->SetVectorParameterValue(TEXT("DiffuseColor"), ClampedColor);
    Material->SetVectorParameterValue(TEXT("EmissiveColor"), ClampedColor * EmissiveStrength);
    Material->SetVectorParameterValue(TEXT("Emissive Color"), ClampedColor * EmissiveStrength);
    Material->SetVectorParameterValue(TEXT("Emissive"), ClampedColor * EmissiveStrength);
    Material->SetScalarParameterValue(TEXT("EmissiveStrength"), EmissiveStrength);
    Material->SetScalarParameterValue(TEXT("Emissive Strength"), EmissiveStrength);
    Material->SetScalarParameterValue(TEXT("EmissiveIntensity"), EmissiveStrength);
    Material->SetScalarParameterValue(TEXT("Glow"), EmissiveStrength);
    Material->SetScalarParameterValue(TEXT("Opacity"), ClampedColor.A);
    Material->SetScalarParameterValue(TEXT("Alpha"), ClampedColor.A);
}
}

AAstroAdventureGameModeBase::AAstroAdventureGameModeBase()
{
    MissionId = TEXT("SolarPassport_FirstExpedition");
    DefaultPawnClass = AAstroPlayerPawn::StaticClass();
    PlayerControllerClass = AAstroAdventurePlayerController::StaticClass();
    HUDClass = AAstroMissionHUD::StaticClass();
}

void AAstroAdventureGameModeBase::BeginPlay()
{
    Super::BeginPlay();
    UKismetSystemLibrary::ExecuteConsoleCommand(GetWorld(), TEXT("DisableAllScreenMessages"));

    BuildLessons();
    LoadProgress();
    SpawnRuntimeScene();
    CurrentScreen = EAstroMissionScreen::Home;
    HomeMenuIndex = HasAnyProgress() ? 1 : 0;
    UpdateDestinationFocus();
}

void AAstroAdventureGameModeBase::AddLesson(
    const TCHAR* Id,
    const TCHAR* Name,
    const TCHAR* QuickFact,
    const TCHAR* WowFact,
    const TCHAR* VisualClue,
    const TCHAR* Ages4To6,
    const TCHAR* Ages7To9,
    const TCHAR* Ages10To12,
    const TCHAR* DeepDive,
    const TCHAR* Compare,
    const TCHAR* Glossary,
    const TCHAR* SourceUrl,
    const TCHAR* QuizPrompt,
    const TCHAR* CorrectId,
    const TCHAR* CorrectText,
    const TCHAR* WrongOneId,
    const TCHAR* WrongOneText,
    const TCHAR* WrongTwoId,
    const TCHAR* WrongTwoText,
    const TCHAR* CorrectFeedback,
    const TCHAR* RetryFeedback,
    const TCHAR* Hint,
    const FLinearColor& Color,
    const float MapScale,
    const bool bRequired)
{
    auto MakeChoice = [](const TCHAR* ChoiceId, const TCHAR* Text)
    {
        FAstroQuizChoice Choice;
        Choice.ChoiceId = FName(ChoiceId);
        Choice.Text = FText::FromString(Text);
        return Choice;
    };

    FAstroDestinationLesson Lesson;
    Lesson.DestinationId = FName(Id);
    Lesson.DisplayName = FText::FromString(Name);
    Lesson.DiscoveryFact = FText::FromString(QuickFact);
    Lesson.WowFact = FText::FromString(WowFact);
    Lesson.VisualClue = FText::FromString(VisualClue);
    Lesson.Ages4To6Text = FText::FromString(Ages4To6);
    Lesson.Ages7To9Text = FText::FromString(Ages7To9);
    Lesson.Ages10To12Text = FText::FromString(Ages10To12);
    Lesson.DeepDiveText = FText::FromString(DeepDive);
    Lesson.CompareFact = FText::FromString(Compare);
    Lesson.GlossaryText = FText::FromString(Glossary);
    Lesson.SourceUrl = SourceUrl;
    Lesson.QuizPrompt = FText::FromString(QuizPrompt);
    Lesson.Choices = {
        MakeChoice(CorrectId, CorrectText),
        MakeChoice(WrongOneId, WrongOneText),
        MakeChoice(WrongTwoId, WrongTwoText)
    };
    Lesson.CorrectChoiceId = FName(CorrectId);
    Lesson.CorrectFeedback = FText::FromString(CorrectFeedback);
    Lesson.RetryFeedback = FText::FromString(RetryFeedback);
    Lesson.HintText = FText::FromString(Hint);
    Lesson.DisplayColor = Color;
    Lesson.MapScale = MapScale;
    Lesson.bRequiredForMission = bRequired;
    Lessons.Add(Lesson);
}

void AAstroAdventureGameModeBase::BuildLessons()
{
    Lessons.Reset();

    AddLesson(TEXT("sun"), TEXT("Sun"), TEXT("The Sun is our star and the center of this expedition."), TEXT("The Sun holds the Solar System together with gravity and gives Earth light."), TEXT("Look for the warm glowing giant with safe-distance rings."), TEXT("The Sun is a bright star."), TEXT("The Sun gives us light and heat, and all the planets travel around it."), TEXT("The Sun is a star. Its gravity keeps planets, dwarf planets, comets, and asteroids moving in orbits."), TEXT("Stars make energy in their centers. We keep the ship at a safe distance and scan light rays instead of touching the Sun."), TEXT("Compared with Earth, the Sun is enormous. Compared with other stars, it is a familiar nearby star."), TEXT("Star: a huge glowing ball of hot gas that makes light."), TEXT("https://science.nasa.gov/sun/"), TEXT("What is the Sun?"), TEXT("star"), TEXT("A star that lights the Solar System."), TEXT("moon"), TEXT("A moon of Earth."), TEXT("belt"), TEXT("A ring of rocks between planets."), TEXT("Brilliant! The Sun is our star."), TEXT("Try again. The Sun makes its own light."), TEXT("A star glows with its own light."), FLinearColor(1.0f, 0.64f, 0.08f), 1.35f, true);
    AddLesson(TEXT("mercury"), TEXT("Mercury"), TEXT("Mercury is the closest planet to the Sun."), TEXT("It has a very short year because it races around the Sun quickly."), TEXT("Small gray world with craters and a heat badge."), TEXT("Mercury is tiny and close to the Sun."), TEXT("Mercury is closest to the Sun. It zooms around fast!"), TEXT("Mercury is the innermost planet. Its short orbit helps scientists compare how distance from the Sun changes a world."), TEXT("Mercury has many craters because it has almost no thick atmosphere to burn up incoming space rocks."), TEXT("Mercury is much smaller than Earth and much closer to the Sun."), TEXT("Crater: a bowl-shaped mark made when a rock from space hits a surface."), TEXT("https://science.nasa.gov/mercury/"), TEXT("Which clue helps identify Mercury?"), TEXT("sun"), TEXT("It is the closest planet to the Sun."), TEXT("rust"), TEXT("It is famous for red rusty dust."), TEXT("rings"), TEXT("It has giant bright rings."), TEXT("Nice scan! Mercury is the Sun-neighbor clue."), TEXT("Almost. Look for the clue about the Sun."), TEXT("Look for the clue that mentions the Sun."), FLinearColor(0.62f, 0.62f, 0.58f), 0.72f, true);
    AddLesson(TEXT("venus"), TEXT("Venus"), TEXT("Venus is wrapped in thick clouds and is extremely hot."), TEXT("Venus is the hottest planet even though Mercury is closer to the Sun."), TEXT("Creamy gold cloud world with a heat shield icon."), TEXT("Venus is a hot cloudy planet."), TEXT("Venus has thick clouds that trap heat like a blanket."), TEXT("Venus has a thick atmosphere that creates an extreme greenhouse effect, making its surface hotter than Mercury."), TEXT("A greenhouse effect happens when an atmosphere lets sunlight in but traps heat. Venus is the Solar System's strongest example."), TEXT("Venus is close to Earth's size, but its atmosphere makes it very different from Earth."), TEXT("Atmosphere: the layer of gases around a planet or moon."), TEXT("https://science.nasa.gov/venus/"), TEXT("Why is Venus so hot?"), TEXT("clouds"), TEXT("Its thick atmosphere traps heat."), TEXT("ice"), TEXT("It is covered in blue ice."), TEXT("tiny"), TEXT("It is the smallest moon."), TEXT("Great! Venus is a cloudy heat-trapping world."), TEXT("Try again. Think about the thick clouds."), TEXT("A thick atmosphere can hold in heat."), FLinearColor(1.0f, 0.76f, 0.42f), 0.9f, true);
    AddLesson(TEXT("earth"), TEXT("Earth"), TEXT("Earth is our home world with liquid water on the surface."), TEXT("Earth has air, oceans, land, clouds, and life."), TEXT("Blue oceans, green-brown land, and white cloud clue."), TEXT("Earth is our home planet."), TEXT("Earth has water, air, land, clouds, and living things."), TEXT("Earth's liquid water, protective atmosphere, and distance from the Sun help make it habitable."), TEXT("Scientists compare other worlds to Earth to ask what conditions help life survive."), TEXT("Earth is bigger than Mercury and Mars, smaller than the gas giants, and has one large Moon."), TEXT("Planet: a large round world that orbits a star."), TEXT("https://science.nasa.gov/earth/"), TEXT("Which clue makes Earth special?"), TEXT("water"), TEXT("It has liquid water and life."), TEXT("rings"), TEXT("It has the largest rings."), TEXT("storm"), TEXT("It has the Great Red Spot."), TEXT("Home badge unlocked! Earth is the water-and-life clue."), TEXT("Try again. Look for water and life."), TEXT("Earth is the planet we live on."), FLinearColor(0.18f, 0.56f, 1.0f), 1.0f, true);
    AddLesson(TEXT("moon"), TEXT("Moon"), TEXT("The Moon orbits Earth."), TEXT("Its craters are clues from ancient impacts."), TEXT("Gray cratered companion linked to Earth."), TEXT("The Moon goes around Earth."), TEXT("The Moon is Earth's natural satellite. It has many craters."), TEXT("The Moon's phases come from how sunlight hits the Moon as it orbits Earth."), TEXT("A moon is a natural object that orbits a planet. Earth's Moon helps us study craters, phases, and gravity."), TEXT("The Moon is much smaller than Earth and much closer than the planets."), TEXT("Moon: a natural object that travels around a planet."), TEXT("https://science.nasa.gov/moon/"), TEXT("What does the Moon orbit?"), TEXT("earth"), TEXT("Earth."), TEXT("sun_star"), TEXT("It is the Sun's twin star."), TEXT("jupiter"), TEXT("Only Jupiter."), TEXT("Correct! The Moon is Earth's companion."), TEXT("Try again. The Moon is linked to our home planet."), TEXT("Look near Earth."), FLinearColor(0.78f, 0.78f, 0.74f), 0.42f, true);
    AddLesson(TEXT("mars"), TEXT("Mars"), TEXT("Mars looks red because rusty iron is mixed into its dust."), TEXT("Mars has giant volcanoes, deep canyons, and signs that water flowed long ago."), TEXT("Rust-red dusty world with a canyon clue."), TEXT("Mars is the red planet."), TEXT("Mars looks red because rusty iron is mixed into its dust."), TEXT("Mars has iron-rich dust and rocks. Oxidation, a rusting process, gives much of the surface its reddish color."), TEXT("Mars is a favorite exploration target because it preserves clues about water, climate, and whether places beyond Earth could have been habitable."), TEXT("Mars is smaller and colder than Earth, with a thinner atmosphere."), TEXT("Rotation: one full spin of a world; revolution: one full trip around the Sun."), TEXT("https://science.nasa.gov/mars/"), TEXT("Why does Mars look red from far away?"), TEXT("rust"), TEXT("Rusty iron is mixed into its dust."), TEXT("plants"), TEXT("It is covered in red plants."), TEXT("jupiter"), TEXT("Jupiter shines red light on it."), TEXT("Great detective work! Rusty dust gives Mars its red color."), TEXT("Try again. Which answer talks about red dust?"), TEXT("Rust can turn iron reddish."), FLinearColor(0.88f, 0.22f, 0.10f), 0.82f, true);
    AddLesson(TEXT("asteroid_belt"), TEXT("Asteroid Belt"), TEXT("The asteroid belt is a region of many small rocky objects."), TEXT("It sits mostly between Mars and Jupiter, but it is not a solid wall."), TEXT("A sparkling rock path between Mars and Jupiter."), TEXT("Asteroids are space rocks."), TEXT("Many asteroids travel around the Sun between Mars and Jupiter."), TEXT("Asteroids are leftover rocky pieces from Solar System formation. Their orbits help scientists study early Solar System history."), TEXT("The belt is spread out across a huge region. A spacecraft can travel through safely with careful planning."), TEXT("Asteroids are much smaller than planets, but together they tell a big history story."), TEXT("Asteroid: a small rocky object that orbits the Sun."), TEXT("https://science.nasa.gov/solar-system/asteroids/"), TEXT("Where is the main asteroid belt?"), TEXT("between"), TEXT("Mostly between Mars and Jupiter."), TEXT("inside_sun"), TEXT("Inside the Sun."), TEXT("after_neptune"), TEXT("Only beyond Neptune."), TEXT("Rock route mapped! The asteroid belt is between Mars and Jupiter."), TEXT("Try again. Look between the red planet and the huge striped planet."), TEXT("The belt comes after Mars on this route."), FLinearColor(0.76f, 0.58f, 0.36f), 0.55f, true);
    AddLesson(TEXT("jupiter"), TEXT("Jupiter"), TEXT("Jupiter is the largest planet in the Solar System."), TEXT("Its Great Red Spot is a giant storm."), TEXT("Huge striped gas giant with a storm badge."), TEXT("Jupiter is the biggest planet."), TEXT("Jupiter is huge, striped, and has many moons."), TEXT("Jupiter is a gas giant. Its gravity shapes many small objects and moons around it."), TEXT("Jupiter does not have a solid surface like Earth. Its clouds form bands, storms, and colorful stripes."), TEXT("Jupiter is far larger than Earth and all the inner rocky planets."), TEXT("Gas giant: a huge planet made mostly of gases and fluids."), TEXT("https://science.nasa.gov/jupiter/"), TEXT("Which planet is the largest?"), TEXT("jupiter"), TEXT("Jupiter."), TEXT("mercury"), TEXT("Mercury."), TEXT("mars"), TEXT("Mars."), TEXT("Giant badge earned! Jupiter is the largest planet."), TEXT("Try again. Find the huge striped world."), TEXT("Jupiter is bigger than every other planet."), FLinearColor(0.94f, 0.64f, 0.36f), 1.55f, true);
    AddLesson(TEXT("europa"), TEXT("Europa"), TEXT("Europa is an icy moon of Jupiter that may hide an ocean under the ice."), TEXT("Scientists are curious because liquid water is one ingredient for habitability."), TEXT("Blue-white cracked ice near Jupiter."), TEXT("Europa is an icy moon."), TEXT("Europa is an icy moon of Jupiter. Scientists hunt for ocean clues under the ice."), TEXT("Europa's icy shell and evidence for a salty ocean make it an important place to study how moons can hold liquid water."), TEXT("Europa shows that moons can be worlds with layers, activity, and big science questions."), TEXT("Europa is much smaller than Jupiter and orbits it, so it is a moon, not a planet."), TEXT("Orbit: the path one object follows around another."), TEXT("https://science.nasa.gov/jupiter/moons/europa/"), TEXT("What kind of world is Europa?"), TEXT("icy_moon"), TEXT("An icy moon of Jupiter."), TEXT("small_planet"), TEXT("The smallest planet near the Sun."), TEXT("red_planet"), TEXT("A red planet with rusty dust."), TEXT("Excellent explorer! Europa is Jupiter's icy moon."), TEXT("Try again. Europa travels around Jupiter."), TEXT("Europa is near Jupiter on the map."), FLinearColor(0.45f, 0.82f, 1.0f), 0.46f, true);
    AddLesson(TEXT("saturn"), TEXT("Saturn"), TEXT("Saturn is famous for its wide bright rings."), TEXT("The rings are made of many icy and rocky pieces."), TEXT("Golden world with a flat ring halo."), TEXT("Saturn has big rings."), TEXT("Saturn's rings are made of ice and rock pieces going around the planet."), TEXT("Saturn is a gas giant. Its ring system helps scientists study gravity, collisions, and orbiting material."), TEXT("The rings look solid from far away, but they are countless pieces traveling around Saturn."), TEXT("Saturn is smaller than Jupiter but much larger than Earth."), TEXT("Gravity: a pull between objects with mass."), TEXT("https://science.nasa.gov/saturn/"), TEXT("Which planet is famous for rings?"), TEXT("saturn"), TEXT("Saturn."), TEXT("earth"), TEXT("Earth."), TEXT("venus"), TEXT("Venus."), TEXT("Ring badge unlocked! Saturn is the ring champion."), TEXT("Try again. Look for the planet with rings."), TEXT("Saturn wears a bright ring system."), FLinearColor(0.95f, 0.78f, 0.34f), 1.35f, true);
    AddLesson(TEXT("uranus"), TEXT("Uranus"), TEXT("Uranus is an ice giant that spins tilted on its side."), TEXT("Its sideways tilt makes its seasons unusual."), TEXT("Pale cyan planet with a tilted axis clue."), TEXT("Uranus is a cold blue-green planet."), TEXT("Uranus spins with a big tilt, almost like it is rolling around the Sun."), TEXT("Uranus is an ice giant with a sideways rotation compared with most planets."), TEXT("A planet's tilt affects seasons. Uranus has one of the strangest tilts in the Solar System."), TEXT("Uranus is larger than Earth but smaller than Jupiter and Saturn."), TEXT("Ice giant: a large cold planet with water, ammonia, and methane-rich materials."), TEXT("https://science.nasa.gov/uranus/"), TEXT("What is unusual about Uranus?"), TEXT("tilt"), TEXT("It spins tilted on its side."), TEXT("closest"), TEXT("It is closest to the Sun."), TEXT("red"), TEXT("It is red from rusty dust."), TEXT("Tilt clue solved! Uranus spins sideways."), TEXT("Try again. Think about the sideways clue."), TEXT("Uranus is the tilted ice giant."), FLinearColor(0.54f, 0.92f, 0.96f), 1.12f, true);
    AddLesson(TEXT("neptune"), TEXT("Neptune"), TEXT("Neptune is the farthest major planet from the Sun."), TEXT("It is a deep blue ice giant with very strong winds."), TEXT("Deep blue world with wind streaks."), TEXT("Neptune is a far blue planet."), TEXT("Neptune is far from the Sun and has strong winds."), TEXT("Neptune is an ice giant. Its blue color and storms help scientists compare the outer planets."), TEXT("Even far from the Sun, Neptune has active weather. Distance does not mean a world is boring."), TEXT("Neptune is similar in size to Uranus and far smaller than Jupiter."), TEXT("Scale: comparing sizes, distances, or times to understand how big space is."), TEXT("https://science.nasa.gov/neptune/"), TEXT("Which major planet is farthest from the Sun?"), TEXT("neptune"), TEXT("Neptune."), TEXT("venus"), TEXT("Venus."), TEXT("moon"), TEXT("The Moon."), TEXT("Far-out scan complete! Neptune is the farthest major planet."), TEXT("Try again. Follow the route to the deep blue world at the edge."), TEXT("Neptune is the last major planet on this map."), FLinearColor(0.10f, 0.28f, 1.0f), 1.08f, true);
    AddLesson(TEXT("pluto"), TEXT("Pluto / Kuiper Preview"), TEXT("Pluto is a dwarf planet in the distant Kuiper Belt."), TEXT("The Kuiper Belt is a faraway region with many icy worlds."), TEXT("Tiny icy bonus world at the edge of the route."), TEXT("Pluto is a tiny faraway world."), TEXT("Pluto is a dwarf planet beyond Neptune."), TEXT("Pluto and other Kuiper Belt objects help scientists study distant icy leftovers from Solar System formation."), TEXT("Dwarf planets are round worlds that orbit the Sun but do not clear their orbital neighborhoods like the eight major planets."), TEXT("Pluto is much smaller than Earth's Moon and far beyond Neptune."), TEXT("Dwarf planet: a round world orbiting the Sun that shares its orbital region with many other objects."), TEXT("https://science.nasa.gov/dwarf-planets/pluto/"), TEXT("What is Pluto called today?"), TEXT("dwarf"), TEXT("A dwarf planet."), TEXT("star"), TEXT("A star."), TEXT("gas"), TEXT("A gas giant."), TEXT("Bonus clue saved! Pluto is a dwarf planet."), TEXT("Try again. Pluto is small and far away."), TEXT("Pluto is a dwarf planet in the Kuiper Belt."), FLinearColor(0.82f, 0.74f, 0.64f), 0.38f, false);
}

void AAstroAdventureGameModeBase::SpawnRuntimeScene()
{
    if (!GetWorld())
    {
        return;
    }

    if (!UGameplayStatics::GetActorOfClass(GetWorld(), APlayerStart::StaticClass()))
    {
        GetWorld()->SpawnActor<APlayerStart>(APlayerStart::StaticClass(), FVector(-1320.0f, -170.0f, 135.0f), FRotator::ZeroRotator);
    }

    ADirectionalLight* KeyLight = GetWorld()->SpawnActor<ADirectionalLight>(ADirectionalLight::StaticClass(), FVector(-900.0f, -900.0f, 900.0f), FRotator(-45.0f, -28.0f, 0.0f));
    if (KeyLight && KeyLight->GetLightComponent())
    {
        KeyLight->GetLightComponent()->SetMobility(EComponentMobility::Movable);
        KeyLight->GetLightComponent()->SetIntensity(14.0f);
        KeyLight->GetLightComponent()->SetLightColor(FLinearColor(0.95f, 0.98f, 1.0f));
    }

    APointLight* SunLight = GetWorld()->SpawnActor<APointLight>(APointLight::StaticClass(), FVector(-1400.0f, 0.0f, 190.0f), FRotator::ZeroRotator);
    if (SunLight && SunLight->PointLightComponent)
    {
        SunLight->PointLightComponent->SetMobility(EComponentMobility::Movable);
        SunLight->PointLightComponent->SetIntensity(90000.0f);
        SunLight->PointLightComponent->SetAttenuationRadius(4200.0f);
        SunLight->PointLightComponent->SetUseInverseSquaredFalloff(false);
        SunLight->PointLightComponent->SetLightColor(FLinearColor(1.0f, 0.76f, 0.28f));
    }

    APointLight* PlayerFillLight = GetWorld()->SpawnActor<APointLight>(APointLight::StaticClass(), FVector(-250.0f, -360.0f, 540.0f), FRotator::ZeroRotator);
    if (PlayerFillLight && PlayerFillLight->PointLightComponent)
    {
        PlayerFillLight->PointLightComponent->SetMobility(EComponentMobility::Movable);
        PlayerFillLight->PointLightComponent->SetIntensity(52000.0f);
        PlayerFillLight->PointLightComponent->SetAttenuationRadius(4400.0f);
        PlayerFillLight->PointLightComponent->SetUseInverseSquaredFalloff(false);
        PlayerFillLight->PointLightComponent->SetLightColor(FLinearColor(0.36f, 0.74f, 1.0f));
    }

    ASkyLight* FillLight = GetWorld()->SpawnActor<ASkyLight>(ASkyLight::StaticClass(), FVector(0.0f, 0.0f, 460.0f), FRotator::ZeroRotator);
    if (FillLight && FillLight->GetLightComponent())
    {
        FillLight->GetLightComponent()->SetMobility(EComponentMobility::Movable);
        FillLight->GetLightComponent()->SetIntensity(5.5f);
        FillLight->GetLightComponent()->SetLightColor(FLinearColor(0.58f, 0.74f, 1.0f));
    }

    APostProcessVolume* LookDevVolume = GetWorld()->SpawnActor<APostProcessVolume>(APostProcessVolume::StaticClass(), FVector::ZeroVector, FRotator::ZeroRotator);
    if (LookDevVolume)
    {
        LookDevVolume->bUnbound = true;
        LookDevVolume->Settings.bOverride_AutoExposureMethod = true;
        LookDevVolume->Settings.AutoExposureMethod = EAutoExposureMethod::AEM_Manual;
        LookDevVolume->Settings.bOverride_AutoExposureBias = true;
        LookDevVolume->Settings.AutoExposureBias = 1.35f;
        LookDevVolume->Settings.bOverride_AutoExposureMinBrightness = true;
        LookDevVolume->Settings.AutoExposureMinBrightness = 1.0f;
        LookDevVolume->Settings.bOverride_AutoExposureMaxBrightness = true;
        LookDevVolume->Settings.AutoExposureMaxBrightness = 1.0f;
        LookDevVolume->Settings.bOverride_BloomIntensity = true;
        LookDevVolume->Settings.BloomIntensity = 0.95f;
        LookDevVolume->Settings.bOverride_BloomThreshold = true;
        LookDevVolume->Settings.BloomThreshold = 0.42f;
        LookDevVolume->Settings.bOverride_ColorSaturation = true;
        LookDevVolume->Settings.ColorSaturation = FVector4(1.16f, 1.14f, 1.2f, 1.0f);
        LookDevVolume->Settings.bOverride_VignetteIntensity = true;
        LookDevVolume->Settings.VignetteIntensity = 0.0f;
    }

    BackdropActors.Reset();
    SpawnBackdrop();

    const FVector Positions[] = {
        FVector(-1400.0f, 0.0f, 180.0f),
        FVector(-1060.0f, -275.0f, 118.0f),
        FVector(-760.0f, 265.0f, 128.0f),
        FVector(-455.0f, -245.0f, 124.0f),
        FVector(-335.0f, -105.0f, 106.0f),
        FVector(-110.0f, 260.0f, 122.0f),
        FVector(235.0f, -10.0f, 110.0f),
        FVector(595.0f, 275.0f, 150.0f),
        FVector(735.0f, 410.0f, 120.0f),
        FVector(1055.0f, -260.0f, 145.0f),
        FVector(1375.0f, 235.0f, 140.0f),
        FVector(1685.0f, -155.0f, 138.0f),
        FVector(1980.0f, 310.0f, 110.0f)
    };

    DestinationActors.Reset();
    ScanBeamActors.Reset();
    RouteMarkerActors.Reset();
    RouteMarkerOwnerIndices.Reset();
    for (int32 Index = 0; Index < Lessons.Num(); ++Index)
    {
        AAstroDestinationActor* Actor = GetWorld()->SpawnActor<AAstroDestinationActor>(AAstroDestinationActor::StaticClass(), Positions[Index], FRotator::ZeroRotator);
        if (Actor)
        {
            Actor->Configure(Lessons[Index], Lessons[Index].DisplayColor, Lessons[Index].MapScale);
            Actor->SetDiscovered(GetMutableProgress(Lessons[Index].DestinationId).bQuizCompleted);
            DestinationActors.Add(Actor);
            SpawnOrbitMarker(Index, Positions[Index], 80.0f + Lessons[Index].MapScale * 35.0f, Lessons[Index].DisplayColor);
            if (Index > 0)
            {
                SpawnRouteSegment(Index, Positions[Index - 1], Positions[Index], Lessons[Index].DisplayColor);
            }
        }
    }

    SpawnAsteroidBelt(6, Positions[6]);

    PlayerPawn = Cast<AAstroPlayerPawn>(UGameplayStatics::GetPlayerPawn(GetWorld(), 0));
    if (PlayerPawn && DestinationActors.IsValidIndex(FocusedDestinationIndex))
    {
        const FVector FocusLocation = DestinationActors[FocusedDestinationIndex]->GetActorLocation();
        PlayerPawn->SetTravelTarget(FocusLocation + FVector(-145.0f, 0.0f, 70.0f));
        PlayerPawn->SetCameraFocusTarget(FocusLocation + FVector(0.0f, 0.0f, 45.0f));
    }
}

void AAstroAdventureGameModeBase::SpawnRouteSegment(const int32 OwnerIndex, const FVector& Start, const FVector& End, const FLinearColor& Color)
{
    UStaticMesh* SphereMesh = LoadObject<UStaticMesh>(nullptr, TEXT("/Engine/BasicShapes/Sphere.Sphere"));
    if (!SphereMesh || !GetWorld())
    {
        return;
    }

    const FLinearColor RouteColor = Color.GetClamped(0.0f, 1.0f) * 0.75f;
    for (int32 Index = 1; Index <= 7; ++Index)
    {
        const float Alpha = static_cast<float>(Index) / 8.0f;
        const FVector ArcLift(0.0f, 0.0f, FMath::Sin(Alpha * PI) * 36.0f);
        AStaticMeshActor* Dot = GetWorld()->SpawnActor<AStaticMeshActor>(AStaticMeshActor::StaticClass(), FMath::Lerp(Start, End, Alpha) + ArcLift, FRotator::ZeroRotator);
        if (Dot)
        {
            Dot->GetStaticMeshComponent()->SetStaticMesh(SphereMesh);
            Dot->SetActorScale3D(FVector(Index % 2 == 0 ? 0.026f : 0.018f));
            Dot->GetStaticMeshComponent()->SetCollisionEnabled(ECollisionEnabled::NoCollision);
            ApplyRuntimeColor(Dot, RouteColor, 1.1f);
            RouteMarkerActors.Add(Dot);
            RouteMarkerOwnerIndices.Add(OwnerIndex);
        }
    }
}

void AAstroAdventureGameModeBase::SpawnOrbitMarker(const int32 OwnerIndex, const FVector& Center, const float Radius, const FLinearColor& Color)
{
    UStaticMesh* SphereMesh = LoadObject<UStaticMesh>(nullptr, TEXT("/Engine/BasicShapes/Sphere.Sphere"));
    if (!SphereMesh || !GetWorld())
    {
        return;
    }

    for (int32 Index = 0; Index < 18; ++Index)
    {
        const float Angle = (2.0f * PI * Index) / 18.0f;
        const FVector Location = Center + FVector(FMath::Cos(Angle) * Radius, FMath::Sin(Angle) * Radius, -42.0f);
        AStaticMeshActor* Dot = GetWorld()->SpawnActor<AStaticMeshActor>(AStaticMeshActor::StaticClass(), Location, FRotator::ZeroRotator);
        if (Dot)
        {
            Dot->GetStaticMeshComponent()->SetStaticMesh(SphereMesh);
            Dot->SetActorScale3D(FVector(Index % 3 == 0 ? 0.03f : 0.018f));
            Dot->GetStaticMeshComponent()->SetCollisionEnabled(ECollisionEnabled::NoCollision);
            ApplyRuntimeColor(Dot, Color, 0.85f);
            RouteMarkerActors.Add(Dot);
            RouteMarkerOwnerIndices.Add(OwnerIndex);
        }
    }
}

void AAstroAdventureGameModeBase::SpawnAsteroidBelt(const int32 OwnerIndex, const FVector& Center)
{
    UStaticMesh* SphereMesh = LoadObject<UStaticMesh>(nullptr, TEXT("/Engine/BasicShapes/Sphere.Sphere"));
    if (!SphereMesh || !GetWorld())
    {
        return;
    }

    for (int32 Index = 0; Index < 42; ++Index)
    {
        const float Angle = FMath::FRandRange(0.0f, 2.0f * PI);
        const float Radius = FMath::FRandRange(80.0f, 180.0f);
        AStaticMeshActor* Rock = GetWorld()->SpawnActor<AStaticMeshActor>(AStaticMeshActor::StaticClass(), Center + FVector(FMath::Cos(Angle) * Radius, FMath::Sin(Angle) * Radius, FMath::FRandRange(-18.0f, 28.0f)), FRotator::ZeroRotator);
        if (Rock)
        {
            Rock->GetStaticMeshComponent()->SetStaticMesh(SphereMesh);
            Rock->SetActorScale3D(FVector(FMath::FRandRange(0.03f, 0.09f)));
            Rock->GetStaticMeshComponent()->SetCollisionEnabled(ECollisionEnabled::NoCollision);
            ApplyRuntimeColor(Rock, FLinearColor(0.72f, 0.58f, 0.42f), 0.35f);
            RouteMarkerActors.Add(Rock);
            RouteMarkerOwnerIndices.Add(OwnerIndex);
        }
    }
}

void AAstroAdventureGameModeBase::SpawnBackdrop()
{
    UStaticMesh* SphereMesh = LoadObject<UStaticMesh>(nullptr, TEXT("/Engine/BasicShapes/Sphere.Sphere"));
    if (!SphereMesh || !GetWorld())
    {
        return;
    }

    FRandomStream BackdropStream(250425);

    for (int32 Index = 0; Index < 360; ++Index)
    {
        const FLinearColor Color = Index % 11 == 0 ? FLinearColor(0.72f, 0.96f, 1.0f) : Index % 17 == 0 ? FLinearColor(1.0f, 0.78f, 0.48f) : FLinearColor(0.86f, 0.9f, 1.0f);
        AStaticMeshActor* Star = GetWorld()->SpawnActor<AStaticMeshActor>(
            AStaticMeshActor::StaticClass(),
            FVector(BackdropStream.FRandRange(-1840.0f, 2440.0f), BackdropStream.FRandRange(-1120.0f, 1120.0f), BackdropStream.FRandRange(120.0f, 920.0f)),
            FRotator::ZeroRotator);
        if (Star)
        {
            Star->GetStaticMeshComponent()->SetStaticMesh(SphereMesh);
            Star->SetActorScale3D(FVector(BackdropStream.FRandRange(0.026f, Index % 13 == 0 ? 0.13f : 0.072f)));
            Star->GetStaticMeshComponent()->SetCollisionEnabled(ECollisionEnabled::NoCollision);
            ApplyRuntimeColor(Star, Color, Index % 13 == 0 ? 5.0f : 2.8f);
            BackdropActors.Add(Star);
        }
    }

    for (int32 Index = 0; Index < 44; ++Index)
    {
        const FLinearColor Color = Index % 4 == 0 ? FLinearColor(0.10f, 0.34f, 0.64f, 0.42f) : Index % 4 == 1 ? FLinearColor(0.46f, 0.16f, 0.62f, 0.34f) : Index % 4 == 2 ? FLinearColor(0.70f, 0.34f, 0.12f, 0.28f) : FLinearColor(0.12f, 0.50f, 0.46f, 0.28f);
        const FVector Center(BackdropStream.FRandRange(-1680.0f, 2320.0f), BackdropStream.FRandRange(-960.0f, 960.0f), BackdropStream.FRandRange(180.0f, 760.0f));
        AStaticMeshActor* Cloud = GetWorld()->SpawnActor<AStaticMeshActor>(
            AStaticMeshActor::StaticClass(),
            Center,
            FRotator(BackdropStream.FRandRange(-18.0f, 18.0f), BackdropStream.FRandRange(0.0f, 360.0f), BackdropStream.FRandRange(-34.0f, 34.0f)));
        if (Cloud)
        {
            Cloud->GetStaticMeshComponent()->SetStaticMesh(SphereMesh);
            Cloud->SetActorScale3D(FVector(BackdropStream.FRandRange(0.42f, 1.35f), BackdropStream.FRandRange(0.11f, 0.34f), BackdropStream.FRandRange(0.035f, 0.13f)));
            Cloud->GetStaticMeshComponent()->SetCollisionEnabled(ECollisionEnabled::NoCollision);
            ApplyRuntimeColor(Cloud, Color, 1.4f);
            BackdropActors.Add(Cloud);
        }
    }
}

void AAstroAdventureGameModeBase::LoadProgress()
{
    if (USaveGame* Existing = UGameplayStatics::LoadGameFromSlot(SaveSlotName, SaveUserIndex))
    {
        ProgressSave = Cast<UAstroProgressSaveGame>(Existing);
    }

    if (!ProgressSave)
    {
        ProgressSave = Cast<UAstroProgressSaveGame>(UGameplayStatics::CreateSaveGameObject(UAstroProgressSaveGame::StaticClass()));
    }

    ProgressSave->MissionId = MissionId;
    ActiveAgeBand = ProgressSave->AgeBand;
    AgeSelectIndex = ActiveAgeBand == EAstroAgeBand::Ages4To6 ? 0 : ActiveAgeBand == EAstroAgeBand::Ages7To9 ? 1 : 2;

    for (const FAstroDestinationLesson& Lesson : Lessons)
    {
        GetMutableProgress(Lesson.DestinationId);
    }
}

void AAstroAdventureGameModeBase::SaveProgress() const
{
    if (ProgressSave)
    {
        UGameplayStatics::SaveGameToSlot(ProgressSave, SaveSlotName, SaveUserIndex);
    }
}

void AAstroAdventureGameModeBase::FocusNextDestination()
{
    if (CurrentScreen == EAstroMissionScreen::Home)
    {
        HomeMenuIndex = (HomeMenuIndex + 1) % 4;
        return;
    }
    if (CurrentScreen == EAstroMissionScreen::AgeSelect)
    {
        AgeSelectIndex = (AgeSelectIndex + 1) % 3;
        return;
    }
    if (CurrentScreen == EAstroMissionScreen::MissionComplete)
    {
        MissionCompleteMenuIndex = (MissionCompleteMenuIndex + 1) % 4;
        return;
    }
    if (CurrentScreen == EAstroMissionScreen::PauseMenu)
    {
        PauseMenuIndex = (PauseMenuIndex + 1) % 4;
        return;
    }
    if (CurrentScreen == EAstroMissionScreen::Quiz)
    {
        MoveQuizFocus(1);
        return;
    }

    if (!Lessons.IsEmpty() && (CurrentScreen == EAstroMissionScreen::Navigation || CurrentScreen == EAstroMissionScreen::AtlasView || CurrentScreen == EAstroMissionScreen::Passport))
    {
        FocusedDestinationIndex = (FocusedDestinationIndex + 1) % Lessons.Num();
        UpdateDestinationFocus();
    }
    else if (CurrentScreen == EAstroMissionScreen::QuizFeedback && bLastAnswerCorrect)
    {
        Confirm();
    }
    else if (CurrentScreen == EAstroMissionScreen::StampAward)
    {
        if (!IsMissionComplete() && AdvanceToNextRouteStop())
        {
            CurrentScreen = EAstroMissionScreen::Navigation;
        }
        else
        {
            CurrentScreen = EAstroMissionScreen::MissionComplete;
            UpdateDestinationFocus();
        }
    }
}

void AAstroAdventureGameModeBase::FocusPreviousDestination()
{
    if (CurrentScreen == EAstroMissionScreen::Home)
    {
        HomeMenuIndex = (HomeMenuIndex + 3) % 4;
        return;
    }
    if (CurrentScreen == EAstroMissionScreen::AgeSelect)
    {
        AgeSelectIndex = (AgeSelectIndex + 2) % 3;
        return;
    }
    if (CurrentScreen == EAstroMissionScreen::MissionComplete)
    {
        MissionCompleteMenuIndex = (MissionCompleteMenuIndex + 3) % 4;
        return;
    }
    if (CurrentScreen == EAstroMissionScreen::PauseMenu)
    {
        PauseMenuIndex = (PauseMenuIndex + 3) % 4;
        return;
    }
    if (CurrentScreen == EAstroMissionScreen::Quiz)
    {
        MoveQuizFocus(-1);
        return;
    }

    if (!Lessons.IsEmpty() && (CurrentScreen == EAstroMissionScreen::Navigation || CurrentScreen == EAstroMissionScreen::AtlasView || CurrentScreen == EAstroMissionScreen::Passport))
    {
        FocusedDestinationIndex = (FocusedDestinationIndex - 1 + Lessons.Num()) % Lessons.Num();
        UpdateDestinationFocus();
    }
    else if (CurrentScreen == EAstroMissionScreen::StampAward)
    {
        CurrentScreen = EAstroMissionScreen::Navigation;
        FocusedDestinationIndex = (FocusedDestinationIndex - 1 + Lessons.Num()) % Lessons.Num();
        UpdateDestinationFocus();
    }
}

void AAstroAdventureGameModeBase::Confirm()
{
    const FAstroDestinationLesson* Lesson = GetFocusedLesson();
    if (CurrentScreen == EAstroMissionScreen::Home)
    {
        ExecuteHomeSelection();
        return;
    }
    if (CurrentScreen == EAstroMissionScreen::AgeSelect)
    {
        SelectAgeBand(AgeSelectIndex);
        CurrentScreen = EAstroMissionScreen::MissionPrompt;
        return;
    }
    if (CurrentScreen == EAstroMissionScreen::PauseMenu)
    {
        ExecutePauseSelection();
        return;
    }
    if (CurrentScreen == EAstroMissionScreen::MissionComplete)
    {
        ExecuteMissionCompleteSelection();
        return;
    }
    if (!Lesson)
    {
        return;
    }

    bShowingHint = false;
    switch (CurrentScreen)
    {
    case EAstroMissionScreen::MissionPrompt:
        CurrentScreen = EAstroMissionScreen::Navigation;
        break;
    case EAstroMissionScreen::Navigation:
        MarkScanned(Lesson->DestinationId);
        TriggerScanFeedback(*Lesson);
        CurrentScreen = EAstroMissionScreen::DiscoveryCard;
        break;
    case EAstroMissionScreen::DiscoveryCard:
    case EAstroMissionScreen::DeepDive:
        FocusedQuizChoiceIndex = 0;
        CurrentScreen = EAstroMissionScreen::Quiz;
        break;
    case EAstroMissionScreen::Passport:
    case EAstroMissionScreen::AtlasView:
        CurrentScreen = EAstroMissionScreen::Navigation;
        break;
    case EAstroMissionScreen::Quiz:
        SubmitAnswer(FocusedQuizChoiceIndex);
        break;
    case EAstroMissionScreen::QuizFeedback:
        if (bLastAnswerCorrect)
        {
            const bool bAlreadyStamped = HasStampForDestination(Lesson->DestinationId);
            CompleteQuiz(Lesson->DestinationId, true);
            if (bAlreadyStamped)
            {
                if (IsMissionComplete() || !AdvanceToNextRouteStop())
                {
                    CurrentScreen = EAstroMissionScreen::MissionComplete;
                }
            }
            else
            {
                TriggerStampFeedback(*Lesson);
                CurrentScreen = EAstroMissionScreen::StampAward;
            }
        }
        else
        {
            CurrentScreen = EAstroMissionScreen::Quiz;
        }
        break;
    case EAstroMissionScreen::StampAward:
        if (IsMissionComplete() || !AdvanceToNextRouteStop())
        {
            CurrentScreen = EAstroMissionScreen::MissionComplete;
        }
        break;
    case EAstroMissionScreen::MissionComplete:
        CurrentScreen = EAstroMissionScreen::AtlasView;
        break;
    default:
        break;
    }

    UpdateDestinationFocus();
}

void AAstroAdventureGameModeBase::Back()
{
    bShowingHint = false;
    if (CurrentScreen == EAstroMissionScreen::Home)
    {
        return;
    }
    if (CurrentScreen == EAstroMissionScreen::AgeSelect || CurrentScreen == EAstroMissionScreen::MissionPrompt)
    {
        CurrentScreen = EAstroMissionScreen::Home;
        HomeMenuIndex = HasAnyProgress() ? 1 : 0;
        return;
    }
    if (CurrentScreen == EAstroMissionScreen::PauseMenu)
    {
        CurrentScreen = PreviousScreen;
    }
    else if (CurrentScreen == EAstroMissionScreen::Quiz)
    {
        CurrentScreen = EAstroMissionScreen::DiscoveryCard;
    }
    else if (CurrentScreen == EAstroMissionScreen::DiscoveryCard || CurrentScreen == EAstroMissionScreen::DeepDive || CurrentScreen == EAstroMissionScreen::QuizFeedback || CurrentScreen == EAstroMissionScreen::StampAward || CurrentScreen == EAstroMissionScreen::Passport || CurrentScreen == EAstroMissionScreen::AtlasView)
    {
        CurrentScreen = EAstroMissionScreen::Navigation;
    }
    else if (CurrentScreen == EAstroMissionScreen::MissionComplete)
    {
        CurrentScreen = EAstroMissionScreen::AtlasView;
    }

    RefreshScenePresentation();
}

void AAstroAdventureGameModeBase::RequestHint()
{
    bShowingHint = true;
}

void AAstroAdventureGameModeBase::ToggleDeepDive()
{
    if (CurrentScreen == EAstroMissionScreen::DiscoveryCard)
    {
        CurrentScreen = EAstroMissionScreen::DeepDive;
    }
    else if (CurrentScreen == EAstroMissionScreen::DeepDive)
    {
        CurrentScreen = EAstroMissionScreen::DiscoveryCard;
    }

    RefreshScenePresentation();
}

void AAstroAdventureGameModeBase::TogglePassport()
{
    if (CurrentScreen == EAstroMissionScreen::AtlasView || CurrentScreen == EAstroMissionScreen::Passport)
    {
        CurrentScreen = PreviousScreen == EAstroMissionScreen::AtlasView || PreviousScreen == EAstroMissionScreen::Passport ? EAstroMissionScreen::Navigation : PreviousScreen;
    }
    else if (CurrentScreen != EAstroMissionScreen::Home && CurrentScreen != EAstroMissionScreen::AgeSelect && CurrentScreen != EAstroMissionScreen::PauseMenu)
    {
        PreviousScreen = CurrentScreen;
        CurrentScreen = EAstroMissionScreen::AtlasView;
    }

    RefreshScenePresentation();
}

void AAstroAdventureGameModeBase::TogglePause()
{
    if (CurrentScreen == EAstroMissionScreen::PauseMenu)
    {
        CurrentScreen = PreviousScreen;
    }
    else if (CurrentScreen == EAstroMissionScreen::Home)
    {
        return;
    }
    else
    {
        PreviousScreen = CurrentScreen;
        PauseMenuIndex = 0;
        CurrentScreen = EAstroMissionScreen::PauseMenu;
    }

    RefreshScenePresentation();
}

void AAstroAdventureGameModeBase::MoveQuizFocus(const int32 Direction)
{
    const FAstroDestinationLesson* Lesson = GetFocusedLesson();
    if (!Lesson || Lesson->Choices.IsEmpty() || CurrentScreen != EAstroMissionScreen::Quiz)
    {
        return;
    }

    FocusedQuizChoiceIndex = (FocusedQuizChoiceIndex + Direction + Lesson->Choices.Num()) % Lesson->Choices.Num();
}

void AAstroAdventureGameModeBase::SubmitAnswer(const int32 ChoiceIndex)
{
    const FAstroDestinationLesson* Lesson = GetFocusedLesson();
    if (!Lesson || !Lesson->Choices.IsValidIndex(ChoiceIndex))
    {
        return;
    }

    FAstroDestinationProgress& Progress = GetMutableProgress(Lesson->DestinationId);
    const bool bAlreadyStamped = Progress.bQuizCompleted;
    Progress.Attempts += 1;

    bLastAnswerCorrect = Lesson->Choices[ChoiceIndex].ChoiceId == Lesson->CorrectChoiceId;
    if (bLastAnswerCorrect && bAlreadyStamped)
    {
        LastFeedback = FString::Printf(TEXT("Review complete! The %s stamp is already saved."), *Lesson->DisplayName.ToString());
    }
    else
    {
        LastFeedback = (bLastAnswerCorrect ? Lesson->CorrectFeedback : Lesson->RetryFeedback).ToString();
    }
    CurrentScreen = EAstroMissionScreen::QuizFeedback;

    if (!bLastAnswerCorrect)
    {
        CompleteQuiz(Lesson->DestinationId, false);
    }
    SaveProgress();
}

FString AAstroAdventureGameModeBase::GetHudStatusLine() const
{
    return FString::Printf(TEXT("Solar Passport %d/%d stamps | Explorer mode ages %s"), CountCompletedStops(), Lessons.Num(), ActiveAgeBand == EAstroAgeBand::Ages4To6 ? TEXT("4-6") : ActiveAgeBand == EAstroAgeBand::Ages7To9 ? TEXT("7-9") : TEXT("10-12"));
}

FString AAstroAdventureGameModeBase::GetHudPrimaryLine() const
{
    const FAstroDestinationLesson* Lesson = GetFocusedLesson();
    const FString Name = Lesson ? Lesson->DisplayName.ToString() : TEXT("space");

    switch (CurrentScreen)
    {
    case EAstroMissionScreen::Home:
        return TEXT("Solar Passport");
    case EAstroMissionScreen::AgeSelect:
        return TEXT("Choose your explorer mode");
    case EAstroMissionScreen::MissionPrompt:
        return TEXT("Solar Passport: First Expedition");
    case EAstroMissionScreen::Navigation:
        if (Lesson && HasStampForDestination(Lesson->DestinationId))
        {
            return FString::Printf(TEXT("Rescan %s to review the saved card"), *Name);
        }
        return FString::Printf(TEXT("Travel to %s, then scan its discovery card!"), *Name);
    case EAstroMissionScreen::DiscoveryCard:
        return FString::Printf(TEXT("%s discovery card unlocked!"), *Name);
    case EAstroMissionScreen::DeepDive:
        return FString::Printf(TEXT("Look closer: %s"), *Name);
    case EAstroMissionScreen::Passport:
    case EAstroMissionScreen::AtlasView:
        return TEXT("Solar Passport discovery log");
    case EAstroMissionScreen::Quiz:
        return Lesson ? Lesson->QuizPrompt.ToString() : TEXT("Quiz");
    case EAstroMissionScreen::QuizFeedback:
        return LastFeedback;
    case EAstroMissionScreen::StampAward:
        return Lesson ? FString::Printf(TEXT("New stamp unlocked: %s"), *Name) : TEXT("New stamp unlocked!");
    case EAstroMissionScreen::MissionComplete:
        return TEXT("Mission complete! Your Solar Passport has a full first-expedition route.");
    case EAstroMissionScreen::PauseMenu:
        return TEXT("Paused");
    default:
        return TEXT("");
    }
}

TArray<FString> AAstroAdventureGameModeBase::GetHudDetailLines() const
{
    TArray<FString> Lines;
    const FAstroDestinationLesson* Lesson = GetFocusedLesson();

    if (CurrentScreen == EAstroMissionScreen::Home)
    {
        const TCHAR* Options[] = {TEXT("New Expedition"), TEXT("Continue"), TEXT("Reset Passport"), TEXT("Quit")};
        for (int32 Index = 0; Index < 4; ++Index)
        {
            FString Label = Options[Index];
            if (Index == 1 && !HasAnyProgress())
            {
                Label += TEXT(" - no saved route yet");
            }
            Lines.Add(FString::Printf(TEXT("%s %s"), Index == HomeMenuIndex ? TEXT(">") : TEXT(" "), *Label));
        }
        if (!LastFeedback.IsEmpty())
        {
            Lines.Add(LastFeedback);
        }
        Lines.Add(TEXT("Start fresh for a clean local playtest."));
        return Lines;
    }

    if (CurrentScreen == EAstroMissionScreen::AgeSelect)
    {
        const TCHAR* Options[] = {TEXT("Ages 4-6: picture clues and tiny facts"), TEXT("Ages 7-9: clue matching and wow facts"), TEXT("Ages 10-12: deeper why/how and scale")};
        for (int32 Index = 0; Index < 3; ++Index)
        {
            Lines.Add(FString::Printf(TEXT("%s %s"), Index == AgeSelectIndex ? TEXT(">") : TEXT(" "), Options[Index]));
        }
        Lines.Add(TEXT("Confirm to launch. You can change this later from Pause."));
        return Lines;
    }

    if (CurrentScreen == EAstroMissionScreen::PauseMenu)
    {
        const TCHAR* Options[] = {TEXT("Resume"), TEXT("Restart mission"), TEXT("Change age"), TEXT("Quit to desktop")};
        for (int32 Index = 0; Index < 4; ++Index)
        {
            Lines.Add(FString::Printf(TEXT("%s %s"), Index == PauseMenuIndex ? TEXT(">") : TEXT(" "), Options[Index]));
        }
        return Lines;
    }

    if (CurrentScreen == EAstroMissionScreen::MissionComplete)
    {
        const TCHAR* Options[] = {TEXT("Explore again"), TEXT("Open Passport"), TEXT("Change age"), TEXT("Quit")};
        Lines.Add(TEXT("Route complete! You scanned the Solar System and earned the required stamps."));
        for (int32 Index = 0; Index < 4; ++Index)
        {
            Lines.Add(FString::Printf(TEXT("%s %s"), Index == MissionCompleteMenuIndex ? TEXT(">") : TEXT(" "), Options[Index]));
        }
        return Lines;
    }

    if (!Lesson)
    {
        return Lines;
    }

    if (CurrentScreen == EAstroMissionScreen::MissionPrompt)
    {
        Lines.Add(TEXT("Pilot the comet ship, scan the Solar System, answer tiny science challenges, and collect passport stamps."));
        Lines.Add(TEXT("Main route: Sun, planets, Moon, asteroid belt, Europa, and Pluto preview."));
    }
    else if (CurrentScreen == EAstroMissionScreen::DiscoveryCard)
    {
        Lines.Add(FString::Printf(TEXT("Quick fact: %s"), *Lesson->DiscoveryFact.ToString()));
        if (ActiveAgeBand != EAstroAgeBand::Ages4To6)
        {
            Lines.Add(FString::Printf(TEXT("Wow fact: %s"), *Lesson->WowFact.ToString()));
        }
        Lines.Add(FString::Printf(TEXT("Look for: %s"), *Lesson->VisualClue.ToString()));
        Lines.Add(UAstroLearningLibrary::LessonTextForAgeBand(*Lesson, ActiveAgeBand).ToString());
        Lines.Add(TEXT("Press M / LT for More Info, or Confirm for the quiz."));
    }
    else if (CurrentScreen == EAstroMissionScreen::DeepDive)
    {
        Lines.Add(Lesson->DeepDiveText.ToString());
        Lines.Add(FString::Printf(TEXT("Compare: %s"), *Lesson->CompareFact.ToString()));
        Lines.Add(FString::Printf(TEXT("Word explorer: %s"), *Lesson->GlossaryText.ToString()));
        Lines.Add(TEXT("Source notes are kept outside the kid cards."));
    }
    else if (CurrentScreen == EAstroMissionScreen::Quiz)
    {
        for (int32 Index = 0; Index < Lesson->Choices.Num(); ++Index)
        {
            const FString Prefix = Index == FocusedQuizChoiceIndex ? TEXT("> ") : TEXT("  ");
            Lines.Add(FString::Printf(TEXT("%s%d. %s"), *Prefix, Index + 1, *Lesson->Choices[Index].Text.ToString()));
        }
    }
    else if (CurrentScreen == EAstroMissionScreen::QuizFeedback)
    {
        const FAstroDestinationProgress* Progress = ProgressSave ? ProgressSave->DestinationProgress.Find(Lesson->DestinationId) : nullptr;
        const bool bReviewingStampedStop = Progress && Progress->bQuizCompleted;
        Lines.Add(bLastAnswerCorrect ? bReviewingStampedStop ? TEXT("Review complete. Confirm or Right/D for the next stop.") : TEXT("Correct answer. Confirm to add the stamp.") : TEXT("No worries. Confirm to retry, or ask for a hint."));
    }
    else if (CurrentScreen == EAstroMissionScreen::StampAward)
    {
        const FAstroDestinationProgress* Progress = ProgressSave ? ProgressSave->DestinationProgress.Find(Lesson->DestinationId) : nullptr;
        Lines.Add(FString::Printf(TEXT("%s is now marked STAMPED in your Passport."), *Lesson->DisplayName.ToString()));
        Lines.Add(TEXT("Each stop saves one stamp; rescans reopen the review card."));
        Lines.Add(IsMissionComplete() ? TEXT("Confirm to celebrate the completed route.") : TEXT("Confirm or press Right/D for Next Stop."));
        Lines.Add(FString::Printf(TEXT("Review box %d | mastery %d"), Progress ? Progress->ReviewBox : 0, Progress ? Progress->MasteryScore : 0));
    }
    else if (CurrentScreen == EAstroMissionScreen::Navigation)
    {
        Lines.Add(FString::Printf(TEXT("Next stop: %s"), *Lesson->DisplayName.ToString()));
        Lines.Add(FString::Printf(TEXT("Clue: %s"), *Lesson->VisualClue.ToString()));
        const FAstroDestinationProgress* Progress = ProgressSave ? ProgressSave->DestinationProgress.Find(Lesson->DestinationId) : nullptr;
        Lines.Add(Progress && Progress->bQuizCompleted ? TEXT("Stamp saved already. Confirm to rescan and review.") : Progress && Progress->bScanned ? TEXT("Scan found. Confirm to scan again and reopen its card.") : TEXT("Confirm to scan for a discovery card."));
        Lines.Add(TEXT("Travel: Arrow keys / WASD / D-pad. Scan: Enter / Space / A."));
    }
    else if (CurrentScreen == EAstroMissionScreen::Passport || CurrentScreen == EAstroMissionScreen::AtlasView)
    {
        Lines.Add(TEXT("Atlas View: full route, stamps, mastery, and future review boxes."));
        for (int32 Index = 0; Index < Lessons.Num(); ++Index)
        {
            const FAstroDestinationProgress* Progress = ProgressSave ? ProgressSave->DestinationProgress.Find(Lessons[Index].DestinationId) : nullptr;
            Lines.Add(FString::Printf(TEXT("%s %s | %s | mastery %d | box %d"), Index == FocusedDestinationIndex ? TEXT(">") : TEXT(" "), *Lessons[Index].DisplayName.ToString(), Progress && Progress->bQuizCompleted ? TEXT("stamped") : Progress && Progress->bScanned ? TEXT("quiz ready") : TEXT("not scanned"), Progress ? Progress->MasteryScore : 0, Progress ? Progress->ReviewBox : 0));
            if (Lines.Num() >= 9)
            {
                Lines.Add(TEXT("Move focus to inspect more stops. Back returns to the mission."));
                break;
            }
        }
    }
    else if (CurrentScreen == EAstroMissionScreen::MissionComplete)
    {
        Lines.Add(TEXT("Review your Passport, replay the route, change age mode, or quit."));
        Lines.Add(TEXT("You matched visual clues, facts, and quiz answers across the Solar System."));
    }

    if (bShowingHint)
    {
        Lines.Add(FString::Printf(TEXT("Hint: %s"), *Lesson->HintText.ToString()));
    }

    return Lines;
}

void AAstroAdventureGameModeBase::UpdateDestinationFocus()
{
    for (int32 Index = 0; Index < DestinationActors.Num(); ++Index)
    {
        if (DestinationActors[Index])
        {
            DestinationActors[Index]->SetFocused(Index == FocusedDestinationIndex);
            const FAstroDestinationProgress* Progress = ProgressSave ? ProgressSave->DestinationProgress.Find(DestinationActors[Index]->DestinationId) : nullptr;
            DestinationActors[Index]->SetDiscovered(Progress && Progress->bQuizCompleted);
        }
    }

    if (PlayerPawn && DestinationActors.IsValidIndex(FocusedDestinationIndex) && DestinationActors[FocusedDestinationIndex])
    {
        const FVector FocusLocation = DestinationActors[FocusedDestinationIndex]->GetActorLocation();
        PlayerPawn->SetTravelTarget(FocusLocation + FVector(-145.0f, 0.0f, 70.0f));
        PlayerPawn->SetCameraFocusTarget(FocusLocation + FVector(0.0f, 0.0f, 45.0f));
    }

    RefreshScenePresentation();
}

void AAstroAdventureGameModeBase::RefreshScenePresentation()
{
    for (int32 Index = 0; Index < DestinationActors.Num(); ++Index)
    {
        if (DestinationActors[Index])
        {
            DestinationActors[Index]->SetActorHiddenInGame(!ShouldShowDestinationInCurrentView(Index));
        }
    }

    for (int32 Index = 0; Index < RouteMarkerActors.Num(); ++Index)
    {
        if (RouteMarkerActors[Index])
        {
            const int32 OwnerIndex = RouteMarkerOwnerIndices.IsValidIndex(Index) ? RouteMarkerOwnerIndices[Index] : INDEX_NONE;
            RouteMarkerActors[Index]->SetActorHiddenInGame(OwnerIndex != INDEX_NONE && !ShouldShowDestinationInCurrentView(OwnerIndex));
        }
    }

    RefreshPlayerPresentation();
}

void AAstroAdventureGameModeBase::RefreshPlayerPresentation()
{
    if (!PlayerPawn)
    {
        return;
    }

    EAstroCameraPresentationProfile Profile = EAstroCameraPresentationProfile::Mission;
    if (CurrentScreen == EAstroMissionScreen::AtlasView || CurrentScreen == EAstroMissionScreen::Passport || CurrentScreen == EAstroMissionScreen::MissionComplete)
    {
        Profile = EAstroCameraPresentationProfile::Atlas;
    }
    else if (CurrentScreen == EAstroMissionScreen::DeepDive || CurrentScreen == EAstroMissionScreen::Quiz || CurrentScreen == EAstroMissionScreen::QuizFeedback || CurrentScreen == EAstroMissionScreen::StampAward || CurrentScreen == EAstroMissionScreen::PauseMenu)
    {
        Profile = EAstroCameraPresentationProfile::Stable;
    }
    else if (IsScanEffectActive() || CurrentScreen == EAstroMissionScreen::DiscoveryCard)
    {
        Profile = EAstroCameraPresentationProfile::Scan;
    }

    PlayerPawn->SetCameraPresentationProfile(Profile);
    PlayerPawn->SetScannerActive(IsScanEffectActive());

    if (const FAstroDestinationLesson* Lesson = GetFocusedLesson())
    {
        PlayerPawn->SetShipAccentColor(Lesson->DisplayColor.GetClamped(0.0f, 1.0f));
    }
}

bool AAstroAdventureGameModeBase::ShouldShowDestinationInCurrentView(const int32 DestinationIndex) const
{
    if (!DestinationActors.IsValidIndex(DestinationIndex))
    {
        return false;
    }

    if (CurrentScreen == EAstroMissionScreen::AtlasView || CurrentScreen == EAstroMissionScreen::Passport || CurrentScreen == EAstroMissionScreen::MissionComplete)
    {
        return true;
    }

    if (CurrentScreen == EAstroMissionScreen::Home || CurrentScreen == EAstroMissionScreen::AgeSelect || CurrentScreen == EAstroMissionScreen::MissionPrompt)
    {
        const int32 Count = FMath::Max(1, DestinationActors.Num());
        return DestinationIndex == FocusedDestinationIndex || DestinationIndex == (FocusedDestinationIndex + 1) % Count;
    }

    if (!IsMissionPlayScreen() && CurrentScreen != EAstroMissionScreen::PauseMenu)
    {
        return true;
    }

    const int32 Count = DestinationActors.Num();
    if (Count <= 0)
    {
        return false;
    }

    return DestinationIndex == FocusedDestinationIndex || DestinationIndex == FocusedDestinationIndex + 1;
}

void AAstroAdventureGameModeBase::MarkScanned(const FName DestinationId)
{
    FAstroDestinationProgress& Progress = GetMutableProgress(DestinationId);
    Progress.bScanned = true;
    SaveProgress();
}

bool AAstroAdventureGameModeBase::HasStampForDestination(const FName DestinationId) const
{
    const FAstroDestinationProgress* Progress = ProgressSave ? ProgressSave->DestinationProgress.Find(DestinationId) : nullptr;
    return Progress && Progress->bQuizCompleted;
}

void AAstroAdventureGameModeBase::TriggerScanFeedback(const FAstroDestinationLesson& Lesson)
{
    LastScanTime = GetWorld() ? GetWorld()->GetTimeSeconds() : 0.0f;

    AAstroDestinationActor* FocusActor = nullptr;
    for (AAstroDestinationActor* DestinationActor : DestinationActors)
    {
        if (DestinationActor && DestinationActor->DestinationId == Lesson.DestinationId)
        {
            FocusActor = DestinationActor;
            break;
        }
    }

    if (FocusActor)
    {
        FocusActor->SetFocused(true);
    }

    if (PlayerPawn)
    {
        if (FocusActor)
        {
            const FVector FocusLocation = FocusActor->GetActorLocation();
            PlayerPawn->SetTravelTarget(FocusLocation + FVector(-145.0f, 0.0f, 70.0f));
            PlayerPawn->SetCameraFocusTarget(FocusLocation + FVector(0.0f, 0.0f, 45.0f));
        }
        PlayerPawn->SetCameraPresentationProfile(EAstroCameraPresentationProfile::Scan);
        PlayerPawn->SetScannerActive(true);
        PlayerPawn->SetShipAccentColor(Lesson.DisplayColor.GetClamped(0.0f, 1.0f));
        PlayerPawn->TriggerScannerPulse(1.0f);
    }
}

void AAstroAdventureGameModeBase::TriggerStampFeedback(const FAstroDestinationLesson& Lesson)
{
    LastStampTime = GetWorld() ? GetWorld()->GetTimeSeconds() : 0.0f;

    AAstroDestinationActor* FocusActor = nullptr;
    for (AAstroDestinationActor* DestinationActor : DestinationActors)
    {
        if (DestinationActor && DestinationActor->DestinationId == Lesson.DestinationId)
        {
            FocusActor = DestinationActor;
            break;
        }
    }

    if (FocusActor)
    {
        FocusActor->SetFocused(true);
        FocusActor->SetDiscovered(true);
    }

    if (PlayerPawn)
    {
        if (FocusActor)
        {
            PlayerPawn->SetCameraFocusTarget(FocusActor->GetActorLocation() + FVector(0.0f, 0.0f, 45.0f));
        }
        PlayerPawn->SetShipAccentColor(Lesson.DisplayColor.GetClamped(0.0f, 1.0f));
        PlayerPawn->TriggerScannerPulse(1.0f);
    }
}

void AAstroAdventureGameModeBase::CompleteQuiz(const FName DestinationId, const bool bAnsweredCorrectly)
{
    FAstroDestinationProgress& Progress = GetMutableProgress(DestinationId);
    const bool bWasQuizCompleted = Progress.bQuizCompleted;
    Progress.bQuizCompleted = Progress.bQuizCompleted || bAnsweredCorrectly;
    Progress.CorrectAnswers += (bAnsweredCorrectly && !bWasQuizCompleted) ? 1 : 0;
    Progress.MasteryScore = FMath::Clamp(Progress.MasteryScore + UAstroLearningLibrary::MasteryDelta(bAnsweredCorrectly, Progress.Attempts), 0, 100);
    Progress.ReviewBox = UAstroLearningLibrary::NextReviewBox(Progress.ReviewBox, bAnsweredCorrectly);
    Progress.NextReviewAtUtc = FDateTime::UtcNow() + FTimespan::FromDays(UAstroLearningLibrary::ReviewDelayDaysForBox(Progress.ReviewBox));
    SaveProgress();
}

void AAstroAdventureGameModeBase::SelectAgeBand(const int32 Index)
{
    ActiveAgeBand = Index == 0 ? EAstroAgeBand::Ages4To6 : Index == 1 ? EAstroAgeBand::Ages7To9 : EAstroAgeBand::Ages10To12;
    if (ProgressSave)
    {
        ProgressSave->AgeBand = ActiveAgeBand;
    }
    SaveProgress();
}

void AAstroAdventureGameModeBase::ExecutePauseSelection()
{
    if (PauseMenuIndex == 0)
    {
        CurrentScreen = PreviousScreen;
    }
    else if (PauseMenuIndex == 1)
    {
        ClearPassportProgress();
        FocusedDestinationIndex = 0;
        CurrentScreen = EAstroMissionScreen::MissionPrompt;
        UpdateDestinationFocus();
    }
    else if (PauseMenuIndex == 2)
    {
        CurrentScreen = EAstroMissionScreen::AgeSelect;
    }
    else
    {
        UKismetSystemLibrary::QuitGame(this, UGameplayStatics::GetPlayerController(GetWorld(), 0), EQuitPreference::Quit, false);
    }
}

void AAstroAdventureGameModeBase::ExecuteHomeSelection()
{
    if (HomeMenuIndex == 0)
    {
        ClearPassportProgress();
        FocusedDestinationIndex = 0;
        LastFeedback.Empty();
        CurrentScreen = EAstroMissionScreen::AgeSelect;
        UpdateDestinationFocus();
    }
    else if (HomeMenuIndex == 1)
    {
        if (HasAnyProgress())
        {
            if (IsMissionComplete())
            {
                MissionCompleteMenuIndex = 0;
                CurrentScreen = EAstroMissionScreen::MissionComplete;
                return;
            }

            for (int32 Index = 0; Index < Lessons.Num(); ++Index)
            {
                const FAstroDestinationProgress* Progress = ProgressSave ? ProgressSave->DestinationProgress.Find(Lessons[Index].DestinationId) : nullptr;
                if (!Progress || !Progress->bQuizCompleted)
                {
                    FocusedDestinationIndex = Index;
                    break;
                }
            }
            LastFeedback.Empty();
            CurrentScreen = EAstroMissionScreen::MissionPrompt;
            UpdateDestinationFocus();
        }
        else
        {
            LastFeedback = TEXT("Start a new expedition first.");
        }
    }
    else if (HomeMenuIndex == 2)
    {
        ClearPassportProgress();
        FocusedDestinationIndex = 0;
        LastFeedback = TEXT("Passport reset. Ready for a fresh launch.");
        UpdateDestinationFocus();
    }
    else
    {
        UKismetSystemLibrary::QuitGame(this, UGameplayStatics::GetPlayerController(GetWorld(), 0), EQuitPreference::Quit, false);
    }
}

void AAstroAdventureGameModeBase::ExecuteMissionCompleteSelection()
{
    if (MissionCompleteMenuIndex == 0)
    {
        ClearPassportProgress();
        FocusedDestinationIndex = 0;
        CurrentScreen = EAstroMissionScreen::MissionPrompt;
        UpdateDestinationFocus();
    }
    else if (MissionCompleteMenuIndex == 1)
    {
        PreviousScreen = EAstroMissionScreen::MissionComplete;
        CurrentScreen = EAstroMissionScreen::AtlasView;
    }
    else if (MissionCompleteMenuIndex == 2)
    {
        CurrentScreen = EAstroMissionScreen::AgeSelect;
    }
    else
    {
        UKismetSystemLibrary::QuitGame(this, UGameplayStatics::GetPlayerController(GetWorld(), 0), EQuitPreference::Quit, false);
    }
}

void AAstroAdventureGameModeBase::ClearPassportProgress()
{
    if (ProgressSave)
    {
        ProgressSave->DestinationProgress.Reset();
        for (const FAstroDestinationLesson& Lesson : Lessons)
        {
            GetMutableProgress(Lesson.DestinationId);
        }
    }
    bShowingHint = false;
    bLastAnswerCorrect = false;
    LastScanTime = -100.0f;
    LastStampTime = -100.0f;
    SaveProgress();
}

bool AAstroAdventureGameModeBase::HasAnyProgress() const
{
    if (!ProgressSave)
    {
        return false;
    }

    for (const TPair<FName, FAstroDestinationProgress>& Entry : ProgressSave->DestinationProgress)
    {
        if (Entry.Value.bScanned || Entry.Value.bQuizCompleted || Entry.Value.Attempts > 0)
        {
            return true;
        }
    }

    return false;
}

bool AAstroAdventureGameModeBase::IsMissionPlayScreen() const
{
    return CurrentScreen == EAstroMissionScreen::Navigation || CurrentScreen == EAstroMissionScreen::DiscoveryCard || CurrentScreen == EAstroMissionScreen::DeepDive || CurrentScreen == EAstroMissionScreen::Quiz || CurrentScreen == EAstroMissionScreen::QuizFeedback || CurrentScreen == EAstroMissionScreen::StampAward;
}

int32 AAstroAdventureGameModeBase::CountCompletedStops() const
{
    return ProgressSave ? Algo::CountIf(Lessons, [this](const FAstroDestinationLesson& Lesson)
    {
        const FAstroDestinationProgress* Progress = ProgressSave->DestinationProgress.Find(Lesson.DestinationId);
        return Progress && Progress->bQuizCompleted;
    }) : 0;
}

bool AAstroAdventureGameModeBase::IsScanEffectActive() const
{
    return GetWorld() && GetWorld()->GetTimeSeconds() - LastScanTime < 2.75f;
}

bool AAstroAdventureGameModeBase::IsStampEffectActive() const
{
    return GetWorld() && GetWorld()->GetTimeSeconds() - LastStampTime < 1.8f;
}

bool AAstroAdventureGameModeBase::IsMissionComplete() const
{
    if (!ProgressSave)
    {
        return false;
    }

    for (const FAstroDestinationLesson& Lesson : Lessons)
    {
        if (!Lesson.bRequiredForMission)
        {
            continue;
        }

        const FAstroDestinationProgress* Progress = ProgressSave->DestinationProgress.Find(Lesson.DestinationId);
        if (!Progress || !Progress->bQuizCompleted)
        {
            return false;
        }
    }

    return true;
}

bool AAstroAdventureGameModeBase::AdvanceToNextRouteStop()
{
    if (Lessons.IsEmpty())
    {
        return false;
    }

    const int32 StartIndex = FocusedDestinationIndex;
    for (int32 Step = 1; Step <= Lessons.Num(); ++Step)
    {
        const int32 CandidateIndex = (StartIndex + Step) % Lessons.Num();
        const FAstroDestinationLesson& Candidate = Lessons[CandidateIndex];
        const FAstroDestinationProgress* Progress = ProgressSave ? ProgressSave->DestinationProgress.Find(Candidate.DestinationId) : nullptr;
        if (!Progress || !Progress->bQuizCompleted)
        {
            FocusedDestinationIndex = CandidateIndex;
            LastFeedback = FString::Printf(TEXT("Next stop: %s. Use Right/D or arrows to travel."), *Candidate.DisplayName.ToString());
            CurrentScreen = EAstroMissionScreen::Navigation;
            bShowingHint = false;
            UpdateDestinationFocus();
            return true;
        }
    }

    return false;
}

const FAstroDestinationLesson* AAstroAdventureGameModeBase::GetFocusedLesson() const
{
    return Lessons.IsValidIndex(FocusedDestinationIndex) ? &Lessons[FocusedDestinationIndex] : nullptr;
}

FAstroDestinationProgress& AAstroAdventureGameModeBase::GetMutableProgress(const FName DestinationId)
{
    check(ProgressSave);
    return ProgressSave->DestinationProgress.FindOrAdd(DestinationId);
}
