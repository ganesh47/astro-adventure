#pragma once

#include "CoreMinimal.h"
#include "GameFramework/GameModeBase.h"
#include "AstroLearningTypes.h"
#include "AstroAdventureGameModeBase.generated.h"

class AAstroDestinationActor;
class UAstroProgressSaveGame;

UCLASS()
class ASTROADVENTUREUE_API AAstroAdventureGameModeBase : public AGameModeBase
{
    GENERATED_BODY()

public:
    AAstroAdventureGameModeBase();
    virtual void BeginPlay() override;

    UPROPERTY(EditDefaultsOnly, BlueprintReadOnly, Category = "Astro Adventure")
    FName MissionId;

    UPROPERTY(EditDefaultsOnly, BlueprintReadOnly, Category = "Astro Adventure")
    EAstroAgeBand ActiveAgeBand = EAstroAgeBand::Ages7To9;

    UFUNCTION(BlueprintCallable, Category = "Astro Adventure")
    void FocusNextDestination();

    UFUNCTION(BlueprintCallable, Category = "Astro Adventure")
    void FocusPreviousDestination();

    UFUNCTION(BlueprintCallable, Category = "Astro Adventure")
    void Confirm();

    UFUNCTION(BlueprintCallable, Category = "Astro Adventure")
    void Back();

    UFUNCTION(BlueprintCallable, Category = "Astro Adventure")
    void RequestHint();

    UFUNCTION(BlueprintCallable, Category = "Astro Adventure")
    void MoveQuizFocus(int32 Direction);

    UFUNCTION(BlueprintCallable, Category = "Astro Adventure")
    void SubmitAnswer(int32 ChoiceIndex);

    FString GetHudStatusLine() const;
    FString GetHudPrimaryLine() const;
    TArray<FString> GetHudDetailLines() const;

private:
    static constexpr int32 SaveUserIndex = 0;
    static const TCHAR* SaveSlotName;

    UPROPERTY()
    TArray<FAstroDestinationLesson> Lessons;

    UPROPERTY()
    TArray<AAstroDestinationActor*> DestinationActors;

    UPROPERTY()
    UAstroProgressSaveGame* ProgressSave = nullptr;

    EAstroMissionScreen CurrentScreen = EAstroMissionScreen::MissionPrompt;
    int32 FocusedDestinationIndex = 0;
    int32 FocusedQuizChoiceIndex = 0;
    bool bShowingHint = false;
    bool bLastAnswerCorrect = false;
    FString LastFeedback;

    void BuildLessons();
    void SpawnRuntimeScene();
    void LoadProgress();
    void SaveProgress() const;
    void UpdateDestinationFocus();
    void MarkScanned(const FName DestinationId);
    void CompleteQuiz(const FName DestinationId, bool bAnsweredCorrectly);
    bool IsMissionComplete() const;
    const FAstroDestinationLesson* GetFocusedLesson() const;
    FAstroDestinationProgress& GetMutableProgress(FName DestinationId);
};
