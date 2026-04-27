#pragma once

#include "CoreMinimal.h"
#include "GameFramework/PlayerController.h"
#include "AstroAdventurePlayerController.generated.h"

UCLASS()
class ASTROADVENTUREUE_API AAstroAdventurePlayerController : public APlayerController
{
    GENERATED_BODY()

public:
    virtual void SetupInputComponent() override;

private:
    void FocusNext();
    void FocusPrevious();
    void Confirm();
    void Back();
    void Hint();
    void MoreInfo();
    void Passport();
    void Pause();
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

    bool bHorizontalAxisReady = true;
    bool bVerticalAxisReady = true;
};
