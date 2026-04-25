#include "AstroAdventureGameModeBase.h"

#include "AstroAdventurePlayerController.h"
#include "AstroDestinationActor.h"
#include "AstroLearningLibrary.h"
#include "AstroMissionHUD.h"
#include "AstroPlayerPawn.h"
#include "AstroProgressSaveGame.h"
#include "Algo/Count.h"
#include "Camera/CameraActor.h"
#include "Engine/DirectionalLight.h"
#include "Engine/World.h"
#include "GameFramework/PlayerStart.h"
#include "Kismet/GameplayStatics.h"

const TCHAR* AAstroAdventureGameModeBase::SaveSlotName = TEXT("AstroAdventureM0Progress");

AAstroAdventureGameModeBase::AAstroAdventureGameModeBase()
{
    MissionId = TEXT("M0_DeploymentProof");
    DefaultPawnClass = AAstroPlayerPawn::StaticClass();
    PlayerControllerClass = AAstroAdventurePlayerController::StaticClass();
    HUDClass = AAstroMissionHUD::StaticClass();
}

void AAstroAdventureGameModeBase::BeginPlay()
{
    Super::BeginPlay();
    BuildLessons();
    LoadProgress();
    SpawnRuntimeScene();
    UpdateDestinationFocus();
}

void AAstroAdventureGameModeBase::BuildLessons()
{
    Lessons.Reset();

    auto MakeChoice = [](const TCHAR* Id, const TCHAR* Text)
    {
        FAstroQuizChoice Choice;
        Choice.ChoiceId = FName(Id);
        Choice.Text = FText::FromString(Text);
        return Choice;
    };

    FAstroDestinationLesson Mercury;
    Mercury.DestinationId = TEXT("mercury");
    Mercury.DisplayName = FText::FromString(TEXT("Mercury"));
    Mercury.DiscoveryFact = FText::FromString(TEXT("Mercury is the closest planet to the Sun."));
    Mercury.Ages4To6Text = FText::FromString(TEXT("Mercury is a tiny planet near the Sun."));
    Mercury.Ages7To9Text = FText::FromString(TEXT("Mercury is the closest planet to the Sun and moves around it very quickly."));
    Mercury.Ages10To12Text = FText::FromString(TEXT("Mercury is the innermost planet. Its short orbit helps scientists compare how distance from the Sun changes a world."));
    Mercury.SourceUrl = TEXT("https://science.nasa.gov/mercury/");
    Mercury.QuizPrompt = FText::FromString(TEXT("Which clue helps identify Mercury?"));
    Mercury.Choices = {MakeChoice(TEXT("sun"), TEXT("It is the closest planet to the Sun.")), MakeChoice(TEXT("rust"), TEXT("It is famous for red rusty dust.")), MakeChoice(TEXT("ice"), TEXT("It is an icy moon of Jupiter."))};
    Mercury.CorrectChoiceId = TEXT("sun");
    Mercury.CorrectFeedback = FText::FromString(TEXT("Yes. Mercury orbits closest to the Sun."));
    Mercury.RetryFeedback = FText::FromString(TEXT("Try the clue about where Mercury travels."));
    Mercury.HintText = FText::FromString(TEXT("Look for the clue that mentions the Sun."));
    Lessons.Add(Mercury);

    FAstroDestinationLesson Mars;
    Mars.DestinationId = TEXT("mars");
    Mars.DisplayName = FText::FromString(TEXT("Mars"));
    Mars.DiscoveryFact = FText::FromString(TEXT("Mars looks red because rusty iron is mixed into its dust."));
    Mars.Ages4To6Text = FText::FromString(TEXT("Mars is the red planet."));
    Mars.Ages7To9Text = FText::FromString(TEXT("Mars looks red because iron in its rocks and dust has rusted."));
    Mars.Ages10To12Text = FText::FromString(TEXT("Mars has iron-rich dust and rocks. Oxidation, a rusting process, gives much of the surface its reddish color."));
    Mars.SourceUrl = TEXT("https://science.nasa.gov/mars/");
    Mars.QuizPrompt = FText::FromString(TEXT("Why does Mars look red from far away?"));
    Mars.Choices = {MakeChoice(TEXT("rust"), TEXT("Rusty iron is mixed into its dust.")), MakeChoice(TEXT("plants"), TEXT("It is covered in red plants.")), MakeChoice(TEXT("jupiter"), TEXT("Jupiter shines red light on it."))};
    Mars.CorrectChoiceId = TEXT("rust");
    Mars.CorrectFeedback = FText::FromString(TEXT("Yes. Iron in Mars rocks and dust has rusted, which makes Mars look red."));
    Mars.RetryFeedback = FText::FromString(TEXT("Try the answer that matches the dust clue."));
    Mars.HintText = FText::FromString(TEXT("Rust can turn iron reddish."));
    Lessons.Add(Mars);

    FAstroDestinationLesson Europa;
    Europa.DestinationId = TEXT("europa");
    Europa.DisplayName = FText::FromString(TEXT("Europa"));
    Europa.DiscoveryFact = FText::FromString(TEXT("Europa is an icy moon of Jupiter that may hide an ocean under the ice."));
    Europa.Ages4To6Text = FText::FromString(TEXT("Europa is an icy moon."));
    Europa.Ages7To9Text = FText::FromString(TEXT("Europa is an icy moon of Jupiter. Scientists study clues about an ocean under its ice."));
    Europa.Ages10To12Text = FText::FromString(TEXT("Europa's icy shell and evidence for a salty ocean make it an important place to study how moons can hold liquid water."));
    Europa.SourceUrl = TEXT("https://science.nasa.gov/jupiter/moons/europa/");
    Europa.QuizPrompt = FText::FromString(TEXT("What kind of world is Europa?"));
    Europa.Choices = {MakeChoice(TEXT("icy_moon"), TEXT("An icy moon of Jupiter.")), MakeChoice(TEXT("small_planet"), TEXT("The smallest planet near the Sun.")), MakeChoice(TEXT("red_planet"), TEXT("A red planet with rusty dust."))};
    Europa.CorrectChoiceId = TEXT("icy_moon");
    Europa.CorrectFeedback = FText::FromString(TEXT("Yes. Europa is an icy moon, and scientists study its hidden ocean clues."));
    Europa.RetryFeedback = FText::FromString(TEXT("Try the clue that says Europa is a moon, not a planet."));
    Europa.HintText = FText::FromString(TEXT("Europa travels around Jupiter."));
    Lessons.Add(Europa);
}

