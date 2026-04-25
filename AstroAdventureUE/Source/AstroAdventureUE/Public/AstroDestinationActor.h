#pragma once

#include "CoreMinimal.h"
#include "GameFramework/Actor.h"
#include "AstroLearningTypes.h"
#include "AstroDestinationActor.generated.h"

class UStaticMeshComponent;
class UTextRenderComponent;
class UMaterialInstanceDynamic;

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
    UTextRenderComponent* Label;

    UPROPERTY(EditAnywhere, BlueprintReadWrite, Category = "Astro Adventure")
    FName DestinationId;

    UPROPERTY(EditAnywhere, BlueprintReadWrite, Category = "Astro Adventure")
    FText DisplayName;

    void Configure(const FAstroDestinationLesson& Lesson, const FLinearColor& Color, float VisualScale);
    void SetFocused(bool bFocused);
    void SetDiscovered(bool bDiscovered);

private:
    FLinearColor BaseColor = FLinearColor::White;
    bool bIsDiscovered = false;
    float BaseVisualScale = 1.0f;

    void ApplyColor(UStaticMeshComponent* Mesh, const FLinearColor& Color, float EmissiveStrength);
};
