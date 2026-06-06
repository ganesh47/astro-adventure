#include "AstroDestinationActor.h"

#include "Components/BillboardComponent.h"
#include "Components/StaticMeshComponent.h"
#include "Components/TextRenderComponent.h"
#include "Engine/StaticMesh.h"
#include "Engine/Texture2D.h"
#include "Materials/MaterialInstanceDynamic.h"
#include "Materials/MaterialInterface.h"
#include "UObject/ConstructorHelpers.h"

namespace
{
constexpr int32 DestinationMotifCount = 18;
constexpr float DestinationPresentationScaleFloor = 0.58f;
constexpr float DestinationFocusedScaleMultiplier = 1.12f;
constexpr float FocusedLabelWorldSize = 38.0f;
constexpr float DiscoveredLabelWorldSize = 30.0f;
constexpr float IdleLabelWorldSize = 24.0f;
const TCHAR* OwnedMaterialRoot = TEXT("/Game/Art/AstroAdventureOwned/MaterialInstances/");

FLinearColor BlendColor(const FLinearColor& From, const FLinearColor& To, const float Alpha)
{
    return FLinearColor(
        FMath::Lerp(From.R, To.R, Alpha),
        FMath::Lerp(From.G, To.G, Alpha),
        FMath::Lerp(From.B, To.B, Alpha),
        FMath::Lerp(From.A, To.A, Alpha));
}

FLinearColor WithAlpha(const FLinearColor& Color, const float Alpha)
{
    return FLinearColor(Color.R, Color.G, Color.B, Alpha);
}

FLinearColor ReadableDestinationColor(const FString& Id, const FLinearColor& Color)
{
    if (Id == TEXT("sun"))
    {
        return FLinearColor(1.0f, 0.74f, 0.22f, 1.0f);
    }
    if (Id == TEXT("mercury"))
    {
        return FLinearColor(0.7f, 0.67f, 0.58f, 1.0f);
    }
    if (Id == TEXT("venus"))
    {
        return FLinearColor(0.98f, 0.68f, 0.28f, 1.0f);
    }
    if (Id == TEXT("earth"))
    {
        return FLinearColor(0.1f, 0.48f, 0.94f, 1.0f);
    }
    if (Id == TEXT("moon"))
    {
        return FLinearColor(0.66f, 0.72f, 0.78f, 1.0f);
    }
    if (Id == TEXT("mars"))
    {
        return FLinearColor(0.95f, 0.28f, 0.12f, 1.0f);
    }
    if (Id == TEXT("jupiter"))
    {
        return FLinearColor(0.93f, 0.62f, 0.34f, 1.0f);
    }
    if (Id == TEXT("saturn"))
    {
        return FLinearColor(0.94f, 0.74f, 0.36f, 1.0f);
    }
    if (Id == TEXT("uranus"))
    {
        return FLinearColor(0.42f, 0.92f, 0.98f, 1.0f);
    }
    if (Id == TEXT("neptune"))
    {
        return FLinearColor(0.15f, 0.36f, 1.0f, 1.0f);
    }
    if (Id == TEXT("pluto"))
    {
        return FLinearColor(0.8f, 0.68f, 0.56f, 1.0f);
    }
    if (Id == TEXT("europa"))
    {
        return FLinearColor(0.82f, 0.95f, 1.0f, 1.0f);
    }
    if (Id == TEXT("asteroid_belt"))
    {
        return FLinearColor(0.56f, 0.51f, 0.45f, 1.0f);
    }

    return WithAlpha(BlendColor(Color, FLinearColor::White, 0.18f), 1.0f);
}

float DestinationBodyEmissiveStrength(const FString& Id)
{
    if (Id == TEXT("sun"))
    {
        return 0.32f;
    }
    if (Id == TEXT("neptune") || Id == TEXT("uranus") || Id == TEXT("earth") || Id == TEXT("europa"))
    {
        return 0.26f;
    }
    if (Id == TEXT("venus") || Id == TEXT("mars") || Id == TEXT("jupiter") || Id == TEXT("saturn"))
    {
        return 0.24f;
    }
    if (Id == TEXT("mercury") || Id == TEXT("moon") || Id == TEXT("pluto") || Id == TEXT("asteroid_belt"))
    {
        return 0.12f;
    }

    return 0.18f;
}

FLinearColor DestinationFocusHaloColor(const FString& Id, const FLinearColor& BaseColor)
{
    if (Id == TEXT("sun"))
    {
        return FLinearColor(1.0f, 0.72f, 0.22f, 0.20f);
    }
    if (Id == TEXT("mercury"))
    {
        return FLinearColor(1.0f, 0.64f, 0.24f, 0.22f);
    }

    return WithAlpha(BlendColor(BaseColor, FLinearColor(1.0f, 0.92f, 0.28f, 1.0f), 0.4f), 0.4f);
}

float DestinationFocusHaloEmissiveStrength(const FString& Id)
{
    if (Id == TEXT("sun"))
    {
        return 0.24f;
    }
    if (Id == TEXT("mercury"))
    {
        return 0.18f;
    }

    return 0.24f;
}

FAstroDestinationVisualProfile MakeVisualProfile(const FString& Id, const FLinearColor& Color, const float VisualScale)
{
    FAstroDestinationVisualProfile Profile;
    Profile.BasePalette = ReadableDestinationColor(Id, Color);
    Profile.MissionScale = FMath::Max(VisualScale, DestinationPresentationScaleFloor);
    Profile.AtlasScale = Profile.MissionScale * 0.82f;
    Profile.FocusRingMaterial = FString(OwnedMaterialRoot) + TEXT("MI_Focus_Ring.MI_Focus_Ring");
    Profile.StampTexture = TEXT("/Game/Art/AstroAdventureOwned/Textures/UI/T_Stamp_Generic");
    Profile.LabelPlacement = FVector(0.0f, 0.0f, 82.0f + 28.0f * Profile.MissionScale);
    Profile.SurfaceMotif = FText::FromString(TEXT("stylized surface detail"));
    Profile.SilhouetteCue = FText::FromString(TEXT("round world"));
    Profile.ObservationCue = FText::FromString(TEXT("Look for its color and shape."));

    if (Id == TEXT("sun"))
    {
        // The generated Sun material assets currently cook but render too dark in
        // packaged play. The child-facing slice applies a proven emissive body in
        // code until the authored material graph is rebuilt.
        Profile.BodyMaterial.Empty();
        Profile.CoronaOrAtmosphereMaterial = FString(OwnedMaterialRoot) + TEXT("MI_Sun_Corona.MI_Sun_Corona");
        Profile.StampTexture = TEXT("/Game/Art/AstroAdventureOwned/Textures/UI/T_Stamp_Sun");
        Profile.SurfaceMotif = FText::FromString(TEXT("warm mottled star surface"));
        Profile.SilhouetteCue = FText::FromString(TEXT("soft corona and safe-distance ring"));
        Profile.ObservationCue = FText::FromString(TEXT("A star glows because it makes its own light."));
    }
    else if (Id == TEXT("mercury") || Id == TEXT("moon"))
    {
        Profile.BodyMaterial = FString(OwnedMaterialRoot) + TEXT("MI_Mercury_Surface.MI_Mercury_Surface");
        Profile.StampTexture = Id == TEXT("mercury") ? TEXT("/Game/Art/AstroAdventureOwned/Textures/UI/T_Stamp_Mercury") : Profile.StampTexture;
        Profile.SurfaceMotif = FText::FromString(TEXT("large dark crater pattern"));
        Profile.SilhouetteCue = FText::FromString(TEXT("rocky gray cratered body"));
        Profile.ObservationCue = FText::FromString(TEXT("Craters are clues from impacts."));
    }
    else if (Id == TEXT("venus"))
    {
        Profile.BodyMaterial = FString(OwnedMaterialRoot) + TEXT("MI_Venus_Surface.MI_Venus_Surface");
        Profile.SurfaceMotif = FText::FromString(TEXT("golden cloud bands"));
        Profile.SilhouetteCue = FText::FromString(TEXT("hazy warm atmosphere"));
        Profile.ObservationCue = FText::FromString(TEXT("Thick clouds hide Venus's rocky surface."));
    }
    else if (Id == TEXT("europa"))
    {
        Profile.BodyMaterial = FString(OwnedMaterialRoot) + TEXT("MI_Europa_Surface.MI_Europa_Surface");
        Profile.SurfaceMotif = FText::FromString(TEXT("blue icy cracks"));
        Profile.SilhouetteCue = FText::FromString(TEXT("small cracked ice moon"));
        Profile.ObservationCue = FText::FromString(TEXT("Cracks hint that Europa has an icy shell."));
    }
    else if (Id == TEXT("saturn"))
    {
        Profile.BodyMaterial = FString(OwnedMaterialRoot) + TEXT("MI_Saturn_Surface.MI_Saturn_Surface");
        Profile.SurfaceMotif = FText::FromString(TEXT("pale bands and wide rings"));
        Profile.SilhouetteCue = FText::FromString(TEXT("giant planet with rings"));
        Profile.ObservationCue = FText::FromString(TEXT("Saturn is easy to spot by its rings."));
    }
    else if (Id == TEXT("uranus"))
    {
        Profile.BodyMaterial = FString(OwnedMaterialRoot) + TEXT("MI_Uranus_Surface.MI_Uranus_Surface");
        Profile.SurfaceMotif = FText::FromString(TEXT("pale cyan tilted ice giant"));
        Profile.SilhouetteCue = FText::FromString(TEXT("tilted cyan ring cue"));
        Profile.ObservationCue = FText::FromString(TEXT("Uranus rolls around the Sun on its side."));
    }
    else if (Id == TEXT("neptune"))
    {
        Profile.BodyMaterial = FString(OwnedMaterialRoot) + TEXT("MI_Neptune_Surface.MI_Neptune_Surface");
        Profile.SurfaceMotif = FText::FromString(TEXT("deep blue storm streaks"));
        Profile.SilhouetteCue = FText::FromString(TEXT("deep blue ice giant"));
        Profile.ObservationCue = FText::FromString(TEXT("Neptune is a far, windy ice giant."));
    }

    return Profile;
}
}

