#include "AstroAdventurePlayerController.h"

#include "AstroAdventureGameModeBase.h"
#include "AstroPlayerPawn.h"
#include "Engine/World.h"
#include "InputCoreTypes.h"
#include "Kismet/KismetSystemLibrary.h"

namespace
{
    constexpr float NavigationPressThreshold = 0.65f;
    constexpr float NavigationReleaseThreshold = 0.25f;
}

void AAstroAdventurePlayerController::SetupInputComponent()
{
    Super::SetupInputComponent();

    InputComponent->BindKey(EKeys::Right, IE_Pressed, this, &AAstroAdventurePlayerController::FocusNext);
    InputComponent->BindKey(EKeys::Right, IE_Repeat, this, &AAstroAdventurePlayerController::FocusNext);
    InputComponent->BindKey(EKeys::D, IE_Pressed, this, &AAstroAdventurePlayerController::FocusNext);
    InputComponent->BindKey(EKeys::D, IE_Repeat, this, &AAstroAdventurePlayerController::FocusNext);
    InputComponent->BindKey(EKeys::Gamepad_RightShoulder, IE_Pressed, this, &AAstroAdventurePlayerController::FocusNext);
    InputComponent->BindKey(EKeys::Gamepad_DPad_Right, IE_Pressed, this, &AAstroAdventurePlayerController::FocusNext);

    InputComponent->BindKey(EKeys::Left, IE_Pressed, this, &AAstroAdventurePlayerController::FocusPrevious);
    InputComponent->BindKey(EKeys::Left, IE_Repeat, this, &AAstroAdventurePlayerController::FocusPrevious);
    InputComponent->BindKey(EKeys::A, IE_Pressed, this, &AAstroAdventurePlayerController::FocusPrevious);
    InputComponent->BindKey(EKeys::A, IE_Repeat, this, &AAstroAdventurePlayerController::FocusPrevious);
    InputComponent->BindKey(EKeys::Gamepad_LeftShoulder, IE_Pressed, this, &AAstroAdventurePlayerController::FocusPrevious);
    InputComponent->BindKey(EKeys::Gamepad_DPad_Left, IE_Pressed, this, &AAstroAdventurePlayerController::FocusPrevious);

    InputComponent->BindKey(EKeys::Enter, IE_Pressed, this, &AAstroAdventurePlayerController::Confirm);
    InputComponent->BindKey(EKeys::SpaceBar, IE_Pressed, this, &AAstroAdventurePlayerController::Confirm);
    InputComponent->BindKey(EKeys::Gamepad_FaceButton_Bottom, IE_Pressed, this, &AAstroAdventurePlayerController::Confirm);

    InputComponent->BindKey(EKeys::Escape, IE_Pressed, this, &AAstroAdventurePlayerController::Pause);
    InputComponent->BindKey(EKeys::BackSpace, IE_Pressed, this, &AAstroAdventurePlayerController::Back);
    InputComponent->BindKey(EKeys::Gamepad_FaceButton_Right, IE_Pressed, this, &AAstroAdventurePlayerController::Back);

    InputComponent->BindKey(EKeys::H, IE_Pressed, this, &AAstroAdventurePlayerController::Hint);
    InputComponent->BindKey(EKeys::Gamepad_FaceButton_Top, IE_Pressed, this, &AAstroAdventurePlayerController::Hint);

    InputComponent->BindKey(EKeys::M, IE_Pressed, this, &AAstroAdventurePlayerController::MoreInfo);
    InputComponent->BindKey(EKeys::Gamepad_LeftTrigger, IE_Pressed, this, &AAstroAdventurePlayerController::MoreInfo);
    InputComponent->BindKey(EKeys::Gamepad_LeftThumbstick, IE_Pressed, this, &AAstroAdventurePlayerController::MoreInfo);

    InputComponent->BindKey(EKeys::P, IE_Pressed, this, &AAstroAdventurePlayerController::Passport);
    InputComponent->BindKey(EKeys::Gamepad_RightTrigger, IE_Pressed, this, &AAstroAdventurePlayerController::Passport);
    InputComponent->BindKey(EKeys::Gamepad_FaceButton_Left, IE_Pressed, this, &AAstroAdventurePlayerController::Passport);

    InputComponent->BindKey(EKeys::Up, IE_Pressed, this, &AAstroAdventurePlayerController::AnswerUp);
    InputComponent->BindKey(EKeys::Up, IE_Repeat, this, &AAstroAdventurePlayerController::AnswerUp);
    InputComponent->BindKey(EKeys::W, IE_Pressed, this, &AAstroAdventurePlayerController::AnswerUp);
    InputComponent->BindKey(EKeys::W, IE_Repeat, this, &AAstroAdventurePlayerController::AnswerUp);
    InputComponent->BindKey(EKeys::Gamepad_DPad_Up, IE_Pressed, this, &AAstroAdventurePlayerController::AnswerUp);
    InputComponent->BindKey(EKeys::Down, IE_Pressed, this, &AAstroAdventurePlayerController::AnswerDown);
    InputComponent->BindKey(EKeys::Down, IE_Repeat, this, &AAstroAdventurePlayerController::AnswerDown);
    InputComponent->BindKey(EKeys::S, IE_Pressed, this, &AAstroAdventurePlayerController::AnswerDown);
    InputComponent->BindKey(EKeys::S, IE_Repeat, this, &AAstroAdventurePlayerController::AnswerDown);
    InputComponent->BindKey(EKeys::Gamepad_DPad_Down, IE_Pressed, this, &AAstroAdventurePlayerController::AnswerDown);
    InputComponent->BindAxis(TEXT("MoveForward"), this, &AAstroAdventurePlayerController::NavigateVertical);
    InputComponent->BindAxis(TEXT("MoveRight"), this, &AAstroAdventurePlayerController::NavigateHorizontal);

    InputComponent->BindKey(EKeys::One, IE_Pressed, this, &AAstroAdventurePlayerController::AnswerOne);
    InputComponent->BindKey(EKeys::Two, IE_Pressed, this, &AAstroAdventurePlayerController::AnswerTwo);
    InputComponent->BindKey(EKeys::Three, IE_Pressed, this, &AAstroAdventurePlayerController::AnswerThree);

    InputComponent->BindKey(EKeys::Q, IE_Pressed, this, &AAstroAdventurePlayerController::Pause);
    InputComponent->BindKey(EKeys::Gamepad_Special_Left, IE_Pressed, this, &AAstroAdventurePlayerController::Pause);
    InputComponent->BindKey(EKeys::Gamepad_Special_Right, IE_Pressed, this, &AAstroAdventurePlayerController::Pause);
    InputComponent->BindKey(EKeys::Gamepad_RightThumbstick, IE_Pressed, this, &AAstroAdventurePlayerController::Pause);
}

