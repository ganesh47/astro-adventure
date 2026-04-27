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
    bool bHasStampFeedback = GameMode->IsStampEffectActive() || PrimaryLine.Contains(TEXT("stamp unlocked"));
    for (const FString& Line : DetailLines)
    {
        bHasQuizRows = bHasQuizRows || IsQuizChoiceLine(Line);
        bHasStampFeedback = bHasStampFeedback || Line.Contains(TEXT("Stamp saved"));
    }

    const float Margin = 32.0f;
    const float HeaderH = 74.0f;
    DrawRect(FLinearColor(0.02f, 0.03f, 0.09f, 0.78f), 0.0f, 0.0f, Canvas->SizeX, HeaderH);
    DrawRect(FLinearColor(0.18f, 0.55f, 0.88f, 0.58f), 0.0f, HeaderH - 5.0f, Canvas->SizeX, 5.0f);

    float Y = 14.0f;
    DrawText(TEXT("Astro Adventure"), FLinearColor(1.0f, 0.98f, 0.86f), Margin, Y, GEngine->GetSmallFont(), 1.28f, false);
    const float StatusBadgeW = FMath::Clamp(Canvas->SizeX - Margin * 2.0f - 256.0f, 160.0f, 520.0f);
    DrawBadge(StatusLine, Margin + 256.0f, 17.0f, StatusBadgeW, FLinearColor(0.12f, 0.28f, 0.48f, 0.92f), FLinearColor(0.86f, 0.96f, 1.0f), 0.74f);

    const float CardW = FMath::Min(Canvas->SizeX - Margin * 2.0f, 1120.0f);
    const float CardH = bHasQuizRows ? 292.0f : 216.0f;
    const float CardX = (Canvas->SizeX - CardW) * 0.5f;
    const float CardY = Canvas->SizeY - CardH - 34.0f;
    DrawRect(FLinearColor(0.035f, 0.05f, 0.105f, 0.90f), CardX, CardY, CardW, CardH);
    DrawRect(FLinearColor(0.98f, 0.70f, 0.18f, 0.96f), CardX, CardY, 12.0f, CardH);
    DrawRect(FLinearColor(0.18f, 0.46f, 0.74f, 0.32f), CardX, CardY, CardW, 4.0f);

    if (GameMode->IsScanEffectActive())
    {
        DrawRect(FLinearColor(0.08f, 0.72f, 1.0f, 0.13f), 0.0f, 0.0f, Canvas->SizeX, Canvas->SizeY);
        DrawFeedbackBanner(TEXT("SCAN COMPLETE"), FLinearColor(0.05f, 0.42f, 0.62f, 0.92f), Canvas->SizeY * 0.27f);
    }

    if (bHasStampFeedback)
    {
        DrawFeedbackBanner(TEXT("PASSPORT STAMP SAVED"), FLinearColor(0.12f, 0.48f, 0.25f, 0.94f), CardY - 66.0f);
    }

    Y = CardY + 24.0f;
    DrawLine(PrimaryLine, CardX + 34.0f, Y, FLinearColor(1.0f, 0.94f, 0.64f), bHasQuizRows ? 1.18f : 1.24f);

    if (bHasQuizRows)
    {
        Y += 8.0f;
        for (const FString& Line : DetailLines)
        {
            if (IsQuizChoiceLine(Line))
            {
                const bool bFocused = Line.TrimStart().StartsWith(TEXT(">"));
                DrawQuizRow(Line, CardX + 34.0f, Y, CardW - 68.0f, bFocused);
                Y += 62.0f;
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

            DrawLine(FriendlyLine, CardX + 34.0f, Y, FLinearColor(0.90f, 0.96f, 1.0f), 0.92f);
            ++DrawnLines;
            if (DrawnLines >= 4)
            {
                break;
            }
        }
    }

    const float BadgeY = CardY + CardH - 42.0f;
    DrawBadge(TEXT("Move"), CardX + 34.0f, BadgeY, 86.0f, FLinearColor(0.11f, 0.22f, 0.38f, 0.95f), FLinearColor::White);
    DrawBadge(TEXT("Confirm"), CardX + 132.0f, BadgeY, 108.0f, FLinearColor(0.08f, 0.38f, 0.26f, 0.95f), FLinearColor::White);
    DrawBadge(TEXT("More"), CardX + 252.0f, BadgeY, 82.0f, FLinearColor(0.28f, 0.18f, 0.42f, 0.95f), FLinearColor::White);
    DrawBadge(TEXT("Passport"), CardX + 346.0f, BadgeY, 112.0f, FLinearColor(0.18f, 0.31f, 0.52f, 0.95f), FLinearColor::White);
    DrawBadge(TEXT("Pause"), CardX + 470.0f, BadgeY, 88.0f, FLinearColor(0.40f, 0.13f, 0.16f, 0.95f), FLinearColor::White);
}