AAstroDestinationActor::AAstroDestinationActor()
{
    PrimaryActorTick.bCanEverTick = false;

    Root = CreateDefaultSubobject<USceneComponent>(TEXT("Root"));
    SetRootComponent(Root);

    BodyMesh = CreateDefaultSubobject<UStaticMeshComponent>(TEXT("BodyMesh"));
    BodyMesh->SetupAttachment(Root);
    BodyMesh->SetMobility(EComponentMobility::Movable);

    SurfaceArt = CreateDefaultSubobject<UStaticMeshComponent>(TEXT("SurfaceArt"));
    SurfaceArt->SetupAttachment(Root);
    SurfaceArt->SetMobility(EComponentMobility::Movable);
    SurfaceArt->SetVisibility(false);
    SurfaceArt->SetCollisionEnabled(ECollisionEnabled::NoCollision);
    SurfaceArt->SetCastShadow(false);

    AtmosphereArt = CreateDefaultSubobject<UStaticMeshComponent>(TEXT("AtmosphereArt"));
    AtmosphereArt->SetupAttachment(Root);
    AtmosphereArt->SetMobility(EComponentMobility::Movable);
    AtmosphereArt->SetVisibility(false);
    AtmosphereArt->SetCollisionEnabled(ECollisionEnabled::NoCollision);
    AtmosphereArt->SetCastShadow(false);

    BillboardArt = CreateDefaultSubobject<UBillboardComponent>(TEXT("BillboardArt"));
    BillboardArt->SetupAttachment(Root);
    BillboardArt->SetMobility(EComponentMobility::Movable);
    BillboardArt->SetVisibility(false);
    BillboardArt->SetHiddenInGame(true);
    BillboardArt->SetCollisionEnabled(ECollisionEnabled::NoCollision);
    BillboardArt->SetCastShadow(false);
    BillboardArt->bIsScreenSizeScaled = false;

    static ConstructorHelpers::FObjectFinder<UStaticMesh> SphereMesh(TEXT("/Engine/BasicShapes/Sphere.Sphere"));
    if (SphereMesh.Succeeded())
    {
        SphereMeshAsset = SphereMesh.Object;
        BodyMesh->SetStaticMesh(SphereMesh.Object);
    }

    FocusHalo = CreateDefaultSubobject<UStaticMeshComponent>(TEXT("FocusHalo"));
    FocusHalo->SetupAttachment(Root);
    FocusHalo->SetMobility(EComponentMobility::Movable);
    FocusHalo->SetVisibility(false);
    FocusHalo->SetCollisionEnabled(ECollisionEnabled::NoCollision);
    FocusHalo->SetCastShadow(false);
    if (SphereMesh.Succeeded())
    {
        FocusHalo->SetStaticMesh(SphereMesh.Object);
    }

    FocusBeacon = CreateDefaultSubobject<UStaticMeshComponent>(TEXT("FocusBeacon"));
    FocusBeacon->SetupAttachment(Root);
    FocusBeacon->SetMobility(EComponentMobility::Movable);
    FocusBeacon->SetVisibility(false);
    FocusBeacon->SetCollisionEnabled(ECollisionEnabled::NoCollision);
    FocusBeacon->SetCastShadow(false);

    static ConstructorHelpers::FObjectFinder<UStaticMesh> CylinderMesh(TEXT("/Engine/BasicShapes/Cylinder.Cylinder"));
    if (CylinderMesh.Succeeded())
    {
        CylinderMeshAsset = CylinderMesh.Object;
        FocusBeacon->SetStaticMesh(CylinderMesh.Object);
        SurfaceArt->SetStaticMesh(CylinderMesh.Object);
        AtmosphereArt->SetStaticMesh(CylinderMesh.Object);
        FocusHalo->SetStaticMesh(CylinderMesh.Object);
    }

    Nameplate = CreateDefaultSubobject<UStaticMeshComponent>(TEXT("Nameplate"));
    Nameplate->SetupAttachment(Root);
    Nameplate->SetMobility(EComponentMobility::Movable);
    Nameplate->SetVisibility(false);
    Nameplate->SetCollisionEnabled(ECollisionEnabled::NoCollision);
    Nameplate->SetCastShadow(false);

    static ConstructorHelpers::FObjectFinder<UStaticMesh> CubeMesh(TEXT("/Engine/BasicShapes/Cube.Cube"));
    if (CubeMesh.Succeeded())
    {
        CubeMeshAsset = CubeMesh.Object;
        Nameplate->SetStaticMesh(CubeMesh.Object);
    }

    static ConstructorHelpers::FObjectFinder<UMaterialInterface> BasicShapeMaterial(TEXT("/Engine/BasicShapes/BasicShapeMaterial.BasicShapeMaterial"));
    static ConstructorHelpers::FObjectFinder<UMaterialInterface> EmissiveShapeMaterial(TEXT("/Engine/EngineMaterials/EmissiveMeshMaterial.EmissiveMeshMaterial"));
    if (BasicShapeMaterial.Succeeded())
    {
        ColorMaterialTemplate = BasicShapeMaterial.Object;
    }
    else if (EmissiveShapeMaterial.Succeeded())
    {
        ColorMaterialTemplate = EmissiveShapeMaterial.Object;
    }

    for (int32 Index = 0; Index < DestinationMotifCount; ++Index)
    {
        const FName ComponentName(*FString::Printf(TEXT("DestinationMotif%d"), Index));
        MotifMeshes.Add(CreateMotifComponent(ComponentName, CubeMeshAsset));
    }

    Label = CreateDefaultSubobject<UTextRenderComponent>(TEXT("Label"));
    Label->SetupAttachment(Root);
    Label->SetHorizontalAlignment(EHTA_Center);
    Label->SetTextRenderColor(FColor(172, 213, 255));
    Label->SetWorldSize(30.0f);
    Label->SetRelativeLocation(FVector(0.0f, 0.0f, 108.0f));
    Label->SetRelativeRotation(FRotator(0.0f, 180.0f, 0.0f));
    Label->SetCastShadow(false);
}

