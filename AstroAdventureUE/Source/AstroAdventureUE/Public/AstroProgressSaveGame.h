#pragma once

#include "CoreMinimal.h"
#include "GameFramework/SaveGame.h"
#include "AstroLearningTypes.h"
#include "AstroProgressSaveGame.generated.h"

UCLASS()
class ASTROADVENTUREUE_API UAstroProgressSaveGame : public USaveGame
{
    GENERATED_BODY()

public:
    UPROPERTY(VisibleAnywhere, BlueprintReadOnly, Category = "Astro Adventure")
    FString SaveVersion = TEXT("0.1.0");

    UPROPERTY(VisibleAnywhere, BlueprintReadOnly, Category = "Astro Adventure")
    FName MissionId = TEXT("M0_DeploymentProof");

    UPROPERTY(VisibleAnywhere, BlueprintReadOnly, Category = "Astro Adventure")
    EAstroAgeBand AgeBand = EAstroAgeBand::Ages7To9;

    UPROPERTY(VisibleAnywhere, BlueprintReadOnly, Category = "Astro Adventure")
    TMap<FName, FAstroDestinationProgress> DestinationProgress;
};
