#pragma once

#include "CoreMinimal.h"
#include "GameFramework/Actor.h"
#include "AstroLearningTypes.h"
#include "AstroDestinationActor.generated.h"

class UStaticMeshComponent;
class UTextRenderComponent;
class UMaterialInstanceDynamic;
class UMaterialInterface;
class UStaticMesh;

UENUM(BlueprintType)
enum class EAstroDestinationPresentationMode : uint8
{
    Mission UMETA(DisplayName = "Mission"),
    Atlas UMETA(DisplayName = "Atlas")
};

UCLASS()
class ASTROADVENTUREUE_API AAstroDestinationActor : public AActor
{
    GENERATED_BODY()

public:
    AAstroDestinationActor();

    UPROPERTY(VisibleAnywhere, BlueprintReadOnly, Category = "Astro Adventure")
    USceneComponent* Root;

    UPROPERTY(VisibleAnywhere, BlueprintReadOnly, Category = "Astro Adventure")
    UStaticMeshComponent* BodyMesh;

    UPROPERTY(VisibleAnywhere, BlueprintReadOnly, Category = "Astro Adventure")
    UStaticMeshComponent* FocusHalo;

    UPROPERTY(VisibleAnywhere, BlueprintReadOnly, Category = "Astro Adventure")
    UStaticMeshComponent* FocusBeacon;

    UPROPERTY(VisibleAnywhere, BlueprintReadOnly, Category = "Astro Adventure")
    UStaticMeshComponent* Nameplate;

    UPROPERTY(VisibleAnywhere, BlueprintReadOnly, Category = "Astro Adventure")
    UTextRenderComponent* Label;

    UPROPERTY(EditAnywhere, BlueprintReadWrite, Category = "Astro Adventure")
    FName DestinationId;

    UPROPERTY(EditAnywhere, BlueprintReadWrite, Category = "Astro Adventure")
    FText DisplayName;

    void Configure(const FAstroDestinationLesson& Lesson, const FLinearColor& Color, float VisualScale);
    void SetFocused(bool bFocused);
    void SetDiscovered(bool bDiscovered);

    UFUNCTION(BlueprintCallable, Category = "Astro Adventure")
    void SetPresentationMode(EAstroDestinationPresentationMode NewPresentationMode);

private:
    UPROPERTY(VisibleAnywhere, Category = "Astro Adventure", meta = (AllowPrivateAccess = "true"))
    TArray<UStaticMeshComponent*> MotifMeshes;

    UPROPERTY(Transient)
    UStaticMesh* SphereMeshAsset = nullptr;

    UPROPERTY(Transient)
    UStaticMesh* CylinderMeshAsset = nullptr;

    UPROPERTY(Transient)
    UStaticMesh* CubeMeshAsset = nullptr;

    UPROPERTY(Transient)
    UMaterialInterface* ColorMaterialTemplate = nullptr;

    FLinearColor BaseColor = FLinearColor::White;
    bool bIsDiscovered = false;
    bool bIsFocused = false;
    EAstroDestinationPresentationMode PresentationMode = EAstroDestinationPresentationMode::Mission;
    float BaseVisualScale = 1.0f;
    FVector BodyIdleScale = FVector::OneVector;
    FVector BodyFocusedScale = FVector::OneVector;

    UStaticMeshComponent* CreateMotifComponent(FName ComponentName, UStaticMesh* Mesh);
    void ApplyColor(UStaticMeshComponent* Mesh, const FLinearColor& Color, float EmissiveStrength);
    void ConfigureMotifs();
    void HideMotifs();
    void SetMotif(int32 Index, UStaticMesh* Mesh, const FVector& Location, const FRotator& Rotation, const FVector& Scale, const FLinearColor& Color, float EmissiveStrength = 0.0f);
    void ApplyFocusVisuals();
    void UpdateNameplateLayout();
};
