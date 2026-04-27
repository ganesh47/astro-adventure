#include "AstroPlayerPawn.h"

#include "Camera/CameraComponent.h"
#include "Components/SceneComponent.h"
#include "Components/StaticMeshComponent.h"
#include "GameFramework/FloatingPawnMovement.h"
#include "Materials/MaterialInstanceDynamic.h"
#include "UObject/ConstructorHelpers.h"

namespace
{
    const FVector TravelTargetToFocusOffset(145.0f, 0.0f, -70.0f);
    constexpr float TravelInterpSpeed = 2.6f;
    constexpr float RotationInterpSpeed = 5.0f;
    constexpr float TravelSnapDistance = 2.0f;
    constexpr float ScannerPulseDecaySpeed = 2.8f;

    struct FAstroCameraPresentationSettings
    {
        FVector Offset = FVector::ZeroVector;
        FRotator Rotation = FRotator::ZeroRotator;
        float InterpSpeed = 4.0f;
        float FieldOfView = 58.0f;
    };

    FAstroCameraPresentationSettings GetCameraPresentationSettings(const EAstroCameraPresentationProfile Profile)
    {
        switch (Profile)
        {
        case EAstroCameraPresentationProfile::Atlas:
            return { FVector(-340.0f, 0.0f, 820.0f), FRotator(-48.0f, 0.0f, 0.0f), 3.2f, 64.0f };
        case EAstroCameraPresentationProfile::Scan:
            return { FVector(-205.0f, 0.0f, 500.0f), FRotator(-30.0f, 0.0f, 0.0f), 5.8f, 52.0f };
        case EAstroCameraPresentationProfile::Stable:
            return { FVector(-300.0f, 0.0f, 660.0f), FRotator(-36.0f, 0.0f, 0.0f), 2.6f, 56.0f };
        case EAstroCameraPresentationProfile::Mission:
        default:
            return { FVector(-260.0f, 0.0f, 620.0f), FRotator(-34.0f, 0.0f, 0.0f), 4.5f, 58.0f };
        }
    }

    void ApplyMaterialColor(UMaterialInstanceDynamic* Material, const FLinearColor& Color, const float EmissiveStrength)
    {
        if (!Material)
        {
            return;
        }

        Material->SetVectorParameterValue(TEXT("Color"), Color);
        Material->SetVectorParameterValue(TEXT("BaseColor"), Color);
        Material->SetVectorParameterValue(TEXT("EmissiveColor"), Color * EmissiveStrength);
        Material->SetScalarParameterValue(TEXT("EmissiveStrength"), EmissiveStrength);
    }
}

