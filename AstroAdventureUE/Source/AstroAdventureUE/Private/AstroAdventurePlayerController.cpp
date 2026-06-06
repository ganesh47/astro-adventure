#include "AstroAdventurePlayerController.h"

#include "AstroAdventureGameModeBase.h"
#include "AstroPlayerPawn.h"
#include "Engine/Engine.h"
#include "Engine/World.h"
#include "Framework/Application/SlateApplication.h"
#include "GameFramework/PlayerInput.h"
#include "InputCoreTypes.h"
#include "Kismet/KismetSystemLibrary.h"

namespace
{
    constexpr float NavigationPressThreshold = 0.65f;
    constexpr float NavigationReleaseThreshold = 0.25f;
}

void AAstroAdventurePlayerController::BeginPlay()
{
    Super::BeginPlay();
    ConfigureGameInputMode();
}

void AAstroAdventurePlayerController::SetupInputComponent()
{
    Super::SetupInputComponent();

    // Digital key/button presses are handled in InputKey so packaged builds have one deterministic path.
    InputComponent->BindAxis(TEXT("MoveForward"), this, &AAstroAdventurePlayerController::NavigateVertical);
    InputComponent->BindAxis(TEXT("MoveRight"), this, &AAstroAdventurePlayerController::NavigateHorizontal);
}

bool AAstroAdventurePlayerController::InputKey(const FInputKeyEventArgs& Params)
{
    const bool bIsPressed = Params.Event == IE_Pressed;
    const bool bIsRepeat = Params.Event == IE_Repeat;
    if (!bIsPressed && !bIsRepeat)
    {
        return Super::InputKey(Params);
    }

    const FKey Key = Params.Key;
    const bool bAllowRepeat = bIsPressed || bIsRepeat;

    if (bIsPressed && (Key == EKeys::Enter || Key == EKeys::SpaceBar || Key == EKeys::Gamepad_FaceButton_Bottom))
    {
        Confirm();
        return true;
    }

    if (bIsPressed && (Key == EKeys::BackSpace || Key == EKeys::Gamepad_FaceButton_Right))
    {
        Back();
        return true;
    }

    if (bIsPressed && (Key == EKeys::Escape || Key == EKeys::Q || Key == EKeys::Gamepad_Special_Left || Key == EKeys::Gamepad_Special_Right || Key == EKeys::Gamepad_RightThumbstick))
    {
        Pause();
        return true;
    }

    if (bIsPressed && (Key == EKeys::M || Key == EKeys::Gamepad_LeftTrigger || Key == EKeys::Gamepad_LeftThumbstick))
    {
        MoreInfo();
        return true;
    }

    if (bIsPressed && (Key == EKeys::P || Key == EKeys::Gamepad_RightTrigger || Key == EKeys::Gamepad_FaceButton_Left))
    {
        Passport();
        return true;
    }

    if (bIsPressed && (Key == EKeys::H || Key == EKeys::Gamepad_FaceButton_Top))
    {
        Hint();
        return true;
    }

    if (bIsPressed && Key == EKeys::LeftMouseButton)
    {
        PointerConfirm();
        return true;
    }

    if (bAllowRepeat && (Key == EKeys::Right || Key == EKeys::D || Key == EKeys::Gamepad_RightShoulder || Key == EKeys::Gamepad_DPad_Right))
    {
        FocusNext();
        return true;
    }

    if (bAllowRepeat && (Key == EKeys::Left || Key == EKeys::A || Key == EKeys::Gamepad_LeftShoulder || Key == EKeys::Gamepad_DPad_Left))
    {
        FocusPrevious();
        return true;
    }

    if (bAllowRepeat && (Key == EKeys::Up || Key == EKeys::W || Key == EKeys::Gamepad_DPad_Up))
    {
        AnswerUp();
        return true;
    }

    if (bAllowRepeat && (Key == EKeys::Down || Key == EKeys::S || Key == EKeys::Gamepad_DPad_Down))
    {
        AnswerDown();
        return true;
    }

    if (bIsPressed && Key == EKeys::One)
    {
        AnswerOne();
        return true;
    }

    if (bIsPressed && Key == EKeys::Two)
    {
        AnswerTwo();
        return true;
    }

    if (bIsPressed && Key == EKeys::Three)
    {
        AnswerThree();
        return true;
    }

    return Super::InputKey(Params);
}