void AAstroAdventureGameModeBase::SpawnRuntimeScene()
{
    if (!GetWorld())
    {
        return;
    }

    if (!UGameplayStatics::GetActorOfClass(GetWorld(), APlayerStart::StaticClass()))
    {
        GetWorld()->SpawnActor<APlayerStart>(APlayerStart::StaticClass(), FVector(-500.0f, 0.0f, 80.0f), FRotator::ZeroRotator);
    }

    GetWorld()->SpawnActor<ADirectionalLight>(ADirectionalLight::StaticClass(), FVector(-600.0f, -500.0f, 800.0f), FRotator(-42.0f, -35.0f, 0.0f));

    const FVector Positions[] = {
        FVector(0.0f, -420.0f, 120.0f),
        FVector(280.0f, 0.0f, 150.0f),
        FVector(0.0f, 420.0f, 110.0f)
    };
    const FLinearColor Colors[] = {
        FLinearColor(0.62f, 0.62f, 0.58f),
        FLinearColor(0.85f, 0.25f, 0.12f),
        FLinearColor(0.45f, 0.78f, 1.0f)
    };

    DestinationActors.Reset();
    for (int32 Index = 0; Index < Lessons.Num(); ++Index)
    {
        AAstroDestinationActor* Actor = GetWorld()->SpawnActor<AAstroDestinationActor>(AAstroDestinationActor::StaticClass(), Positions[Index], FRotator::ZeroRotator);
        if (Actor)
        {
            Actor->Configure(Lessons[Index], Colors[Index]);
            Actor->SetDiscovered(GetMutableProgress(Lessons[Index].DestinationId).bQuizCompleted);
            DestinationActors.Add(Actor);
        }
    }
}

