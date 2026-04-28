#include "AstroMissionHUD.h"

#include "AstroAdventureGameModeBase.h"
#include "Engine/Canvas.h"
#include "Engine/Engine.h"
#include "Engine/World.h"

void AAstroMissionHUD::DrawHUD()
{
    Super::DrawHUD();

    UWorld* World = GetWorld();
    AAstroAdventureGameModeBase* GameMode = World ? World->GetAuthGameMode<AAstroAdventureGameModeBase>() : nullptr;
    if (!Canvas || !GameMode)
    {
        return;
    }

    const FString StatusLine = GameMode->GetHudStatusLine();
    const FString PrimaryLine = GameMode->GetHudPrimaryLine();
    const FString DisplayPrimaryLine = FriendlyPrimaryLine(PrimaryLine);
    const TArray<FString> DetailLines = GameMode->GetHudDetailLines();
    const EAstroMissionScreen CurrentScreen = GameMode->GetCurrentScreen();

    bool bHasQuizRows = false;
    bool bHasPassportRows = false;
    const bool bHasMenuRows = IsMenuScreen(CurrentScreen);
    bool bHasStampFeedback = GameMode->IsStampEffectActive() || PrimaryLine.Contains(TEXT("stamp unlocked"));
    for (const FString& Line : DetailLines)
    {
        bHasQuizRows = bHasQuizRows || IsQuizChoiceLine(Line);
        bHasPassportRows = bHasPassportRows || IsPassportRouteLine(Line);
        bHasStampFeedback = bHasStampFeedback || Line.Contains(TEXT("Stamp saved"));
    }

    const float Margin = 28.0f;
    const float HeaderH = 64.0f;
    DrawRect(FLinearColor(0.015f, 0.035f, 0.055f, 0.74f), 0.0f, 0.0f, Canvas->SizeX, HeaderH);
    DrawRect(FLinearColor(0.90f, 0.52f, 0.12f, 0.95f), 0.0f, HeaderH - 5.0f, Canvas->SizeX, 5.0f);
    DrawRect(FLinearColor(0.10f, 0.54f, 0.64f, 0.42f), 0.0f, HeaderH - 8.0f, Canvas->SizeX, 3.0f);

    DrawText(TEXT("SOLAR PASSPORT"), FLinearColor(1.0f, 0.96f, 0.78f), Margin, 12.0f, GEngine->GetSmallFont(), 1.10f, false);
    const float StatusBadgeW = FMath::Clamp(Canvas->SizeX - Margin * 2.0f - 270.0f, 190.0f, 430.0f);
    DrawBadge(FriendlyStatusLine(StatusLine), Margin + 246.0f, 17.0f, StatusBadgeW, FLinearColor(0.08f, 0.24f, 0.32f, 0.90f), FLinearColor(0.90f, 0.99f, 1.0f), 0.76f);

    const float CardW = FMath::Min(Canvas->SizeX - Margin * 2.0f, bHasQuizRows ? 1000.0f : 960.0f);
    const float CardH = bHasPassportRows ? 318.0f : bHasQuizRows ? 334.0f : bHasMenuRows ? 326.0f : 236.0f;
    const float CardX = (Canvas->SizeX - CardW) * 0.5f;
    const float CardY = Canvas->SizeY - CardH - 24.0f;

    if (GameMode->IsScanEffectActive())
    {
        const float ScanY = FMath::Fmod(World->GetTimeSeconds() * 420.0f, FMath::Max(1.0f, static_cast<float>(Canvas->SizeY)));
        DrawRect(FLinearColor(0.08f, 0.74f, 1.0f, 0.08f), 0.0f, 0.0f, Canvas->SizeX, Canvas->SizeY);
        DrawRect(FLinearColor(0.78f, 0.98f, 1.0f, 0.62f), 0.0f, ScanY, Canvas->SizeX, 5.0f);
        DrawFeedbackBanner(TEXT("DISCOVERY SCAN FOUND"), FLinearColor(0.04f, 0.42f, 0.58f, 0.94f), Canvas->SizeY * 0.22f);
    }

    DrawPassportFrame(CardX, CardY, CardW, CardH);
    if (!bHasQuizRows && !bHasPassportRows && !bHasMenuRows)
    {
        DrawStampStrip(StatusLine, CardX + 32.0f, CardY + CardH - 82.0f, CardW - 64.0f);
    }

    if (bHasStampFeedback)
    {
        DrawFeedbackBanner(TEXT("NEW STAMP IN YOUR PASSPORT"), FLinearColor(0.11f, 0.48f, 0.25f, 0.95f), CardY - 68.0f);
    }

    float Y = CardY + 24.0f;
    DrawLine(DisplayPrimaryLine, CardX + 42.0f, Y, FLinearColor(1.0f, 0.95f, 0.68f), bHasQuizRows ? 1.42f : 1.36f);

    if (bHasQuizRows)
    {
        Y += 8.0f;
        for (const FString& Line : DetailLines)
        {
            if (IsQuizChoiceLine(Line))
            {
                const bool bFocused = Line.TrimStart().StartsWith(TEXT(">"));
                DrawQuizRow(Line, CardX + 42.0f, Y, CardW - 84.0f, bFocused);
                Y += 72.0f;
            }
        }
    }
    else if (bHasMenuRows)
    {
        int32 DrawnRows = 0;
        Y += 8.0f;
        for (const FString& Line : DetailLines)
        {
            if (IsMenuChoiceLine(Line))
            {
                const bool bFocused = Line.TrimStart().StartsWith(TEXT(">"));
                DrawMenuRow(Line, CardX + 42.0f, Y, CardW - 84.0f, bFocused);
                Y += 42.0f;
                ++DrawnRows;
            }
        }

        int32 DrawnNotes = 0;
        for (const FString& Line : DetailLines)
        {
            if (IsMenuChoiceLine(Line))
            {
                continue;
            }

            const FString FriendlyLine = FriendlyDetailLine(Line);
            if (!FriendlyLine.IsEmpty())
            {
                float NoteY = Y + 4.0f;
                DrawLine(FriendlyLine, CardX + 42.0f, NoteY, FLinearColor(0.88f, 0.98f, 1.0f), 0.88f);
                ++DrawnNotes;
                if (DrawnNotes >= 2 || DrawnRows >= 4)
                {
                    break;
                }
            }
        }
    }
    else if (bHasPassportRows)
    {
        int32 DrawnRows = 0;
        Y += 8.0f;
        for (const FString& Line : DetailLines)
        {
            if (IsPassportRouteLine(Line))
            {
                DrawPassportRow(Line, CardX + 42.0f, Y, CardW - 84.0f);
                Y += 38.0f;
                ++DrawnRows;
                if (DrawnRows >= 5)
                {
                    break;
                }
            }
        }
    }
    else
    {
        int32 DrawnLines = 0;
        for (const FString& Line : DetailLines)
        {
            const FString FriendlyLine = FriendlyDetailLine(Line);
            if (FriendlyLine.IsEmpty())
            {
                continue;
            }

            DrawLine(FriendlyLine, CardX + 42.0f, Y, FLinearColor(0.91f, 0.98f, 1.0f), 1.02f);
            ++DrawnLines;
            if (DrawnLines >= 3)
            {
                break;
            }
        }
    }

    DrawActionBar(CurrentScreen, CardX + 30.0f, CardY + CardH - 40.0f, CardW - 60.0f, bHasQuizRows);
}

