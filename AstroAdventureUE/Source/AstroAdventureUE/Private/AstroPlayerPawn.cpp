#include "AstroPlayerPawn.h"

#include "Camera/CameraComponent.h"
#include "Components/SceneComponent.h"
#include "Components/StaticMeshComponent.h"
#include "GameFramework/FloatingPawnMovement.h"
#include "Materials/MaterialInstanceDynamic.h"
#include "Materials/MaterialInterface.h"
#include "UObject/ConstructorHelpers.h"

namespace
{
    const FVector TravelTargetToFocusOffset(145.0f, 0.0f, -70.0f);
    constexpr float TravelInterpSpeed = 2.6f;
    constexpr float RotationInterpSpeed = 5.0f;
    constexpr float TravelSnapDistance = 2.0f;
    constexpr float ScannerPulseDecaySpeed = 2.8f;
    constexpr float NavigationPulseDecaySpeed = 5.8f;
    constexpr float CameraFocusSnapDistance = 0.35f;
    constexpr float CameraLocationSnapDistance = 0.5f;
    constexpr float CameraRotationSnapDegrees = 0.08f;
    constexpr float CameraFovSnapDegrees = 0.05f;

    struct FAstroCameraPresentationSettings
    {
        FVector Offset = FVector::ZeroVector;
        float AimZOffset = -110.0f;
        FVector AimOffset = FVector::ZeroVector;
        float FocusInterpSpeed = 4.0f;
        float CameraInterpSpeed = 4.0f;
        float FieldOfView = 58.0f;
    };

    FAstroCameraPresentationSettings GetCameraPresentationSettings(const EAstroCameraPresentationProfile Profile)
    {
        switch (Profile)
        {
        case EAstroCameraPresentationProfile::Atlas:
            return { FVector(-1500.0f, -80.0f, 1720.0f), -150.0f, FVector(120.0f, 0.0f, 70.0f), 3.0f, 2.5f, 72.0f };
        case EAstroCameraPresentationProfile::Scan:
            return { FVector(-650.0f, -72.0f, 700.0f), -86.0f, FVector(58.0f, 0.0f, 58.0f), 6.4f, 5.8f, 60.0f };
        case EAstroCameraPresentationProfile::Stable:
            return { FVector(-800.0f, -70.0f, 900.0f), -112.0f, FVector(54.0f, 0.0f, 56.0f), 3.0f, 2.6f, 62.0f };
        case EAstroCameraPresentationProfile::Mission:
        default:
            return { FVector(-840.0f, -88.0f, 940.0f), -110.0f, FVector(62.0f, 0.0f, 66.0f), 4.6f, 4.0f, 66.0f };
        }
    }

    float RotationDeltaDegrees(const FRotator& A, const FRotator& B)
    {
        return FMath::Max3(
            FMath::Abs(FRotator::NormalizeAxis(A.Pitch - B.Pitch)),
            FMath::Abs(FRotator::NormalizeAxis(A.Yaw - B.Yaw)),
            FMath::Abs(FRotator::NormalizeAxis(A.Roll - B.Roll)));
    }

