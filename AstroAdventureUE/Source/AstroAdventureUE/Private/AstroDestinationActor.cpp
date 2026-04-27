#include "AstroDestinationActor.h"

#include "Components/StaticMeshComponent.h"
#include "Components/TextRenderComponent.h"
#include "Materials/MaterialInstanceDynamic.h"
#include "UObject/ConstructorHelpers.h"

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
        BodyMesh->SetStaticMesh(SphereMesh.Object);
    }

    FocusHalo = CreateDefaultSubobject<UStaticMeshComponent>(TEXT("FocusHalo"));
    FocusHalo->SetupAttachment(Root);
    FocusHalo->SetMobility(EComponentMobility::Movable);
    FocusHalo->SetVisibility(false);
    FocusHalo->SetCollisionEnabled(ECollisionEnabled::NoCollision);
    if (SphereMesh.Succeeded())
    {
        FocusHalo->SetStaticMesh(SphereMesh.Object);
    }

    FocusBeacon = CreateDefaultSubobject<UStaticMeshComponent>(TEXT("FocusBeacon"));
    FocusBeacon->SetupAttachment(Root);
    FocusBeacon->SetMobility(EComponentMobility::Movable);
    FocusBeacon->SetVisibility(false);
    FocusBeacon->SetCollisionEnabled(ECollisionEnabled::NoCollision);

    static ConstructorHelpers::FObjectFinder<UStaticMesh> CylinderMesh(TEXT("/Engine/BasicShapes/Cylinder.Cylinder"));
    if (CylinderMesh.Succeeded())
    {
        FocusBeacon->SetStaticMesh(CylinderMesh.Object);
    }

    Nameplate = CreateDefaultSubobject<UStaticMeshComponent>(TEXT("Nameplate"));
    Nameplate->SetupAttachment(Root);
    Nameplate->SetMobility(EComponentMobility::Movable);
    Nameplate->SetVisibility(false);
    Nameplate->SetCollisionEnabled(ECollisionEnabled::NoCollision);

    static ConstructorHelpers::FObjectFinder<UStaticMesh> CubeMesh(TEXT("/Engine/BasicShapes/Cube.Cube"));
    if (CubeMesh.Succeeded())
    {
        Nameplate->SetStaticMesh(CubeMesh.Object);
    }

    Label = CreateDefaultSubobject<UTextRenderComponent>(TEXT("Label"));
    Label->SetupAttachment(Root);
    Label->SetHorizontalAlignment(EHTA_Center);
    Label->SetTextRenderColor(FColor(118, 156, 198));
    Label->SetWorldSize(46.0f);
    Label->SetRelativeLocation(FVector(0.0f, 0.0f, 145.0f));
    Label->SetRelativeRotation(FRotator(0.0f, 180.0f, 0.0f));
}

void AAstroDestinationActor::Configure(const FAstroDestinationLesson& Lesson, const FLinearColor& Color, const float VisualScale)
{
    DestinationId = Lesson.DestinationId;
    DisplayName = Lesson.DisplayName;
    BaseColor = Color;
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
    Nameplate->SetRelativeScale3D(FVector(0.04f, 2.7f, 0.34f));
    FocusBeacon->SetRelativeLocation(FVector(0.0f, 0.0f, 116.0f + 70.0f * BaseVisualScale));
    FocusBeacon->SetRelativeScale3D(FVector(0.08f, 0.08f, 1.55f + 0.35f * BaseVisualScale));

    ApplyColor(BodyMesh, BaseColor, 0.22f);
    ApplyColor(FocusHalo, FLinearColor(1.0f, 0.88f, 0.18f, 0.55f), 1.85f);
    ApplyColor(FocusBeacon, FLinearColor(0.35f, 0.82f, 1.0f, 0.7f), 2.4f);
    ApplyColor(Nameplate, FLinearColor(0.02f, 0.05f, 0.11f, 0.82f), 0.05f);
    SetActorScale3D(FVector(BaseVisualScale));
    ApplyFocusVisuals();
}

void AAstroDestinationActor::ApplyColor(UStaticMeshComponent* Mesh, const FLinearColor& Color, const float EmissiveStrength)
{
    if (Mesh)
    {
        if (UMaterialInstanceDynamic* Material = Mesh->CreateAndSetMaterialInstanceDynamic(0))
        {
            Material->SetVectorParameterValue(TEXT("Color"), Color);
            Material->SetVectorParameterValue(TEXT("BaseColor"), Color);
            Material->SetVectorParameterValue(TEXT("EmissiveColor"), Color * EmissiveStrength);
        }
    }
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

    Nameplate->SetVisibility(bIsFocused);
    Nameplate->SetRelativeScale3D(bIsFocused ? FVector(0.045f, 3.2f, 0.42f) : FVector(0.035f, 2.35f, 0.28f));

    Label->SetWorldSize(bIsFocused ? 72.0f : 42.0f);
    Label->SetTextRenderColor(bIsFocused ? FColor(255, 241, 112) : FColor(105, 145, 186));
}
