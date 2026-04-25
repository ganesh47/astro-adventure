#if WITH_DEV_AUTOMATION_TESTS

#include "AstroLearningLibrary.h"
#include "Misc/AutomationTest.h"

IMPLEMENT_SIMPLE_AUTOMATION_TEST(FAstroReviewBoxTest, "AstroAdventure.Learning.ReviewBox", EAutomationTestFlags::EditorContext | EAutomationTestFlags::EngineFilter)

bool FAstroReviewBoxTest::RunTest(const FString& Parameters)
{
    TestEqual(TEXT("Correct answer advances to box 1 from new content"), UAstroLearningLibrary::NextReviewBox(0, true), 1);
    TestEqual(TEXT("Correct answer caps at box 5"), UAstroLearningLibrary::NextReviewBox(5, true), 5);
    TestEqual(TEXT("Incorrect answer resets to box 1"), UAstroLearningLibrary::NextReviewBox(4, false), 1);
    TestEqual(TEXT("Box 3 review delay is four days"), UAstroLearningLibrary::ReviewDelayDaysForBox(3), 4);
    return true;
}

IMPLEMENT_SIMPLE_AUTOMATION_TEST(FAstroMasteryDeltaTest, "AstroAdventure.Learning.MasteryDelta", EAutomationTestFlags::EditorContext | EAutomationTestFlags::EngineFilter)

bool FAstroMasteryDeltaTest::RunTest(const FString& Parameters)
{
    TestEqual(TEXT("First-try correct answer gives full mastery"), UAstroLearningLibrary::MasteryDelta(true, 1), 25);
    TestEqual(TEXT("Retry correct answer still gives growth"), UAstroLearningLibrary::MasteryDelta(true, 2), 15);
    TestEqual(TEXT("Incorrect answer does not add mastery"), UAstroLearningLibrary::MasteryDelta(false, 1), 0);
    return true;
}

#endif