void AAstroMissionHUD::DrawLine(const FString& Text, const float X, float& Y, const FLinearColor& Color, const float Scale)
{
    DrawText(Text, Color, X, Y, GEngine->GetSmallFont(), Scale, false);
    Y += 24.0f * Scale;
}

void AAstroMissionHUD::DrawBadge(const FString& Text, const float X, const float Y, const float W, const FLinearColor& Fill, const FLinearColor& TextColor, const float Scale)
{
    DrawRect(Fill, X, Y, W, 30.0f);
    DrawRect(FLinearColor(1.0f, 0.96f, 0.76f, 0.18f), X, Y, W, 3.0f);
    DrawText(Text, TextColor, X + 11.0f, Y + 7.0f, GEngine->GetSmallFont(), Scale, false);
}

void AAstroMissionHUD::DrawPassportFrame(const float X, const float Y, const float W, const float H)
{
    DrawRect(FLinearColor(0.03f, 0.08f, 0.09f, 0.90f), X - 6.0f, Y + 6.0f, W + 12.0f, H);
    DrawRect(FLinearColor(0.06f, 0.15f, 0.18f, 0.94f), X, Y, W, H);
    DrawRect(FLinearColor(0.94f, 0.60f, 0.16f, 0.98f), X, Y, 16.0f, H);
    DrawRect(FLinearColor(0.93f, 0.82f, 0.54f, 0.30f), X + 28.0f, Y + 18.0f, W - 56.0f, 2.0f);
    DrawRect(FLinearColor(0.12f, 0.53f, 0.62f, 0.32f), X + 28.0f, Y + H - 54.0f, W - 56.0f, 2.0f);
}

