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
    Mission UMETA(DisplayName = "Mission"),
    Atlas UMETA(DisplayName = "Atlas"),
    Scan UMETA(DisplayName = "Scan"),
    Stable UMETA(DisplayName = "Stable")
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
    UStaticMeshComponent* CockpitGlow;

    UPROPERTY(VisibleAnywhere, BlueprintReadOnly, Category = "Astro Adventure")
    UStaticMeshComponent* PortWing;

    UPROPERTY(VisibleAnywhere, BlueprintReadOnly, Category = "Astro Adventure")
    UStaticMeshComponent* StarboardWing;

    UPROPERTY(VisibleAnywhere, BlueprintReadOnly, Category = "Astro Adventure")
    UStaticMeshComponent* TrailGlow;

    UPROPERTY(VisibleAnywhere, BlueprintReadOnly, Category = "Astro Adventure")
    UStaticMeshComponent* ScannerEmitter;

    UPROPERTY(VisibleAnywhere, BlueprintReadOnly, Category = "Astro Adventure")
    UStaticMeshComponent* ScannerBeam;

    UPROPERTY(VisibleAnywhere, BlueprintReadOnly, Category = "Astro Adventure")
    UCameraComponent* Camera;

    UPROPERTY(VisibleAnywhere, BlueprintReadOnly, Category = "Astro Adventure")
    UFloatingPawnMovement* Movement;

    virtual void SetupPlayerInputComponent(UInputComponent* PlayerInputComponent) override;
    virtual void Tick(float DeltaSeconds) override;

    void MoveForward(float Value);
    void MoveRight(float Value);
    void SetTravelTarget(const FVector& TargetLocation);
    void SetCameraFocusTarget(const FVector& TargetLocation);
    void SetCameraPresentationProfile(EAstroCameraPresentationProfile NewProfile);
    void SetScannerActive(bool bActive);
    void TriggerScannerPulse(float PulseStrength = 1.0f);
    void SetShipAccentColor(const FLinearColor& NewColor);

private:
    void UpdateCameraPresentation(float DeltaSeconds);
    void UpdateShipPresentation(float DeltaSeconds);
    void ApplyShipMaterials();

    FVector TravelTarget = FVector::ZeroVector;
    FVector CameraFocusTarget = FVector::ZeroVector;
    bool bHasTravelTarget = false;
    bool bHasCameraFocusTarget = false;

    EAstroCameraPresentationProfile CameraPresentationProfile = EAstroCameraPresentationProfile::Mission;
    FLinearColor ShipAccentColor = FLinearColor(0.18f, 0.84f, 1.0f);
    float ShipBobTime = 0.0f;
    float ScannerPulse = 0.0f;
    float SmoothedSpeedAlpha = 0.0f;
    FVector LastActorLocation = FVector::ZeroVector;
    bool bScannerActive = false;
    bool bHasLastActorLocation = false;

    UPROPERTY(Transient)
    UMaterialInstanceDynamic* BodyMaterial = nullptr;

    UPROPERTY(Transient)
    UMaterialInstanceDynamic* AccentMaterial = nullptr;

    UPROPERTY(Transient)
    UMaterialInstanceDynamic* GlowMaterial = nullptr;

    UPROPERTY(Transient)
    UMaterialInstanceDynamic* TrailMaterial = nullptr;

    UPROPERTY(Transient)
    UMaterialInstanceDynamic* ScannerMaterial = nullptr;
};