void AAstroAdventureGameModeBase::LoadProgress()
{
    if (USaveGame* Existing = UGameplayStatics::LoadGameFromSlot(SaveSlotName, SaveUserIndex))
    {
        ProgressSave = Cast<UAstroProgressSaveGame>(Existing);
    }

    if (!ProgressSave)
    {
        ProgressSave = Cast<UAstroProgressSaveGame>(UGameplayStatics::CreateSaveGameObject(UAstroProgressSaveGame::StaticClass()));
    }

    ProgressSave->MissionId = MissionId;
    ProgressSave->AgeBand = ActiveAgeBand;

    for (const FAstroDestinationLesson& Lesson : Lessons)
    {
        GetMutableProgress(Lesson.DestinationId);
    }
}

void AAstroAdventureGameModeBase::SaveProgress() const
{
    if (ProgressSave)
    {
        UGameplayStatics::SaveGameToSlot(ProgressSave, SaveSlotName, SaveUserIndex);
    }
}

void AAstroAdventureGameModeBase::FocusNextDestination()
{
    if (Lessons.IsEmpty() || CurrentScreen == EAstroMissionScreen::Quiz || CurrentScreen == EAstroMissionScreen::QuizFeedback)
    {
        MoveQuizFocus(1);
        return;
    }

    FocusedDestinationIndex = (FocusedDestinationIndex + 1) % Lessons.Num();
    UpdateDestinationFocus();
}

void AAstroAdventureGameModeBase::FocusPreviousDestination()
{
    if (Lessons.IsEmpty() || CurrentScreen == EAstroMissionScreen::Quiz || CurrentScreen == EAstroMissionScreen::QuizFeedback)
    {
        MoveQuizFocus(-1);
        return;
    }

    FocusedDestinationIndex = (FocusedDestinationIndex - 1 + Lessons.Num()) % Lessons.Num();
    UpdateDestinationFocus();
}

void AAstroAdventureGameModeBase::Confirm()
{
    const FAstroDestinationLesson* Lesson = GetFocusedLesson();
    if (!Lesson)
    {
        return;
    }

    bShowingHint = false;
    switch (CurrentScreen)
    {
    case EAstroMissionScreen::MissionPrompt:
        CurrentScreen = EAstroMissionScreen::Navigation;
        break;
    case EAstroMissionScreen::Navigation:
        MarkScanned(Lesson->DestinationId);
        CurrentScreen = EAstroMissionScreen::DiscoveryCard;
        break;
    case EAstroMissionScreen::DiscoveryCard:
        FocusedQuizChoiceIndex = 0;
        CurrentScreen = EAstroMissionScreen::Quiz;
        break;
    case EAstroMissionScreen::Quiz:
        SubmitAnswer(FocusedQuizChoiceIndex);
        break;
    case EAstroMissionScreen::QuizFeedback:
        if (bLastAnswerCorrect)
        {
            CompleteQuiz(Lesson->DestinationId, true);
            CurrentScreen = IsMissionComplete() ? EAstroMissionScreen::MissionComplete : EAstroMissionScreen::Navigation;
        }
        else
        {
            CurrentScreen = EAstroMissionScreen::Quiz;
        }
        break;
    case EAstroMissionScreen::MissionComplete:
        CurrentScreen = EAstroMissionScreen::Navigation;
        break;
    default:
        break;
    }

    UpdateDestinationFocus();
}

void AAstroAdventureGameModeBase::Back()
{
    bShowingHint = false;
    if (CurrentScreen == EAstroMissionScreen::Quiz)
    {
        CurrentScreen = EAstroMissionScreen::DiscoveryCard;
    }
    else if (CurrentScreen == EAstroMissionScreen::DiscoveryCard || CurrentScreen == EAstroMissionScreen::QuizFeedback)
    {
        CurrentScreen = EAstroMissionScreen::Navigation;
    }
}

void AAstroAdventureGameModeBase::RequestHint()
{
    bShowingHint = true;
}