void AAstroMissionHUD::DrawStampStrip(const FString& StatusLine, const float X, const float Y, const float W)
{
    int32 Stamped = 0;
    int32 Total = 0;
    GetStampProgress(StatusLine, Stamped, Total);
    if (Total <= 0)
    {
        return;
    }

    const int32 VisibleSlots = FMath::Clamp(Total, 1, 12);
    const float LabelW = 88.0f;
    const float SlotSize = FMath::Clamp((W - LabelW - 10.0f) / VisibleSlots - 5.0f, 16.0f, 28.0f);
    DrawText(TEXT("STAMPS"), FLinearColor(1.0f, 0.92f, 0.62f), X, Y + 6.0f, GEngine->GetSmallFont(), 0.78f, false);

    float SlotX = X + LabelW;
    for (int32 Index = 0; Index < VisibleSlots; ++Index)
    {
        DrawStampSlot(SlotX, Y, SlotSize, Index < Stamped, Index);
        SlotX += SlotSize + 5.0f;
    }
}

void AAstroMissionHUD::DrawStampSlot(const float X, const float Y, const float Size, const bool bFilled, const int32 Index)
{
    const FLinearColor Fill = bFilled ? FLinearColor(0.94f, 0.52f, 0.12f, 0.96f) : FLinearColor(0.78f, 0.92f, 0.95f, 0.18f);
    const FLinearColor Mark = bFilled ? FLinearColor(1.0f, 0.94f, 0.66f, 1.0f) : FLinearColor(0.72f, 0.92f, 0.96f, 0.26f);
    DrawRect(Fill, X, Y, Size, Size);
    DrawRect(FLinearColor(0.05f, 0.12f, 0.14f, 0.55f), X + 2.0f, Y + 2.0f, Size - 4.0f, Size - 4.0f);
    DrawRect(Mark, X + Size * 0.34f, Y + Size * 0.22f, Size * 0.32f, Size * 0.56f);
    if (Index % 2 == 0)
    {
        DrawRect(Mark, X + Size * 0.22f, Y + Size * 0.36f, Size * 0.56f, Size * 0.28f);
    }
}