void AAstroAdventurePlayerController::ConfigureGameInputMode()
{
    bShowMouseCursor = true;
    bEnableClickEvents = true;
    bEnableMouseOverEvents = false;
    SetIgnoreMoveInput(false);
    SetIgnoreLookInput(false);

    FInputModeGameOnly InputMode;
    InputMode.SetConsumeCaptureMouseDown(false);
    SetInputMode(InputMode);

    if (GEngine && GEngine->GameViewport)
    {
        GEngine->GameViewport->SetSuppressTransitionMessage(true);
    }
    if (FSlateApplication::IsInitialized())
    {
        FSlateApplication::Get().SetAllUserFocusToGameViewport();
    }
}

void AAstroAdventurePlayerController::NotifyHomeInputIfNeeded(AAstroAdventureGameModeBase* GameMode)
{
    if (!GameMode || bHomeInputHeartbeatSent || GameMode->GetCurrentScreen() != EAstroMissionScreen::Home)
    {
        return;
    }

    bHomeInputHeartbeatSent = true;
    GameMode->NotifyHomeInputReceived();
}

void AAstroAdventurePlayerController::FocusNext()
{
    if (AAstroAdventureGameModeBase* GameMode = GetWorld()->GetAuthGameMode<AAstroAdventureGameModeBase>())
    {
        NotifyHomeInputIfNeeded(GameMode);
        if (GameMode->GetCurrentScreen() == EAstroMissionScreen::MissionPrompt)
        {
            if (!CanAcceptFocusStep())
            {
                return;
            }
            RouteToMissionPrompt();
            return;
        }
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
        NotifyHomeInputIfNeeded(GameMode);
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
        NotifyHomeInputIfNeeded(GameMode);
        GameMode->Confirm();
    }
}

void AAstroAdventurePlayerController::Back()
{
    if (AAstroAdventureGameModeBase* GameMode = GetWorld()->GetAuthGameMode<AAstroAdventureGameModeBase>())
    {
        NotifyHomeInputIfNeeded(GameMode);
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

void AAstroAdventurePlayerController::PointerConfirm()
{
    AAstroAdventureGameModeBase* GameMode = GetWorld() ? GetWorld()->GetAuthGameMode<AAstroAdventureGameModeBase>() : nullptr;
    if (!GameMode)
    {
        return;
    }

    float MouseX = 0.0f;
    float MouseY = 0.0f;
    int32 ViewportX = 0;
    int32 ViewportY = 0;
    GetViewportSize(ViewportX, ViewportY);
    if (GetMousePosition(MouseX, MouseY) && ViewportX > 0 && ViewportY > 0)
    {
        NotifyHomeInputIfNeeded(GameMode);
        if (GameMode->HandlePointerConfirm(MouseX, MouseY, static_cast<float>(ViewportX), static_cast<float>(ViewportY)))
        {
            return;
        }
    }

    // A click used only to focus the packaged window should not advance the child's route.
}

void AAstroAdventurePlayerController::RouteToMissionPrompt()
{
    Confirm();
    TriggerFocusFeedback(1.0f);
}

void AAstroAdventurePlayerController::AnswerUp()
{
    if (AAstroAdventureGameModeBase* GameMode = GetWorld()->GetAuthGameMode<AAstroAdventureGameModeBase>())
    {
        const EAstroMissionScreen Screen = GameMode->GetCurrentScreen();
        if (Screen == EAstroMissionScreen::MissionPrompt)
        {
            if (!CanAcceptFocusStep())
            {
                return;
            }
            RouteToMissionPrompt();
            return;
        }
        if (!CanAcceptFocusStep())
        {
            return;
        }

        if (Screen == EAstroMissionScreen::Quiz)
        {
            GameMode->MoveQuizFocus(-1);
            TriggerFocusFeedback(-1.0f);
        }
        else if (Screen == EAstroMissionScreen::Navigation || Screen == EAstroMissionScreen::AtlasView || Screen == EAstroMissionScreen::Passport)
        {
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
        if (!CanAcceptFocusStep())
        {
            return;
        }

        if (Screen == EAstroMissionScreen::Quiz)
        {
            GameMode->MoveQuizFocus(1);
            TriggerFocusFeedback(1.0f);
        }
        else if (Screen == EAstroMissionScreen::Navigation || Screen == EAstroMissionScreen::AtlasView || Screen == EAstroMissionScreen::Passport)
        {
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
