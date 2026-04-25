#include "AstroAdventurePlayerController.h"

#include "AstroAdventureGameModeBase.h"
#include "Engine/World.h"
#include "InputCoreTypes.h"

void AAstroAdventurePlayerController::SetupInputComponent()
{
    Super::SetupInputComponent();

    InputComponent->BindKey(EKeys::Right, IE_Pressed, this, &AAstroAdventurePlayerController::FocusNext);
    InputComponent->BindKey(EKeys::Gamepad_RightShoulder, IE_Pressed, this, &AAstroAdventurePlayerController::FocusNext);
    InputComponent->BindKey(EKeys::Gamepad_DPad_Right, IE_Pressed, this, &AAstroAdventurePlayerController::FocusNext);

    InputComponent->BindKey(EKeys::Left, IE_Pressed, this, &AAstroAdventurePlayerController::FocusPrevious);
    InputComponent->BindKey(EKeys::Gamepad_LeftShoulder, IE_Pressed, this, &AAstroAdventurePlayerController::FocusPrevious);
    InputComponent->BindKey(EKeys::Gamepad_DPad_Left, IE_Pressed, this, &AAstroAdventurePlayerController::FocusPrevious);

    InputComponent->BindKey(EKeys::Enter, IE_Pressed, this, &AAstroAdventurePlayerController::Confirm);
    InputComponent->BindKey(EKeys::SpaceBar, IE_Pressed, this, &AAstroAdventurePlayerController::Confirm);
    InputComponent->BindKey(EKeys::Gamepad_FaceButton_Bottom, IE_Pressed, this, &AAstroAdventurePlayerController::Confirm);

    InputComponent->BindKey(EKeys::Escape, IE_Pressed, this, &AAstroAdventurePlayerController::Back);
    InputComponent->BindKey(EKeys::BackSpace, IE_Pressed, this, &AAstroAdventurePlayerController::Back);
    InputComponent->BindKey(EKeys::Gamepad_FaceButton_Right, IE_Pressed, this, &AAstroAdventurePlayerController::Back);

    InputComponent->BindKey(EKeys::H, IE_Pressed, this, &AAstroAdventurePlayerController::Hint);
    InputComponent->BindKey(EKeys::Gamepad_FaceButton_Top, IE_Pressed, this, &AAstroAdventurePlayerController::Hint);

    InputComponent->BindKey(EKeys::Up, IE_Pressed, this, &AAstroAdventurePlayerController::AnswerUp);
    InputComponent->BindKey(EKeys::Gamepad_DPad_Up, IE_Pressed, this, &AAstroAdventurePlayerController::AnswerUp);
    InputComponent->BindKey(EKeys::Down, IE_Pressed, this, &AAstroAdventurePlayerController::AnswerDown);
    InputComponent->BindKey(EKeys::Gamepad_DPad_Down, IE_Pressed, this, &AAstroAdventurePlayerController::AnswerDown);

    InputComponent->BindKey(EKeys::One, IE_Pressed, this, &AAstroAdventurePlayerController::AnswerOne);
    InputComponent->BindKey(EKeys::Two, IE_Pressed, this, &AAstroAdventurePlayerController::AnswerTwo);
    InputComponent->BindKey(EKeys::Three, IE_Pressed, this, &AAstroAdventurePlayerController::AnswerThree);
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

void AAstroAdventurePlayerController::AnswerUp()
{
    if (AAstroAdventureGameModeBase* GameMode = GetWorld()->GetAuthGameMode<AAstroAdventureGameModeBase>())
    {
        GameMode->MoveQuizFocus(-1);
    }
}

void AAstroAdventurePlayerController::AnswerDown()
{
    if (AAstroAdventureGameModeBase* GameMode = GetWorld()->GetAuthGameMode<AAstroAdventureGameModeBase>())
    {
        GameMode->MoveQuizFocus(1);
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
