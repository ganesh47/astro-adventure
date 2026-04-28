#include "AstroDestinationActor.h"

#include "Components/StaticMeshComponent.h"
#include "Components/TextRenderComponent.h"
#include "Engine/StaticMesh.h"
#include "Materials/MaterialInstanceDynamic.h"
#include "Materials/MaterialInterface.h"
#include "UObject/ConstructorHelpers.h"

namespace
{
constexpr int32 DestinationMotifCount = 18;

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
        return FLinearColor(1.0f, 0.58f, 0.05f, 1.0f);
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
        return 1.55f;
    }
    if (Id == TEXT("neptune") || Id == TEXT("uranus") || Id == TEXT("earth") || Id == TEXT("europa"))
    {
        return 0.62f;
    }
    if (Id == TEXT("venus") || Id == TEXT("mars") || Id == TEXT("jupiter") || Id == TEXT("saturn"))
    {
        return 0.5f;
    }
    if (Id == TEXT("mercury") || Id == TEXT("moon") || Id == TEXT("pluto") || Id == TEXT("asteroid_belt"))
    {
        return 0.42f;
    }

    return 0.38f;
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
    if (BasicShapeMaterial.Succeeded())
    {
        ColorMaterialTemplate = BasicShapeMaterial.Object;
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
    Label->SetWorldSize(48.0f);
    Label->SetRelativeLocation(FVector(0.0f, 0.0f, 145.0f));
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
    BaseColor = ReadableDestinationColor(DestinationKey, Color);
    BaseVisualScale = VisualScale;
    const uint32 ShapeHash = GetTypeHash(DestinationId);
    const float WidthCue = 0.94f + 0.04f * static_cast<float>(ShapeHash % 4);
    const float DepthCue = 0.94f + 0.035f * static_cast<float>((ShapeHash / 4) % 4);
    const float HeightCue = 0.9f + 0.035f * static_cast<float>((ShapeHash / 16) % 5);
    BodyIdleScale = FVector(WidthCue, DepthCue, HeightCue);
    BodyFocusedScale = BodyIdleScale + FVector(0.04f, 0.04f, 0.12f);
#if WITH_EDITOR
    SetActorLabel(DisplayName.ToString());
#endif
    Label->SetText(DisplayName);
    Label->SetRelativeLocation(FVector(0.0f, 0.0f, 115.0f + 45.0f * BaseVisualScale));
    Nameplate->SetRelativeLocation(FVector(-5.0f, 0.0f, 108.0f + 45.0f * BaseVisualScale));
    Nameplate->SetRelativeRotation(Label->GetRelativeRotation());
    UpdateNameplateLayout();
    FocusBeacon->SetRelativeLocation(FVector(0.0f, 0.0f, 116.0f + 70.0f * BaseVisualScale));
    FocusBeacon->SetRelativeScale3D(FVector(0.08f, 0.08f, 1.55f + 0.35f * BaseVisualScale));

    ApplyColor(BodyMesh, BaseColor, DestinationBodyEmissiveStrength(DestinationKey));
    ApplyColor(FocusHalo, WithAlpha(BlendColor(BaseColor, FLinearColor(1.0f, 0.92f, 0.28f, 1.0f), 0.4f), 0.64f), 1.7f);
    ApplyColor(FocusBeacon, FLinearColor(0.42f, 0.9f, 1.0f, 0.78f), 2.05f);
    ApplyColor(Nameplate, FLinearColor(0.01f, 0.025f, 0.06f, 0.92f), 0.16f);
    ConfigureMotifs();
    SetActorScale3D(FVector(BaseVisualScale));
    ApplyFocusVisuals();
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

    Nameplate->SetVisibility(bIsFocused);
    Nameplate->SetRelativeScale3D(FVector(PlateDepth, PlateWidth * FocusWidthBoost, PlateHeight) * LabelScaleCompensation);

    Label->SetRelativeScale3D(FVector(LabelScaleCompensation));
    Label->SetWorldSize(bIsFocused ? 54.0f : (bIsDiscovered ? 42.0f : 36.0f));
    Label->SetTextRenderColor(bIsFocused ? FColor(255, 244, 118) : FColor(188, 224, 255));
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
        SetMotif(0, CylinderMeshAsset, FVector::ZeroVector, FRotator(0.0f, 90.0f, 0.0f), FVector(1.7f, 1.7f, 0.014f), FLinearColor(1.0f, 0.42f, 0.02f, 0.68f), 1.45f);
        for (int32 RayIndex = 0; RayIndex < 8; ++RayIndex)
        {
            const float Angle = (2.0f * PI * static_cast<float>(RayIndex)) / 8.0f;
            const float Y = FMath::Cos(Angle) * 82.0f;
            const float Z = FMath::Sin(Angle) * 82.0f;
            SetMotif(1 + RayIndex, CubeMeshAsset, FVector(-4.0f, Y, Z), FRotator(0.0f, 0.0f, FMath::RadiansToDegrees(Angle)), FVector(0.02f, 0.44f, 0.045f), FLinearColor(1.0f, 0.82f, 0.16f, 0.92f), 1.85f);
        }
        SetMotif(15, CylinderMeshAsset, FVector(SurfaceX - 1.0f, -17.0f, 20.0f), FRotator(0.0f, 90.0f, 0.0f), FVector(0.28f, 0.28f, 0.012f), FLinearColor(1.0f, 0.92f, 0.36f, 0.95f), 1.7f);
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
        const FLinearColor Crater = BlendColor(BaseColor, Black, 0.5f);
        SetMotif(6, SphereMeshAsset, FVector(SurfaceX - 1.0f, -20.0f, 18.0f), FRotator::ZeroRotator, FVector(0.012f, 0.16f, 0.16f), Crater, 0.02f);
        SetMotif(7, SphereMeshAsset, FVector(SurfaceX - 1.0f, 16.0f, 5.0f), FRotator::ZeroRotator, FVector(0.012f, 0.11f, 0.11f), Crater, 0.02f);
        SetMotif(8, SphereMeshAsset, FVector(SurfaceX - 1.0f, -2.0f, -24.0f), FRotator::ZeroRotator, FVector(0.012f, 0.13f, 0.13f), Crater, 0.02f);
        SetMotif(9, SphereMeshAsset, FVector(SurfaceX - 1.0f, 28.0f, -18.0f), FRotator::ZeroRotator, FVector(0.01f, 0.08f, 0.08f), BlendColor(BaseColor, White, 0.2f), 0.02f);
        if (Id == TEXT("moon"))
        {
            SetMotif(16, CubeMeshAsset, FVector(SurfaceX - 5.0f, -54.0f, 0.0f), FRotator(0.0f, 0.0f, 0.0f), FVector(0.01f, 0.32f, 0.012f), FLinearColor(0.72f, 0.84f, 1.0f, 0.72f), 0.12f);
        }
        else
        {
            SetMotif(15, CylinderMeshAsset, FVector(SurfaceX - 2.0f, 30.0f, 28.0f), FRotator(0.0f, 90.0f, 0.0f), FVector(0.11f, 0.11f, 0.012f), FLinearColor(1.0f, 0.48f, 0.08f, 1.0f), 0.35f);
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

void AAstroDestinationActor::ApplyFocusVisuals()
{
    const float Scale = bIsFocused ? BaseVisualScale * 1.22f : BaseVisualScale;
    SetActorScale3D(FVector(Scale));

    BodyMesh->SetRenderCustomDepth(bIsFocused);
    BodyMesh->SetRelativeScale3D(bIsFocused ? BodyFocusedScale : BodyIdleScale);

    FocusHalo->SetVisibility(bIsFocused);
    FocusHalo->SetRelativeScale3D(bIsFocused ? FVector(1.52f, 1.52f, 0.075f) : FVector(1.18f, 1.18f, 0.045f));

    FocusBeacon->SetVisibility(bIsFocused);
    FocusBeacon->SetRelativeScale3D(bIsFocused ? FVector(0.1f, 0.1f, 1.85f + 0.45f * BaseVisualScale) : FVector(0.06f, 0.06f, 1.25f));

    UpdateNameplateLayout();
}
