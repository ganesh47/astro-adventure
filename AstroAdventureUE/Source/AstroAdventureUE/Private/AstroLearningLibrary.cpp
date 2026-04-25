#include "AstroLearningLibrary.h"

int32 UAstroLearningLibrary::NextReviewBox(const int32 CurrentBox, const bool bAnsweredCorrectly)
{
    if (bAnsweredCorrectly)
    {
        return FMath::Clamp(CurrentBox + 1, 1, 5);
    }

    return 1;
}

int32 UAstroLearningLibrary::ReviewDelayDaysForBox(const int32 ReviewBox)
{
    static constexpr int32 Delays[] = {0, 1, 2, 4, 8, 16};
    return Delays[FMath::Clamp(ReviewBox, 0, 5)];
}

int32 UAstroLearningLibrary::MasteryDelta(const bool bAnsweredCorrectly, const int32 AttemptsForQuestion)
{
    if (!bAnsweredCorrectly)
    {
        return 0;
    }

    return AttemptsForQuestion <= 1 ? 25 : 15;
}

FText UAstroLearningLibrary::LessonTextForAgeBand(const FAstroDestinationLesson& Lesson, const EAstroAgeBand AgeBand)
{
    switch (AgeBand)
    {
    case EAstroAgeBand::Ages4To6:
        return Lesson.Ages4To6Text;
    case EAstroAgeBand::Ages7To9:
        return Lesson.Ages7To9Text;
    case EAstroAgeBand::Ages10To12:
        return Lesson.Ages10To12Text;
    default:
        return Lesson.Ages7To9Text;
    }
}
