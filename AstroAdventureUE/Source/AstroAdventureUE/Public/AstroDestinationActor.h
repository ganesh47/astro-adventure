#pragma once

#include "CoreMinimal.h"
#include "GameFramework/Actor.h"
#include "AstroLearningTypes.h"
#include "AstroDestinationActor.generated.h"

class UStaticMeshComponent;
class UTextRenderComponent;
class UBillboardComponent;
class UMaterialInstanceDynamic;
class UMaterialInterface;
class UStaticMesh;

UENUM(BlueprintType)
enum class EAstroDestinationPresentationMode : uint8
{
    Home UMETA(DisplayName = "Home"),
    Mission UMETA(DisplayName = "Mission"),
    Atlas UMETA(DisplayName = "Atlas")
};

UENUM(BlueprintType)
enum class EAstroPresentationLayer : uint8
{
    Body UMETA(DisplayName = "Body"),
    Atmosphere UMETA(DisplayName = "Atmosphere"),
    Focus UMETA(DisplayName = "Focus"),
    ScanPulse UMETA(DisplayName = "Scan Pulse"),
    Label UMETA(DisplayName = "Label"),
    Route UMETA(DisplayName = "Route")
};

USTRUCT(BlueprintType)
struct FAstroDestinationVisualProfile
{
    GENERATED_BODY()

    UPROPERTY(EditAnywhere, BlueprintReadWrite, Category = "Astro Adventure")
    FString BodyMaterial;

    UPROPERTY(EditAnywhere, BlueprintReadWrite, Category = "Astro Adventure")
    FString CoronaOrAtmosphereMaterial;

    UPROPERTY(EditAnywhere, BlueprintReadWrite, Category = "Astro Adventure")
    FString FocusRingMaterial;

    UPROPERTY(EditAnywhere, BlueprintReadWrite, Category = "Astro Adventure")
    FString StampTexture;

    UPROPERTY(EditAnywhere, BlueprintReadWrite, Category = "Astro Adventure")
    FLinearColor BasePalette = FLinearColor::White;

    UPROPERTY(EditAnywhere, BlueprintReadWrite, Category = "Astro Adventure")
    FText SurfaceMotif;

    UPROPERTY(EditAnywhere, BlueprintReadWrite, Category = "Astro Adventure")
    FText SilhouetteCue;

    UPROPERTY(EditAnywhere, BlueprintReadWrite, Category = "Astro Adventure")
    float MissionScale = 1.0f;

    UPROPERTY(EditAnywhere, BlueprintReadWrite, Category = "Astro Adventure")
    float AtlasScale = 1.0f;

    UPROPERTY(EditAnywhere, BlueprintReadWrite, Category = "Astro Adventure")
    FVector LabelPlacement = FVector::ZeroVector;

    UPROPERTY(EditAnywhere, BlueprintReadWrite, Category = "Astro Adventure")
    FText ObservationCue;
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
    UStaticMeshComponent* SurfaceArt;

    UPROPERTY(VisibleAnywhere, BlueprintReadOnly, Category = "Astro Adventure")
    UStaticMeshComponent* AtmosphereArt;

    UPROPERTY(VisibleAnywhere, BlueprintReadOnly, Category = "Astro Adventure")
    UBillboardComponent* BillboardArt;

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
    void ApplyVisualProfile(const FAstroDestinationVisualProfile& VisualProfile);
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

    UPROPERTY(Transient)
    UMaterialInterface* BodyMaterialAsset = nullptr;

    UPROPERTY(Transient)
    UMaterialInterface* AtmosphereMaterialAsset = nullptr;

    UPROPERTY(Transient)
    UMaterialInterface* FocusRingMaterialAsset = nullptr;

    FLinearColor BaseColor = FLinearColor::White;
    FAstroDestinationVisualProfile CurrentVisualProfile;
    bool bIsDiscovered = false;
    bool bIsFocused = false;
    EAstroDestinationPresentationMode PresentationMode = EAstroDestinationPresentationMode::Mission;
    float BaseVisualScale = 1.0f;
    FVector BodyIdleScale = FVector::OneVector;
    FVector BodyFocusedScale = FVector::OneVector;

    UStaticMeshComponent* CreateMotifComponent(FName ComponentName, UStaticMesh* Mesh);
    void ApplyColor(UStaticMeshComponent* Mesh, const FLinearColor& Color, float EmissiveStrength);
    UMaterialInterface* LoadProfileMaterial(const FString& ProfileMaterialPath) const;
    void ApplyProfileArt();
    void ConfigureMotifs();
    void HideMotifs();
    void SetMotif(int32 Index, UStaticMesh* Mesh, const FVector& Location, const FRotator& Rotation, const FVector& Scale, const FLinearColor& Color, float EmissiveStrength = 0.0f);
    void ApplyFocusVisuals();
    void UpdateNameplateLayout();
};