UStaticMeshComponent* AAstroDestinationActor::CreateMotifComponent(const FName ComponentName, UStaticMesh* Mesh)
{
    UStaticMeshComponent* Motif = CreateDefaultSubobject<UStaticMeshComponent>(ComponentName);
    Motif->SetupAttachment(Root);
    Motif->SetMobility(EComponentMobility::Movable);
    Motif->SetVisibility(false);
    Motif->SetCollisionEnabled(ECollisionEnabled::NoCollision);
    Motif->SetCastShadow(false);
    if (Mesh)
    {
        Motif->SetStaticMesh(Mesh);
    }
    return Motif;
}

void AAstroDestinationActor::Configure(const FAstroDestinationLesson& Lesson, const FLinearColor& Color, const float VisualScale)
{
    DestinationId = Lesson.DestinationId;
    DisplayName = Lesson.DisplayName;
    const FString DestinationKey = DestinationId.ToString().ToLower();
    ApplyVisualProfile(MakeVisualProfile(DestinationKey, Color, VisualScale));
    const uint32 ShapeHash = GetTypeHash(DestinationId);
    const float WidthCue = 0.94f + 0.04f * static_cast<float>(ShapeHash % 4);
    const float DepthCue = 0.94f + 0.035f * static_cast<float>((ShapeHash / 4) % 4);
    const float HeightCue = 0.9f + 0.035f * static_cast<float>((ShapeHash / 16) % 5);
    BodyIdleScale = FVector(WidthCue, DepthCue, HeightCue);
    BodyFocusedScale = BodyIdleScale + FVector(0.04f, 0.04f, 0.12f);
    if (DestinationKey == TEXT("sun"))
    {
        BodyIdleScale = FVector(1.0f);
        BodyFocusedScale = FVector(1.04f);
    }
#if WITH_EDITOR
    SetActorLabel(DisplayName.ToString());
#endif
    Label->SetText(DisplayName);
    Label->SetRelativeLocation(CurrentVisualProfile.LabelPlacement);
    Nameplate->SetRelativeLocation(FVector(-5.0f, 0.0f, 76.0f + 28.0f * BaseVisualScale));
    Nameplate->SetRelativeRotation(Label->GetRelativeRotation());
    UpdateNameplateLayout();
    FocusBeacon->SetRelativeLocation(FVector(0.0f, 0.0f, 116.0f + 70.0f * BaseVisualScale));
    FocusBeacon->SetRelativeScale3D(FVector(0.08f, 0.08f, 1.55f + 0.35f * BaseVisualScale));

    ApplyColor(BodyMesh, BaseColor, DestinationBodyEmissiveStrength(DestinationKey));
    ApplyColor(FocusHalo, DestinationFocusHaloColor(DestinationKey, BaseColor), DestinationFocusHaloEmissiveStrength(DestinationKey));
    ApplyColor(FocusBeacon, FLinearColor(0.42f, 0.9f, 1.0f, 0.46f), 0.86f);
    ApplyColor(Nameplate, FLinearColor(0.92f, 0.68f, 0.30f, 0.72f), 0.04f);
    ApplyProfileArt();
    ConfigureMotifs();
    SetActorScale3D(FVector(BaseVisualScale));
    ApplyFocusVisuals();
}

