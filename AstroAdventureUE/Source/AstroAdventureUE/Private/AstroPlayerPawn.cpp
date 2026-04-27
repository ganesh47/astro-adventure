#include "AstroPlayerPawn.h"

#include "Camera/CameraComponent.h"
#include "Components/StaticMeshComponent.h"
#include "GameFramework/FloatingPawnMovement.h"
#include "UObject/ConstructorHelpers.h"

namespace
{
    const FVector TravelTargetToFocusOffset(145.0f, 0.0f, -70.0f);
    const FVector CameraAnchorOffset(-260.0f, 0.0f, 620.0f);
    const FRotator CameraAnchorRotation(-34.0f, 0.0f, 0.0f);
    constexpr float TravelInterpSpeed = 2.6f;
    constexpr float RotationInterpSpeed = 5.0f;
    constexpr float CameraInterpSpeed = 4.5f;
    constexpr float TravelSnapDistance = 2.0f;
}

AAstroPlayerPawn::AAstroPlayerPawn()
{
    PrimaryActorTick.bCanEverTick = true;

    Root = CreateDefaultSubobject<USceneComponent>(TEXT("Root"));
    SetRootComponent(Root);

    ShipMesh = CreateDefaultSubobject<UStaticMeshComponent>(TEXT("ShipMesh"));
    ShipMesh->SetupAttachment(Root);
    ShipMesh->SetRelativeScale3D(FVector(0.75f, 0.75f, 0.35f));
    ShipMesh->SetRelativeRotation(FRotator(0.0f, 90.0f, 0.0f));

    static ConstructorHelpers::FObjectFinder<UStaticMesh> ConeMesh(TEXT("/Engine/BasicShapes/Cone.Cone"));
    if (ConeMesh.Succeeded())
    {
        ShipMesh->SetStaticMesh(ConeMesh.Object);
    }

    TrailGlow = CreateDefaultSubobject<UStaticMeshComponent>(TEXT("TrailGlow"));
    TrailGlow->SetupAttachment(Root);
    TrailGlow->SetRelativeLocation(FVector(-55.0f, 0.0f, 0.0f));
    TrailGlow->SetRelativeScale3D(FVector(0.55f, 0.18f, 0.18f));
    TrailGlow->SetCollisionEnabled(ECollisionEnabled::NoCollision);
    if (ConeMesh.Succeeded())
    {
        TrailGlow->SetStaticMesh(ConeMesh.Object);
    }

    Camera = CreateDefaultSubobject<UCameraComponent>(TEXT("Camera"));
    Camera->SetupAttachment(Root);
    Camera->SetRelativeLocation(FVector(-920.0f, 0.0f, 640.0f));
    Camera->SetRelativeRotation(FRotator(-38.0f, 0.0f, 0.0f));
    Camera->SetUsingAbsoluteLocation(true);
    Camera->SetUsingAbsoluteRotation(true);

    Movement = CreateDefaultSubobject<UFloatingPawnMovement>(TEXT("Movement"));
    Movement->MaxSpeed = 650.0f;
    AutoPossessPlayer = EAutoReceiveInput::Player0;
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

    if (bHasTravelTarget || bHasCameraFocusTarget)
    {
        const FVector FocusTarget = bHasCameraFocusTarget ? CameraFocusTarget : TravelTarget + TravelTargetToFocusOffset;
        const FVector DesiredCameraLocation = FocusTarget + CameraAnchorOffset;
        Camera->SetWorldLocation(FMath::VInterpTo(Camera->GetComponentLocation(), DesiredCameraLocation, DeltaSeconds, CameraInterpSpeed));
        Camera->SetWorldRotation(CameraAnchorRotation);
    }
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