AAstroPlayerPawn::AAstroPlayerPawn()
{
    PrimaryActorTick.bCanEverTick = true;

    Root = CreateDefaultSubobject<USceneComponent>(TEXT("Root"));
    SetRootComponent(Root);

    ShipVisualRoot = CreateDefaultSubobject<USceneComponent>(TEXT("ShipVisualRoot"));
    ShipVisualRoot->SetupAttachment(Root);

    static ConstructorHelpers::FObjectFinder<UStaticMesh> ConeMesh(TEXT("/Engine/BasicShapes/Cone.Cone"));
    static ConstructorHelpers::FObjectFinder<UStaticMesh> SphereMesh(TEXT("/Engine/BasicShapes/Sphere.Sphere"));
    static ConstructorHelpers::FObjectFinder<UStaticMesh> CubeMesh(TEXT("/Engine/BasicShapes/Cube.Cube"));

    ShipMesh = CreateDefaultSubobject<UStaticMeshComponent>(TEXT("ShipMesh"));
    ShipMesh->SetupAttachment(ShipVisualRoot);
    ShipMesh->SetRelativeScale3D(FVector(0.72f, 0.72f, 0.32f));
    ShipMesh->SetRelativeRotation(FRotator(0.0f, 90.0f, 0.0f));
    ShipMesh->SetCollisionEnabled(ECollisionEnabled::NoCollision);

    if (ConeMesh.Succeeded())
    {
        ShipMesh->SetStaticMesh(ConeMesh.Object);
    }

    CockpitGlow = CreateDefaultSubobject<UStaticMeshComponent>(TEXT("CockpitGlow"));
    CockpitGlow->SetupAttachment(ShipVisualRoot);
    CockpitGlow->SetRelativeLocation(FVector(18.0f, 0.0f, 22.0f));
    CockpitGlow->SetRelativeScale3D(FVector(0.18f, 0.24f, 0.10f));
    CockpitGlow->SetCollisionEnabled(ECollisionEnabled::NoCollision);
    if (SphereMesh.Succeeded())
    {
        CockpitGlow->SetStaticMesh(SphereMesh.Object);
    }

    PortWing = CreateDefaultSubobject<UStaticMeshComponent>(TEXT("PortWing"));
    PortWing->SetupAttachment(ShipVisualRoot);
    PortWing->SetRelativeLocation(FVector(-8.0f, -34.0f, -7.0f));
    PortWing->SetRelativeScale3D(FVector(0.36f, 0.10f, 0.055f));
    PortWing->SetRelativeRotation(FRotator(0.0f, 0.0f, -8.0f));
    PortWing->SetCollisionEnabled(ECollisionEnabled::NoCollision);
    if (CubeMesh.Succeeded())
    {
        PortWing->SetStaticMesh(CubeMesh.Object);
    }

    StarboardWing = CreateDefaultSubobject<UStaticMeshComponent>(TEXT("StarboardWing"));
    StarboardWing->SetupAttachment(ShipVisualRoot);
    StarboardWing->SetRelativeLocation(FVector(-8.0f, 34.0f, -7.0f));
    StarboardWing->SetRelativeScale3D(FVector(0.36f, 0.10f, 0.055f));
    StarboardWing->SetRelativeRotation(FRotator(0.0f, 0.0f, 8.0f));
    StarboardWing->SetCollisionEnabled(ECollisionEnabled::NoCollision);
    if (CubeMesh.Succeeded())
    {
        StarboardWing->SetStaticMesh(CubeMesh.Object);
    }

    TrailGlow = CreateDefaultSubobject<UStaticMeshComponent>(TEXT("TrailGlow"));
    TrailGlow->SetupAttachment(ShipVisualRoot);
    TrailGlow->SetRelativeLocation(FVector(-62.0f, 0.0f, -2.0f));
    TrailGlow->SetRelativeScale3D(FVector(0.46f, 0.14f, 0.14f));
    TrailGlow->SetRelativeRotation(FRotator(0.0f, -90.0f, 0.0f));
    TrailGlow->SetCollisionEnabled(ECollisionEnabled::NoCollision);
    if (ConeMesh.Succeeded())
    {
        TrailGlow->SetStaticMesh(ConeMesh.Object);
    }

    ScannerEmitter = CreateDefaultSubobject<UStaticMeshComponent>(TEXT("ScannerEmitter"));
    ScannerEmitter->SetupAttachment(ShipVisualRoot);
    ScannerEmitter->SetRelativeLocation(FVector(46.0f, 0.0f, 2.0f));
    ScannerEmitter->SetRelativeScale3D(FVector(0.09f, 0.09f, 0.09f));
    ScannerEmitter->SetCollisionEnabled(ECollisionEnabled::NoCollision);
    if (SphereMesh.Succeeded())
    {
        ScannerEmitter->SetStaticMesh(SphereMesh.Object);
    }

    ScannerBeam = CreateDefaultSubobject<UStaticMeshComponent>(TEXT("ScannerBeam"));
    ScannerBeam->SetupAttachment(ShipVisualRoot);
    ScannerBeam->SetRelativeLocation(FVector(104.0f, 0.0f, 2.0f));
    ScannerBeam->SetRelativeScale3D(FVector(0.64f, 0.06f, 0.06f));
    ScannerBeam->SetRelativeRotation(FRotator(0.0f, -90.0f, 0.0f));
    ScannerBeam->SetCollisionEnabled(ECollisionEnabled::NoCollision);
    ScannerBeam->SetVisibility(false);
    ScannerBeam->SetHiddenInGame(true);
    if (ConeMesh.Succeeded())
    {
        ScannerBeam->SetStaticMesh(ConeMesh.Object);
    }

    Camera = CreateDefaultSubobject<UCameraComponent>(TEXT("Camera"));
    Camera->SetupAttachment(Root);
    Camera->SetRelativeLocation(FVector(-920.0f, 0.0f, 640.0f));
    Camera->SetRelativeRotation(FRotator(-38.0f, 0.0f, 0.0f));
    Camera->SetUsingAbsoluteLocation(true);
    Camera->SetUsingAbsoluteRotation(true);
    Camera->SetFieldOfView(58.0f);

    Movement = CreateDefaultSubobject<UFloatingPawnMovement>(TEXT("Movement"));
    Movement->MaxSpeed = 650.0f;
    AutoPossessPlayer = EAutoReceiveInput::Player0;

    BodyMaterial = ShipMesh->CreateAndSetMaterialInstanceDynamic(0);
    GlowMaterial = CockpitGlow->CreateAndSetMaterialInstanceDynamic(0);
    AccentMaterial = PortWing->CreateAndSetMaterialInstanceDynamic(0);
    if (AccentMaterial)
    {
        StarboardWing->SetMaterial(0, AccentMaterial);
    }
    TrailMaterial = TrailGlow->CreateAndSetMaterialInstanceDynamic(0);
    ScannerMaterial = ScannerEmitter->CreateAndSetMaterialInstanceDynamic(0);
    if (ScannerMaterial)
    {
        ScannerBeam->SetMaterial(0, ScannerMaterial);
    }

    ApplyShipMaterials();
}

