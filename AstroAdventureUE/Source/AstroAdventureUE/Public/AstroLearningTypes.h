#pragma once

#include "CoreMinimal.h"
#include "AstroLearningTypes.generated.h"

UENUM(BlueprintType)
enum class EAstroAgeBand : uint8
{
    Ages4To6 UMETA(DisplayName = "Ages 4-6"),
    Ages7To9 UMETA(DisplayName = "Ages 7-9"),
    Ages10To12 UMETA(DisplayName = "Ages 10-12")
};

UENUM(BlueprintType)
enum class EAstroMissionScreen : uint8
{
    AgeSelect,
    MissionPrompt,
    Navigation,
    DiscoveryCard,
    DeepDive,
    Passport,
    Quiz,
    QuizFeedback,
    MissionComplete,
    PauseMenu
};

USTRUCT(BlueprintType)
struct FAstroQuizChoice
{
    GENERATED_BODY()

    UPROPERTY(EditAnywhere, BlueprintReadWrite, Category = "Astro Adventure")
    FName ChoiceId;

    UPROPERTY(EditAnywhere, BlueprintReadWrite, Category = "Astro Adventure")
    FText Text;
};

USTRUCT(BlueprintType)
struct FAstroDestinationLesson
{
    GENERATED_BODY()

    UPROPERTY(EditAnywhere, BlueprintReadWrite, Category = "Astro Adventure")
    FName DestinationId;

    UPROPERTY(EditAnywhere, BlueprintReadWrite, Category = "Astro Adventure")
    FText DisplayName;

    UPROPERTY(EditAnywhere, BlueprintReadWrite, Category = "Astro Adventure")
    FText DiscoveryFact;

    UPROPERTY(EditAnywhere, BlueprintReadWrite, Category = "Astro Adventure")
    FText WowFact;

    UPROPERTY(EditAnywhere, BlueprintReadWrite, Category = "Astro Adventure")
    FText VisualClue;

    UPROPERTY(EditAnywhere, BlueprintReadWrite, Category = "Astro Adventure")
    FText DeepDiveText;

    UPROPERTY(EditAnywhere, BlueprintReadWrite, Category = "Astro Adventure")
    FText CompareFact;

    UPROPERTY(EditAnywhere, BlueprintReadWrite, Category = "Astro Adventure")
    FText GlossaryText;

    UPROPERTY(EditAnywhere, BlueprintReadWrite, Category = "Astro Adventure")
    FText Ages4To6Text;

    UPROPERTY(EditAnywhere, BlueprintReadWrite, Category = "Astro Adventure")
    FText Ages7To9Text;

    UPROPERTY(EditAnywhere, BlueprintReadWrite, Category = "Astro Adventure")
    FText Ages10To12Text;

    UPROPERTY(EditAnywhere, BlueprintReadWrite, Category = "Astro Adventure")
    FString SourceUrl;

    UPROPERTY(EditAnywhere, BlueprintReadWrite, Category = "Astro Adventure")
    FText QuizPrompt;

    UPROPERTY(EditAnywhere, BlueprintReadWrite, Category = "Astro Adventure")
    TArray<FAstroQuizChoice> Choices;

    UPROPERTY(EditAnywhere, BlueprintReadWrite, Category = "Astro Adventure")
    FName CorrectChoiceId;

    UPROPERTY(EditAnywhere, BlueprintReadWrite, Category = "Astro Adventure")
    FText CorrectFeedback;

    UPROPERTY(EditAnywhere, BlueprintReadWrite, Category = "Astro Adventure")
    FText RetryFeedback;

    UPROPERTY(EditAnywhere, BlueprintReadWrite, Category = "Astro Adventure")
    FText HintText;

    UPROPERTY(EditAnywhere, BlueprintReadWrite, Category = "Astro Adventure")
    FLinearColor DisplayColor = FLinearColor::White;

    UPROPERTY(EditAnywhere, BlueprintReadWrite, Category = "Astro Adventure")
    float MapScale = 1.0f;

    UPROPERTY(EditAnywhere, BlueprintReadWrite, Category = "Astro Adventure")
    bool bRequiredForMission = true;
};

USTRUCT(BlueprintType)
struct FAstroDestinationProgress
{
    GENERATED_BODY()

    UPROPERTY(EditAnywhere, BlueprintReadWrite, Category = "Astro Adventure")
    bool bScanned = false;

    UPROPERTY(EditAnywhere, BlueprintReadWrite, Category = "Astro Adventure")
    bool bQuizCompleted = false;

    UPROPERTY(EditAnywhere, BlueprintReadWrite, Category = "Astro Adventure")
    int32 CorrectAnswers = 0;

    UPROPERTY(EditAnywhere, BlueprintReadWrite, Category = "Astro Adventure")
    int32 Attempts = 0;

    UPROPERTY(EditAnywhere, BlueprintReadWrite, Category = "Astro Adventure")
    int32 MasteryScore = 0;

    UPROPERTY(EditAnywhere, BlueprintReadWrite, Category = "Astro Adventure")
    int32 ReviewBox = 0;

    UPROPERTY(EditAnywhere, BlueprintReadWrite, Category = "Astro Adventure")
    FDateTime NextReviewAtUtc;
};