void AAstroMissionHUD::DrawActionBar(const EAstroMissionScreen Screen, const float X, const float Y, const float W, const bool bHasQuizRows)
{
    TArray<FString> Actions;

    if (bHasQuizRows)
    {
        AddActionIfMissing(Actions, TEXT("Pick answer"));
        AddActionIfMissing(Actions, TEXT("Confirm"));
        AddActionIfMissing(Actions, TEXT("Hint"));
    }
    else if (Screen == EAstroMissionScreen::Home)
    {
        AddActionIfMissing(Actions, TEXT("Move"));
        AddActionIfMissing(Actions, TEXT("Confirm"));
        AddActionIfMissing(Actions, TEXT("Quit"));
    }
    else if (Screen == EAstroMissionScreen::AgeSelect)
    {
        AddActionIfMissing(Actions, TEXT("Pick age"));
        AddActionIfMissing(Actions, TEXT("Launch"));
        AddActionIfMissing(Actions, TEXT("Back"));
    }
    else if (Screen == EAstroMissionScreen::MissionPrompt)
    {
        AddActionIfMissing(Actions, TEXT("Launch"));
        AddActionIfMissing(Actions, TEXT("Back"));
        AddActionIfMissing(Actions, TEXT("Pause"));
    }
    else if (Screen == EAstroMissionScreen::PauseMenu)
    {
        AddActionIfMissing(Actions, TEXT("Move"));
        AddActionIfMissing(Actions, TEXT("Confirm"));
        AddActionIfMissing(Actions, TEXT("Quit"));
    }
    else if (Screen == EAstroMissionScreen::MissionComplete)
    {
        AddActionIfMissing(Actions, TEXT("Move"));
        AddActionIfMissing(Actions, TEXT("Confirm"));
        AddActionIfMissing(Actions, TEXT("Quit"));
    }
    else if (Screen == EAstroMissionScreen::Navigation)
    {
        AddActionIfMissing(Actions, TEXT("Scan"));
        AddActionIfMissing(Actions, TEXT("Passport"));
        AddActionIfMissing(Actions, TEXT("Pause"));
    }
    else if (Screen == EAstroMissionScreen::Passport || Screen == EAstroMissionScreen::AtlasView)
    {
        AddActionIfMissing(Actions, TEXT("Pick stop"));
        AddActionIfMissing(Actions, TEXT("Open stop"));
        AddActionIfMissing(Actions, TEXT("Back"));
    }
    else if (Screen == EAstroMissionScreen::DiscoveryCard)
    {
        AddActionIfMissing(Actions, TEXT("Quiz"));
        AddActionIfMissing(Actions, TEXT("More Info"));
        AddActionIfMissing(Actions, TEXT("Back"));
    }
    else if (Screen == EAstroMissionScreen::DeepDive)
    {
        AddActionIfMissing(Actions, TEXT("Close Info"));
        AddActionIfMissing(Actions, TEXT("Quiz"));
        AddActionIfMissing(Actions, TEXT("Back"));
    }
    else if (Screen == EAstroMissionScreen::QuizFeedback)
    {
        AddActionIfMissing(Actions, TEXT("Next"));
        AddActionIfMissing(Actions, TEXT("Hint"));
        AddActionIfMissing(Actions, TEXT("Retry"));
    }
    else if (Screen == EAstroMissionScreen::StampAward)
    {
        AddActionIfMissing(Actions, TEXT("Next"));
        AddActionIfMissing(Actions, TEXT("Passport"));
        AddActionIfMissing(Actions, TEXT("Pause"));
    }
    else
    {
        AddActionIfMissing(Actions, TEXT("Confirm"));
        AddActionIfMissing(Actions, TEXT("Back"));
        AddActionIfMissing(Actions, TEXT("Pause"));
    }

    float BadgeX = X;
    for (int32 Index = 0; Index < Actions.Num() && Index < 3; ++Index)
    {
        const float BadgeW = FMath::Clamp(38.0f + Actions[Index].Len() * 10.0f, 82.0f, 142.0f);
        if (BadgeX + BadgeW > X + W)
        {
            break;
        }

        const FLinearColor Fill = Index == 0 ? FLinearColor(0.10f, 0.48f, 0.44f, 0.96f) : FLinearColor(0.12f, 0.24f, 0.32f, 0.96f);
        DrawBadge(Actions[Index], BadgeX, Y, BadgeW, Fill, FLinearColor::White, 0.82f);
        BadgeX += BadgeW + 10.0f;
    }
}