void AAstroDestinationActor::ApplyVisualProfile(const FAstroDestinationVisualProfile& VisualProfile)
{
    CurrentVisualProfile = VisualProfile;
    BaseColor = CurrentVisualProfile.BasePalette.GetClamped(0.0f, 1.0f);
    BaseVisualScale = FMath::Max(CurrentVisualProfile.MissionScale, DestinationPresentationScaleFloor);
    BodyMaterialAsset = LoadProfileMaterial(CurrentVisualProfile.BodyMaterial);
    AtmosphereMaterialAsset = LoadProfileMaterial(CurrentVisualProfile.CoronaOrAtmosphereMaterial);
    FocusRingMaterialAsset = LoadProfileMaterial(CurrentVisualProfile.FocusRingMaterial);
}

void AAstroDestinationActor::ApplyColor(UStaticMeshComponent* Mesh, const FLinearColor& Color, const float EmissiveStrength)
{
    if (Mesh)
    {
        UMaterialInstanceDynamic* Material = Mesh->CreateDynamicMaterialInstance(0, ColorMaterialTemplate);
        if (!Material)
        {
            Material = Mesh->CreateAndSetMaterialInstanceDynamic(0);
        }
        if (Material)
        {
            Material->SetVectorParameterValue(TEXT("Color"), Color);
            Material->SetVectorParameterValue(TEXT("BaseColor"), Color);
            Material->SetVectorParameterValue(TEXT("Base Color"), Color);
            Material->SetVectorParameterValue(TEXT("ShapeColor"), Color);
            Material->SetVectorParameterValue(TEXT("Tint"), Color);
            Material->SetVectorParameterValue(TEXT("DiffuseColor"), Color);
            Material->SetVectorParameterValue(TEXT("EmissiveColor"), Color * EmissiveStrength);
            Material->SetVectorParameterValue(TEXT("Emissive Color"), Color * EmissiveStrength);
            Material->SetVectorParameterValue(TEXT("Emissive"), Color * EmissiveStrength);
            Material->SetScalarParameterValue(TEXT("EmissiveStrength"), EmissiveStrength);
            Material->SetScalarParameterValue(TEXT("Emissive Strength"), EmissiveStrength);
            Material->SetScalarParameterValue(TEXT("EmissiveIntensity"), EmissiveStrength);
            Material->SetScalarParameterValue(TEXT("Glow"), EmissiveStrength);
            Material->SetScalarParameterValue(TEXT("Opacity"), Color.A);
            Material->SetScalarParameterValue(TEXT("Alpha"), Color.A);
            Material->SetScalarParameterValue(TEXT("Roughness"), 0.72f);
        }
    }
}

UMaterialInterface* AAstroDestinationActor::LoadProfileMaterial(const FString& ProfileMaterialPath) const
{
    if (ProfileMaterialPath.IsEmpty())
    {
        return nullptr;
    }
    return LoadObject<UMaterialInterface>(nullptr, *ProfileMaterialPath);
}