void AAstroAdventureGameModeBase::MoveQuizFocus(const int32 Direction)
{
    const FAstroDestinationLesson* Lesson = GetFocusedLesson();
    if (!Lesson || Lesson->Choices.IsEmpty() || CurrentScreen != EAstroMissionScreen::Quiz)
    {
        return;
    }

    FocusedQuizChoiceIndex = (FocusedQuizChoiceIndex + Direction + Lesson->Choices.Num()) % Lesson->Choices.Num();
}

void AAstroAdventureGameModeBase::SubmitAnswer(const int32 ChoiceIndex)
{
    const FAstroDestinationLesson* Lesson = GetFocusedLesson();
    if (!Lesson || !Lesson->Choices.IsValidIndex(ChoiceIndex))
    {
        return;
    }

    FAstroDestinationProgress& Progress = GetMutableProgress(Lesson->DestinationId);
    Progress.Attempts += 1;

    bLastAnswerCorrect = Lesson->Choices[ChoiceIndex].ChoiceId == Lesson->CorrectChoiceId;
    LastFeedback = (bLastAnswerCorrect ? Lesson->CorrectFeedback : Lesson->RetryFeedback).ToString();
    CurrentScreen = EAstroMissionScreen::QuizFeedback;

    if (!bLastAnswerCorrect)
    {
        CompleteQuiz(Lesson->DestinationId, false);
    }
    SaveProgress();
}

FString AAstroAdventureGameModeBase::GetHudStatusLine() const
{
    const int32 CompleteCount = ProgressSave ? Algo::CountIf(Lessons, [this](const FAstroDestinationLesson& Lesson)
    {
        const FAstroDestinationProgress* Progress = ProgressSave->DestinationProgress.Find(Lesson.DestinationId);
        return Progress && Progress->bQuizCompleted;
    }) : 0;

    return FString::Printf(TEXT("Mission %s | Progress %d/%d | Age band %s"), *MissionId.ToString(), CompleteCount, Lessons.Num(), ActiveAgeBand == EAstroAgeBand::Ages4To6 ? TEXT("4-6") : ActiveAgeBand == EAstroAgeBand::Ages7To9 ? TEXT("7-9") : TEXT("10-12"));
}

FString AAstroAdventureGameModeBase::GetHudPrimaryLine() const
{
    const FAstroDestinationLesson* Lesson = GetFocusedLesson();
    const FString Name = Lesson ? Lesson->DisplayName.ToString() : TEXT("space");

    switch (CurrentScreen)
    {
    case EAstroMissionScreen::MissionPrompt:
        return TEXT("Mission Control: Scan Mercury, Mars, and Europa. Match each world to its clue.");
    case EAstroMissionScreen::Navigation:
        return FString::Printf(TEXT("Focused destination: %s. Confirm to scan."), *Name);
    case EAstroMissionScreen::DiscoveryCard:
        return FString::Printf(TEXT("Discovery card - %s"), *Name);
    case EAstroMissionScreen::Quiz:
        return Lesson ? Lesson->QuizPrompt.ToString() : TEXT("Quiz");
    case EAstroMissionScreen::QuizFeedback:
        return LastFeedback;
    case EAstroMissionScreen::MissionComplete:
        return TEXT("Mission complete: you matched three space clues. Different worlds have different clues.");
    default:
        return TEXT("");
    }
}