void AAstroMissionHUD::DrawMenuRow(const FString& Text, const float X, const float Y, const float W, const bool bFocused)
{
    FString ChoiceText = FriendlyDetailLine(Text);
    ChoiceText.RemoveFromStart(TEXT(">"));
    ChoiceText.TrimStartAndEndInline();

    const FLinearColor Fill = bFocused ? FLinearColor(0.96f, 0.66f, 0.18f, 0.96f) : FLinearColor(0.08f, 0.18f, 0.22f, 0.90f);
    const FLinearColor Stripe = bFocused ? FLinearColor(1.0f, 0.95f, 0.62f, 1.0f) : FLinearColor(0.18f, 0.46f, 0.56f, 0.86f);
    const FLinearColor TextColor = bFocused ? FLinearColor(0.05f, 0.06f, 0.07f, 1.0f) : FLinearColor(0.94f, 0.98f, 1.0f, 1.0f);

    DrawRect(Fill, X, Y, W, 34.0f);
    DrawRect(Stripe, X, Y, 10.0f, 34.0f);
    DrawText(bFocused ? TEXT("READY") : TEXT(""), TextColor, X + 20.0f, Y + 8.0f, GEngine->GetSmallFont(), 0.62f, false);
    DrawText(ChoiceText, TextColor, X + (bFocused ? 92.0f : 24.0f), Y + 7.0f, GEngine->GetSmallFont(), 0.96f, false);
}

void AAstroMissionHUD::DrawQuizRow(const FString& Text, const float X, const float Y, const float W, const bool bFocused)
{
    FString ChoiceText = FriendlyDetailLine(Text);
    ChoiceText.RemoveFromStart(TEXT(">"));
    ChoiceText.TrimStartAndEndInline();

    const FLinearColor Fill = bFocused ? FLinearColor(0.98f, 0.66f, 0.18f, 0.96f) : FLinearColor(0.08f, 0.19f, 0.24f, 0.96f);
    const FLinearColor Stripe = bFocused ? FLinearColor(1.0f, 0.94f, 0.60f, 1.0f) : FLinearColor(0.28f, 0.56f, 0.86f, 0.84f);
    const FLinearColor TextColor = bFocused ? FLinearColor(0.06f, 0.06f, 0.08f, 1.0f) : FLinearColor(0.94f, 0.97f, 1.0f, 1.0f);

    DrawRect(Fill, X, Y, W, 64.0f);
    DrawRect(Stripe, X, Y, 12.0f, 64.0f);
    DrawText(bFocused ? TEXT("READY") : TEXT("PICK"), TextColor, X + 22.0f, Y + 12.0f, GEngine->GetSmallFont(), 0.76f, false);
    DrawText(ChoiceText, TextColor, X + 122.0f, Y + 17.0f, GEngine->GetSmallFont(), 1.18f, false);
}

