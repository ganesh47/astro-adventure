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
        float OrthoWidth = 980.0f;
    };

    FAstroCameraPresentationSettings GetCameraPresentationSettings(const EAstroCameraPresentationProfile Profile)
    {
        switch (Profile)
        {
        case EAstroCameraPresentationProfile::Home:
            return { FVector(-500.0f, -820.0f, 720.0f), -58.0f, FVector(82.0f, -8.0f, 118.0f), 5.4f, 4.8f, 58.0f, 980.0f };
        case EAstroCameraPresentationProfile::Atlas:
            return { FVector(-820.0f, -1640.0f, 1840.0f), -92.0f, FVector(80.0f, 0.0f, 70.0f), 3.0f, 2.6f, 72.0f, 4500.0f };
        case EAstroCameraPresentationProfile::Scan:
            return { FVector(-500.0f, -860.0f, 760.0f), -48.0f, FVector(42.0f, 0.0f, 64.0f), 6.2f, 5.6f, 60.0f, 1240.0f };
        case EAstroCameraPresentationProfile::Stable:
            return { FVector(-560.0f, -940.0f, 800.0f), -56.0f, FVector(36.0f, 0.0f, 42.0f), 3.2f, 2.8f, 62.0f, 1120.0f };
        case EAstroCameraPresentationProfile::Mission:
        default:
            return { FVector(-560.0f, -940.0f, 800.0f), -56.0f, FVector(40.0f, 0.0f, 42.0f), 4.8f, 4.2f, 62.0f, 1120.0f };
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
        Material->SetVectorParameterValue(TEXT("BodyTint"), Color);
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
    ShipVisualRoot->SetRelativeScale3D(FVector(1.42f));

    static ConstructorHelpers::FObjectFinder<UStaticMesh> ConeMesh(TEXT("/Engine/BasicShapes/Cone.Cone"));
    static ConstructorHelpers::FObjectFinder<UStaticMesh> SphereMesh(TEXT("/Engine/BasicShapes/Sphere.Sphere"));
    static ConstructorHelpers::FObjectFinder<UStaticMesh> CubeMesh(TEXT("/Engine/BasicShapes/Cube.Cube"));
    static ConstructorHelpers::FObjectFinder<UStaticMesh> BackdropQuadMesh(TEXT("/Game/Art/AstroAdventureOwned/Scene/SM_Backdrop_Quad.SM_Backdrop_Quad"));
    static ConstructorHelpers::FObjectFinder<UStaticMesh> PlaneMesh(TEXT("/Engine/BasicShapes/Plane.Plane"));
    static ConstructorHelpers::FObjectFinder<UMaterialInterface> BasicShapeMaterial(TEXT("/Engine/BasicShapes/BasicShapeMaterial.BasicShapeMaterial"));
    static ConstructorHelpers::FObjectFinder<UMaterialInterface> ScannerBeamMaterialAsset(TEXT("/Game/Art/AstroAdventureOwned/MaterialInstances/MI_Scanner_Beam.MI_Scanner_Beam"));
    static ConstructorHelpers::FObjectFinder<UMaterialInterface> BackdropMaterialAsset(TEXT("/Game/Art/AstroAdventureOwned/MaterialInstances/MI_Sky_Backdrop.MI_Sky_Backdrop"));
    UMaterialInterface* ShipMaterialTemplate = BasicShapeMaterial.Succeeded() ? BasicShapeMaterial.Object : nullptr;
    UMaterialInterface* ScannerBeamMaterialTemplate = ScannerBeamMaterialAsset.Succeeded() ? ScannerBeamMaterialAsset.Object.Get() : ShipMaterialTemplate;

    ShipMesh = CreateDefaultSubobject<UStaticMeshComponent>(TEXT("ShipMesh"));
    ShipMesh->SetupAttachment(ShipVisualRoot);
    ShipMesh->SetRelativeScale3D(FVector(0.48f, 0.38f, 0.22f));
    ShipMesh->SetCollisionEnabled(ECollisionEnabled::NoCollision);

    if (SphereMesh.Succeeded())
    {
        ShipMesh->SetStaticMesh(SphereMesh.Object);
    }

    NoseCone = CreateDefaultSubobject<UStaticMeshComponent>(TEXT("NoseCone"));
    NoseCone->SetupAttachment(ShipVisualRoot);
    NoseCone->SetRelativeLocation(FVector(38.0f, 0.0f, -1.0f));
    NoseCone->SetRelativeScale3D(FVector(0.30f, 0.24f, 0.18f));
    NoseCone->SetRelativeRotation(FRotator(0.0f, 90.0f, 0.0f));
    NoseCone->SetCollisionEnabled(ECollisionEnabled::NoCollision);
    if (ConeMesh.Succeeded())
    {
        NoseCone->SetStaticMesh(ConeMesh.Object);
    }

    CockpitGlow = CreateDefaultSubobject<UStaticMeshComponent>(TEXT("CockpitGlow"));
    CockpitGlow->SetupAttachment(ShipVisualRoot);
    CockpitGlow->SetRelativeLocation(FVector(5.0f, 0.0f, 26.0f));
    CockpitGlow->SetRelativeScale3D(FVector(0.26f, 0.32f, 0.16f));
    CockpitGlow->SetCollisionEnabled(ECollisionEnabled::NoCollision);
    if (SphereMesh.Succeeded())
    {
        CockpitGlow->SetStaticMesh(SphereMesh.Object);
    }

    PortWing = CreateDefaultSubobject<UStaticMeshComponent>(TEXT("PortWing"));
    PortWing->SetupAttachment(ShipVisualRoot);
    PortWing->SetRelativeLocation(FVector(-10.0f, -36.0f, -6.0f));
    PortWing->SetRelativeScale3D(FVector(0.34f, 0.16f, 0.055f));
    PortWing->SetRelativeRotation(FRotator(0.0f, 0.0f, -12.0f));
    PortWing->SetCollisionEnabled(ECollisionEnabled::NoCollision);
    if (CubeMesh.Succeeded())
    {
        PortWing->SetStaticMesh(CubeMesh.Object);
    }

    StarboardWing = CreateDefaultSubobject<UStaticMeshComponent>(TEXT("StarboardWing"));
    StarboardWing->SetupAttachment(ShipVisualRoot);
    StarboardWing->SetRelativeLocation(FVector(-10.0f, 36.0f, -6.0f));
    StarboardWing->SetRelativeScale3D(FVector(0.34f, 0.16f, 0.055f));
    StarboardWing->SetRelativeRotation(FRotator(0.0f, 0.0f, 12.0f));
    StarboardWing->SetCollisionEnabled(ECollisionEnabled::NoCollision);
    if (CubeMesh.Succeeded())
    {
        StarboardWing->SetStaticMesh(CubeMesh.Object);
    }

    TrailGlow = CreateDefaultSubobject<UStaticMeshComponent>(TEXT("TrailGlow"));
    TrailGlow->SetupAttachment(ShipVisualRoot);
    TrailGlow->SetRelativeLocation(FVector(-58.0f, 0.0f, -2.0f));
    TrailGlow->SetRelativeScale3D(FVector(0.38f, 0.12f, 0.12f));
    TrailGlow->SetRelativeRotation(FRotator(0.0f, -90.0f, 0.0f));
    TrailGlow->SetCollisionEnabled(ECollisionEnabled::NoCollision);
    if (ConeMesh.Succeeded())
    {
        TrailGlow->SetStaticMesh(ConeMesh.Object);
    }

    PortEngineGlow = CreateDefaultSubobject<UStaticMeshComponent>(TEXT("PortEngineGlow"));
    PortEngineGlow->SetupAttachment(ShipVisualRoot);
    PortEngineGlow->SetRelativeLocation(FVector(-38.0f, -18.0f, -6.0f));
    PortEngineGlow->SetRelativeScale3D(FVector(0.10f, 0.10f, 0.08f));
    PortEngineGlow->SetCollisionEnabled(ECollisionEnabled::NoCollision);
    if (SphereMesh.Succeeded())
    {
        PortEngineGlow->SetStaticMesh(SphereMesh.Object);
    }

    StarboardEngineGlow = CreateDefaultSubobject<UStaticMeshComponent>(TEXT("StarboardEngineGlow"));
    StarboardEngineGlow->SetupAttachment(ShipVisualRoot);
    StarboardEngineGlow->SetRelativeLocation(FVector(-38.0f, 18.0f, -6.0f));
    StarboardEngineGlow->SetRelativeScale3D(FVector(0.10f, 0.10f, 0.08f));
    StarboardEngineGlow->SetCollisionEnabled(ECollisionEnabled::NoCollision);
    if (SphereMesh.Succeeded())
    {
        StarboardEngineGlow->SetStaticMesh(SphereMesh.Object);
    }

    ScannerDish = CreateDefaultSubobject<UStaticMeshComponent>(TEXT("ScannerDish"));
    ScannerDish->SetupAttachment(ShipVisualRoot);
    ScannerDish->SetRelativeLocation(FVector(45.0f, 0.0f, 8.0f));
    ScannerDish->SetRelativeScale3D(FVector(0.06f, 0.18f, 0.18f));
    ScannerDish->SetRelativeRotation(FRotator(0.0f, 90.0f, 0.0f));
    ScannerDish->SetCollisionEnabled(ECollisionEnabled::NoCollision);
    if (SphereMesh.Succeeded())
    {
        ScannerDish->SetStaticMesh(SphereMesh.Object);
    }

    ScannerEmitter = CreateDefaultSubobject<UStaticMeshComponent>(TEXT("ScannerEmitter"));
    ScannerEmitter->SetupAttachment(ShipVisualRoot);
    ScannerEmitter->SetRelativeLocation(FVector(53.0f, 0.0f, 8.0f));
    ScannerEmitter->SetRelativeScale3D(FVector(0.105f, 0.105f, 0.105f));
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
    if (CubeMesh.Succeeded())
    {
        ScannerBeam->SetStaticMesh(CubeMesh.Object);
    }

    ScannerBeamHalo = CreateDefaultSubobject<UStaticMeshComponent>(TEXT("ScannerBeamHalo"));
    ScannerBeamHalo->SetupAttachment(ShipVisualRoot);
    ScannerBeamHalo->SetRelativeLocation(FVector(138.0f, 0.0f, 4.0f));
    ScannerBeamHalo->SetRelativeScale3D(FVector(1.05f, 0.16f, 0.16f));
    ScannerBeamHalo->SetRelativeRotation(FRotator(0.0f, -90.0f, 0.0f));
    ScannerBeamHalo->SetCollisionEnabled(ECollisionEnabled::NoCollision);
    ScannerBeamHalo->SetVisibility(false);
    ScannerBeamHalo->SetHiddenInGame(true);
    if (CubeMesh.Succeeded())
    {
        ScannerBeamHalo->SetStaticMesh(CubeMesh.Object);
    }

    Camera = CreateDefaultSubobject<UCameraComponent>(TEXT("Camera"));
    Camera->SetupAttachment(Root);
    Camera->SetRelativeLocation(FVector(-560.0f, -940.0f, 800.0f));
    Camera->SetRelativeRotation(FRotator(-38.0f, 0.0f, 0.0f));
    Camera->SetUsingAbsoluteLocation(true);
    Camera->SetUsingAbsoluteRotation(true);
    Camera->SetFieldOfView(62.0f);
    Camera->SetProjectionMode(ECameraProjectionMode::Orthographic);
    Camera->SetOrthoWidth(960.0f);

    BackdropQuad = CreateDefaultSubobject<UStaticMeshComponent>(TEXT("BackdropQuad"));
    BackdropQuad->SetupAttachment(Camera);
    BackdropQuad->SetRelativeLocation(FVector(2600.0f, 0.0f, 0.0f));
    BackdropQuad->SetRelativeRotation(FRotator(90.0f, 0.0f, 0.0f));
    BackdropQuad->SetRelativeScale3D(FVector(42.0f, 24.0f, 1.0f));
    BackdropQuad->SetCollisionEnabled(ECollisionEnabled::NoCollision);
    BackdropQuad->SetCastShadow(false);
    BackdropQuad->SetRenderInMainPass(false);
    BackdropQuad->SetVisibility(false);
    BackdropQuad->SetHiddenInGame(true);
    if (BackdropQuadMesh.Succeeded())
    {
        BackdropQuad->SetStaticMesh(BackdropQuadMesh.Object);
    }
    else if (PlaneMesh.Succeeded())
    {
        BackdropQuad->SetStaticMesh(PlaneMesh.Object);
    }
    if (BackdropMaterialAsset.Succeeded())
    {
        BackdropQuad->SetMaterial(0, BackdropMaterialAsset.Object);
    }

    Movement = CreateDefaultSubobject<UFloatingPawnMovement>(TEXT("Movement"));
    Movement->MaxSpeed = 650.0f;
    AutoPossessPlayer = EAutoReceiveInput::Player0;

    BodyMaterial = ShipMesh->CreateDynamicMaterialInstance(0, ShipMaterialTemplate);
    NoseMaterial = NoseCone->CreateDynamicMaterialInstance(0, ShipMaterialTemplate);
    GlowMaterial = CockpitGlow->CreateDynamicMaterialInstance(0, ShipMaterialTemplate);
    AccentMaterial = PortWing->CreateDynamicMaterialInstance(0, ShipMaterialTemplate);
    if (AccentMaterial)
    {
        StarboardWing->SetMaterial(0, AccentMaterial);
    }
    TrailMaterial = TrailGlow->CreateDynamicMaterialInstance(0, ShipMaterialTemplate);
    EngineGlowMaterial = PortEngineGlow->CreateDynamicMaterialInstance(0, ShipMaterialTemplate);
    if (EngineGlowMaterial)
    {
        StarboardEngineGlow->SetMaterial(0, EngineGlowMaterial);
    }
    ScannerDishMaterial = ScannerDish->CreateDynamicMaterialInstance(0, ShipMaterialTemplate);
    ScannerMaterial = ScannerEmitter->CreateDynamicMaterialInstance(0, ShipMaterialTemplate);
    ScannerBeamMaterial = ScannerBeam->CreateDynamicMaterialInstance(0, ScannerBeamMaterialTemplate);
    ScannerBeamHaloMaterial = ScannerBeamHalo->CreateDynamicMaterialInstance(0, ScannerBeamMaterialTemplate);
    if (ScannerMaterial && !ScannerBeamMaterial)
    {
        ScannerBeam->SetMaterial(0, ScannerMaterial);
    }
    if (ScannerMaterial && !ScannerBeamHaloMaterial)
    {
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

void AAstroPlayerPawn::SetCameraCompositionProfile(const EAstroCameraCompositionProfile NewProfile)
{
    switch (NewProfile)
    {
    case EAstroCameraCompositionProfile::Home:
    case EAstroCameraCompositionProfile::Launch:
        SetCameraPresentationProfile(EAstroCameraPresentationProfile::Home);
        break;
    case EAstroCameraCompositionProfile::Atlas:
        SetCameraPresentationProfile(EAstroCameraPresentationProfile::Atlas);
        break;
    case EAstroCameraCompositionProfile::ScanFocus:
        SetCameraPresentationProfile(EAstroCameraPresentationProfile::Scan);
        break;
    case EAstroCameraCompositionProfile::DiscoveryHold:
    case EAstroCameraCompositionProfile::StampHold:
        SetCameraPresentationProfile(EAstroCameraPresentationProfile::Stable);
        break;
    case EAstroCameraCompositionProfile::MissionFocus:
    default:
        SetCameraPresentationProfile(EAstroCameraPresentationProfile::Mission);
        break;
    }
}

void AAstroPlayerPawn::SetScannerTarget(const FVector& TargetLocation)
{
    ScannerTargetLocation = TargetLocation;
    bHasScannerTargetLocation = true;
    SetCameraFocusTarget(TargetLocation);
    SetScannerActive(true);
    TriggerScannerPulse(1.0f);
}

void AAstroPlayerPawn::SetScannerActive(const bool bActive)
{
    const bool bWasActive = bScannerActive;
    bScannerActive = bActive;
    if (bScannerActive)
    {
        if (!bWasActive)
        {
            ScannerSequenceTime = 0.0f;
        }
        ScannerActiveTimeRemaining = FMath::Max(ScannerActiveTimeRemaining, 2.3f);
        TriggerScannerPulse(0.65f);
    }
    else
    {
        ScannerSequenceTime = 0.0f;
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

    const float NewOrthoWidth = FMath::FInterpTo(Camera->OrthoWidth, Settings.OrthoWidth, DeltaSeconds, Settings.CameraInterpSpeed);

    Camera->SetWorldLocation(NewCameraLocation);
    Camera->SetWorldRotation(NewCameraRotation);
    Camera->SetProjectionMode(ECameraProjectionMode::Orthographic);
    Camera->SetFieldOfView(NewFieldOfView);
    Camera->SetOrthoWidth(NewOrthoWidth);
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
        ScannerSequenceTime += DeltaSeconds;
        ScannerActiveTimeRemaining -= DeltaSeconds;
        if (ScannerActiveTimeRemaining <= 0.0f)
        {
            ScannerActiveTimeRemaining = 0.0f;
            ScannerSequenceTime = 0.0f;
            bScannerActive = false;
        }
    }
    else
    {
        ScannerSequenceTime = 0.0f;
    }

    ScannerPulse = FMath::FInterpTo(ScannerPulse, 0.0f, DeltaSeconds, ScannerPulseDecaySpeed);
    const float ScannerAlpha = FMath::Clamp((bScannerActive ? 0.76f : 0.0f) + ScannerPulse, 0.0f, 1.0f);
    const float ScannerTravelAlpha = bScannerActive ? FMath::Clamp(ScannerSequenceTime / 0.72f, 0.0f, 1.0f) : 0.0f;
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
        const float EmitterScale = 0.105f + FeedbackAlpha * 0.070f;
        ScannerEmitter->SetRelativeScale3D(FVector(EmitterScale));
    }

    if (ScannerBeam)
    {
        const bool bShowBeam = ScannerAlpha > 0.05f;
        ScannerBeam->SetVisibility(bShowBeam);
        ScannerBeam->SetHiddenInGame(!bShowBeam);
        FVector BeamLocation(118.0f + ScannerAlpha * 28.0f, 0.0f, 4.0f);
        FVector BeamScale(0.64f + ScannerAlpha * 0.36f, 0.01f + ScannerAlpha * 0.01f, 0.01f + ScannerAlpha * 0.01f);
        FRotator BeamRotation = FRotator::ZeroRotator;
        if (bHasScannerTargetLocation && ScannerEmitter)
        {
            const FVector LocalTarget = ShipVisualRoot->GetComponentTransform().InverseTransformPosition(ScannerTargetLocation);
            const float BeamLength = FMath::Clamp(LocalTarget.Size(), 90.0f, 760.0f);
            const FVector BeamDirection = LocalTarget.GetSafeNormal(UE_SMALL_NUMBER, FVector::ForwardVector);
            const float VisibleBeamLength = BeamLength * FMath::Lerp(0.12f, 1.0f, ScannerTravelAlpha);
            BeamLocation = BeamDirection * (46.0f + VisibleBeamLength * 0.5f) + FVector(0.0f, 0.0f, 4.0f);
            BeamRotation = BeamDirection.Rotation();
            BeamScale = FVector((VisibleBeamLength / 100.0f) * FMath::Lerp(0.75f, 1.0f, ScannerAlpha), 0.009f + ScannerAlpha * 0.01f, 0.009f + ScannerAlpha * 0.01f);
        }
        ScannerBeam->SetRelativeLocation(BeamLocation);
        ScannerBeam->SetRelativeRotation(BeamRotation);
        ScannerBeam->SetRelativeScale3D(BeamScale);
    }

    if (ScannerBeamHalo)
    {
        ScannerBeamHalo->SetVisibility(false);
        ScannerBeamHalo->SetHiddenInGame(true);
    }

    ApplyMaterialColor(BodyMaterial, FLinearColor(0.84f, 0.94f, 1.0f), 0.50f + NavigationPulse * 0.35f);
    ApplyMaterialColor(NoseMaterial, FLinearColor(1.0f, 0.88f, 0.34f), 1.04f + NavigationPulse * 0.7f);
    ApplyMaterialColor(GlowMaterial, FLinearColor(0.36f, 1.0f, 0.92f), 1.72f + NavigationPulse * 1.55f);
    ApplyMaterialColor(AccentMaterial, FLinearColor(1.0f, 0.80f, 0.22f), 1.18f + NavigationPulse * 1.1f);
    ApplyMaterialColor(TrailMaterial, FLinearColor(0.18f, 0.86f, 1.0f), 0.48f + SmoothedSpeedAlpha * 1.2f + NavigationPulse * 0.45f);
    ApplyMaterialColor(EngineGlowMaterial, FLinearColor(0.18f, 0.86f, 1.0f), 1.15f + SmoothedSpeedAlpha * 1.2f + ScannerAlpha * 0.55f);
    ApplyMaterialColor(ScannerDishMaterial, FLinearColor(0.64f, 0.92f, 1.0f), 0.72f + ScannerAlpha * 0.65f);
    ApplyMaterialColor(ScannerMaterial, FLinearColor(0.36f, 1.0f, 0.72f), 0.75f + ScannerAlpha * 1.05f + NavigationPulse * 0.3f);
    ApplyMaterialColor(ScannerBeamMaterial, FLinearColor(0.22f, 1.0f, 0.76f, 0.36f + ScannerAlpha * 0.18f), 0.06f + ScannerAlpha * 0.16f);
    ApplyMaterialColor(ScannerBeamHaloMaterial, FLinearColor(0.36f, 1.0f, 0.82f, 0.0f), 0.0f);
}

void AAstroPlayerPawn::ApplyShipMaterials()
{
    ApplyMaterialColor(BodyMaterial, FLinearColor(0.84f, 0.94f, 1.0f), 0.50f);
    ApplyMaterialColor(NoseMaterial, FLinearColor(1.0f, 0.88f, 0.34f), 1.04f);
    ApplyMaterialColor(GlowMaterial, FLinearColor(0.36f, 1.0f, 0.92f), 1.72f);
    ApplyMaterialColor(AccentMaterial, FLinearColor(1.0f, 0.80f, 0.22f), 1.18f);
    ApplyMaterialColor(TrailMaterial, FLinearColor(0.18f, 0.86f, 1.0f), 0.5f);
    ApplyMaterialColor(EngineGlowMaterial, FLinearColor(0.18f, 0.86f, 1.0f), 1.15f);
    ApplyMaterialColor(ScannerDishMaterial, FLinearColor(0.64f, 0.92f, 1.0f), 0.72f);
    ApplyMaterialColor(ScannerMaterial, FLinearColor(0.36f, 1.0f, 0.72f), 0.78f);
    ApplyMaterialColor(ScannerBeamMaterial, FLinearColor(0.22f, 1.0f, 0.76f, 0.38f), 0.08f);
    ApplyMaterialColor(ScannerBeamHaloMaterial, FLinearColor(0.36f, 1.0f, 0.82f, 0.0f), 0.0f);
}
