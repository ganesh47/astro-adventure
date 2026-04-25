#pragma once

#include "CoreMinimal.h"
#include "GameFramework/Pawn.h"
#include "AstroPlayerPawn.generated.h"

class UCameraComponent;
class UFloatingPawnMovement;
class UStaticMeshComponent;

UCLASS()
class ASTROADVENTUREUE_API AAstroPlayerPawn : public APawn
{
    GENERATED_BODY()

public:
    AAstroPlayerPawn();

    UPROPERTY(VisibleAnywhere, BlueprintReadOnly, Category = "Astro Adventure")
    USceneComponent* Root;

    UPROPERTY(VisibleAnywhere, BlueprintReadOnly, Category = "Astro Adventure")
    UStaticMeshComponent* ShipMesh;

    UPROPERTY(VisibleAnywhere, BlueprintReadOnly, Category = "Astro Adventure")
    UStaticMeshComponent* TrailGlow;

    UPROPERTY(VisibleAnywhere, BlueprintReadOnly, Category = "Astro Adventure")
    UCameraComponent* Camera;

    UPROPERTY(VisibleAnywhere, BlueprintReadOnly, Category = "Astro Adventure")
    UFloatingPawnMovement* Movement;

    virtual void SetupPlayerInputComponent(UInputComponent* PlayerInputComponent) override;
    virtual void Tick(float DeltaSeconds) override;

    void MoveForward(float Value);
    void MoveRight(float Value);
    void SetTravelTarget(const FVector& TargetLocation);

private:
    FVector TravelTarget = FVector::ZeroVector;
    bool bHasTravelTarget = false;
};