void AAstroAdventurePlayerController::FocusNext()
{
    if (AAstroAdventureGameModeBase* GameMode = GetWorld()->GetAuthGameMode<AAstroAdventureGameModeBase>())
    {
        if (GameMode->GetCurrentScreen() == EAstroMissionScreen::Quiz)
        {
            return;
        }
        if (!CanAcceptFocusStep())
        {
            return;
        }

        GameMode->FocusNextDestination();
        TriggerFocusFeedback(1.0f);
    }
}

void AAstroAdventurePlayerController::FocusPrevious()
{
    if (AAstroAdventureGameModeBase* GameMode = GetWorld()->GetAuthGameMode<AAstroAdventureGameModeBase>())
    {
        if (GameMode->GetCurrentScreen() == EAstroMissionScreen::Quiz)
        {
            return;
        }
        if (!CanAcceptFocusStep())
        {
            return;
        }

        GameMode->FocusPreviousDestination();
        TriggerFocusFeedback(-1.0f);
    }
}

void AAstroAdventurePlayerController::Confirm()
{
    if (AAstroAdventureGameModeBase* GameMode = GetWorld()->GetAuthGameMode<AAstroAdventureGameModeBase>())
    {
        GameMode->Confirm();
    }
}

void AAstroAdventurePlayerController::Back()
{
    if (AAstroAdventureGameModeBase* GameMode = GetWorld()->GetAuthGameMode<AAstroAdventureGameModeBase>())
    {
        GameMode->Back();
    }
}

void AAstroAdventurePlayerController::Hint()
{
    if (AAstroAdventureGameModeBase* GameMode = GetWorld()->GetAuthGameMode<AAstroAdventureGameModeBase>())
    {
        GameMode->RequestHint();
    }
}

void AAstroAdventurePlayerController::MoreInfo()
{
    if (AAstroAdventureGameModeBase* GameMode = GetWorld()->GetAuthGameMode<AAstroAdventureGameModeBase>())
    {
        GameMode->ToggleDeepDive();
    }
}

void AAstroAdventurePlayerController::Passport()
{
    if (AAstroAdventureGameModeBase* GameMode = GetWorld()->GetAuthGameMode<AAstroAdventureGameModeBase>())
    {
        GameMode->TogglePassport();
    }
}

void AAstroAdventurePlayerController::Pause()
{
    if (AAstroAdventureGameModeBase* GameMode = GetWorld()->GetAuthGameMode<AAstroAdventureGameModeBase>())
    {
        GameMode->TogglePause();
    }
}