void AAstroDestinationActor::ApplyProfileArt()
{
    const FString Id = DestinationId.ToString().ToLower();
    const bool bHasBodyArt = BodyMaterialAsset != nullptr;
    const bool bIsSun = Id == TEXT("sun");

    SurfaceArt->SetVisibility(false);
    BillboardArt->SetVisibility(false);
    BillboardArt->SetHiddenInGame(true);
    SurfaceArt->SetRelativeLocation(FVector(-58.0f, 0.0f, 0.0f));
    SurfaceArt->SetRelativeRotation(FRotator(0.0f, 90.0f, 0.0f));
    SurfaceArt->SetRelativeScale3D(FVector(1.34f, 1.34f, 0.006f));

    AtmosphereArt->SetVisibility(AtmosphereMaterialAsset != nullptr);
    AtmosphereArt->SetHiddenInGame(AtmosphereMaterialAsset == nullptr);
    AtmosphereArt->SetRelativeLocation(FVector(-63.0f, 0.0f, 0.0f));
    AtmosphereArt->SetRelativeRotation(FRotator(0.0f, 90.0f, 0.0f));
    AtmosphereArt->SetRelativeScale3D(FVector(bIsSun ? 1.18f : 1.24f, bIsSun ? 1.18f : 1.24f, 0.004f));
    if (AtmosphereMaterialAsset)
    {
        AtmosphereArt->SetMaterial(0, AtmosphereMaterialAsset);
    }

    FocusHalo->SetRelativeRotation(FRotator(0.0f, 90.0f, 0.0f));
    if (FocusRingMaterialAsset)
    {
        FocusHalo->SetMaterial(0, FocusRingMaterialAsset);
    }

    BodyMesh->SetVisibility(true);
    BodyMesh->SetRelativeLocation(FVector::ZeroVector);
    BodyMesh->SetCastShadow(false);
    if (bIsSun)
    {
        BodyMesh->SetVisibility(false);
        if (UTexture2D* SunSprite = LoadObject<UTexture2D>(nullptr, TEXT("/Game/Art/AstroAdventureOwned/Textures/Planets/T_Sun_Disk_ChildReadable.T_Sun_Disk_ChildReadable")))
        {
            BillboardArt->SetSprite(SunSprite);
            BillboardArt->SetRelativeLocation(FVector::ZeroVector);
            BillboardArt->SetRelativeScale3D(FVector(0.94f));
            BillboardArt->SetVisibility(true);
            BillboardArt->SetHiddenInGame(false);
        }
        SurfaceArt->SetVisibility(false);
        // A visible Sun body is better for first-play learning than the current
        // flat corona card, which reads as a second yellow planet in packaged play.
        AtmosphereArt->SetVisibility(false);
        AtmosphereArt->SetHiddenInGame(true);
        return;
    }

    if (BodyMaterialAsset)
    {
        BodyMesh->SetMaterial(0, BodyMaterialAsset);
    }
}

void AAstroDestinationActor::HideMotifs()
{
    for (UStaticMeshComponent* Motif : MotifMeshes)
    {
        if (Motif)
        {
            Motif->SetVisibility(false);
        }
    }
}

void AAstroDestinationActor::SetMotif(const int32 Index, UStaticMesh* Mesh, const FVector& Location, const FRotator& Rotation, const FVector& Scale, const FLinearColor& Color, const float EmissiveStrength)
{
    if (!MotifMeshes.IsValidIndex(Index) || !MotifMeshes[Index])
    {
        return;
    }

    UStaticMeshComponent* Motif = MotifMeshes[Index];
    if (Mesh)
    {
        Motif->SetStaticMesh(Mesh);
    }
    Motif->SetRelativeLocation(Location);
    Motif->SetRelativeRotation(Rotation);
    Motif->SetRelativeScale3D(Scale);
    Motif->SetVisibility(true);
    ApplyColor(Motif, Color, EmissiveStrength);
}

void AAstroDestinationActor::UpdateNameplateLayout()
{
    const int32 DisplayLength = FMath::Max(DisplayName.ToString().Len(), 5);
    const float PlateWidth = FMath::Clamp(1.12f + static_cast<float>(DisplayLength) * 0.07f, 1.48f, 2.7f);
    const float FocusWidthBoost = bIsFocused ? 1.08f : 1.0f;
    const float PlateHeight = bIsFocused ? 0.32f : 0.24f;
    const float PlateDepth = bIsFocused ? 0.035f : 0.03f;
    const float LabelScaleCompensation = 1.0f / FMath::Max(GetActorScale3D().GetAbsMax(), 0.1f);

    const bool bAtlasMode = PresentationMode == EAstroDestinationPresentationMode::Atlas;
    const bool bHomeMode = PresentationMode == EAstroDestinationPresentationMode::Home;
    const bool bFirstLoopTeachMode = PresentationMode == EAstroDestinationPresentationMode::FirstLoopTeach;
    Nameplate->SetVisibility(bIsFocused && !bAtlasMode && !bHomeMode);
    Label->SetVisibility(!bHomeMode || bFirstLoopTeachMode);
    Nameplate->SetRelativeScale3D(FVector(PlateDepth, PlateWidth * FocusWidthBoost, PlateHeight) * LabelScaleCompensation);

    Label->SetRelativeScale3D(FVector(LabelScaleCompensation));
    const float LabelSize = bIsFocused
        ? (bAtlasMode ? DiscoveredLabelWorldSize : FocusedLabelWorldSize)
        : (bAtlasMode ? IdleLabelWorldSize : (bIsDiscovered ? DiscoveredLabelWorldSize : IdleLabelWorldSize));
    Label->SetWorldSize(LabelSize);
    Label->SetTextRenderColor(bIsFocused ? FColor(255, 244, 118) : ((bAtlasMode || bHomeMode) ? FColor(142, 178, 215) : FColor(188, 224, 255)));
}

