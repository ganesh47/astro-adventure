#pragma once

#include "CoreMinimal.h"
#include "GameFramework/GameModeBase.h"
#include "AstroLearningTypes.h"
#include "AstroAdventureGameModeBase.generated.h"

class AAstroDestinationActor;
class AAstroPlayerPawn;
class UAstroProgressSaveGame;
class AStaticMeshActor;

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
    void ToggleDeepDive();

    UFUNCTION(BlueprintCallable, Category = "Astro Adventure")
    void TogglePassport();

    UFUNCTION(BlueprintCallable, Category = "Astro Adventure")
    void TogglePause();

    UFUNCTION(BlueprintCallable, Category = "Astro Adventure")
    void MoveQuizFocus(int32 Direction);

    UFUNCTION(BlueprintCallable, Category = "Astro Adventure")
    void SubmitAnswer(int32 ChoiceIndex);

    FString GetHudStatusLine() const;
    FString GetHudPrimaryLine() const;
    TArray<FString> GetHudDetailLines() const;
    bool IsScanEffectActive() const;

private:
    static constexpr int32 SaveUserIndex = 0;
    static const TCHAR* SaveSlotName;

    UPROPERTY()
    TArray<FAstroDestinationLesson> Lessons;

    UPROPERTY()
    TArray<AAstroDestinationActor*> DestinationActors;

    UPROPERTY()
    AAstroPlayerPawn* PlayerPawn = nullptr;

    UPROPERTY()
    TArray<AStaticMeshActor*> ScanBeamActors;

    UPROPERTY()
    UAstroProgressSaveGame* ProgressSave = nullptr;

    EAstroMissionScreen CurrentScreen = EAstroMissionScreen::MissionPrompt;
    EAstroMissionScreen PreviousScreen = EAstroMissionScreen::Navigation;
    int32 FocusedDestinationIndex = 0;
    int32 FocusedQuizChoiceIndex = 0;
    int32 PauseMenuIndex = 0;
    int32 AgeSelectIndex = 1;
    float LastScanTime = -100.0f;
    bool bShowingHint = false;
    bool bLastAnswerCorrect = false;
    FString LastFeedback;

    void BuildLessons();
    void AddLesson(const TCHAR* Id, const TCHAR* Name, const TCHAR* QuickFact, const TCHAR* WowFact, const TCHAR* VisualClue, const TCHAR* Ages4To6, const TCHAR* Ages7To9, const TCHAR* Ages10To12, const TCHAR* DeepDive, const TCHAR* Compare, const TCHAR* Glossary, const TCHAR* SourceUrl, const TCHAR* QuizPrompt, const TCHAR* CorrectId, const TCHAR* CorrectText, const TCHAR* WrongOneId, const TCHAR* WrongOneText, const TCHAR* WrongTwoId, const TCHAR* WrongTwoText, const TCHAR* CorrectFeedback, const TCHAR* RetryFeedback, const TCHAR* Hint, const FLinearColor& Color, float MapScale, bool bRequired);
    void SpawnRuntimeScene();
    void SpawnOrbitMarker(const FVector& Center, float Radius, const FLinearColor& Color);
    void SpawnAsteroidBelt(const FVector& Center);
    void SpawnBackdrop();
    void LoadProgress();
    void SaveProgress() const;
    void UpdateDestinationFocus();
    void MarkScanned(const FName DestinationId);
    void CompleteQuiz(const FName DestinationId, bool bAnsweredCorrectly);
    void SelectAgeBand(int32 Index);
    void ExecutePauseSelection();
    int32 CountCompletedStops() const;
    bool IsMissionComplete() const;
    const FAstroDestinationLesson* GetFocusedLesson() const;
    FAstroDestinationProgress& GetMutableProgress(FName DestinationId);
};
