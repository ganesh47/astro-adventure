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

    struct FHudBuckets
    {
        TArray<FString> MenuRows;
        TArray<FString> QuizRows;
        TArray<FString> PassportRows;
        TArray<FString> BodyLines;
        TArray<FString> HintLines;
    };

    FHudBuckets Buckets;
    bool bHasStampFeedback = GameMode->IsStampEffectActive() || PrimaryLine.Contains(TEXT("stamp unlocked"));
    for (const FString& Line : DetailLines)
    {
        bHasStampFeedback = bHasStampFeedback || Line.Contains(TEXT("Stamp saved"));

        const FString FriendlyLine = FriendlyDetailLine(Line);
        if (FriendlyLine.IsEmpty())
        {
            continue;
        }

        if (CurrentScreen == EAstroMissionScreen::Home)
        {
            if (IsHomeChoiceLine(Line))
            {
                Buckets.MenuRows.Add(FriendlyLine);
            }
            else
            {
                Buckets.HintLines.Add(FriendlyLine);
            }
        }
        else if (CurrentScreen == EAstroMissionScreen::Quiz)
        {
            if (IsQuizChoiceLine(Line))
            {
                Buckets.QuizRows.Add(FriendlyLine);
            }
        }
        else if (CurrentScreen == EAstroMissionScreen::Passport || CurrentScreen == EAstroMissionScreen::AtlasView)
        {
            if (IsPassportRouteLine(Line))
            {
                Buckets.PassportRows.Add(FriendlyLine);
            }
            else
            {
                Buckets.HintLines.Add(FriendlyLine);
            }
        }
        else if (IsMenuScreen(CurrentScreen))
        {
            if (IsMenuChoiceLine(Line))
            {
                Buckets.MenuRows.Add(FriendlyLine);
            }
            else
            {
                Buckets.BodyLines.Add(FriendlyLine);
            }
        }
        else if (CurrentScreen == EAstroMissionScreen::MissionPrompt)
        {
            Buckets.BodyLines.Add(FriendlyLine);
        }
        else if (CurrentScreen == EAstroMissionScreen::Navigation)
        {
            if (FriendlyLine.StartsWith(TEXT("Next stop:")) || FriendlyLine.StartsWith(TEXT("Clue:"))
                || FriendlyLine.Contains(TEXT("scan")) || FriendlyLine.Contains(TEXT("Card found")) || FriendlyLine.Contains(TEXT("Stamped already")))
            {
                Buckets.BodyLines.Add(FriendlyLine);
            }
            else
            {
                Buckets.HintLines.Add(FriendlyLine);
            }
        }
        else if (CurrentScreen == EAstroMissionScreen::DiscoveryCard)
        {
            if (FriendlyLine.Contains(TEXT("quiz")) || FriendlyLine.Contains(TEXT("More Info")) || FriendlyLine.Contains(TEXT("Passport")))
            {
                Buckets.HintLines.Add(FriendlyLine);
            }
            else if (Buckets.BodyLines.Num() < 3)
            {
                Buckets.BodyLines.Add(FriendlyLine);
            }
        }
        else if (CurrentScreen == EAstroMissionScreen::DeepDive)
        {
            if (Buckets.BodyLines.Num() < 3)
            {
                if (Buckets.BodyLines.Num() == 0 && !FriendlyLine.Contains(TEXT(":")))
                {
                    Buckets.BodyLines.Add(FString::Printf(TEXT("Closer Look: %s"), *FriendlyLine));
                }
                else
                {
                    Buckets.BodyLines.Add(FriendlyLine);
                }
            }
        }
        else if (CurrentScreen == EAstroMissionScreen::StampAward)
        {
            if (FriendlyLine.Contains(TEXT("Confirm")) || FriendlyLine.Contains(TEXT("review")))
            {
                Buckets.HintLines.Add(FriendlyLine);
            }
            else
            {
                Buckets.BodyLines.Add(FriendlyLine);
            }
        }
        else
        {
            Buckets.BodyLines.Add(FriendlyLine);
        }
    }

    const bool bHasQuizRows = Buckets.QuizRows.Num() > 0;
    const bool bHasPassportRows = Buckets.PassportRows.Num() > 0;
    const bool bHasMenuRows = Buckets.MenuRows.Num() > 0;

    const float Margin = FMath::Clamp(Canvas->SizeX * 0.018f, 18.0f, 28.0f);
    const float HeaderH = FMath::Clamp(Canvas->SizeY * 0.066f, 46.0f, 64.0f);
    DrawRect(FLinearColor(0.015f, 0.035f, 0.055f, 0.74f), 0.0f, 0.0f, Canvas->SizeX, HeaderH);
    DrawRect(FLinearColor(0.90f, 0.52f, 0.12f, 0.95f), 0.0f, HeaderH - 5.0f, Canvas->SizeX, 5.0f);
    DrawRect(FLinearColor(0.10f, 0.54f, 0.64f, 0.42f), 0.0f, HeaderH - 8.0f, Canvas->SizeX, 3.0f);

    const float TitleScale = Canvas->SizeX < 1600.0f ? 0.92f : 1.10f;
    DrawText(TEXT("SOLAR PASSPORT"), FLinearColor(1.0f, 0.96f, 0.78f), Margin, 10.0f, GEngine->GetSmallFont(), TitleScale, false);
    const float StatusX = Canvas->SizeX < 1600.0f ? Margin + 194.0f : Margin + 246.0f;
    const float StatusBadgeW = FMath::Clamp(Canvas->SizeX - StatusX - Margin, 190.0f, 430.0f);
    DrawBadge(FriendlyStatusLine(StatusLine), StatusX, 14.0f, StatusBadgeW, FLinearColor(0.08f, 0.24f, 0.32f, 0.90f), FLinearColor(0.90f, 0.99f, 1.0f), 0.72f);

    const float CardW = FMath::Min(Canvas->SizeX - Margin * 2.0f, bHasQuizRows ? 980.0f : 930.0f);
    const float CardH = bHasPassportRows ? 300.0f : bHasQuizRows ? 314.0f : bHasMenuRows ? 286.0f : Buckets.BodyLines.Num() >= 3 ? 246.0f : 220.0f;
    const float CardX = (Canvas->SizeX - CardW) * 0.5f;
    const float CardY = FMath::Max(HeaderH + 12.0f, Canvas->SizeY - CardH - FMath::Clamp(Canvas->SizeY * 0.022f, 12.0f, 24.0f));

    if (GameMode->IsScanEffectActive())
    {
        const float ScanY = FMath::Fmod(World->GetTimeSeconds() * 420.0f, FMath::Max(1.0f, static_cast<float>(Canvas->SizeY)));
        DrawRect(FLinearColor(0.08f, 0.74f, 1.0f, 0.08f), 0.0f, 0.0f, Canvas->SizeX, Canvas->SizeY);
        DrawRect(FLinearColor(0.78f, 0.98f, 1.0f, 0.62f), 0.0f, ScanY, Canvas->SizeX, 5.0f);
        DrawFeedbackToast(TEXT("SCAN LOCKED"), FLinearColor(0.04f, 0.42f, 0.58f, 0.94f), CardX + 28.0f, CardY - 46.0f, FMath::Min(CardW - 56.0f, 360.0f));
    }

    DrawPassportFrame(CardX, CardY, CardW, CardH);
    if (!bHasQuizRows && !bHasPassportRows && !bHasMenuRows)
    {
        DrawStampStrip(StatusLine, CardX + 32.0f, CardY + CardH - 82.0f, CardW - 64.0f);
    }

    if (bHasStampFeedback)
    {
        DrawFeedbackBanner(TEXT("Stamp added to your passport"), FLinearColor(0.11f, 0.48f, 0.25f, 0.95f), CardY - 68.0f);
    }

    float Y = CardY + 24.0f;
    DrawLine(DisplayPrimaryLine, CardX + 42.0f, Y, FLinearColor(1.0f, 0.95f, 0.68f), bHasQuizRows ? 1.42f : 1.36f);

    if (bHasQuizRows)
    {
        Y += 8.0f;
        for (const FString& Line : Buckets.QuizRows)
        {
            const bool bFocused = Line.TrimStart().StartsWith(TEXT(">"));
            DrawQuizRow(Line, CardX + 42.0f, Y, CardW - 84.0f, bFocused);
            Y += 66.0f;
        }
    }
    else if (bHasMenuRows)
    {
        Y += 8.0f;
        for (const FString& Line : Buckets.MenuRows)
        {
            const bool bFocused = Line.TrimStart().StartsWith(TEXT(">")) || Line.StartsWith(TEXT("READY:"));
            DrawMenuRow(Line, CardX + 42.0f, Y, CardW - 84.0f, bFocused);
            Y += 38.0f;
        }

        int32 DrawnNotes = 0;
        const TArray<FString>& NoteLines = Buckets.BodyLines.Num() > 0 ? Buckets.BodyLines : Buckets.HintLines;
        for (const FString& Line : NoteLines)
        {
            float NoteY = Y + 4.0f;
            DrawLine(Line, CardX + 42.0f, NoteY, FLinearColor(0.78f, 0.91f, 0.94f), 0.84f);
            ++DrawnNotes;
            if (DrawnNotes >= (Buckets.MenuRows.Num() >= 4 ? 1 : 2))
            {
                break;
            }
        }
    }
    else if (bHasPassportRows)
    {
        int32 DrawnRows = 0;
        Y += 8.0f;
        for (const FString& Line : Buckets.PassportRows)
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
    else
    {
        int32 DrawnLines = 0;
        for (const FString& Line : Buckets.BodyLines)
        {
            DrawLine(Line, CardX + 42.0f, Y, FLinearColor(0.91f, 0.98f, 1.0f), 1.02f);
            ++DrawnLines;
            if (DrawnLines >= 3)
            {
                break;
            }
        }

        for (const FString& Line : Buckets.HintLines)
        {
            if (DrawnLines >= 4)
            {
                break;
            }

            Y += 2.0f;
            DrawLine(Line, CardX + 42.0f, Y, FLinearColor(0.76f, 0.90f, 0.92f), 0.84f);
            ++DrawnLines;
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
        AddActionIfMissing(Actions, TEXT("Up/Down pick"));
        AddActionIfMissing(Actions, TEXT("Enter/A answer"));
        AddActionIfMissing(Actions, TEXT("H/Y hint"));
    }
    else if (Screen == EAstroMissionScreen::Home)
    {
        AddActionIfMissing(Actions, TEXT("Arrows/WASD"));
        AddActionIfMissing(Actions, TEXT("Enter/A choose"));
        AddActionIfMissing(Actions, TEXT("Select Quit"));
    }
    else if (Screen == EAstroMissionScreen::AgeSelect)
    {
        AddActionIfMissing(Actions, TEXT("Arrows/WASD"));
        AddActionIfMissing(Actions, TEXT("Enter/A launch"));
        AddActionIfMissing(Actions, TEXT("Backspace/B"));
    }
    else if (Screen == EAstroMissionScreen::MissionPrompt)
    {
        AddActionIfMissing(Actions, TEXT("Enter/A launch"));
        AddActionIfMissing(Actions, TEXT("Right/D launch"));
        AddActionIfMissing(Actions, TEXT("Esc pause"));
    }
    else if (Screen == EAstroMissionScreen::PauseMenu)
    {
        AddActionIfMissing(Actions, TEXT("Arrows/WASD"));
        AddActionIfMissing(Actions, TEXT("Enter/A choose"));
        AddActionIfMissing(Actions, TEXT("Quit option"));
    }
    else if (Screen == EAstroMissionScreen::MissionComplete)
    {
        AddActionIfMissing(Actions, TEXT("Arrows/WASD"));
        AddActionIfMissing(Actions, TEXT("Enter/A choose"));
        AddActionIfMissing(Actions, TEXT("Quit option"));
    }
    else if (Screen == EAstroMissionScreen::Navigation)
    {
        AddActionIfMissing(Actions, TEXT("Arrows/WASD travel"));
        AddActionIfMissing(Actions, TEXT("Enter/A scan"));
        AddActionIfMissing(Actions, TEXT("P/RT atlas"));
    }
    else if (Screen == EAstroMissionScreen::Passport || Screen == EAstroMissionScreen::AtlasView)
    {
        AddActionIfMissing(Actions, TEXT("Arrows/WASD"));
        AddActionIfMissing(Actions, TEXT("Enter/A open"));
        AddActionIfMissing(Actions, TEXT("Backspace/B"));
    }
    else if (Screen == EAstroMissionScreen::DiscoveryCard)
    {
        AddActionIfMissing(Actions, TEXT("Enter/A quiz"));
        AddActionIfMissing(Actions, TEXT("M/LT info"));
        AddActionIfMissing(Actions, TEXT("Backspace/B"));
    }
    else if (Screen == EAstroMissionScreen::DeepDive)
    {
        AddActionIfMissing(Actions, TEXT("M/LT close"));
        AddActionIfMissing(Actions, TEXT("Enter/A quiz"));
        AddActionIfMissing(Actions, TEXT("Backspace/B"));
    }
    else if (Screen == EAstroMissionScreen::QuizFeedback)
    {
        AddActionIfMissing(Actions, TEXT("Enter/A continue"));
        AddActionIfMissing(Actions, TEXT("H/Y hint"));
        AddActionIfMissing(Actions, TEXT("Backspace/B"));
    }
    else if (Screen == EAstroMissionScreen::StampAward)
    {
        AddActionIfMissing(Actions, TEXT("Enter/A next"));
        AddActionIfMissing(Actions, TEXT("P/RT atlas"));
        AddActionIfMissing(Actions, TEXT("Esc pause"));
    }
    else
    {
        AddActionIfMissing(Actions, TEXT("Enter/A"));
        AddActionIfMissing(Actions, TEXT("Backspace/B"));
        AddActionIfMissing(Actions, TEXT("Esc pause"));
    }

    float BadgeX = X;
    for (int32 Index = 0; Index < Actions.Num() && Index < 3; ++Index)
    {
        const float BadgeW = FMath::Clamp(38.0f + Actions[Index].Len() * 8.4f, 92.0f, 184.0f);
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
    ChoiceText.RemoveFromStart(TEXT("READY:"));
    ChoiceText.TrimStartAndEndInline();

    const FLinearColor Fill = bFocused ? FLinearColor(0.96f, 0.66f, 0.18f, 0.96f) : FLinearColor(0.08f, 0.18f, 0.22f, 0.90f);
    const FLinearColor Stripe = bFocused ? FLinearColor(1.0f, 0.95f, 0.62f, 1.0f) : FLinearColor(0.18f, 0.46f, 0.56f, 0.86f);
    const FLinearColor TextColor = bFocused ? FLinearColor(0.05f, 0.06f, 0.07f, 1.0f) : FLinearColor(0.94f, 0.98f, 1.0f, 1.0f);

    DrawRect(Fill, X, Y, W, 34.0f);
    DrawRect(Stripe, X, Y, 10.0f, 34.0f);
    DrawText(bFocused ? TEXT("GO") : TEXT(""), TextColor, X + 20.0f, Y + 8.0f, GEngine->GetSmallFont(), 0.62f, false);
    DrawText(ChoiceText, TextColor, X + (bFocused ? 72.0f : 24.0f), Y + 7.0f, GEngine->GetSmallFont(), 0.96f, false);
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

    const FString LowerRest = Rest.ToLower();
    const bool bStamped = LowerRest.StartsWith(TEXT("stamped"));
    const bool bQuizReady = LowerRest.StartsWith(TEXT("ready")) || LowerRest.StartsWith(TEXT("quiz ready"));
    const FString StampLabel = bStamped ? TEXT("Stamped") : bQuizReady ? TEXT("Ready") : TEXT("Visit");
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

void AAstroMissionHUD::DrawFeedbackToast(const FString& Text, const FLinearColor& Fill, const float X, const float Y, const float W)
{
    const float ToastY = FMath::Max(74.0f, Y);
    const float ToastW = FMath::Clamp(W, 220.0f, 380.0f);
    DrawRect(FLinearColor(0.02f, 0.04f, 0.05f, 0.54f), X + 4.0f, ToastY + 4.0f, ToastW, 36.0f);
    DrawRect(Fill, X, ToastY, ToastW, 36.0f);
    DrawRect(FLinearColor(0.75f, 0.98f, 1.0f, 0.92f), X, ToastY, 8.0f, 36.0f);
    DrawText(Text, FLinearColor::White, X + 18.0f, ToastY + 9.0f, GEngine->GetSmallFont(), 0.86f, false);
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

bool AAstroMissionHUD::IsHomeChoiceLine(const FString& Text) const
{
    const FString Trimmed = Text.TrimStartAndEnd();
    return (Trimmed.StartsWith(TEXT(">")) || Trimmed.StartsWith(TEXT("New Expedition")) || Trimmed.StartsWith(TEXT("Continue"))
            || Trimmed.StartsWith(TEXT("Reset Passport")) || Trimmed.StartsWith(TEXT("Quit")))
        && (Trimmed.Contains(TEXT("New Expedition")) || Trimmed.Contains(TEXT("Continue"))
            || Trimmed.Contains(TEXT("Reset Passport")) || Trimmed.Contains(TEXT("Quit")));
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
    return Lower.Contains(TEXT("|")) && (Lower.Contains(TEXT("stamped")) || Lower.Contains(TEXT("ready"))
        || Lower.Contains(TEXT("visit")) || Lower.Contains(TEXT("quiz ready")) || Lower.Contains(TEXT("not scanned")));
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

    Result.ReplaceInline(TEXT("New stamp unlocked:"), TEXT("Stamp added:"), ESearchCase::IgnoreCase);
    Result.ReplaceInline(TEXT("New stamp unlocked!"), TEXT("Stamp added!"), ESearchCase::IgnoreCase);
    Result.ReplaceInline(TEXT("stamp unlocked"), TEXT("stamp added"), ESearchCase::IgnoreCase);
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

    Result.ReplaceInline(TEXT("Continue - no saved route yet"), TEXT("Continue saved route - none yet"));
    if (Result.Equals(TEXT("Continue"), ESearchCase::IgnoreCase) || Result.Equals(TEXT("> Continue"), ESearchCase::IgnoreCase))
    {
        Result.ReplaceInline(TEXT("Continue"), TEXT("Continue saved route"));
    }

    Result.ReplaceInline(TEXT("Press M / LT for More Info, or Confirm for the quiz."), TEXT("More Info opens Closer Look. Confirm starts the quiz."));
    Result.ReplaceInline(TEXT("Open Passport / RT for the full Atlas route."), TEXT("Passport shows the full route."));
    Result.ReplaceInline(TEXT("Confirm to scan for a discovery card."), TEXT("Confirm to scan this stop."));
    Result.ReplaceInline(TEXT("Scan found. Confirm to scan again and reopen its card."), TEXT("Card found. Confirm to reopen it."));
    Result.ReplaceInline(TEXT("Scan found. Confirm to open its card again."), TEXT("Card found. Confirm to reopen it."));
    Result.ReplaceInline(TEXT("Stamp saved already. Confirm to rescan and review."), TEXT("Stamped already. Confirm to review."));
    Result.ReplaceInline(TEXT("Stamped already. Pick another stop or open Passport."), TEXT("Stamped already. Pick another stop."));
    Result.ReplaceInline(TEXT("Review box "), TEXT("Review round "));
    Result.ReplaceInline(TEXT(" | mastery "), TEXT(" - recall "));
    Result.ReplaceInline(TEXT(" | review box "), TEXT(" - review "));
    Result.ReplaceInline(TEXT(" | box "), TEXT(" - review "));
    Result.ReplaceInline(TEXT("passport stamped"), TEXT("stamp saved"));
    Result.ReplaceInline(TEXT("quiz ready"), TEXT("quiz ready"));
    Result.ReplaceInline(TEXT("ready to scan"), TEXT("ready to scan"));
    Result.ReplaceInline(TEXT("mastery"), TEXT("recall"));

    if (Result.StartsWith(TEXT("Quick fact:")))
    {
        Result.ReplaceInline(TEXT("Quick fact:"), TEXT("Fact:"));
    }
    else if (Result.StartsWith(TEXT("Wow fact:")))
    {
        Result.ReplaceInline(TEXT("Wow fact:"), TEXT("Also:"));
    }

    if (Result.StartsWith(TEXT("Compare:")))
    {
        Result.ReplaceInline(TEXT("Compare:"), TEXT("Compare:"));
    }
    else if (Result.StartsWith(TEXT("Word explorer:")))
    {
        Result.ReplaceInline(TEXT("Word explorer:"), TEXT("Word Explorer:"));
    }

    if (Result.Contains(TEXT(" is now marked STAMPED in your Passport.")))
    {
        Result.ReplaceInline(TEXT(" is now marked STAMPED in your Passport."), TEXT(" is stamped in your passport."));
    }
    Result.ReplaceInline(TEXT("Each stop saves one stamp; rescans reopen the review card."), TEXT("Your passport keeps this card for later."));
    Result.ReplaceInline(TEXT("Confirm or press Right/D for Next Stop."), TEXT("Confirm for the next stop."));
    Result.ReplaceInline(TEXT("Stamp saved. You can review this card from Atlas later."), TEXT("Saved in Atlas for later."));

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