void AAstroAdventurePlayerController::AnswerUp()
{
    if (AAstroAdventureGameModeBase* GameMode = GetWorld()->GetAuthGameMode<AAstroAdventureGameModeBase>())
    {
        const EAstroMissionScreen Screen = GameMode->GetCurrentScreen();
        if (Screen == EAstroMissionScreen::Quiz)
        {
            GameMode->MoveQuizFocus(-1);
            TriggerFocusFeedback(-1.0f);
        }
        else if (Screen == EAstroMissionScreen::Navigation || Screen == EAstroMissionScreen::AtlasView || Screen == EAstroMissionScreen::Passport || Screen == EAstroMissionScreen::StampAward)
        {
            if (!CanAcceptFocusStep())
            {
                return;
            }
            GameMode->FocusNextDestination();
            TriggerFocusFeedback(1.0f);
        }
        else
        {
            GameMode->FocusPreviousDestination();
            TriggerFocusFeedback(-1.0f);
        }
    }
}

void AAstroAdventurePlayerController::AnswerDown()
{
    if (AAstroAdventureGameModeBase* GameMode = GetWorld()->GetAuthGameMode<AAstroAdventureGameModeBase>())
    {
        const EAstroMissionScreen Screen = GameMode->GetCurrentScreen();
        if (Screen == EAstroMissionScreen::Quiz)
        {
            GameMode->MoveQuizFocus(1);
            TriggerFocusFeedback(1.0f);
        }
        else if (Screen == EAstroMissionScreen::Navigation || Screen == EAstroMissionScreen::AtlasView || Screen == EAstroMissionScreen::Passport || Screen == EAstroMissionScreen::StampAward)
        {
            if (!CanAcceptFocusStep())
            {
                return;
            }
            GameMode->FocusPreviousDestination();
            TriggerFocusFeedback(-1.0f);
        }
        else
        {
            GameMode->FocusNextDestination();
            TriggerFocusFeedback(1.0f);
        }
    }
}

void AAstroAdventurePlayerController::AnswerOne()
{
    SubmitAnswerChoice(0);
}

void AAstroAdventurePlayerController::AnswerTwo()
{
    SubmitAnswerChoice(1);
}

void AAstroAdventurePlayerController::AnswerThree()
{
    SubmitAnswerChoice(2);
}

void AAstroAdventurePlayerController::SubmitAnswerChoice(const int32 ChoiceIndex)
{
    if (AAstroAdventureGameModeBase* GameMode = GetWorld()->GetAuthGameMode<AAstroAdventureGameModeBase>())
    {
        if (GameMode->GetCurrentScreen() == EAstroMissionScreen::Quiz)
        {
            GameMode->SubmitAnswer(ChoiceIndex);
        }
    }
}

void AAstroAdventurePlayerController::QuitGame()
{
    UKismetSystemLibrary::QuitGame(this, this, EQuitPreference::Quit, false);
}

void AAstroAdventurePlayerController::TriggerFocusFeedback(const float Direction)
{
    if (AAstroPlayerPawn* AstroPawn = Cast<AAstroPlayerPawn>(GetPawn()))
    {
        AstroPawn->TriggerNavigationFeedback(Direction);
    }
}

bool AAstroAdventurePlayerController::CanAcceptFocusStep()
{
    const float Now = GetWorld() ? GetWorld()->GetTimeSeconds() : 0.0f;
    if (Now - LastFocusStepTime < 0.18f)
    {
        return false;
    }

    LastFocusStepTime = Now;
    return true;
}

void AAstroAdventurePlayerController::NavigateHorizontal(const float Value)
{
    if (IsInputKeyDown(EKeys::A) || IsInputKeyDown(EKeys::D) || IsInputKeyDown(EKeys::Left) || IsInputKeyDown(EKeys::Right))
    {
        return;
    }

    HandleNavigationAxis(Value, bHorizontalAxisReady, true);
}

void AAstroAdventurePlayerController::NavigateVertical(const float Value)
{
    if (IsInputKeyDown(EKeys::W) || IsInputKeyDown(EKeys::S) || IsInputKeyDown(EKeys::Up) || IsInputKeyDown(EKeys::Down))
    {
        return;
    }

    HandleNavigationAxis(Value, bVerticalAxisReady, false);
}

void AAstroAdventurePlayerController::HandleNavigationAxis(const float Value, bool& bAxisReady, const bool bHorizontal)
{
    if (FMath::Abs(Value) < NavigationReleaseThreshold)
    {
        bAxisReady = true;
        return;
    }

    if (!bAxisReady)
    {
        return;
    }

    if (bHorizontal)
    {
        if (Value > NavigationPressThreshold)
        {
            FocusNext();
            bAxisReady = false;
        }
        else if (Value < -NavigationPressThreshold)
        {
            FocusPrevious();
            bAxisReady = false;
        }
    }
    else
    {
        if (Value > NavigationPressThreshold)
        {
            AnswerUp();
            bAxisReady = false;
        }
        else if (Value < -NavigationPressThreshold)
        {
            AnswerDown();
            bAxisReady = false;
        }
    }
}