void AAstroMissionHUD::DrawPassportRow(const FString& Text, const float X, const float Y, const float W)
{
    FString Row = Text;
    Row.TrimStartAndEndInline();
    const bool bFocused = Row.StartsWith(TEXT(">"));
    Row.RemoveFromStart(TEXT(">"));
    Row.TrimStartAndEndInline();

    FString StopName;
    FString Rest;
    Row.Split(TEXT("|"), &StopName, &Rest);
    StopName.TrimStartAndEndInline();
    Rest.TrimStartAndEndInline();

    const bool bStamped = Rest.StartsWith(TEXT("stamped"));
    const bool bQuizReady = Rest.StartsWith(TEXT("quiz ready"));
    const FString StampLabel = bStamped ? TEXT("STAMPED") : bQuizReady ? TEXT("QUIZ") : TEXT("VISIT");
    const FLinearColor Fill = bFocused ? FLinearColor(0.91f, 0.58f, 0.18f, 0.94f) : FLinearColor(0.08f, 0.18f, 0.20f, 0.88f);
    const FLinearColor TextColor = bFocused ? FLinearColor(0.05f, 0.06f, 0.06f, 1.0f) : FLinearColor(0.92f, 0.98f, 1.0f, 1.0f);
    const FLinearColor StampColor = bStamped ? FLinearColor(0.96f, 0.45f, 0.16f, 0.98f) : bQuizReady ? FLinearColor(0.12f, 0.56f, 0.64f, 0.98f) : FLinearColor(0.55f, 0.62f, 0.66f, 0.78f);

    DrawRect(Fill, X, Y, W, 30.0f);
    DrawRect(StampColor, X + 8.0f, Y + 5.0f, 84.0f, 20.0f);
    DrawText(StampLabel, FLinearColor::White, X + 15.0f, Y + 8.0f, GEngine->GetSmallFont(), 0.60f, false);
    DrawText(StopName, TextColor, X + 110.0f, Y + 6.0f, GEngine->GetSmallFont(), 0.92f, false);
}

void AAstroMissionHUD::DrawFeedbackBanner(const FString& Text, const FLinearColor& Fill, const float Y)
{
    const float BannerW = FMath::Min(Canvas->SizeX - 64.0f, 610.0f);
    const float BannerX = (Canvas->SizeX - BannerW) * 0.5f;
    DrawRect(FLinearColor(0.02f, 0.04f, 0.05f, 0.62f), BannerX + 6.0f, Y + 6.0f, BannerW, 54.0f);
    DrawRect(Fill, BannerX, Y, BannerW, 54.0f);
    DrawRect(FLinearColor(1.0f, 0.92f, 0.42f, 0.96f), BannerX, Y, 12.0f, 54.0f);
    DrawRect(FLinearColor(1.0f, 0.92f, 0.42f, 0.96f), BannerX + BannerW - 12.0f, Y, 12.0f, 54.0f);
    DrawRect(FLinearColor(1.0f, 0.97f, 0.72f, 0.86f), BannerX + 34.0f, Y + 10.0f, 9.0f, 9.0f);
    DrawRect(FLinearColor(1.0f, 0.97f, 0.72f, 0.86f), BannerX + BannerW - 48.0f, Y + 35.0f, 9.0f, 9.0f);
    DrawText(Text, FLinearColor::White, BannerX + 58.0f, Y + 14.0f, GEngine->GetSmallFont(), 1.12f, false);
}

void AAstroMissionHUD::AddActionIfMissing(TArray<FString>& Actions, const FString& Action) const
{
    if (!Actions.Contains(Action))
    {
        Actions.Add(Action);
    }
}

void AAstroMissionHUD::GetStampProgress(const FString& StatusLine, int32& OutStamped, int32& OutTotal) const
{
    OutStamped = 0;
    OutTotal = 0;

    FString BeforePassport;
    FString AfterPassport;
    if (!StatusLine.Split(TEXT("Passport "), &BeforePassport, &AfterPassport))
    {
        return;
    }

    FString CountText;
    FString AfterCounts;
    if (!AfterPassport.Split(TEXT(" stamps"), &CountText, &AfterCounts))
    {
        return;
    }

    FString StampedText;
    FString TotalText;
    if (!CountText.Split(TEXT("/"), &StampedText, &TotalText))
    {
        return;
    }

    OutStamped = FMath::Max(0, FCString::Atoi(*StampedText));
    OutTotal = FMath::Max(0, FCString::Atoi(*TotalText));
}