void AAstroPlayerPawn::Tick(const float DeltaSeconds)
{
    Super::Tick(DeltaSeconds);

    if (bHasTravelTarget)
    {
        const FVector Current = GetActorLocation();
        const FVector NewLocation = FMath::VInterpTo(Current, TravelTarget, DeltaSeconds, TravelInterpSpeed);
        SetActorLocation(NewLocation);

        if (FVector::DistSquared(NewLocation, TravelTarget) <= FMath::Square(TravelSnapDistance))
        {
            SetActorLocation(TravelTarget);
        }

        const FVector ToTarget = TravelTarget - NewLocation;
        if (!ToTarget.IsNearlyZero())
        {
            SetActorRotation(FMath::RInterpTo(GetActorRotation(), ToTarget.Rotation(), DeltaSeconds, RotationInterpSpeed));
        }
    }

    UpdateShipPresentation(DeltaSeconds);
    UpdateCameraPresentation(DeltaSeconds);
}

void AAstroPlayerPawn::SetupPlayerInputComponent(UInputComponent* PlayerInputComponent)
{
    Super::SetupPlayerInputComponent(PlayerInputComponent);
}

void AAstroPlayerPawn::MoveForward(const float Value)
{
}

void AAstroPlayerPawn::MoveRight(const float Value)
{
}

void AAstroPlayerPawn::SetTravelTarget(const FVector& TargetLocation)
{
    TravelTarget = TargetLocation;
    bHasTravelTarget = true;

    if (!bHasCameraFocusTarget)
    {
        CameraFocusTarget = TargetLocation + TravelTargetToFocusOffset;
    }
}

void AAstroPlayerPawn::SetCameraFocusTarget(const FVector& TargetLocation)
{
    CameraFocusTarget = TargetLocation;
    bHasCameraFocusTarget = true;
}

void AAstroPlayerPawn::SetCameraPresentationProfile(const EAstroCameraPresentationProfile NewProfile)
{
    CameraPresentationProfile = NewProfile;
}

void AAstroPlayerPawn::SetScannerActive(const bool bActive)
{
    bScannerActive = bActive;
    if (bScannerActive)
    {
        TriggerScannerPulse(0.65f);
    }
}

void AAstroPlayerPawn::TriggerScannerPulse(const float PulseStrength)
{
    ScannerPulse = FMath::Clamp(FMath::Max(ScannerPulse, PulseStrength), 0.0f, 1.0f);
}

void AAstroPlayerPawn::SetShipAccentColor(const FLinearColor& NewColor)
{
    ShipAccentColor = NewColor;
    ApplyShipMaterials();
}

void AAstroPlayerPawn::UpdateCameraPresentation(const float DeltaSeconds)
{
    if (!Camera)
    {
        return;
    }

    const FAstroCameraPresentationSettings Settings = GetCameraPresentationSettings(CameraPresentationProfile);
    const FVector FocusTarget = bHasCameraFocusTarget
        ? CameraFocusTarget
        : bHasTravelTarget
            ? TravelTarget + TravelTargetToFocusOffset
            : GetActorLocation() + TravelTargetToFocusOffset;
    const FVector DesiredCameraLocation = FocusTarget + Settings.Offset;

    Camera->SetWorldLocation(FMath::VInterpTo(Camera->GetComponentLocation(), DesiredCameraLocation, DeltaSeconds, Settings.InterpSpeed));
    Camera->SetWorldRotation(FMath::RInterpTo(Camera->GetComponentRotation(), Settings.Rotation, DeltaSeconds, Settings.InterpSpeed));
    Camera->SetFieldOfView(FMath::FInterpTo(Camera->FieldOfView, Settings.FieldOfView, DeltaSeconds, Settings.InterpSpeed));
}