    void ApplyMaterialColor(UMaterialInstanceDynamic* Material, const FLinearColor& Color, const float EmissiveStrength)
    {
        if (!Material)
        {
            return;
        }

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
    static ConstructorHelpers::FObjectFinder<UMaterialInterface> EmissiveMaterial(TEXT("/Engine/EngineMaterials/EmissiveMeshMaterial.EmissiveMeshMaterial"));
    static ConstructorHelpers::FObjectFinder<UMaterialInterface> BasicShapeMaterial(TEXT("/Engine/BasicShapes/BasicShapeMaterial.BasicShapeMaterial"));
    UMaterialInterface* ShipMaterialTemplate = EmissiveMaterial.Succeeded() ? EmissiveMaterial.Object : BasicShapeMaterial.Succeeded() ? BasicShapeMaterial.Object : nullptr;

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
    ScannerBeam->SetRelativeLocation(FVector(128.0f, 0.0f, 4.0f));
    ScannerBeam->SetRelativeScale3D(FVector(0.88f, 0.075f, 0.075f));
    ScannerBeam->SetRelativeRotation(FRotator(0.0f, -90.0f, 0.0f));
    ScannerBeam->SetCollisionEnabled(ECollisionEnabled::NoCollision);
    ScannerBeam->SetVisibility(false);
    ScannerBeam->SetHiddenInGame(true);
    if (ConeMesh.Succeeded())
    {
        ScannerBeam->SetStaticMesh(ConeMesh.Object);
    }

    ScannerBeamHalo = CreateDefaultSubobject<UStaticMeshComponent>(TEXT("ScannerBeamHalo"));
    ScannerBeamHalo->SetupAttachment(ShipVisualRoot);
    ScannerBeamHalo->SetRelativeLocation(FVector(138.0f, 0.0f, 4.0f));
    ScannerBeamHalo->SetRelativeScale3D(FVector(1.05f, 0.16f, 0.16f));
    ScannerBeamHalo->SetRelativeRotation(FRotator(0.0f, -90.0f, 0.0f));
    ScannerBeamHalo->SetCollisionEnabled(ECollisionEnabled::NoCollision);
    ScannerBeamHalo->SetVisibility(false);
    ScannerBeamHalo->SetHiddenInGame(true);
    if (ConeMesh.Succeeded())
    {
        ScannerBeamHalo->SetStaticMesh(ConeMesh.Object);
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

    BodyMaterial = ShipMesh->CreateDynamicMaterialInstance(0, ShipMaterialTemplate);
    GlowMaterial = CockpitGlow->CreateDynamicMaterialInstance(0, ShipMaterialTemplate);
    AccentMaterial = PortWing->CreateDynamicMaterialInstance(0, ShipMaterialTemplate);
    if (AccentMaterial)
    {
        StarboardWing->SetMaterial(0, AccentMaterial);
    }
    TrailMaterial = TrailGlow->CreateDynamicMaterialInstance(0, ShipMaterialTemplate);
    ScannerMaterial = ScannerEmitter->CreateDynamicMaterialInstance(0, ShipMaterialTemplate);
    if (ScannerMaterial)
    {
        ScannerBeam->SetMaterial(0, ScannerMaterial);
        ScannerBeamHalo->SetMaterial(0, ScannerMaterial);
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
        ScannerActiveTimeRemaining = FMath::Max(ScannerActiveTimeRemaining, 1.45f);
        TriggerScannerPulse(0.65f);
    }
    else
    {
        ScannerActiveTimeRemaining = 0.0f;
    }
}

void AAstroPlayerPawn::TriggerScannerPulse(const float PulseStrength)
{
    ScannerPulse = FMath::Clamp(FMath::Max(ScannerPulse, PulseStrength), 0.0f, 1.0f);
}

void AAstroPlayerPawn::TriggerNavigationFeedback(const float Direction)
{
    NavigationPulse = 1.0f;
    NavigationPulseDirection = FMath::Clamp(Direction, -1.0f, 1.0f);

    if (FMath::IsNearlyZero(NavigationPulseDirection))
    {
        NavigationPulseDirection = 1.0f;
    }
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

    if (!bHasSmoothedCameraFocusTarget || DeltaSeconds <= SMALL_NUMBER)
    {
        SmoothedCameraFocusTarget = FocusTarget;
        bHasSmoothedCameraFocusTarget = true;
    }
    else
    {
        SmoothedCameraFocusTarget = FMath::VInterpTo(SmoothedCameraFocusTarget, FocusTarget, DeltaSeconds, Settings.FocusInterpSpeed);
        if (FVector::DistSquared(SmoothedCameraFocusTarget, FocusTarget) <= FMath::Square(CameraFocusSnapDistance))
        {
            SmoothedCameraFocusTarget = FocusTarget;
        }
    }

    const FVector DesiredCameraLocation = SmoothedCameraFocusTarget + Settings.Offset;
    const FVector DesiredLookAtLocation = SmoothedCameraFocusTarget + FVector(0.0f, 0.0f, Settings.AimZOffset) + Settings.AimOffset;
    const FRotator DesiredCameraRotation = (DesiredLookAtLocation - DesiredCameraLocation).Rotation();

    FVector NewCameraLocation = FMath::VInterpTo(Camera->GetComponentLocation(), DesiredCameraLocation, DeltaSeconds, Settings.CameraInterpSpeed);
    if (FVector::DistSquared(NewCameraLocation, DesiredCameraLocation) <= FMath::Square(CameraLocationSnapDistance))
    {
        NewCameraLocation = DesiredCameraLocation;
    }

    FRotator NewCameraRotation = FMath::RInterpTo(Camera->GetComponentRotation(), DesiredCameraRotation, DeltaSeconds, Settings.CameraInterpSpeed);
    if (RotationDeltaDegrees(NewCameraRotation, DesiredCameraRotation) <= CameraRotationSnapDegrees)
    {
        NewCameraRotation = DesiredCameraRotation;
    }

    float NewFieldOfView = FMath::FInterpTo(Camera->FieldOfView, Settings.FieldOfView, DeltaSeconds, Settings.CameraInterpSpeed);
    if (FMath::Abs(NewFieldOfView - Settings.FieldOfView) <= CameraFovSnapDegrees)
    {
        NewFieldOfView = Settings.FieldOfView;
    }

    Camera->SetWorldLocation(NewCameraLocation);
    Camera->SetWorldRotation(NewCameraRotation);
    Camera->SetFieldOfView(NewFieldOfView);
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

    NavigationPulse = FMath::FInterpTo(NavigationPulse, 0.0f, DeltaSeconds, NavigationPulseDecaySpeed);
    if (NavigationPulse <= 0.01f)
    {
        NavigationPulse = 0.0f;
    }

    ShipBobTime += DeltaSeconds * FMath::Lerp(1.15f, 1.75f, SmoothedSpeedAlpha);
    const float Bob = FMath::Sin(ShipBobTime) * 4.0f;
    const float SoftBank = FMath::Sin(ShipBobTime * 0.73f) * 1.8f;
    const float FocusBank = NavigationPulseDirection * NavigationPulse * 7.5f;
    const float FocusLift = NavigationPulse * 3.5f;
    ShipVisualRoot->SetRelativeLocation(FVector(0.0f, 0.0f, Bob + FocusLift));
    ShipVisualRoot->SetRelativeRotation(FRotator(FMath::Lerp(0.0f, -3.5f, SmoothedSpeedAlpha), 0.0f, SoftBank + FocusBank));

    if (bScannerActive)
    {
        ScannerActiveTimeRemaining -= DeltaSeconds;
        if (ScannerActiveTimeRemaining <= 0.0f)
        {
            ScannerActiveTimeRemaining = 0.0f;
            bScannerActive = false;
        }
    }

    ScannerPulse = FMath::FInterpTo(ScannerPulse, 0.0f, DeltaSeconds, ScannerPulseDecaySpeed);
    const float ScannerAlpha = FMath::Clamp((bScannerActive ? 0.76f : 0.0f) + ScannerPulse, 0.0f, 1.0f);
    const float FeedbackAlpha = FMath::Max(ScannerAlpha, NavigationPulse * 0.65f);

    if (TrailGlow)
    {
        const float TrailAlpha = FMath::Clamp(SmoothedSpeedAlpha + ScannerAlpha * 0.25f, 0.0f, 1.0f);
        TrailGlow->SetRelativeScale3D(FVector(0.42f + TrailAlpha * 0.42f, 0.12f + TrailAlpha * 0.08f, 0.12f + TrailAlpha * 0.08f));
        TrailGlow->SetVisibility(TrailAlpha > 0.03f);
        TrailGlow->SetHiddenInGame(TrailAlpha <= 0.03f);
    }

    if (ScannerEmitter)
    {
        const float EmitterScale = 0.09f + FeedbackAlpha * 0.065f;
        ScannerEmitter->SetRelativeScale3D(FVector(EmitterScale));
    }

    if (ScannerBeam)
    {
        const bool bShowBeam = ScannerAlpha > 0.05f;
        ScannerBeam->SetVisibility(bShowBeam);
        ScannerBeam->SetHiddenInGame(!bShowBeam);
        ScannerBeam->SetRelativeLocation(FVector(122.0f + ScannerAlpha * 32.0f, 0.0f, 4.0f));
        ScannerBeam->SetRelativeScale3D(FVector(0.82f + ScannerAlpha * 0.54f, 0.065f + ScannerAlpha * 0.075f, 0.065f + ScannerAlpha * 0.075f));
    }

    if (ScannerBeamHalo)
    {
        const bool bShowHalo = ScannerAlpha > 0.08f;
        ScannerBeamHalo->SetVisibility(bShowHalo);
        ScannerBeamHalo->SetHiddenInGame(!bShowHalo);
        ScannerBeamHalo->SetRelativeLocation(FVector(132.0f + ScannerAlpha * 40.0f, 0.0f, 4.0f));
        ScannerBeamHalo->SetRelativeScale3D(FVector(1.08f + ScannerAlpha * 0.72f, 0.16f + ScannerAlpha * 0.18f, 0.16f + ScannerAlpha * 0.18f));
    }

    ApplyMaterialColor(GlowMaterial, ShipAccentColor, 1.15f + NavigationPulse * 1.35f);
    ApplyMaterialColor(AccentMaterial, ShipAccentColor, 0.65f + NavigationPulse * 1.0f);
    ApplyMaterialColor(TrailMaterial, FLinearColor(0.18f, 0.86f, 1.0f), 0.4f + SmoothedSpeedAlpha * 1.2f + NavigationPulse * 0.45f);
    ApplyMaterialColor(ScannerMaterial, FLinearColor(0.36f, 1.0f, 0.72f), 0.85f + ScannerAlpha * 2.4f + NavigationPulse * 0.65f);
}

void AAstroPlayerPawn::ApplyShipMaterials()
{
    ApplyMaterialColor(BodyMaterial, FLinearColor(0.88f, 0.92f, 1.0f), 0.08f);
    ApplyMaterialColor(GlowMaterial, ShipAccentColor, 1.15f);
    ApplyMaterialColor(AccentMaterial, ShipAccentColor, 0.65f);
    ApplyMaterialColor(TrailMaterial, FLinearColor(0.18f, 0.86f, 1.0f), 0.5f);
    ApplyMaterialColor(ScannerMaterial, FLinearColor(0.36f, 1.0f, 0.72f), 1.0f);
}