TArray<FString> AAstroAdventureGameModeBase::GetHudDetailLines() const
{
    TArray<FString> Lines;
    const FAstroDestinationLesson* Lesson = GetFocusedLesson();
    if (!Lesson)
    {
        return Lines;
    }

    if (CurrentScreen == EAstroMissionScreen::DiscoveryCard)
    {
        Lines.Add(Lesson->DiscoveryFact.ToString());
        Lines.Add(UAstroLearningLibrary::LessonTextForAgeBand(*Lesson, ActiveAgeBand).ToString());
        Lines.Add(FString::Printf(TEXT("Source: %s"), *Lesson->SourceUrl));
    }
    else if (CurrentScreen == EAstroMissionScreen::Quiz)
    {
        for (int32 Index = 0; Index < Lesson->Choices.Num(); ++Index)
        {
            const FString Prefix = Index == FocusedQuizChoiceIndex ? TEXT("> ") : TEXT("  ");
            Lines.Add(FString::Printf(TEXT("%s%d. %s"), *Prefix, Index + 1, *Lesson->Choices[Index].Text.ToString()));
        }
    }
    else if (CurrentScreen == EAstroMissionScreen::QuizFeedback)
    {
        Lines.Add(bLastAnswerCorrect ? TEXT("Confirm to save this discovery.") : TEXT("Confirm to retry, or ask for a hint."));
    }
    else if (CurrentScreen == EAstroMissionScreen::Navigation)
    {
        for (int32 Index = 0; Index < Lessons.Num(); ++Index)
        {
            const FAstroDestinationProgress* Progress = ProgressSave ? ProgressSave->DestinationProgress.Find(Lessons[Index].DestinationId) : nullptr;
            Lines.Add(FString::Printf(TEXT("%s %s - %s"), Index == FocusedDestinationIndex ? TEXT(">") : TEXT(" "), *Lessons[Index].DisplayName.ToString(), Progress && Progress->bQuizCompleted ? TEXT("discovered") : Progress && Progress->bScanned ? TEXT("scanned") : TEXT("ready")));
        }
    }

    if (bShowingHint)
    {
        Lines.Add(FString::Printf(TEXT("Hint: %s"), *Lesson->HintText.ToString()));
    }

    return Lines;
}

void AAstroAdventureGameModeBase::UpdateDestinationFocus()
{
    for (int32 Index = 0; Index < DestinationActors.Num(); ++Index)
    {
        if (DestinationActors[Index])
        {
            DestinationActors[Index]->SetFocused(Index == FocusedDestinationIndex);
            const FAstroDestinationProgress* Progress = ProgressSave ? ProgressSave->DestinationProgress.Find(DestinationActors[Index]->DestinationId) : nullptr;
            DestinationActors[Index]->SetDiscovered(Progress && Progress->bQuizCompleted);
        }
    }
}

void AAstroAdventureGameModeBase::MarkScanned(const FName DestinationId)
{
    FAstroDestinationProgress& Progress = GetMutableProgress(DestinationId);
    Progress.bScanned = true;
    SaveProgress();
}

void AAstroAdventureGameModeBase::CompleteQuiz(const FName DestinationId, const bool bAnsweredCorrectly)
{
    FAstroDestinationProgress& Progress = GetMutableProgress(DestinationId);
    Progress.bQuizCompleted = Progress.bQuizCompleted || bAnsweredCorrectly;
    Progress.CorrectAnswers += bAnsweredCorrectly ? 1 : 0;
    Progress.MasteryScore = FMath::Clamp(Progress.MasteryScore + UAstroLearningLibrary::MasteryDelta(bAnsweredCorrectly, Progress.Attempts), 0, 100);
    Progress.ReviewBox = UAstroLearningLibrary::NextReviewBox(Progress.ReviewBox, bAnsweredCorrectly);
    Progress.NextReviewAtUtc = FDateTime::UtcNow() + FTimespan::FromDays(UAstroLearningLibrary::ReviewDelayDaysForBox(Progress.ReviewBox));
    SaveProgress();
}

bool AAstroAdventureGameModeBase::IsMissionComplete() const
{
    if (!ProgressSave)
    {
        return false;
    }

    for (const FAstroDestinationLesson& Lesson : Lessons)
    {
        const FAstroDestinationProgress* Progress = ProgressSave->DestinationProgress.Find(Lesson.DestinationId);
        if (!Progress || !Progress->bQuizCompleted)
        {
            return false;
        }
    }

    return true;
}

const FAstroDestinationLesson* AAstroAdventureGameModeBase::GetFocusedLesson() const
{
    return Lessons.IsValidIndex(FocusedDestinationIndex) ? &Lessons[FocusedDestinationIndex] : nullptr;
}

FAstroDestinationProgress& AAstroAdventureGameModeBase::GetMutableProgress(const FName DestinationId)
{
    check(ProgressSave);
    return ProgressSave->DestinationProgress.FindOrAdd(DestinationId);
}
