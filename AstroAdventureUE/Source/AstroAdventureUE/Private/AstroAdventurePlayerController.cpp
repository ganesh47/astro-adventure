#include "AstroAdventurePlayerController.h"

#include "AstroAdventureGameModeBase.h"
#include "Engine/World.h"
#include "InputCoreTypes.h"
#include "Kismet/KismetSystemLibrary.h"

void AAstroAdventurePlayerController::SetupInputComponent()
{
    Super::SetupInputComponent();

    InputComponent->BindKey(EKeys::Right, IE_Pressed, this, &AAstroAdventurePlayerController::FocusNext);
    InputComponent->BindKey(EKeys::D, IE_Pressed, this, &AAstroAdventurePlayerController::FocusNext);
    InputComponent->BindKey(EKeys::Gamepad_RightShoulder, IE_Pressed, this, &AAstroAdventurePlayerController::FocusNext);
    InputComponent->BindKey(EKeys::Gamepad_DPad_Right, IE_Pressed, this, &AAstroAdventurePlayerController::FocusNext);

    InputComponent->BindKey(EKeys::Left, IE_Pressed, this, &AAstroAdventurePlayerController::FocusPrevious);
    InputComponent->BindKey(EKeys::A, IE_Pressed, this, &AAstroAdventurePlayerController::FocusPrevious);
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

    InputComponent->BindKey(EKeys::P, IE_Pressed, this, &AAstroAdventurePlayerController::Passport);
    InputComponent->BindKey(EKeys::Gamepad_RightTrigger, IE_Pressed, this, &AAstroAdventurePlayerController::Passport);

    InputComponent->BindKey(EKeys::Gamepad_Special_Left, IE_Pressed, this, &AAstroAdventurePlayerController::Pause);

    InputComponent->BindKey(EKeys::Up, IE_Pressed, this, &AAstroAdventurePlayerController::AnswerUp);
    InputComponent->BindKey(EKeys::W, IE_Pressed, this, &AAstroAdventurePlayerController::AnswerUp);
    InputComponent->BindKey(EKeys::Gamepad_DPad_Up, IE_Pressed, this, &AAstroAdventurePlayerController::AnswerUp);
    InputComponent->BindKey(EKeys::Down, IE_Pressed, this, &AAstroAdventurePlayerController::AnswerDown);
    InputComponent->BindKey(EKeys::S, IE_Pressed, this, &AAstroAdventurePlayerController::AnswerDown);
    InputComponent->BindKey(EKeys::Gamepad_DPad_Down, IE_Pressed, this, &AAstroAdventurePlayerController::AnswerDown);
    InputComponent->BindAxis(TEXT("MoveForward"), this, &AAstroAdventurePlayerController::NavigateVertical);
    InputComponent->BindAxis(TEXT("MoveRight"), this, &AAstroAdventurePlayerController::NavigateHorizontal);

    InputComponent->BindKey(EKeys::One, IE_Pressed, this, &AAstroAdventurePlayerController::AnswerOne);
    InputComponent->BindKey(EKeys::Two, IE_Pressed, this, &AAstroAdventurePlayerController::AnswerTwo);
    InputComponent->BindKey(EKeys::Three, IE_Pressed, this, &AAstroAdventurePlayerController::AnswerThree);

    InputComponent->BindKey(EKeys::Q, IE_Pressed, this, &AAstroAdventurePlayerController::Pause);
    InputComponent->BindKey(EKeys::Gamepad_Special_Right, IE_Pressed, this, &AAstroAdventurePlayerController::Pause);
}

void AAstroAdventurePlayerController::FocusNext()
{
    if (AAstroAdventureGameModeBase* GameMode = GetWorld()->GetAuthGameMode<AAstroAdventureGameModeBase>())
    {
        GameMode->FocusNextDestination();
    }
}

void AAstroAdventurePlayerController::FocusPrevious()
{
    if (AAstroAdventureGameModeBase* GameMode = GetWorld()->GetAuthGameMode<AAstroAdventureGameModeBase>())
    {
        GameMode->FocusPreviousDestination();
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
        GameMode->FocusPreviousDestination();
    }
}

void AAstroAdventurePlayerController::AnswerDown()
{
    if (AAstroAdventureGameModeBase* GameMode = GetWorld()->GetAuthGameMode<AAstroAdventureGameModeBase>())
    {
        GameMode->FocusNextDestination();
    }
}

void AAstroAdventurePlayerController::AnswerOne()
{
    if (AAstroAdventureGameModeBase* GameMode = GetWorld()->GetAuthGameMode<AAstroAdventureGameModeBase>())
    {
        GameMode->SubmitAnswer(0);
    }
}

void AAstroAdventurePlayerController::AnswerTwo()
{
    if (AAstroAdventureGameModeBase* GameMode = GetWorld()->GetAuthGameMode<AAstroAdventureGameModeBase>())
    {
        GameMode->SubmitAnswer(1);
    }
}

void AAstroAdventurePlayerController::AnswerThree()
{
    if (AAstroAdventureGameModeBase* GameMode = GetWorld()->GetAuthGameMode<AAstroAdventureGameModeBase>())
    {
        GameMode->SubmitAnswer(2);
    }
}

void AAstroAdventurePlayerController::QuitGame()
{
    UKismetSystemLibrary::QuitGame(this, this, EQuitPreference::Quit, false);
}

void AAstroAdventurePlayerController::NavigateHorizontal(const float Value)
{
    if (IsInputKeyDown(EKeys::A) || IsInputKeyDown(EKeys::D) || IsInputKeyDown(EKeys::Left) || IsInputKeyDown(EKeys::Right))
    {
        return;
    }

    constexpr float PressThreshold = 0.65f;
    constexpr float ReleaseThreshold = 0.25f;

    if (FMath::Abs(Value) < ReleaseThreshold)
    {
        bHorizontalAxisReady = true;
        return;
    }

    if (!bHorizontalAxisReady)
    {
        return;
    }

    if (Value > PressThreshold)
    {
        FocusNext();
        bHorizontalAxisReady = false;
    }
    else if (Value < -PressThreshold)
    {
        FocusPrevious();
        bHorizontalAxisReady = false;
    }
}

void AAstroAdventurePlayerController::NavigateVertical(const float Value)
{
    if (IsInputKeyDown(EKeys::W) || IsInputKeyDown(EKeys::S) || IsInputKeyDown(EKeys::Up) || IsInputKeyDown(EKeys::Down))
    {
        return;
    }

    constexpr float PressThreshold = 0.65f;
    constexpr float ReleaseThreshold = 0.25f;

    if (FMath::Abs(Value) < ReleaseThreshold)
    {
        bVerticalAxisReady = true;
        return;
    }

    if (!bVerticalAxisReady)
    {
        return;
    }

    if (Value > PressThreshold)
    {
        AnswerUp();
        bVerticalAxisReady = false;
    }
    else if (Value < -PressThreshold)
    {
        AnswerDown();
        bVerticalAxisReady = false;
    }
}