bool AAstroMissionHUD::LooksLikeRawTechnicalLine(const FString& Text) const
{
    const FString Trimmed = Text.TrimStartAndEnd();
    const FString Lower = Trimmed.ToLower();
    return Lower.Contains(TEXT("http://")) || Lower.Contains(TEXT("https://"))
        || Lower.Contains(TEXT("docs/")) || Lower.Contains(TEXT("/source/")) || Lower.Contains(TEXT("source/"))
        || Lower.Contains(TEXT("content/")) || Lower.Contains(TEXT("saved/")) || Lower.Contains(TEXT("config/"))
        || Lower.Contains(TEXT(".cpp")) || Lower.Contains(TEXT(".h")) || Lower.Contains(TEXT("\\"))
        || Lower.StartsWith(TEXT("log")) || Lower.StartsWith(TEXT("warning:")) || Lower.StartsWith(TEXT("error:"));
}

bool AAstroMissionHUD::IsMenuScreen(const EAstroMissionScreen Screen) const
{
    return Screen == EAstroMissionScreen::Home
        || Screen == EAstroMissionScreen::AgeSelect
        || Screen == EAstroMissionScreen::PauseMenu
        || Screen == EAstroMissionScreen::MissionComplete;
}

bool AAstroMissionHUD::IsMenuChoiceLine(const FString& Text) const
{
    const FString Trimmed = Text.TrimStartAndEnd();
    if (!(Trimmed.StartsWith(TEXT(">")) || Trimmed.StartsWith(TEXT("New Expedition")) || Trimmed.StartsWith(TEXT("Continue"))
        || Trimmed.StartsWith(TEXT("Reset Passport")) || Trimmed.StartsWith(TEXT("Quit"))
        || Trimmed.StartsWith(TEXT("Ages ")) || Trimmed.StartsWith(TEXT("Resume"))
        || Trimmed.StartsWith(TEXT("Restart")) || Trimmed.StartsWith(TEXT("Change age"))
        || Trimmed.StartsWith(TEXT("Explore again")) || Trimmed.StartsWith(TEXT("Open Passport"))))
    {
        return false;
    }

    return Trimmed.Contains(TEXT("New Expedition")) || Trimmed.Contains(TEXT("Continue"))
        || Trimmed.Contains(TEXT("Reset Passport")) || Trimmed.Contains(TEXT("Quit"))
        || Trimmed.Contains(TEXT("Ages 4-6")) || Trimmed.Contains(TEXT("Ages 7-9")) || Trimmed.Contains(TEXT("Ages 10-12"))
        || Trimmed.Contains(TEXT("Resume")) || Trimmed.Contains(TEXT("Restart mission"))
        || Trimmed.Contains(TEXT("Change age")) || Trimmed.Contains(TEXT("Explore again"))
        || Trimmed.Contains(TEXT("Open Passport"));
}

bool AAstroMissionHUD::IsQuizChoiceLine(const FString& Text) const
{
    const FString Trimmed = Text.TrimStart();
    return Trimmed.StartsWith(TEXT("> 1.")) || Trimmed.StartsWith(TEXT("> 2.")) || Trimmed.StartsWith(TEXT("> 3."))
        || Trimmed.StartsWith(TEXT("1.")) || Trimmed.StartsWith(TEXT("2.")) || Trimmed.StartsWith(TEXT("3."));
}

bool AAstroMissionHUD::IsPassportRouteLine(const FString& Text) const
{
    const FString Lower = Text.ToLower();
    return Lower.Contains(TEXT("|")) && (Lower.Contains(TEXT("stamped")) || Lower.Contains(TEXT("quiz ready")) || Lower.Contains(TEXT("not scanned")));
}

FString AAstroMissionHUD::FriendlyPrimaryLine(const FString& Text) const
{
    FString Result = Text;
    Result.TrimStartAndEndInline();

    if (Result.IsEmpty())
    {
        return TEXT("Choose your next passport step.");
    }

    if (LooksLikeRawTechnicalLine(Result))
    {
        return TEXT("Follow the Solar Passport clue.");
    }

    Result.ReplaceInline(TEXT("stamp unlocked"), TEXT("stamp unlocked!"), ESearchCase::IgnoreCase);
    Result.ReplaceInline(TEXT("mission complete"), TEXT("mission complete!"), ESearchCase::IgnoreCase);
    Result.ReplaceInline(TEXT("discovery card"), TEXT("discovery card"), ESearchCase::IgnoreCase);
    return Result;
}