void AAstroDestinationActor::ConfigureMotifs()
{
    HideMotifs();

    const FString Id = DestinationId.ToString().ToLower();
    const FLinearColor White = FLinearColor::White;
    const FLinearColor Black = FLinearColor::Black;
    const FLinearColor Light = BlendColor(BaseColor, White, 0.42f);
    const FLinearColor Pale = BlendColor(BaseColor, White, 0.68f);
    const FLinearColor Dark = BlendColor(BaseColor, Black, 0.38f);
    const FLinearColor Deep = BlendColor(BaseColor, Black, 0.62f);
    constexpr float SurfaceX = -52.0f;

    if (Id == TEXT("sun"))
    {
        // The Sun's authored surface and corona carry the identity. Extra mesh rays read
        // as black/white wedge artifacts in the first-play camera, so keep this layer calm.
        return;
    }

    if (Id == TEXT("saturn"))
    {
        SetMotif(0, CylinderMeshAsset, FVector::ZeroVector, FRotator(0.0f, 90.0f, -13.0f), FVector(1.96f, 1.96f, 0.014f), FLinearColor(1.0f, 0.88f, 0.46f, 0.92f), 0.62f);
        SetMotif(1, CylinderMeshAsset, FVector::ZeroVector, FRotator(0.0f, 90.0f, -13.0f), FVector(1.48f, 1.48f, 0.016f), FLinearColor(0.7f, 0.52f, 0.28f, 0.86f), 0.32f);
        SetMotif(2, CubeMeshAsset, FVector(SurfaceX, 0.0f, 22.0f), FRotator::ZeroRotator, FVector(0.012f, 0.84f, 0.034f), Pale, 0.12f);
        SetMotif(3, CubeMeshAsset, FVector(SurfaceX, 0.0f, -7.0f), FRotator::ZeroRotator, FVector(0.012f, 0.9f, 0.03f), Dark, 0.06f);
        SetMotif(4, CubeMeshAsset, FVector(SurfaceX, 0.0f, -29.0f), FRotator::ZeroRotator, FVector(0.012f, 0.74f, 0.022f), Light, 0.09f);
        return;
    }

    if (Id == TEXT("jupiter"))
    {
        SetMotif(2, CubeMeshAsset, FVector(SurfaceX, 0.0f, 32.0f), FRotator::ZeroRotator, FVector(0.014f, 1.0f, 0.032f), Pale, 0.11f);
        SetMotif(3, CubeMeshAsset, FVector(SurfaceX, 0.0f, 12.0f), FRotator::ZeroRotator, FVector(0.014f, 1.02f, 0.038f), Deep, 0.06f);
        SetMotif(4, CubeMeshAsset, FVector(SurfaceX, 0.0f, -10.0f), FRotator::ZeroRotator, FVector(0.014f, 0.98f, 0.034f), Light, 0.08f);
        SetMotif(5, CubeMeshAsset, FVector(SurfaceX, 0.0f, -33.0f), FRotator::ZeroRotator, FVector(0.014f, 0.82f, 0.03f), Dark, 0.05f);
        SetMotif(15, SphereMeshAsset, FVector(SurfaceX - 3.0f, -24.0f, -11.0f), FRotator::ZeroRotator, FVector(0.032f, 0.26f, 0.15f), FLinearColor(0.92f, 0.16f, 0.08f, 1.0f), 0.32f);
        return;
    }

    if (Id == TEXT("uranus"))
    {
        SetMotif(0, CylinderMeshAsset, FVector::ZeroVector, FRotator(0.0f, 90.0f, 62.0f), FVector(1.22f, 1.22f, 0.008f), FLinearColor(0.82f, 1.0f, 0.98f, 0.68f), 0.18f);
        SetMotif(2, CubeMeshAsset, FVector(SurfaceX, 0.0f, 8.0f), FRotator(0.0f, 0.0f, 14.0f), FVector(0.01f, 0.74f, 0.018f), Pale, 0.08f);
        SetMotif(16, CubeMeshAsset, FVector(SurfaceX - 4.0f, 0.0f, 0.0f), FRotator(0.0f, 0.0f, 62.0f), FVector(0.012f, 0.96f, 0.016f), FLinearColor(0.9f, 1.0f, 1.0f, 0.9f), 0.12f);
        return;
    }

    if (Id == TEXT("neptune"))
    {
        SetMotif(2, CubeMeshAsset, FVector(SurfaceX, -4.0f, 22.0f), FRotator(0.0f, 0.0f, -10.0f), FVector(0.01f, 0.56f, 0.018f), Pale, 0.18f);
        SetMotif(3, CubeMeshAsset, FVector(SurfaceX, 8.0f, 0.0f), FRotator(0.0f, 0.0f, 8.0f), FVector(0.01f, 0.66f, 0.016f), Light, 0.14f);
        SetMotif(4, CubeMeshAsset, FVector(SurfaceX, -10.0f, -19.0f), FRotator(0.0f, 0.0f, -14.0f), FVector(0.01f, 0.52f, 0.014f), Pale, 0.14f);
        SetMotif(15, SphereMeshAsset, FVector(SurfaceX - 2.0f, 24.0f, -5.0f), FRotator::ZeroRotator, FVector(0.022f, 0.16f, 0.1f), Deep, 0.05f);
        return;
    }

    if (Id == TEXT("earth"))
    {
        SetMotif(2, SphereMeshAsset, FVector(SurfaceX - 2.0f, -19.0f, 15.0f), FRotator::ZeroRotator, FVector(0.022f, 0.28f, 0.22f), FLinearColor(0.08f, 0.68f, 0.26f, 1.0f), 0.12f);
        SetMotif(3, SphereMeshAsset, FVector(SurfaceX - 2.0f, 20.0f, -15.0f), FRotator::ZeroRotator, FVector(0.022f, 0.24f, 0.2f), FLinearColor(0.22f, 0.62f, 0.2f, 1.0f), 0.1f);
        SetMotif(4, CubeMeshAsset, FVector(SurfaceX - 3.0f, 0.0f, 25.0f), FRotator(0.0f, 0.0f, 9.0f), FVector(0.01f, 0.78f, 0.022f), FLinearColor(0.96f, 0.99f, 1.0f, 0.96f), 0.28f);
        SetMotif(5, CubeMeshAsset, FVector(SurfaceX - 3.0f, -4.0f, -7.0f), FRotator(0.0f, 0.0f, -8.0f), FVector(0.01f, 0.9f, 0.018f), FLinearColor(0.96f, 0.99f, 1.0f, 0.96f), 0.24f);
        return;
    }

    if (Id == TEXT("venus"))
    {
        SetMotif(2, CubeMeshAsset, FVector(SurfaceX, 0.0f, 26.0f), FRotator(0.0f, 0.0f, 11.0f), FVector(0.012f, 0.82f, 0.026f), Pale, 0.28f);
        SetMotif(3, CubeMeshAsset, FVector(SurfaceX, 0.0f, 4.0f), FRotator(0.0f, 0.0f, -7.0f), FVector(0.012f, 0.96f, 0.024f), Light, 0.24f);
        SetMotif(4, CubeMeshAsset, FVector(SurfaceX, 0.0f, -21.0f), FRotator(0.0f, 0.0f, 9.0f), FVector(0.012f, 0.8f, 0.024f), Dark, 0.12f);
        SetMotif(15, CylinderMeshAsset, FVector(SurfaceX - 2.0f, 25.0f, 25.0f), FRotator(0.0f, 90.0f, 0.0f), FVector(0.17f, 0.17f, 0.014f), FLinearColor(1.0f, 0.36f, 0.08f, 1.0f), 0.55f);
        return;
    }

    if (Id == TEXT("mars"))
    {
        SetMotif(2, SphereMeshAsset, FVector(SurfaceX - 2.0f, 0.0f, 39.0f), FRotator::ZeroRotator, FVector(0.016f, 0.38f, 0.1f), FLinearColor(0.98f, 0.86f, 0.66f, 1.0f), 0.16f);
        SetMotif(11, CubeMeshAsset, FVector(SurfaceX - 3.0f, -13.0f, -9.0f), FRotator(0.0f, 0.0f, 24.0f), FVector(0.01f, 0.64f, 0.022f), Deep, 0.06f);
        SetMotif(12, CubeMeshAsset, FVector(SurfaceX - 3.0f, 17.0f, -19.0f), FRotator(0.0f, 0.0f, -18.0f), FVector(0.01f, 0.48f, 0.018f), Dark, 0.05f);
        SetMotif(6, SphereMeshAsset, FVector(SurfaceX - 2.0f, 21.0f, 12.0f), FRotator::ZeroRotator, FVector(0.018f, 0.13f, 0.13f), Dark, 0.05f);
        return;
    }

    if (Id == TEXT("mercury") || Id == TEXT("moon"))
    {
        const bool bMercury = Id == TEXT("mercury");
        const FLinearColor Crater = BlendColor(BaseColor, Black, bMercury ? 0.76f : 0.5f);
        const FLinearColor CraterSoft = BlendColor(BaseColor, Black, bMercury ? 0.62f : 0.42f);
        const FLinearColor CraterRim = BlendColor(BaseColor, bMercury ? FLinearColor(1.0f, 0.84f, 0.46f, 1.0f) : White, bMercury ? 0.64f : 0.34f);
        const float CraterDepth = bMercury ? 0.019f : 0.012f;
        SetMotif(6, SphereMeshAsset, FVector(SurfaceX - 1.0f, -18.0f, 16.0f), FRotator::ZeroRotator, FVector(CraterDepth, bMercury ? 0.58f : 0.42f, bMercury ? 0.58f : 0.42f), Crater, bMercury ? 0.032f : 0.0f);
        SetMotif(7, SphereMeshAsset, FVector(SurfaceX - 1.0f, 14.0f, 3.0f), FRotator::ZeroRotator, FVector(CraterDepth, bMercury ? 0.48f : 0.34f, bMercury ? 0.48f : 0.34f), CraterSoft, bMercury ? 0.022f : 0.0f);
        SetMotif(8, SphereMeshAsset, FVector(SurfaceX - 1.0f, -2.0f, -20.0f), FRotator::ZeroRotator, FVector(CraterDepth, bMercury ? 0.50f : 0.38f, bMercury ? 0.50f : 0.38f), Crater, bMercury ? 0.022f : 0.0f);
        SetMotif(9, SphereMeshAsset, FVector(SurfaceX - 2.0f, 25.0f, -15.0f), FRotator::ZeroRotator, FVector(0.014f, bMercury ? 0.38f : 0.18f, bMercury ? 0.38f : 0.18f), CraterRim, bMercury ? 0.14f : 0.02f);
        if (bMercury)
        {
            SetMotif(17, SphereMeshAsset, FVector(SurfaceX - 1.0f, -32.0f, -6.0f), FRotator::ZeroRotator, FVector(0.014f, 0.36f, 0.28f), CraterSoft, 0.024f);
        }
        if (Id == TEXT("moon"))
        {
            SetMotif(16, CubeMeshAsset, FVector(SurfaceX - 5.0f, -54.0f, 0.0f), FRotator(0.0f, 0.0f, 0.0f), FVector(0.01f, 0.32f, 0.012f), FLinearColor(0.72f, 0.84f, 1.0f, 0.72f), 0.12f);
        }
        else
        {
            SetMotif(16, CubeMeshAsset, FVector(SurfaceX - 5.0f, 1.0f, 0.0f), FRotator(0.0f, 0.0f, -8.0f), FVector(0.008f, 0.38f, 0.008f), FLinearColor(1.0f, 0.70f, 0.28f, 0.18f), 0.035f);
        }
        return;
    }

    if (Id == TEXT("europa"))
    {
        SetMotif(11, CubeMeshAsset, FVector(SurfaceX - 2.0f, -10.0f, 15.0f), FRotator(0.0f, 0.0f, 34.0f), FVector(0.008f, 0.54f, 0.012f), FLinearColor(0.08f, 0.45f, 0.62f, 1.0f), 0.08f);
        SetMotif(12, CubeMeshAsset, FVector(SurfaceX - 2.0f, 10.0f, -8.0f), FRotator(0.0f, 0.0f, -28.0f), FVector(0.008f, 0.44f, 0.012f), FLinearColor(0.08f, 0.45f, 0.62f, 1.0f), 0.08f);
        SetMotif(13, CubeMeshAsset, FVector(SurfaceX - 2.0f, 0.0f, -26.0f), FRotator(0.0f, 0.0f, 8.0f), FVector(0.008f, 0.34f, 0.01f), FLinearColor(0.74f, 0.98f, 1.0f, 1.0f), 0.18f);
        return;
    }

    if (Id == TEXT("asteroid_belt"))
    {
        for (int32 RockIndex = 0; RockIndex < 10; ++RockIndex)
        {
            const float Angle = (2.0f * PI * static_cast<float>(RockIndex)) / 10.0f;
            const float Radius = RockIndex % 2 == 0 ? 56.0f : 70.0f;
            const float RockScale = 0.08f + 0.018f * static_cast<float>(RockIndex % 3);
            SetMotif(6 + RockIndex, SphereMeshAsset, FVector(FMath::Cos(Angle) * 6.0f, FMath::Cos(Angle) * Radius, FMath::Sin(Angle) * 34.0f), FRotator::ZeroRotator, FVector(RockScale, RockScale * 0.82f, RockScale * 1.08f), BlendColor(BaseColor, Black, RockIndex % 2 == 0 ? 0.18f : 0.42f), 0.03f);
        }
        SetMotif(0, CylinderMeshAsset, FVector::ZeroVector, FRotator(0.0f, 90.0f, 0.0f), FVector(1.24f, 1.24f, 0.008f), WithAlpha(Light, 0.5f), 0.1f);
        return;
    }

    if (Id == TEXT("pluto"))
    {
        SetMotif(6, SphereMeshAsset, FVector(SurfaceX - 1.0f, -12.0f, 10.0f), FRotator::ZeroRotator, FVector(0.012f, 0.16f, 0.12f), Pale, 0.06f);
        SetMotif(7, SphereMeshAsset, FVector(SurfaceX - 1.0f, 12.0f, -14.0f), FRotator::ZeroRotator, FVector(0.012f, 0.1f, 0.1f), Dark, 0.02f);
        SetMotif(11, CubeMeshAsset, FVector(SurfaceX - 2.0f, 0.0f, -26.0f), FRotator(0.0f, 0.0f, -12.0f), FVector(0.008f, 0.34f, 0.01f), FLinearColor(0.88f, 0.96f, 1.0f, 0.8f), 0.1f);
        return;
    }

    SetMotif(2, CubeMeshAsset, FVector(SurfaceX, 0.0f, 16.0f), FRotator::ZeroRotator, FVector(0.01f, 0.62f, 0.018f), Light, 0.06f);
    SetMotif(3, CubeMeshAsset, FVector(SurfaceX, 0.0f, -14.0f), FRotator::ZeroRotator, FVector(0.01f, 0.56f, 0.016f), Dark, 0.04f);
}

