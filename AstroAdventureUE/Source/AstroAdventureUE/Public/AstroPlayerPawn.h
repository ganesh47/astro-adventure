#pragma once

#include "CoreMinimal.h"
#include "GameFramework/Pawn.h"
#include "AstroPlayerPawn.generated.h"

class UCameraComponent;
class UFloatingPawnMovement;
class UMaterialInstanceDynamic;
class USceneComponent;
class UStaticMeshComponent;

UENUM(BlueprintType)
enum class EAstroCameraPresentationProfile : uint8
{
    Home UMETA(DisplayName = "Home"),
    Mission UMETA(DisplayName = "Mission"),
    FirstLoopTeach UMETA(DisplayName = "First Loop Teach"),
    Atlas UMETA(DisplayName = "Atlas"),
    Scan UMETA(DisplayName = "Scan"),
    Stable UMETA(DisplayName = "Stable")
};

UENUM(BlueprintType)
enum class EAstroCameraCompositionProfile : uint8
{
    Home UMETA(DisplayName = "Home"),
    Launch UMETA(DisplayName = "Launch"),
    MissionFocus UMETA(DisplayName = "Mission Focus"),
    ScanFocus UMETA(DisplayName = "Scan Focus"),
    DiscoveryHold UMETA(DisplayName = "Discovery Hold"),
    StampHold UMETA(DisplayName = "Stamp Hold"),
    Atlas UMETA(DisplayName = "Atlas")
};

UCLASS()
class ASTROADVENTUREUE_API AAstroPlayerPawn : public APawn
{
    GENERATED_BODY()

public:
    AAstroPlayerPawn();

    UPROPERTY(VisibleAnywhere, BlueprintReadOnly, Category = "Astro Adventure")
    USceneComponent* Root;

    UPROPERTY(VisibleAnywhere, BlueprintReadOnly, Category = "Astro Adventure")
    USceneComponent* ShipVisualRoot;

    UPROPERTY(VisibleAnywhere, BlueprintReadOnly, Category = "Astro Adventure")
    UStaticMeshComponent* ShipMesh;

    UPROPERTY(VisibleAnywhere, BlueprintReadOnly, Category = "Astro Adventure")
    UStaticMeshComponent* NoseCone;

    UPROPERTY(VisibleAnywhere, BlueprintReadOnly, Category = "Astro Adventure")
    UStaticMeshComponent* CockpitGlow;

    UPROPERTY(VisibleAnywhere, BlueprintReadOnly, Category = "Astro Adventure")
    UStaticMeshComponent* PortWing;

    UPROPERTY(VisibleAnywhere, BlueprintReadOnly, Category = "Astro Adventure")
    UStaticMeshComponent* StarboardWing;

    UPROPERTY(VisibleAnywhere, BlueprintReadOnly, Category = "Astro Adventure")
    UStaticMeshComponent* TrailGlow;

    UPROPERTY(VisibleAnywhere, BlueprintReadOnly, Category = "Astro Adventure")
    UStaticMeshComponent* PortEngineGlow;

    UPROPERTY(VisibleAnywhere, BlueprintReadOnly, Category = "Astro Adventure")
    UStaticMeshComponent* StarboardEngineGlow;

    UPROPERTY(VisibleAnywhere, BlueprintReadOnly, Category = "Astro Adventure")
    UStaticMeshComponent* ScannerDish;

    UPROPERTY(VisibleAnywhere, BlueprintReadOnly, Category = "Astro Adventure")
    UStaticMeshComponent* ScannerEmitter;

    UPROPERTY(VisibleAnywhere, BlueprintReadOnly, Category = "Astro Adventure")
    UStaticMeshComponent* ScannerBeam;

    UPROPERTY(VisibleAnywhere, BlueprintReadOnly, Category = "Astro Adventure")
    UStaticMeshComponent* ScannerBeamHalo;

    UPROPERTY(VisibleAnywhere, BlueprintReadOnly, Category = "Astro Adventure")
    UCameraComponent* Camera;

    UPROPERTY(VisibleAnywhere, BlueprintReadOnly, Category = "Astro Adventure")
    UStaticMeshComponent* BackdropQuad;

    UPROPERTY(VisibleAnywhere, BlueprintReadOnly, Category = "Astro Adventure")
    UFloatingPawnMovement* Movement;

    virtual void SetupPlayerInputComponent(UInputComponent* PlayerInputComponent) override;
    virtual void Tick(float DeltaSeconds) override;

    void MoveForward(float Value);
    void MoveRight(float Value);
    void SetTravelTarget(const FVector& TargetLocation);
    void SetCameraFocusTarget(const FVector& TargetLocation);
    void SetCameraPresentationProfile(EAstroCameraPresentationProfile NewProfile);
    void SetCameraCompositionProfile(EAstroCameraCompositionProfile NewProfile);
    void SetScannerTarget(const FVector& TargetLocation);
    void SetScannerActive(bool bActive);
    void TriggerScannerPulse(float PulseStrength = 1.0f);
    void TriggerNavigationFeedback(float Direction);
    void SetShipAccentColor(const FLinearColor& NewColor);

private:
    void UpdateCameraPresentation(float DeltaSeconds);
    void UpdateShipPresentation(float DeltaSeconds);
    void ApplyShipMaterials();

    FVector TravelTarget = FVector::ZeroVector;
    FVector CameraFocusTarget = FVector::ZeroVector;
    FVector SmoothedCameraFocusTarget = FVector::ZeroVector;
    bool bHasTravelTarget = false;
    bool bHasCameraFocusTarget = false;
    bool bHasSmoothedCameraFocusTarget = false;

    EAstroCameraPresentationProfile CameraPresentationProfile = EAstroCameraPresentationProfile::Mission;
    FLinearColor ShipAccentColor = FLinearColor(0.18f, 0.84f, 1.0f);
    float ShipBobTime = 0.0f;
    float ScannerPulse = 0.0f;
    float ScannerSequenceTime = 0.0f;
    float ScannerActiveTimeRemaining = 0.0f;
    float SmoothedSpeedAlpha = 0.0f;
    float NavigationPulse = 0.0f;
    float NavigationPulseDirection = 0.0f;
    FVector LastActorLocation = FVector::ZeroVector;
    bool bScannerActive = false;
    bool bHasLastActorLocation = false;

    UPROPERTY(Transient)
    UMaterialInstanceDynamic* BodyMaterial = nullptr;

    UPROPERTY(Transient)
    UMaterialInstanceDynamic* NoseMaterial = nullptr;

    UPROPERTY(Transient)
    UMaterialInstanceDynamic* AccentMaterial = nullptr;

    UPROPERTY(Transient)
    UMaterialInstanceDynamic* GlowMaterial = nullptr;

    UPROPERTY(Transient)
    UMaterialInstanceDynamic* EngineGlowMaterial = nullptr;

    UPROPERTY(Transient)
    UMaterialInstanceDynamic* ScannerDishMaterial = nullptr;

    UPROPERTY(Transient)
    UMaterialInstanceDynamic* TrailMaterial = nullptr;

    UPROPERTY(Transient)
    UMaterialInstanceDynamic* ScannerMaterial = nullptr;

    UPROPERTY(Transient)
    UMaterialInstanceDynamic* ScannerBeamMaterial = nullptr;

    UPROPERTY(Transient)
    UMaterialInstanceDynamic* ScannerBeamHaloMaterial = nullptr;

    FVector ScannerTargetLocation = FVector::ZeroVector;
    bool bHasScannerTargetLocation = false;
};