void AAstroMissionHUD::DrawLine(const FString& Text, const float X, float& Y, const FLinearColor& Color, const float Scale)
{
    DrawText(Text, Color, X, Y, GEngine->GetSmallFont(), Scale, false);
    Y += 24.0f * Scale;
}

void AAstroMissionHUD::DrawBadge(const FString& Text, const float X, const float Y, const float W, const FLinearColor& Fill, const FLinearColor& TextColor, const float Scale)
{
    DrawRect(Fill, X, Y, W, 30.0f);
    DrawText(Text, TextColor, X + 10.0f, Y + 7.0f, GEngine->GetSmallFont(), Scale, false);
}

void AAstroMissionHUD::DrawQuizRow(const FString& Text, const float X, const float Y, const float W, const bool bFocused)
{
    FString ChoiceText = FriendlyDetailLine(Text);
    ChoiceText.RemoveFromStart(TEXT(">"));
    ChoiceText.TrimStartAndEndInline();

    const FLinearColor Fill = bFocused ? FLinearColor(0.98f, 0.66f, 0.18f, 0.94f) : FLinearColor(0.10f, 0.16f, 0.27f, 0.96f);
    const FLinearColor Stripe = bFocused ? FLinearColor(1.0f, 0.94f, 0.60f, 1.0f) : FLinearColor(0.28f, 0.56f, 0.86f, 0.84f);
    const FLinearColor TextColor = bFocused ? FLinearColor(0.06f, 0.06f, 0.08f, 1.0f) : FLinearColor(0.94f, 0.97f, 1.0f, 1.0f);

    DrawRect(Fill, X, Y, W, 52.0f);
    DrawRect(Stripe, X, Y, 8.0f, 52.0f);
    DrawText(bFocused ? TEXT("SELECT") : TEXT("CHOICE"), TextColor, X + 18.0f, Y + 8.0f, GEngine->GetSmallFont(), 0.62f, false);
    DrawText(ChoiceText, TextColor, X + 116.0f, Y + 13.0f, GEngine->GetSmallFont(), 1.0f, false);
}

void AAstroMissionHUD::DrawFeedbackBanner(const FString& Text, const FLinearColor& Fill, const float Y)
{
    const float BannerW = FMath::Min(Canvas->SizeX - 64.0f, 520.0f);
    const float BannerX = (Canvas->SizeX - BannerW) * 0.5f;
    DrawRect(Fill, BannerX, Y, BannerW, 46.0f);
    DrawRect(FLinearColor(1.0f, 0.92f, 0.42f, 0.96f), BannerX, Y, 10.0f, 46.0f);
    DrawText(Text, FLinearColor::White, BannerX + 24.0f, Y + 11.0f, GEngine->GetSmallFont(), 1.08f, false);
}

bool AAstroMissionHUD::IsQuizChoiceLine(const FString& Text) const
{
    const FString Trimmed = Text.TrimStart();
    return Trimmed.StartsWith(TEXT("> 1.")) || Trimmed.StartsWith(TEXT("> 2.")) || Trimmed.StartsWith(TEXT("> 3."))
        || Trimmed.StartsWith(TEXT("1.")) || Trimmed.StartsWith(TEXT("2.")) || Trimmed.StartsWith(TEXT("3."));
}

FString AAstroMissionHUD::FriendlyDetailLine(const FString& Text) const
{
    FString Result = Text;
    Result.TrimStartAndEndInline();

    if (Result.StartsWith(TEXT("Atlas route:")) || Result.StartsWith(TEXT("Sources are tracked")))
    {
        return TEXT("");
    }

    Result.ReplaceInline(TEXT(" | mastery "), TEXT(" - mastery "));
    Result.ReplaceInline(TEXT(" | review box "), TEXT(" - review "));
    Result.ReplaceInline(TEXT("passport stamped"), TEXT("stamp saved"));
    Result.ReplaceInline(TEXT("quiz ready"), TEXT("quiz ready"));
    Result.ReplaceInline(TEXT("ready to scan"), TEXT("scan me"));

    if ((Result.StartsWith(TEXT("*")) || Result.StartsWith(TEXT("-"))) && Result.Contains(TEXT(" - mastery ")))
    {
        const bool bStamped = Result.StartsWith(TEXT("*"));
        Result.RightChopInline(1);
        Result.TrimStartAndEndInline();

        FString StopName;
        FString Unused;
        Result.Split(TEXT(" - mastery "), &StopName, &Unused);
        Result = FString::Printf(TEXT("%s %s"), bStamped ? TEXT("STAMP") : TEXT("OPEN"), *StopName);
    }

    return Result;
}