FString AAstroMissionHUD::FriendlyStatusLine(const FString& Text) const
{
    int32 Stamped = 0;
    int32 Total = 0;
    GetStampProgress(Text, Stamped, Total);
    if (Total > 0)
    {
        return FString::Printf(TEXT("Passport %d/%d stamps"), Stamped, Total);
    }

    FString Result = Text;
    Result.TrimStartAndEndInline();
    if (Result.IsEmpty() || LooksLikeRawTechnicalLine(Result))
    {
        return TEXT("Solar Passport ready");
    }

    Result.ReplaceInline(TEXT(" | "), TEXT("   "));
    Result.ReplaceInline(TEXT("Explorer mode ages"), TEXT("Ages"));
    return Result;
}

FString AAstroMissionHUD::FriendlyDetailLine(const FString& Text) const
{
    FString Result = Text;
    Result.TrimStartAndEndInline();

    if (Result.StartsWith(TEXT("Atlas route:")) || Result.StartsWith(TEXT("Sources are tracked")) || LooksLikeRawTechnicalLine(Result))
    {
        return TEXT("");
    }

    Result.ReplaceInline(TEXT("Press M / LT for More Info, or Confirm for the quiz."), TEXT("More Info opens a closer look. Confirm starts the quiz."));
    Result.ReplaceInline(TEXT("Open Passport / RT for the full Atlas route."), TEXT("Passport shows the full route."));
    Result.ReplaceInline(TEXT("Confirm to scan for a discovery card."), TEXT("Confirm to scan this stop."));
    Result.ReplaceInline(TEXT("Scan found. Confirm to open its card again."), TEXT("Scan found. Confirm to reopen the card."));
    Result.ReplaceInline(TEXT("Stamped already. Pick another stop or open Passport."), TEXT("Stamp saved already. Pick another stop."));
    Result.ReplaceInline(TEXT("Review box "), TEXT("Review round "));
    Result.ReplaceInline(TEXT(" | mastery "), TEXT(" - recall "));
    Result.ReplaceInline(TEXT(" | review box "), TEXT(" - review "));
    Result.ReplaceInline(TEXT(" | box "), TEXT(" - review "));
    Result.ReplaceInline(TEXT("passport stamped"), TEXT("stamp saved"));
    Result.ReplaceInline(TEXT("quiz ready"), TEXT("quiz ready"));
    Result.ReplaceInline(TEXT("not scanned"), TEXT("ready to visit"));
    Result.ReplaceInline(TEXT("ready to scan"), TEXT("ready to scan"));
    Result.ReplaceInline(TEXT("mastery"), TEXT("recall"));

    if (Result.StartsWith(TEXT("Atlas View:")))
    {
        return TEXT("Pick a passport stop to inspect.");
    }

    if (Result.StartsWith(TEXT(">")) && !IsQuizChoiceLine(Result) && !IsPassportRouteLine(Result))
    {
        Result.RightChopInline(1);
        Result.TrimStartAndEndInline();
        Result = FString::Printf(TEXT("READY: %s"), *Result);
    }

    if ((Result.StartsWith(TEXT("*")) || Result.StartsWith(TEXT("-"))) && Result.Contains(TEXT(" - recall ")))
    {
        const bool bStamped = Result.StartsWith(TEXT("*"));
        Result.RightChopInline(1);
        Result.TrimStartAndEndInline();

        FString StopName;
        FString Unused;
        Result.Split(TEXT(" - recall "), &StopName, &Unused);
        Result = FString::Printf(TEXT("%s %s"), bStamped ? TEXT("STAMP") : TEXT("OPEN"), *StopName);
    }

    return Result;
}
