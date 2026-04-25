#pragma once

#include "CoreMinimal.h"
#include "Kismet/BlueprintFunctionLibrary.h"
#include "AstroLearningTypes.h"
#include "AstroLearningLibrary.generated.h"

UCLASS()
class ASTROADVENTUREUE_API UAstroLearningLibrary : public UBlueprintFunctionLibrary
{
    GENERATED_BODY()

public:
    UFUNCTION(BlueprintPure, Category = "Astro Adventure|Learning")
    static int32 NextReviewBox(int32 CurrentBox, bool bAnsweredCorrectly);

    UFUNCTION(BlueprintPure, Category = "Astro Adventure|Learning")
    static int32 ReviewDelayDaysForBox(int32 ReviewBox);

    UFUNCTION(BlueprintPure, Category = "Astro Adventure|Learning")
    static int32 MasteryDelta(bool bAnsweredCorrectly, int32 AttemptsForQuestion);

    UFUNCTION(BlueprintPure, Category = "Astro Adventure|Learning")
    static FText LessonTextForAgeBand(const FAstroDestinationLesson& Lesson, EAstroAgeBand AgeBand);
};