void AAstroDestinationActor::SetFocused(const bool bFocused)
{
    bIsFocused = bFocused;
    ApplyFocusVisuals();
}

void AAstroDestinationActor::SetDiscovered(const bool bDiscovered)
{
    bIsDiscovered = bDiscovered;
    const FString Prefix = bIsDiscovered ? TEXT("* ") : TEXT("");
    Label->SetText(FText::FromString(Prefix + DisplayName.ToString()));
    ApplyFocusVisuals();
}

void AAstroDestinationActor::SetPresentationMode(const EAstroDestinationPresentationMode NewPresentationMode)
{
    PresentationMode = NewPresentationMode;
    ApplyFocusVisuals();
}

void AAstroDestinationActor::ApplyFocusVisuals()
{
    float Scale = bIsFocused ? BaseVisualScale * DestinationFocusedScaleMultiplier : BaseVisualScale;
    const bool bHomeMode = PresentationMode == EAstroDestinationPresentationMode::Home;
    const bool bFirstLoopTeachMode = PresentationMode == EAstroDestinationPresentationMode::FirstLoopTeach;
    const bool bTeachingMode = bHomeMode || bFirstLoopTeachMode;
    if (bTeachingMode && DestinationId == FName(TEXT("sun")))
    {
        Scale = FMath::Max(BaseVisualScale * (bFirstLoopTeachMode ? 1.62f : 1.34f), bFirstLoopTeachMode ? 2.08f : 1.58f);
    }
    if (bTeachingMode && DestinationId == FName(TEXT("mercury")))
    {
        Scale = FMath::Max(BaseVisualScale * (bFirstLoopTeachMode ? 1.44f : 1.12f), bFirstLoopTeachMode ? 1.08f : 0.88f);
    }
    SetActorScale3D(FVector(Scale));

    BodyMesh->SetRenderCustomDepth(bIsFocused);
    BodyMesh->SetRelativeScale3D(bIsFocused ? BodyFocusedScale : BodyIdleScale);

    const bool bSun = DestinationId == FName(TEXT("sun"));
    const bool bSuppressSunHalo = bSun && PresentationMode != EAstroDestinationPresentationMode::Atlas && !bFirstLoopTeachMode;
    FocusHalo->SetVisibility(bIsFocused && !bSuppressSunHalo);
    FocusHalo->SetRelativeScale3D(bIsFocused
        ? (bSun ? FVector(1.08f, 1.08f, 0.005f) : bHomeMode ? FVector(1.22f, 1.22f, 0.008f) : FVector(1.28f, 1.28f, 0.01f))
        : FVector(1.0f, 1.0f, 0.006f));

    FocusBeacon->SetVisibility(false);
    FocusBeacon->SetRelativeScale3D(FVector(0.04f, 0.04f, 0.18f));

    UpdateNameplateLayout();
}