void AAstroPlayerPawn::UpdateShipPresentation(const float DeltaSeconds)
{
    if (!ShipVisualRoot)
    {
        return;
    }

    const FVector ActorLocation = GetActorLocation();
    if (!bHasLastActorLocation)
    {
        LastActorLocation = ActorLocation;
        bHasLastActorLocation = true;
    }

    const float MaxSpeed = Movement ? Movement->MaxSpeed : 650.0f;
    const float CurrentSpeed = DeltaSeconds > SMALL_NUMBER ? (ActorLocation - LastActorLocation).Size() / DeltaSeconds : 0.0f;
    const float TargetSpeedAlpha = FMath::Clamp(CurrentSpeed / FMath::Max(MaxSpeed, 1.0f), 0.0f, 1.0f);
    SmoothedSpeedAlpha = FMath::FInterpTo(SmoothedSpeedAlpha, TargetSpeedAlpha, DeltaSeconds, 4.0f);
    LastActorLocation = ActorLocation;

    ShipBobTime += DeltaSeconds * FMath::Lerp(1.15f, 1.75f, SmoothedSpeedAlpha);
    const float Bob = FMath::Sin(ShipBobTime) * 4.0f;
    const float SoftBank = FMath::Sin(ShipBobTime * 0.73f) * 1.8f;
    ShipVisualRoot->SetRelativeLocation(FVector(0.0f, 0.0f, Bob));
    ShipVisualRoot->SetRelativeRotation(FRotator(FMath::Lerp(0.0f, -3.5f, SmoothedSpeedAlpha), 0.0f, SoftBank));

    ScannerPulse = FMath::FInterpTo(ScannerPulse, 0.0f, DeltaSeconds, ScannerPulseDecaySpeed);
    const float ScannerAlpha = FMath::Clamp((bScannerActive ? 0.72f : 0.0f) + ScannerPulse, 0.0f, 1.0f);

    if (TrailGlow)
    {
        const float TrailAlpha = FMath::Clamp(SmoothedSpeedAlpha + ScannerAlpha * 0.25f, 0.0f, 1.0f);
        TrailGlow->SetRelativeScale3D(FVector(0.42f + TrailAlpha * 0.42f, 0.12f + TrailAlpha * 0.08f, 0.12f + TrailAlpha * 0.08f));
        TrailGlow->SetVisibility(TrailAlpha > 0.03f);
        TrailGlow->SetHiddenInGame(TrailAlpha <= 0.03f);
    }

    if (ScannerEmitter)
    {
        const float EmitterScale = 0.09f + ScannerAlpha * 0.055f;
        ScannerEmitter->SetRelativeScale3D(FVector(EmitterScale));
    }

    if (ScannerBeam)
    {
        const bool bShowBeam = ScannerAlpha > 0.05f;
        ScannerBeam->SetVisibility(bShowBeam);
        ScannerBeam->SetHiddenInGame(!bShowBeam);
        ScannerBeam->SetRelativeScale3D(FVector(0.58f + ScannerAlpha * 0.36f, 0.045f + ScannerAlpha * 0.055f, 0.045f + ScannerAlpha * 0.055f));
    }

    ApplyMaterialColor(TrailMaterial, FLinearColor(0.18f, 0.86f, 1.0f), 0.4f + SmoothedSpeedAlpha * 1.2f);
    ApplyMaterialColor(ScannerMaterial, FLinearColor(0.36f, 1.0f, 0.72f), 0.8f + ScannerAlpha * 1.8f);
}

void AAstroPlayerPawn::ApplyShipMaterials()
{
    ApplyMaterialColor(BodyMaterial, FLinearColor(0.88f, 0.92f, 1.0f), 0.08f);
    ApplyMaterialColor(GlowMaterial, ShipAccentColor, 1.15f);
    ApplyMaterialColor(AccentMaterial, ShipAccentColor, 0.65f);
    ApplyMaterialColor(TrailMaterial, FLinearColor(0.18f, 0.86f, 1.0f), 0.5f);
    ApplyMaterialColor(ScannerMaterial, FLinearColor(0.36f, 1.0f, 0.72f), 1.0f);
}
