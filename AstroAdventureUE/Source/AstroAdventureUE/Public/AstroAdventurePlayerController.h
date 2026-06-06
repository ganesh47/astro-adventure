#pragma once

#include "CoreMinimal.h"
#include "GameFramework/PlayerController.h"
#include "AstroAdventurePlayerController.generated.h"

UCLASS()
class ASTROADVENTUREUE_API AAstroAdventurePlayerController : public APlayerController
{
    GENERATED_BODY()

public:
    virtual void BeginPlay() override;
    virtual void SetupInputComponent() override;
    virtual bool InputKey(const FInputKeyEventArgs& Params) override;

private:
    void ConfigureGameInputMode();
    void NotifyHomeInputIfNeeded(class AAstroAdventureGameModeBase* GameMode);
    void FocusNext();
    void FocusPrevious();
    void Confirm();
    void Back();
    void Hint();
    void MoreInfo();
    void Passport();
    void Pause();
    void PointerConfirm();
    void RouteToMissionPrompt();
    void AnswerUp();
    void AnswerDown();
    void AnswerOne();
    void AnswerTwo();
    void AnswerThree();
    void QuitGame();
    void SubmitAnswerChoice(int32 ChoiceIndex);
    void NavigateHorizontal(float Value);
    void NavigateVertical(float Value);
    void HandleNavigationAxis(float Value, bool& bAxisReady, bool bHorizontal);
    void TriggerFocusFeedback(float Direction);
    bool CanAcceptFocusStep();

    bool bHorizontalAxisReady = true;
    bool bVerticalAxisReady = true;
    bool bHomeInputHeartbeatSent = false;
    float LastFocusStepTime = -100.0f;
};
