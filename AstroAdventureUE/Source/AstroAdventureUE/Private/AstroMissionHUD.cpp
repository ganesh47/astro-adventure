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
    const TArray<FString> DetailLines = GameMode->GetHudDetailLines();

    bool bHasQuizRows = false;
    bool bHasPassportRows = false;
    bool bHasStampFeedback = GameMode->IsStampEffectActive() || PrimaryLine.Contains(TEXT("stamp unlocked"));
    for (const FString& Line : DetailLines)
    {
        bHasQuizRows = bHasQuizRows || IsQuizChoiceLine(Line);
        bHasPassportRows = bHasPassportRows || IsPassportRouteLine(Line);
        bHasStampFeedback = bHasStampFeedback || Line.Contains(TEXT("Stamp saved"));
    }

    const float Margin = 34.0f;
    const float HeaderH = 92.0f;
    DrawRect(FLinearColor(0.015f, 0.035f, 0.055f, 0.84f), 0.0f, 0.0f, Canvas->SizeX, HeaderH);
    DrawRect(FLinearColor(0.90f, 0.52f, 0.12f, 0.96f), 0.0f, HeaderH - 7.0f, Canvas->SizeX, 7.0f);
    DrawRect(FLinearColor(0.10f, 0.54f, 0.64f, 0.54f), 0.0f, HeaderH - 12.0f, Canvas->SizeX, 5.0f);

    DrawText(TEXT("SOLAR PASSPORT"), FLinearColor(1.0f, 0.96f, 0.78f), Margin, 13.0f, GEngine->GetSmallFont(), 1.42f, false);
    DrawText(TEXT("Astro Adventure"), FLinearColor(0.70f, 0.94f, 0.98f), Margin + 3.0f, 48.0f, GEngine->GetSmallFont(), 0.84f, false);
    const float StatusBadgeW = FMath::Clamp(Canvas->SizeX - Margin * 2.0f - 318.0f, 210.0f, 590.0f);
    FString FriendlyStatus = StatusLine.Replace(TEXT(" | "), TEXT("    "));
    FriendlyStatus.ReplaceInline(TEXT("Explorer mode ages"), TEXT("Ages"));
    DrawBadge(FriendlyStatus, Margin + 304.0f, 22.0f, StatusBadgeW, FLinearColor(0.08f, 0.24f, 0.32f, 0.94f), FLinearColor(0.90f, 0.99f, 1.0f), 0.82f);

    const float CardW = FMath::Min(Canvas->SizeX - Margin * 2.0f, 1120.0f);
    const float CardH = bHasPassportRows ? 376.0f : bHasQuizRows ? 384.0f : 258.0f;
    const float CardX = (Canvas->SizeX - CardW) * 0.5f;
    const float CardY = Canvas->SizeY - CardH - 34.0f;

    if (GameMode->IsScanEffectActive())
    {
        const float ScanY = FMath::Fmod(World->GetTimeSeconds() * 420.0f, FMath::Max(1.0f, static_cast<float>(Canvas->SizeY)));
        DrawRect(FLinearColor(0.08f, 0.74f, 1.0f, 0.12f), 0.0f, 0.0f, Canvas->SizeX, Canvas->SizeY);
        DrawRect(FLinearColor(0.78f, 0.98f, 1.0f, 0.62f), 0.0f, ScanY, Canvas->SizeX, 5.0f);
        DrawFeedbackBanner(TEXT("DISCOVERY SCAN FOUND"), FLinearColor(0.04f, 0.42f, 0.58f, 0.94f), Canvas->SizeY * 0.27f);
    }

    DrawPassportFrame(CardX, CardY, CardW, CardH);
    DrawStampStrip(StatusLine, CardX + 32.0f, CardY + CardH - 92.0f, CardW - 64.0f);

    if (bHasStampFeedback)
    {
        DrawFeedbackBanner(TEXT("NEW STAMP IN YOUR PASSPORT"), FLinearColor(0.11f, 0.48f, 0.25f, 0.95f), CardY - 68.0f);
    }

    float Y = CardY + 27.0f;
    DrawLine(PrimaryLine, CardX + 42.0f, Y, FLinearColor(1.0f, 0.95f, 0.68f), bHasQuizRows ? 1.24f : 1.30f);

    if (bHasQuizRows)
    {
        Y += 12.0f;
        for (const FString& Line : DetailLines)
        {
            if (IsQuizChoiceLine(Line))
            {
                const bool bFocused = Line.TrimStart().StartsWith(TEXT(">"));
                DrawQuizRow(Line, CardX + 42.0f, Y, CardW - 84.0f, bFocused);
                Y += 66.0f;
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
                Y += 36.0f;
                ++DrawnRows;
                if (DrawnRows >= 6)
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
            if (DrawnLines >= 4)
            {
                break;
            }
        }
    }

    DrawActionBar(PrimaryLine, DetailLines, CardX + 30.0f, CardY + CardH - 42.0f, CardW - 60.0f, bHasQuizRows);
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

void AAstroMissionHUD::DrawActionBar(const FString& PrimaryLine, const TArray<FString>& DetailLines, const float X, const float Y, const float W, const bool bHasQuizRows)
{
    TArray<FString> Actions;
    const FString PrimaryLower = PrimaryLine.ToLower();

    bool bMentionsScan = PrimaryLower.Contains(TEXT("scan"));
    bool bMentionsPassport = PrimaryLower.Contains(TEXT("passport"));
    bool bMentionsPaused = PrimaryLower.Contains(TEXT("paused"));
    bool bMentionsLaunch = PrimaryLower.Contains(TEXT("first expedition"));
    bool bMentionsMenu = PrimaryLower == TEXT("solar passport")
        || PrimaryLower.Contains(TEXT("choose your explorer")) || PrimaryLower.Contains(TEXT("mission complete"));
    bool bMentionsMore = PrimaryLower.Contains(TEXT("discovery card")) || PrimaryLower.Contains(TEXT("look closer"));
    bool bMentionsDeepDive = PrimaryLower.Contains(TEXT("look closer"));
    bool bMentionsRouteRows = false;
    bool bMentionsHint = false;
    bool bMentionsStampAward = PrimaryLower.Contains(TEXT("stamp unlocked"));

    for (const FString& Line : DetailLines)
    {
        const FString Lower = Line.ToLower();
        bMentionsScan = bMentionsScan || Lower.Contains(TEXT("confirm to scan"));
        bMentionsPassport = bMentionsPassport || Lower.Contains(TEXT("passport"));
        bMentionsMore = bMentionsMore || Lower.Contains(TEXT("more info"));
        bMentionsRouteRows = bMentionsRouteRows || IsPassportRouteLine(Line);
        bMentionsHint = bMentionsHint || Lower.Contains(TEXT("hint"));
        bMentionsStampAward = bMentionsStampAward || Lower.Contains(TEXT("stamp saved")) || Lower.Contains(TEXT("stamp added"));
    }

    if (bHasQuizRows)
    {
        AddActionIfMissing(Actions, TEXT("Pick answer"));
        AddActionIfMissing(Actions, TEXT("Confirm"));
        AddActionIfMissing(Actions, TEXT("Hint"));
        AddActionIfMissing(Actions, TEXT("Back"));
    }
    else if (bMentionsPaused || bMentionsMenu)
    {
        AddActionIfMissing(Actions, TEXT("Move"));
        AddActionIfMissing(Actions, TEXT("Confirm"));
    }
    else if (bMentionsLaunch)
    {
        AddActionIfMissing(Actions, TEXT("Launch"));
        AddActionIfMissing(Actions, TEXT("Back"));
    }
    else if (bMentionsRouteRows)
    {
        AddActionIfMissing(Actions, TEXT("Pick stop"));
        AddActionIfMissing(Actions, TEXT("Open stop"));
        AddActionIfMissing(Actions, TEXT("Back"));
    }
    else if (bMentionsStampAward)
    {
        AddActionIfMissing(Actions, TEXT("Next"));
        AddActionIfMissing(Actions, TEXT("Passport"));
        AddActionIfMissing(Actions, TEXT("Pause"));
    }
    else if (bMentionsMore)
    {
        AddActionIfMissing(Actions, bMentionsDeepDive ? TEXT("Close Info") : TEXT("More Info"));
        AddActionIfMissing(Actions, TEXT("Quiz"));
        AddActionIfMissing(Actions, TEXT("Back"));
        AddActionIfMissing(Actions, TEXT("Pause"));
    }
    else
    {
        if (bMentionsScan)
        {
            AddActionIfMissing(Actions, TEXT("Scan"));
            AddActionIfMissing(Actions, TEXT("Pick stop"));
        }
        else
        {
            AddActionIfMissing(Actions, TEXT("Confirm"));
        }

        if (bMentionsHint)
        {
            AddActionIfMissing(Actions, TEXT("Hint"));
        }

        if (bMentionsPassport)
        {
            AddActionIfMissing(Actions, TEXT("Passport"));
        }

        AddActionIfMissing(Actions, TEXT("Pause"));
    }

    float BadgeX = X;
    for (int32 Index = 0; Index < Actions.Num(); ++Index)
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

void AAstroMissionHUD::DrawQuizRow(const FString& Text, const float X, const float Y, const float W, const bool bFocused)
{
    FString ChoiceText = FriendlyDetailLine(Text);
    ChoiceText.RemoveFromStart(TEXT(">"));
    ChoiceText.TrimStartAndEndInline();

    const FLinearColor Fill = bFocused ? FLinearColor(0.98f, 0.66f, 0.18f, 0.96f) : FLinearColor(0.08f, 0.19f, 0.24f, 0.96f);
    const FLinearColor Stripe = bFocused ? FLinearColor(1.0f, 0.94f, 0.60f, 1.0f) : FLinearColor(0.28f, 0.56f, 0.86f, 0.84f);
    const FLinearColor TextColor = bFocused ? FLinearColor(0.06f, 0.06f, 0.08f, 1.0f) : FLinearColor(0.94f, 0.97f, 1.0f, 1.0f);

    DrawRect(Fill, X, Y, W, 56.0f);
    DrawRect(Stripe, X, Y, 10.0f, 56.0f);
    DrawText(bFocused ? TEXT("READY") : TEXT("CHOICE"), TextColor, X + 20.0f, Y + 9.0f, GEngine->GetSmallFont(), 0.72f, false);
    DrawText(ChoiceText, TextColor, X + 124.0f, Y + 14.0f, GEngine->GetSmallFont(), 1.10f, false);
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

FString AAstroMissionHUD::FriendlyDetailLine(const FString& Text) const
{
    FString Result = Text;
    Result.TrimStartAndEndInline();

    if (Result.StartsWith(TEXT("Atlas route:")) || Result.StartsWith(TEXT("Sources are tracked"))
        || Result.Contains(TEXT("http://")) || Result.Contains(TEXT("https://")) || Result.Contains(TEXT("docs/"))
        || Result.Contains(TEXT(".cpp")) || Result.Contains(TEXT(".h")) || Result.Contains(TEXT("\\")))
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
