#pragma once

#include "CoreMinimal.h"
#include "GameFramework/GameModeBase.h"
#include "TimerManager.h"
#include "AstroLearningTypes.h"
#include "AstroAdventureGameModeBase.generated.h"

class AAstroDestinationActor;
class AAstroPlayerPawn;
class ADirectionalLight;
class APointLight;
class APostProcessVolume;
class ASkyLight;
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

    void NotifyHomeInputReceived();
    bool HandlePointerConfirm(float ScreenX, float ScreenY, float ViewportWidth, float ViewportHeight);

    FString GetHudStatusLine() const;
    FString GetHudPrimaryLine() const;
    TArray<FString> GetHudDetailLines() const;
    bool IsScanEffectActive() const;
    bool IsStampEffectActive() const;
    EAstroMissionScreen GetCurrentScreen() const { return CurrentScreen; }

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
    TArray<AStaticMeshActor*> RouteMarkerActors;

    TArray<int32> RouteMarkerOwnerIndices;

    UPROPERTY()
    TArray<AStaticMeshActor*> BackdropActors;

    UPROPERTY()
    AStaticMeshActor* SunTeachingGlowActor = nullptr;

    UPROPERTY()
    AStaticMeshActor* SunTeachingBodyActor = nullptr;

    UPROPERTY()
    AStaticMeshActor* SunTeachingCoreActor = nullptr;

    UPROPERTY()
    TArray<AStaticMeshActor*> SunTeachingRayActors;

    UPROPERTY()
    TArray<AStaticMeshActor*> FirstLoopTeachingTrailActors;

    UPROPERTY()
    ADirectionalLight* KeyLightActor = nullptr;

    UPROPERTY()
    APointLight* SunLightActor = nullptr;

    UPROPERTY()
    APointLight* PlayerFillLightActor = nullptr;

    UPROPERTY()
    ASkyLight* SkyLightActor = nullptr;

    UPROPERTY()
    APostProcessVolume* LookDevVolume = nullptr;

    int32 NebulaBackdropStartIndex = INDEX_NONE;
    TArray<FVector> DestinationRoutePositions;

    UPROPERTY()
    UAstroProgressSaveGame* ProgressSave = nullptr;

    EAstroMissionScreen CurrentScreen = EAstroMissionScreen::Home;
    EAstroMissionScreen PreviousScreen = EAstroMissionScreen::Navigation;
    int32 HomeMenuIndex = 0;
    int32 FocusedDestinationIndex = 0;
    int32 FocusedQuizChoiceIndex = 0;
    int32 PauseMenuIndex = 0;
    int32 MissionCompleteMenuIndex = 0;
    int32 AgeSelectIndex = 1;
    float LastScanTime = -100.0f;
    float LastStampTime = -100.0f;
    FName PendingScanDestinationId;
    FTimerHandle ScanRevealTimerHandle;
    bool bShowingHint = false;
    bool bLastAnswerCorrect = false;
    FString LastFeedback;

    void BuildLessons();
    void AddLesson(const TCHAR* Id, const TCHAR* Name, const TCHAR* QuickFact, const TCHAR* WowFact, const TCHAR* VisualClue, const TCHAR* Ages4To6, const TCHAR* Ages7To9, const TCHAR* Ages10To12, const TCHAR* DeepDive, const TCHAR* Compare, const TCHAR* Glossary, const TCHAR* SourceUrl, const TCHAR* QuizPrompt, const TCHAR* CorrectId, const TCHAR* CorrectText, const TCHAR* WrongOneId, const TCHAR* WrongOneText, const TCHAR* WrongTwoId, const TCHAR* WrongTwoText, const TCHAR* CorrectFeedback, const TCHAR* RetryFeedback, const TCHAR* Hint, const FLinearColor& Color, float MapScale, bool bRequired);
    void SpawnRuntimeScene();
    void SpawnRouteSegment(int32 OwnerIndex, const FVector& Start, const FVector& End, const FLinearColor& Color);
    void SpawnOrbitMarker(int32 OwnerIndex, const FVector& Center, float Radius, const FLinearColor& Color);
    void SpawnAsteroidBelt(int32 OwnerIndex, const FVector& Center);
    void SpawnBackdrop();
    void SpawnSunTeachingVisual();
    void UpdateSunTeachingVisual();
    void SpawnFirstLoopTeachingTrail();
    void UpdateFirstLoopTeachingTrail();
    void ApplyFirstLoopStaging();
    void ApplyLightingLook();
    void RefreshScenePresentation();
    void RefreshPlayerPresentation();
    bool ShouldShowDestinationInCurrentView(int32 DestinationIndex) const;
    void LoadProgress();
    void SaveProgress() const;
    void UpdateDestinationFocus();
    void SetMissionScreen(EAstroMissionScreen NewScreen);
    void MarkScanned(const FName DestinationId);
    void CompleteQuiz(const FName DestinationId, bool bAnsweredCorrectly);
    bool HasStampForDestination(FName DestinationId) const;
    void TriggerScanFeedback(const FAstroDestinationLesson& Lesson);
    void FinishScanReveal();
    void TriggerStampFeedback(const FAstroDestinationLesson& Lesson);
    void SelectAgeBand(int32 Index);
    void ExecutePauseSelection();
    void ExecuteHomeSelection();
    void ExecuteMissionCompleteSelection();
    void ClearPassportProgress();
    bool HasAnyProgress() const;
    bool IsFirstStopLocked() const;
    bool IsMissionPlayScreen() const;
    int32 CountCompletedStops() const;
    bool IsMissionComplete() const;
    bool AdvanceToNextRouteStop();
    const FAstroDestinationLesson* GetFocusedLesson() const;
    FAstroDestinationProgress& GetMutableProgress(FName DestinationId);
};
