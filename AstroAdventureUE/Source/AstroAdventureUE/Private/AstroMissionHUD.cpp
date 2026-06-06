#include "AstroMissionHUD.h"

#include "AstroAdventureGameModeBase.h"
#include "Engine/Canvas.h"
#include "Engine/CanvasRenderTarget2D.h"
#include "Engine/Engine.h"
#include "Engine/Texture2D.h"
#include "Engine/World.h"
#include "IImageWrapper.h"
#include "IImageWrapperModule.h"
#include "Misc/FileHelper.h"
#include "Misc/Paths.h"
#include "Modules/ModuleManager.h"

namespace
{
    float AstroApproxCharWidth(const float Scale)
    {
        return FMath::Max(1.0f, 7.2f * Scale);
    }

    FString AstroClipTextToWidth(const FString& Text, const float MaxW, const float Scale)
    {
        const int32 MaxChars = FMath::Max(4, FMath::FloorToInt(MaxW / AstroApproxCharWidth(Scale)));
        if (Text.Len() <= MaxChars)
        {
            return Text;
        }

        return Text.Left(FMath::Max(1, MaxChars - 3)) + TEXT("...");
    }

    TArray<FString> AstroWrapTextToWidth(const FString& Text, const float MaxW, const float Scale, const int32 MaxLines)
    {
        TArray<FString> Lines;
        const int32 LineLimit = FMath::Max(1, MaxLines);
        const int32 MaxChars = FMath::Max(8, FMath::FloorToInt(MaxW / AstroApproxCharWidth(Scale)));

        TArray<FString> Words;
        Text.ParseIntoArray(Words, TEXT(" "), true);
        FString CurrentLine;
        bool bClipped = false;

        for (const FString& Word : Words)
        {
            const FString Candidate = CurrentLine.IsEmpty() ? Word : CurrentLine + TEXT(" ") + Word;
            if (Candidate.Len() <= MaxChars)
            {
                CurrentLine = Candidate;
                continue;
            }

            if (!CurrentLine.IsEmpty())
            {
                Lines.Add(CurrentLine);
                CurrentLine.Empty();
                if (Lines.Num() >= LineLimit)
                {
                    bClipped = true;
                    break;
                }
            }

            if (Word.Len() > MaxChars)
            {
                Lines.Add(AstroClipTextToWidth(Word, MaxW, Scale));
                if (Lines.Num() >= LineLimit)
                {
                    bClipped = true;
                    break;
                }
            }
            else
            {
                CurrentLine = Word;
            }
        }

        if (!bClipped && !CurrentLine.IsEmpty() && Lines.Num() < LineLimit)
        {
            Lines.Add(CurrentLine);
        }
        else if (bClipped && Lines.Num() > 0)
        {
            Lines.Last() = AstroClipTextToWidth(Lines.Last() + TEXT("..."), MaxW, Scale);
        }

        if (Lines.Num() == 0)
        {
            Lines.Add(TEXT(""));
        }

        return Lines;
    }

    FString AstroActionVerbForChoice(const FString& ChoiceText)
    {
        const FString Lower = ChoiceText.ToLower();
        if (Lower.Contains(TEXT("start")) || Lower.Contains(TEXT("new expedition")) || Lower.Contains(TEXT("continue")) || Lower.Contains(TEXT("resume")))
        {
            return TEXT("Start");
        }
        if (Lower.Contains(TEXT("quit")) || Lower.Contains(TEXT("back")))
        {
            return TEXT("Back");
        }
        if (Lower.Contains(TEXT("passport")) || Lower.Contains(TEXT("atlas")))
        {
            return TEXT("Open");
        }
        if (Lower.Contains(TEXT("age")) || Lower.Contains(TEXT("reset")) || Lower.Contains(TEXT("restart")))
        {
            return TEXT("Pick");
        }
        return TEXT("Pick");
    }
}

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
    const bool bYoungExplorer = GameMode->ActiveAgeBand == EAstroAgeBand::Ages4To6;

    EnsureOwnedTexturesLoaded();

    const bool bWorldLearningScreen = CurrentScreen == EAstroMissionScreen::Home
        || CurrentScreen == EAstroMissionScreen::AgeSelect
        || CurrentScreen == EAstroMissionScreen::MissionPrompt
        || CurrentScreen == EAstroMissionScreen::Navigation
        || CurrentScreen == EAstroMissionScreen::Scanning
        || CurrentScreen == EAstroMissionScreen::DiscoveryCard
        || CurrentScreen == EAstroMissionScreen::DeepDive
        || CurrentScreen == EAstroMissionScreen::Quiz
        || CurrentScreen == EAstroMissionScreen::QuizFeedback
        || CurrentScreen == EAstroMissionScreen::StampAward;

    if (StarfieldTexture)
    {
        const float BaseTintAlpha = bWorldLearningScreen ? 0.26f : 0.30f;
        const float StarAlpha = bWorldLearningScreen ? 0.48f : 0.56f;
        const float TopTintAlpha = bWorldLearningScreen ? 0.055f : 0.14f;
        DrawRect(FLinearColor(0.035f, 0.08f, 0.13f, BaseTintAlpha), 0.0f, 0.0f, Canvas->SizeX, Canvas->SizeY);
        DrawSoftEllipse(Canvas->SizeX * 0.68f, Canvas->SizeY * 0.28f, Canvas->SizeX * 0.42f, Canvas->SizeY * 0.22f, FLinearColor(0.16f, 0.38f, 0.62f, bWorldLearningScreen ? 0.075f : 0.05f), 34);
        DrawSoftEllipse(Canvas->SizeX * 0.76f, Canvas->SizeY * 0.64f, Canvas->SizeX * 0.34f, Canvas->SizeY * 0.18f, FLinearColor(0.46f, 0.20f, 0.58f, bWorldLearningScreen ? 0.055f : 0.04f), 30);
        DrawSoftEllipse(Canvas->SizeX * 0.42f, Canvas->SizeY * 0.74f, Canvas->SizeX * 0.30f, Canvas->SizeY * 0.16f, FLinearColor(0.96f, 0.54f, 0.18f, bWorldLearningScreen ? 0.035f : 0.025f), 28);
        DrawOwnedTexture(StarfieldTexture, 0.0f, 0.0f, Canvas->SizeX, Canvas->SizeY, FLinearColor(0.96f, 0.99f, 1.0f, StarAlpha));
        DrawRect(FLinearColor(0.08f, 0.14f, 0.21f, TopTintAlpha), 0.0f, 0.0f, Canvas->SizeX, Canvas->SizeY);
    }

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
        else if (CurrentScreen == EAstroMissionScreen::Navigation || CurrentScreen == EAstroMissionScreen::Scanning)
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
            else if (Buckets.BodyLines.Num() < (bYoungExplorer ? 2 : 3))
            {
                Buckets.BodyLines.Add(FriendlyLine);
            }
        }
        else if (CurrentScreen == EAstroMissionScreen::DeepDive)
        {
            if (Buckets.BodyLines.Num() < (bYoungExplorer ? 2 : 3))
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

    if (CurrentScreen == EAstroMissionScreen::Home)
    {
        const float PanelX = FMath::Clamp(Canvas->SizeX * 0.055f, 28.0f, 86.0f);
        const float PanelW = FMath::Clamp(Canvas->SizeX * 0.43f, 560.0f, 640.0f);
        const float PanelH = FMath::Clamp(Canvas->SizeY * 0.34f, 260.0f, 286.0f);
        const float PanelY = FMath::Clamp(Canvas->SizeY * 0.235f, 116.0f, 220.0f);

        DrawText(TEXT("My Solar Passport"), FLinearColor(1.0f, 0.88f, 0.42f), PanelX, FMath::Clamp(Canvas->SizeY * 0.070f, 30.0f, 72.0f), GEngine->GetSmallFont(), Canvas->SizeX < 1000.0f ? 1.92f : 2.18f, false);
        DrawText(TEXT("Meet the Sun, our star. Find a clue. Collect a stamp."), FLinearColor(0.92f, 0.99f, 1.0f), PanelX + 3.0f, FMath::Clamp(Canvas->SizeY * 0.145f, 70.0f, 120.0f), GEngine->GetSmallFont(), Canvas->SizeX < 1000.0f ? 0.88f : 0.98f, false);

        DrawRect(FLinearColor(0.03f, 0.035f, 0.045f, 0.42f), PanelX + 7.0f, PanelY + 8.0f, PanelW, PanelH);
        DrawRect(FLinearColor(0.72f, 0.51f, 0.28f, 0.88f), PanelX, PanelY, PanelW, PanelH);
        DrawRect(FLinearColor(0.28f, 0.16f, 0.10f, 0.88f), PanelX + 12.0f, PanelY + 10.0f, PanelW - 24.0f, PanelH - 20.0f);
        DrawRect(FLinearColor(1.0f, 0.78f, 0.28f, 0.95f), PanelX, PanelY, 12.0f, PanelH);
        DrawRect(FLinearColor(1.0f, 0.86f, 0.48f, 0.28f), PanelX + 22.0f, PanelY + 38.0f, PanelW - 44.0f, 2.0f);

        DrawText(TEXT("Let's visit the Sun, a star"), FLinearColor(1.0f, 0.96f, 0.74f), PanelX + 24.0f, PanelY + 12.0f, GEngine->GetSmallFont(), Canvas->SizeX < 1000.0f ? 0.98f : 1.10f, false);
        DrawBadge(TEXT("Meet"), PanelX + 24.0f, PanelY + 42.0f, 76.0f, FLinearColor(0.86f, 0.36f, 0.10f, 0.94f), FLinearColor::White, 0.68f);
        DrawBadge(TEXT("Find"), PanelX + 112.0f, PanelY + 42.0f, 84.0f, FLinearColor(0.12f, 0.50f, 0.60f, 0.94f), FLinearColor::White, 0.68f);
        DrawBadge(TEXT("Collect"), PanelX + 208.0f, PanelY + 42.0f, 96.0f, FLinearColor(0.60f, 0.28f, 0.72f, 0.94f), FLinearColor::White, 0.68f);
        const float RowX = PanelX + 22.0f;
        const float RowW = PanelW - 44.0f;
        const float RowStep = FMath::Clamp(PanelH * 0.16f, 44.0f, 48.0f);
        float RowY = PanelY + 82.0f;
        for (const FString& Line : Buckets.MenuRows)
        {
            const bool bFocused = Line.TrimStart().StartsWith(TEXT(">")) || Line.StartsWith(TEXT("READY:"));
            DrawHomeRow(Line, RowX, RowY, RowW, bFocused);
            RowY += RowStep;
        }

        if (Canvas->SizeX >= 1280.0f)
        {
            const float VignetteX = FMath::Clamp(PanelX + PanelW + 58.0f, Canvas->SizeX * 0.44f, Canvas->SizeX - 620.0f);
            const float VignetteY = FMath::Clamp(Canvas->SizeY * 0.095f, 58.0f, 112.0f);
            const float VignetteW = FMath::Min(Canvas->SizeX - VignetteX - 56.0f, 540.0f);
            if (VignetteW >= 390.0f)
            {
                DrawHomeRouteVignette(VignetteX, VignetteY, VignetteW, FMath::Clamp(Canvas->SizeY * 0.24f, 158.0f, 230.0f));
            }
        }

        DrawActionBar(CurrentScreen, PanelX + 22.0f, PanelY + PanelH + 6.0f, FMath::Min(PanelW, Canvas->SizeX - PanelX - 44.0f), false);
        return;
    }

    const float Margin = FMath::Clamp(Canvas->SizeX * 0.018f, 18.0f, 28.0f);
    const float HeaderH = FMath::Clamp(Canvas->SizeY * 0.046f, 34.0f, 46.0f);
    DrawRect(FLinearColor(0.018f, 0.045f, 0.105f, 0.04f), 0.0f, 0.0f, Canvas->SizeX, Canvas->SizeY);
    DrawRect(FLinearColor(0.025f, 0.026f, 0.04f, 0.34f), 0.0f, 0.0f, Canvas->SizeX, HeaderH);
    DrawRect(FLinearColor(0.93f, 0.64f, 0.18f, 0.68f), 0.0f, HeaderH - 2.0f, Canvas->SizeX, 2.0f);
    DrawRect(FLinearColor(0.95f, 0.82f, 0.44f, 0.24f), 0.0f, HeaderH - 5.0f, Canvas->SizeX, 2.0f);

    const float TitleScale = Canvas->SizeX < 1600.0f ? 0.86f : 1.0f;
    DrawText(TEXT("Solar Passport"), FLinearColor(1.0f, 0.96f, 0.78f), Margin, 7.0f, GEngine->GetSmallFont(), TitleScale, false);
    const float StatusX = Canvas->SizeX < 1600.0f ? Margin + 184.0f : Margin + 224.0f;
    const float StatusBadgeW = FMath::Clamp(Canvas->SizeX - StatusX - Margin, 156.0f, 280.0f);
    DrawBadge(FriendlyStatusLine(StatusLine), StatusX, 7.0f, StatusBadgeW, FLinearColor(0.20f, 0.18f, 0.22f, 0.58f), FLinearColor(0.98f, 0.92f, 0.74f), 0.72f);

    const bool bWorldTeachingScreen = CurrentScreen == EAstroMissionScreen::Navigation
        || CurrentScreen == EAstroMissionScreen::Scanning
        || CurrentScreen == EAstroMissionScreen::DiscoveryCard
        || CurrentScreen == EAstroMissionScreen::DeepDive
        || CurrentScreen == EAstroMissionScreen::Quiz
        || CurrentScreen == EAstroMissionScreen::QuizFeedback
        || CurrentScreen == EAstroMissionScreen::StampAward;
    const float MaxCardW = CurrentScreen == EAstroMissionScreen::StampAward ? 760.0f
        : CurrentScreen == EAstroMissionScreen::Scanning ? 540.0f
        : CurrentScreen == EAstroMissionScreen::DeepDive ? 920.0f
        : CurrentScreen == EAstroMissionScreen::QuizFeedback ? 820.0f
        : CurrentScreen == EAstroMissionScreen::Navigation ? 560.0f
        : bHasQuizRows ? 920.0f
        : bHasMenuRows ? 760.0f
        : bWorldTeachingScreen ? 760.0f
        : 700.0f;
    const float CardW = FMath::Min(Canvas->SizeX - Margin * 2.0f, MaxCardW);
    const float CardH = CurrentScreen == EAstroMissionScreen::Home
        ? FMath::Clamp(Canvas->SizeY * 0.42f, 226.0f, 246.0f)
        : bHasPassportRows ? 310.0f
        : bHasQuizRows ? 434.0f
        : bHasMenuRows ? 204.0f
        : bWorldTeachingScreen ? (CurrentScreen == EAstroMissionScreen::StampAward ? 336.0f : CurrentScreen == EAstroMissionScreen::DeepDive ? 378.0f : CurrentScreen == EAstroMissionScreen::QuizFeedback ? 258.0f : CurrentScreen == EAstroMissionScreen::DiscoveryCard ? 250.0f : CurrentScreen == EAstroMissionScreen::Scanning ? 132.0f : CurrentScreen == EAstroMissionScreen::Navigation ? 142.0f : 118.0f)
        : Buckets.BodyLines.Num() >= 3 ? 184.0f : 164.0f;
    const float CardX = CurrentScreen == EAstroMissionScreen::StampAward
        ? FMath::Clamp(Canvas->SizeX * 0.07f, 34.0f, 96.0f)
        : CurrentScreen == EAstroMissionScreen::Scanning
        ? FMath::Clamp(Canvas->SizeX * 0.045f, 34.0f, 64.0f)
        : bWorldTeachingScreen && !bHasQuizRows
        ? FMath::Clamp(Canvas->SizeX * 0.045f, 34.0f, 72.0f)
        : (Canvas->SizeX - CardW) * 0.5f;
    const float DesiredCardY = CurrentScreen == EAstroMissionScreen::StampAward
        ? FMath::Clamp(Canvas->SizeY * 0.15f, HeaderH + 18.0f, 142.0f)
        : bHasQuizRows
        ? FMath::Max(HeaderH + 12.0f, FMath::Clamp(Canvas->SizeY * 0.28f, 176.0f, 236.0f))
        : CurrentScreen == EAstroMissionScreen::Scanning
        ? FMath::Max(HeaderH + 12.0f, Canvas->SizeY - CardH - FMath::Clamp(Canvas->SizeY * 0.07f, 34.0f, 54.0f))
        : FMath::Max(HeaderH + 12.0f, FMath::Clamp(Canvas->SizeY * (bWorldTeachingScreen ? 0.54f : 0.40f), bWorldTeachingScreen ? 382.0f : 286.0f, bWorldTeachingScreen ? 442.0f : 350.0f));
    const float MinCardY = HeaderH + 12.0f;
    const float MaxCardY = FMath::Max(MinCardY, Canvas->SizeY - CardH - 52.0f);
    const float CardY = FMath::Clamp(DesiredCardY, MinCardY, MaxCardY);

    if (GameMode->IsScanEffectActive())
    {
        DrawRect(FLinearColor(0.08f, 0.74f, 1.0f, 0.035f), 0.0f, 0.0f, Canvas->SizeX, Canvas->SizeY);
        DrawFeedbackToast(CurrentScreen == EAstroMissionScreen::Scanning ? TEXT("Beam travelling") : TEXT("Discovery signal"), FLinearColor(0.04f, 0.36f, 0.46f, 0.88f), CardX + 28.0f, CardY - 42.0f, FMath::Min(CardW - 56.0f, 320.0f));
        if (CurrentScreen == EAstroMissionScreen::Scanning)
        {
            DrawScanImpactBurst(Canvas->SizeX * 0.58f, Canvas->SizeY * 0.70f, FMath::Clamp(Canvas->SizeX * 0.035f, 34.0f, 56.0f));
        }
    }

    if (CurrentScreen == EAstroMissionScreen::DeepDive)
    {
        const float CueW = FMath::Clamp(Canvas->SizeX - (CardX + CardW + 58.0f), 0.0f, 292.0f);
        if (CueW >= 210.0f)
        {
            DrawDeepDiveWorldCue(CardX + CardW + 24.0f, FMath::Max(HeaderH + 24.0f, CardY - 16.0f), CueW, FMath::Min(194.0f, Canvas->SizeY - HeaderH - 92.0f));
        }
    }

    DrawPassportFrame(CardX, CardY, CardW, CardH);
    if (CurrentScreen == EAstroMissionScreen::StampAward)
    {
        DrawStampAwardHero(CardX, CardY, CardW, CardH);
        DrawFirstRouteCue(CardX + 36.0f, CardY + CardH - 142.0f, FMath::Min(430.0f, CardW - 72.0f), true);
    }
    if (bHasStampFeedback
        && CurrentScreen != EAstroMissionScreen::StampAward
        && CurrentScreen != EAstroMissionScreen::AtlasView
        && CurrentScreen != EAstroMissionScreen::Passport)
    {
        DrawFeedbackBanner(TEXT("Stamp added to your passport"), FLinearColor(0.11f, 0.48f, 0.25f, 0.95f), CardY - 68.0f);
    }

    float Y = CardY + 24.0f;
    DrawLine(DisplayPrimaryLine, CardX + 42.0f, Y, FLinearColor(1.0f, 0.95f, 0.68f), CurrentScreen == EAstroMissionScreen::Home ? 1.18f : CurrentScreen == EAstroMissionScreen::StampAward ? 1.28f : CurrentScreen == EAstroMissionScreen::Navigation ? 1.16f : bHasQuizRows ? 1.42f : 1.36f);

    if (bHasQuizRows)
    {
        Y += 8.0f;
        const FString LowerPrompt = DisplayPrimaryLine.ToLower();
        const FString QuizClue = LowerPrompt.Contains(TEXT("sun"))
            ? TEXT("World clue: the Sun is a star that makes its own light.")
            : LowerPrompt.Contains(TEXT("mercury"))
            ? TEXT("World clue: Mercury is small, rocky, and cratered.")
            : TEXT("World clue: match your answer to what you scanned.");
        DrawRect(FLinearColor(0.04f, 0.16f, 0.18f, 0.88f), CardX + 42.0f, Y, CardW - 84.0f, 48.0f);
        DrawRect(FLinearColor(0.35f, 0.90f, 0.86f, 0.94f), CardX + 42.0f, Y, 12.0f, 48.0f);
        DrawMiniLearningIcon(LowerPrompt.Contains(TEXT("mercury")) ? TEXT("Mercury") : TEXT("Sun"), CardX + 76.0f, Y + 24.0f, 26.0f);
        DrawText(AstroClipTextToWidth(QuizClue, CardW - 158.0f, 1.02f), FLinearColor(0.88f, 1.0f, 0.96f), CardX + 104.0f, Y + 13.0f, GEngine->GetSmallFont(), 1.02f, false);
        Y += 58.0f;
        for (const FString& Line : Buckets.QuizRows)
        {
            const bool bFocused = Line.TrimStart().StartsWith(TEXT(">"));
            DrawQuizRow(Line, CardX + 42.0f, Y, CardW - 84.0f, bFocused);
            Y += 78.0f;
        }
    }
    else if (bHasMenuRows)
    {
        Y += 8.0f;
        for (const FString& Line : Buckets.MenuRows)
        {
            const bool bFocused = Line.TrimStart().StartsWith(TEXT(">")) || Line.StartsWith(TEXT("READY:"));
            DrawMenuRow(Line, CardX + 42.0f, Y, CardW - 84.0f, bFocused);
            Y += CurrentScreen == EAstroMissionScreen::Home ? 32.0f : 38.0f;
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
        DrawAtlasRouteMap(CardX + 42.0f, Y + 4.0f, CardW - 84.0f);
        Y += 62.0f;
        for (const FString& Line : Buckets.PassportRows)
        {
            DrawPassportRow(Line, CardX + 42.0f, Y, CardW - 84.0f);
            Y += 34.0f;
            ++DrawnRows;
            if (DrawnRows >= 4)
            {
                break;
            }
        }
    }
    else
    {
        int32 DrawnLines = 0;
        const int32 MaxBodyLines = CurrentScreen == EAstroMissionScreen::DeepDive ? 3 : (CurrentScreen == EAstroMissionScreen::Navigation || CurrentScreen == EAstroMissionScreen::Scanning || CurrentScreen == EAstroMissionScreen::DiscoveryCard || CurrentScreen == EAstroMissionScreen::StampAward) ? 2 : bYoungExplorer ? 2 : 3;
        if (CurrentScreen == EAstroMissionScreen::QuizFeedback)
        {
            const FString LowerFeedback = DisplayPrimaryLine.ToLower();
            const bool bTryAgain = LowerFeedback.Contains(TEXT("try")) || LowerFeedback.Contains(TEXT("no worries")) || LowerFeedback.Contains(TEXT("again"));
            DrawBadge(bTryAgain ? TEXT("TRY AGAIN") : TEXT("GREAT PICK"), CardX + 42.0f, Y + 4.0f, bTryAgain ? 128.0f : 132.0f, bTryAgain ? FLinearColor(0.14f, 0.46f, 0.66f, 0.96f) : FLinearColor(0.86f, 0.38f, 0.12f, 0.96f), FLinearColor::White, 0.74f);
            DrawText(bTryAgain ? TEXT("Use the Sun clue, then pick again.") : TEXT("You found the Sun clue. Stamp time!"), FLinearColor(0.91f, 0.98f, 1.0f), CardX + 184.0f, Y + 11.0f, GEngine->GetSmallFont(), 0.88f, false);
            Y += 52.0f;
        }
        else if (CurrentScreen == EAstroMissionScreen::DiscoveryCard || CurrentScreen == EAstroMissionScreen::DeepDive || CurrentScreen == EAstroMissionScreen::StampAward)
        {
            DrawLearningBadgeRow(CurrentScreen, CardX + 42.0f, Y, CurrentScreen == EAstroMissionScreen::StampAward ? FMath::Max(220.0f, CardW - 270.0f) : CardW - 84.0f);
            Y += 50.0f;
        }
        for (const FString& Line : Buckets.BodyLines)
        {
            const float BodyX = CardX + 42.0f;
            const float BodyScale = CurrentScreen == EAstroMissionScreen::StampAward ? 1.14f : CurrentScreen == EAstroMissionScreen::DeepDive ? 1.00f : CurrentScreen == EAstroMissionScreen::DiscoveryCard ? 1.12f : 1.02f;
            if (CurrentScreen == EAstroMissionScreen::DeepDive && DrawDeepDiveSectionLine(Line, BodyX, Y, CardW - 84.0f))
            {
                ++DrawnLines;
                if (DrawnLines >= MaxBodyLines)
                {
                    break;
                }
                continue;
            }
            const FString BodyLine = CurrentScreen == EAstroMissionScreen::StampAward
                ? AstroClipTextToWidth(Line, FMath::Max(180.0f, CardW - 252.0f), BodyScale)
                : Line;
            DrawLine(BodyLine, BodyX, Y, FLinearColor(0.91f, 0.98f, 1.0f), BodyScale);
            ++DrawnLines;
            if (DrawnLines >= MaxBodyLines)
            {
                break;
            }
        }

        for (const FString& Line : Buckets.HintLines)
        {
            if (DrawnLines >= (bYoungExplorer ? 2 : 4))
            {
                break;
            }

            Y += 2.0f;
            DrawLine(Line, CardX + 42.0f, Y, FLinearColor(0.76f, 0.90f, 0.92f), CurrentScreen == EAstroMissionScreen::QuizFeedback ? 0.98f : 0.84f);
            ++DrawnLines;
        }
    }

    DrawActionBar(CurrentScreen, CardX + 30.0f, CardY + CardH - 40.0f, CardW - 60.0f, bHasQuizRows);
}

void AAstroMissionHUD::EnsureOwnedTexturesLoaded()
{
    if (PassportCardTexture)
    {
        return;
    }

    PassportCardTexture = LoadOwnedTexture(TEXT("UI/T_Passport_Card_Background.png"));
    ActionChipTexture = LoadOwnedTexture(TEXT("UI/T_Action_Chip.png"));
    StampSunTexture = LoadOwnedTexture(TEXT("UI/T_Stamp_Sun.png"));
    StampMercuryTexture = LoadOwnedTexture(TEXT("UI/T_Stamp_Mercury.png"));
    StampGenericTexture = LoadOwnedTexture(TEXT("UI/T_Stamp_Generic.png"));
    SunSurfaceTexture = LoadObject<UTexture2D>(nullptr, TEXT("/Game/Art/AstroAdventureOwned/Textures/Planets/T_Sun_Surface_Stylized.T_Sun_Surface_Stylized"));
    MercurySurfaceTexture = LoadObject<UTexture2D>(nullptr, TEXT("/Game/Art/AstroAdventureOwned/Textures/Planets/T_Mercury_Craters_Stylized.T_Mercury_Craters_Stylized"));
    StarfieldTexture = LoadObject<UTexture2D>(nullptr, TEXT("/Game/Art/AstroAdventureOwned/Textures/FX/T_Starfield_SoftDepth.T_Starfield_SoftDepth"));
    if (!SunSurfaceTexture)
    {
        SunSurfaceTexture = LoadOwnedTexture(TEXT("Planets/T_Sun_Surface_Stylized.png"));
    }
    if (!MercurySurfaceTexture)
    {
        MercurySurfaceTexture = LoadOwnedTexture(TEXT("Planets/T_Mercury_Craters_Stylized.png"));
    }
    if (!StarfieldTexture)
    {
        StarfieldTexture = LoadOwnedTexture(TEXT("FX/T_Starfield_SoftDepth.png"));
    }
}

UTexture2D* AAstroMissionHUD::LoadOwnedTexture(const FString& RelativePath) const
{
    const FString TexturePath = FPaths::ProjectContentDir() / TEXT("Art/AstroAdventureOwned/Textures") / RelativePath;
    TArray<uint8> CompressedData;
    if (!FFileHelper::LoadFileToArray(CompressedData, *TexturePath))
    {
        return nullptr;
    }

    IImageWrapperModule& ImageWrapperModule = FModuleManager::LoadModuleChecked<IImageWrapperModule>(TEXT("ImageWrapper"));
    TSharedPtr<IImageWrapper> ImageWrapper = ImageWrapperModule.CreateImageWrapper(EImageFormat::PNG);
    if (!ImageWrapper.IsValid() || !ImageWrapper->SetCompressed(CompressedData.GetData(), CompressedData.Num()))
    {
        return nullptr;
    }

    TArray<uint8> RawData;
    if (!ImageWrapper->GetRaw(ERGBFormat::BGRA, 8, RawData))
    {
        return nullptr;
    }

    UTexture2D* Texture = UTexture2D::CreateTransient(ImageWrapper->GetWidth(), ImageWrapper->GetHeight(), PF_B8G8R8A8);
    if (!Texture || !Texture->GetPlatformData() || Texture->GetPlatformData()->Mips.Num() == 0)
    {
        return nullptr;
    }

    void* TextureData = Texture->GetPlatformData()->Mips[0].BulkData.Lock(LOCK_READ_WRITE);
    FMemory::Memcpy(TextureData, RawData.GetData(), RawData.Num());
    Texture->GetPlatformData()->Mips[0].BulkData.Unlock();
    Texture->SRGB = true;
    Texture->UpdateResource();
    return Texture;
}

void AAstroMissionHUD::DrawOwnedTexture(UTexture2D* Texture, const float X, const float Y, const float W, const float H, const FLinearColor& Tint)
{
    if (!Texture)
    {
        return;
    }

    DrawTexture(Texture, X, Y, W, H, 0.0f, 0.0f, 1.0f, 1.0f, Tint, BLEND_Translucent);
}

void AAstroMissionHUD::DrawLine(const FString& Text, const float X, float& Y, const FLinearColor& Color, const float Scale)
{
    const float MaxW = Canvas ? FMath::Min(FMath::Max(120.0f, Canvas->SizeX - X - 28.0f), 680.0f) : 480.0f;
    const int32 MaxLines = Scale >= 1.20f && Scale < 1.40f ? 2 : 1;
    const TArray<FString> Lines = AstroWrapTextToWidth(Text, MaxW, Scale, MaxLines);
    for (const FString& Line : Lines)
    {
        DrawText(Line, Color, X, Y, GEngine->GetSmallFont(), Scale, false);
        Y += 22.0f * Scale;
    }
}

void AAstroMissionHUD::DrawBadge(const FString& Text, const float X, const float Y, const float W, const FLinearColor& Fill, const FLinearColor& TextColor, const float Scale)
{
    DrawRect(Fill, X, Y, W, 30.0f);
    DrawOwnedTexture(ActionChipTexture, X, Y, W, 30.0f, FLinearColor(1.0f, 1.0f, 1.0f, 0.30f));
    DrawRect(FLinearColor(1.0f, 0.96f, 0.76f, 0.18f), X, Y, W, 3.0f);
    DrawText(AstroClipTextToWidth(Text, W - 22.0f, Scale), TextColor, X + 11.0f, Y + 7.0f, GEngine->GetSmallFont(), Scale, false);
}

void AAstroMissionHUD::DrawMiniLearningIcon(const FString& Icon, const float CenterX, const float CenterY, const float Size)
{
    const FString Lower = Icon.ToLower();
    const float S = FMath::Max(8.0f, Size);
    if (Lower.Contains(TEXT("sun")))
    {
        DrawSoftEllipse(CenterX, CenterY, S * 0.55f, S * 0.50f, FLinearColor(1.0f, 0.48f, 0.08f, 0.22f), 14);
        DrawSoftEllipse(CenterX, CenterY, S * 0.34f, S * 0.31f, FLinearColor(1.0f, 0.72f, 0.14f, 0.98f), 14);
        DrawRect(FLinearColor(1.0f, 0.88f, 0.32f, 0.70f), CenterX - S * 0.05f, CenterY - S * 0.62f, S * 0.10f, S * 0.26f);
        DrawRect(FLinearColor(1.0f, 0.88f, 0.32f, 0.70f), CenterX - S * 0.05f, CenterY + S * 0.36f, S * 0.10f, S * 0.26f);
        DrawRect(FLinearColor(1.0f, 0.88f, 0.32f, 0.70f), CenterX - S * 0.62f, CenterY - S * 0.05f, S * 0.26f, S * 0.10f);
        DrawRect(FLinearColor(1.0f, 0.88f, 0.32f, 0.70f), CenterX + S * 0.36f, CenterY - S * 0.05f, S * 0.26f, S * 0.10f);
    }
    else if (Lower.Contains(TEXT("mercury")) || Lower.Contains(TEXT("crater")))
    {
        DrawSoftEllipse(CenterX, CenterY, S * 0.42f, S * 0.38f, FLinearColor(0.62f, 0.65f, 0.62f, 0.98f), 14);
        DrawSoftEllipse(CenterX - S * 0.14f, CenterY - S * 0.10f, S * 0.10f, S * 0.08f, FLinearColor(0.18f, 0.20f, 0.20f, 0.58f), 8);
        DrawSoftEllipse(CenterX + S * 0.15f, CenterY + S * 0.08f, S * 0.13f, S * 0.10f, FLinearColor(0.22f, 0.24f, 0.23f, 0.52f), 8);
    }
    else if (Lower.Contains(TEXT("check")) || Lower.Contains(TEXT("stamp")))
    {
        DrawRect(FLinearColor(0.12f, 0.54f, 0.32f, 0.96f), CenterX - S * 0.42f, CenterY - S * 0.38f, S * 0.84f, S * 0.76f);
        DrawRect(FLinearColor(1.0f, 0.96f, 0.68f, 0.96f), CenterX - S * 0.24f, CenterY + S * 0.04f, S * 0.17f, S * 0.30f);
        DrawRect(FLinearColor(1.0f, 0.96f, 0.68f, 0.96f), CenterX - S * 0.07f, CenterY + S * 0.20f, S * 0.42f, S * 0.14f);
    }
    else
    {
        DrawSoftEllipse(CenterX, CenterY, S * 0.40f, S * 0.36f, FLinearColor(0.34f, 0.76f, 0.90f, 0.96f), 12);
        DrawRect(FLinearColor(0.88f, 1.0f, 0.98f, 0.92f), CenterX - S * 0.05f, CenterY - S * 0.24f, S * 0.10f, S * 0.30f);
        DrawRect(FLinearColor(0.88f, 1.0f, 0.98f, 0.92f), CenterX - S * 0.05f, CenterY + S * 0.18f, S * 0.10f, S * 0.10f);
    }
}

void AAstroMissionHUD::DrawLearningBadge(const FString& Icon, const FString& Label, const FString& Detail, const float X, const float Y, const float W, const FLinearColor& Fill)
{
    DrawRect(FLinearColor(0.02f, 0.04f, 0.05f, 0.38f), X + 3.0f, Y + 4.0f, W, 42.0f);
    DrawRect(Fill, X, Y, W, 42.0f);
    DrawRect(FLinearColor(1.0f, 0.96f, 0.74f, 0.20f), X + 8.0f, Y + 5.0f, W - 16.0f, 2.0f);
    DrawMiniLearningIcon(Icon, X + 24.0f, Y + 21.0f, 26.0f);
    DrawText(AstroClipTextToWidth(Label, W - 54.0f, 0.62f), FLinearColor(1.0f, 0.96f, 0.74f), X + 46.0f, Y + 7.0f, GEngine->GetSmallFont(), 0.62f, false);
    DrawText(AstroClipTextToWidth(Detail, W - 54.0f, 0.58f), FLinearColor(0.90f, 1.0f, 0.98f), X + 46.0f, Y + 23.0f, GEngine->GetSmallFont(), 0.58f, false);
}

void AAstroMissionHUD::DrawLearningBadgeRow(const EAstroMissionScreen Screen, const float X, const float Y, const float W)
{
    FString FirstIcon = TEXT("Sun");
    FString FirstLabel = TEXT("NOTICE");
    FString FirstDetail = TEXT("Sun makes light");
    FString SecondIcon = TEXT("Info");
    FString SecondLabel = TEXT("REMEMBER");
    FString SecondDetail = TEXT("A star is a light maker");
    FString ThirdIcon = TEXT("Mercury");
    FString ThirdLabel = TEXT("NEXT");
    FString ThirdDetail = TEXT("Mercury has craters");

    FLinearColor FirstFill = FLinearColor(0.76f, 0.30f, 0.10f, 0.94f);
    FLinearColor SecondFill = FLinearColor(0.12f, 0.42f, 0.56f, 0.94f);
    FLinearColor ThirdFill = FLinearColor(0.40f, 0.36f, 0.42f, 0.94f);

    if (Screen == EAstroMissionScreen::DeepDive)
    {
        FirstLabel = TEXT("LOOK");
        FirstDetail = TEXT("light and heat");
        SecondLabel = TEXT("COMPARE");
        SecondDetail = TEXT("star, not planet");
        ThirdIcon = TEXT("Info");
        ThirdLabel = TEXT("WORD");
        ThirdDetail = TEXT("star");
        ThirdFill = FLinearColor(0.42f, 0.28f, 0.62f, 0.94f);
    }
    else if (Screen == EAstroMissionScreen::QuizFeedback)
    {
        FirstIcon = TEXT("Info");
        FirstLabel = TEXT("CLUE");
        FirstDetail = TEXT("match the card");
        SecondIcon = TEXT("Check");
        SecondLabel = TEXT("TRY");
        SecondDetail = TEXT("one answer");
        ThirdIcon = TEXT("Stamp");
        ThirdLabel = TEXT("GOAL");
        ThirdDetail = TEXT("earn Sun stamp");
        SecondFill = FLinearColor(0.20f, 0.50f, 0.72f, 0.94f);
        ThirdFill = FLinearColor(0.12f, 0.54f, 0.32f, 0.94f);
    }
    else if (Screen == EAstroMissionScreen::StampAward)
    {
        FirstIcon = TEXT("Stamp");
        FirstLabel = TEXT("I LEARNED");
        FirstDetail = TEXT("Sun is a star");
        SecondIcon = TEXT("Sun");
        SecondLabel = TEXT("STAR POWER");
        SecondDetail = TEXT("makes light");
        ThirdIcon = TEXT("Mercury");
        ThirdLabel = TEXT("NEXT");
        ThirdDetail = TEXT("closest planet");
        SecondFill = FLinearColor(0.86f, 0.40f, 0.12f, 0.94f);
        ThirdFill = FLinearColor(0.40f, 0.46f, 0.50f, 0.94f);
    }

    const int32 BadgeCount = W >= 500.0f ? 3 : 2;
    const float Gap = 8.0f;
    const float BadgeW = (W - Gap * (BadgeCount - 1)) / BadgeCount;
    DrawLearningBadge(FirstIcon, FirstLabel, FirstDetail, X, Y, BadgeW, FirstFill);
    DrawLearningBadge(SecondIcon, SecondLabel, SecondDetail, X + BadgeW + Gap, Y, BadgeW, SecondFill);
    if (BadgeCount >= 3)
    {
        DrawLearningBadge(ThirdIcon, ThirdLabel, ThirdDetail, X + (BadgeW + Gap) * 2.0f, Y, BadgeW, ThirdFill);
    }
}

void AAstroMissionHUD::DrawFirstRouteCue(const float X, const float Y, const float W, const bool bUnlocked)
{
    const float CueW = FMath::Max(230.0f, W);
    const float CueH = bUnlocked ? 74.0f : 92.0f;
    DrawRect(FLinearColor(0.02f, 0.035f, 0.055f, 0.48f), X + 5.0f, Y + 6.0f, CueW, CueH);
    DrawRect(bUnlocked ? FLinearColor(0.20f, 0.13f, 0.08f, 0.82f) : FLinearColor(0.06f, 0.14f, 0.20f, 0.72f), X, Y, CueW, CueH);
    DrawRect(FLinearColor(1.0f, 0.78f, 0.24f, bUnlocked ? 0.95f : 0.72f), X, Y, 8.0f, CueH);

    const FString Title = bUnlocked ? TEXT("Route unlocked") : TEXT("First route");
    const FString Detail = bUnlocked ? TEXT("Fly from the Sun stamp to Mercury") : TEXT("Sun -> Mercury");
    DrawText(Title, FLinearColor(1.0f, 0.94f, 0.68f), X + 18.0f, Y + 10.0f, GEngine->GetSmallFont(), 0.74f, false);
    DrawText(AstroClipTextToWidth(Detail, CueW - 36.0f, 0.66f), FLinearColor(0.88f, 1.0f, 0.96f), X + 18.0f, Y + 29.0f, GEngine->GetSmallFont(), 0.66f, false);

    const float IconY = Y + (bUnlocked ? 54.0f : 68.0f);
    const float SunX = X + 34.0f;
    const float MercuryX = X + CueW - 34.0f;
    DrawMiniLearningIcon(TEXT("Sun"), SunX, IconY, 30.0f);
    DrawMiniLearningIcon(TEXT("Mercury"), MercuryX, IconY, 28.0f);

    const float LineX = SunX + 24.0f;
    const float LineW = FMath::Max(32.0f, MercuryX - SunX - 52.0f);
    DrawRect(FLinearColor(1.0f, 0.78f, 0.26f, bUnlocked ? 0.82f : 0.52f), LineX, IconY - 2.0f, LineW, 4.0f);
    for (int32 Index = 0; Index < 5; ++Index)
    {
        const float Alpha = static_cast<float>(Index + 1) / 6.0f;
        DrawSoftEllipse(LineX + LineW * Alpha, IconY - FMath::Sin(Alpha * PI) * 11.0f, bUnlocked ? 6.0f : 4.0f, bUnlocked ? 6.0f : 4.0f, FLinearColor(1.0f, 0.92f, 0.36f, bUnlocked ? 0.95f : 0.64f), 8);
    }

    DrawRect(FLinearColor(1.0f, 0.78f, 0.26f, bUnlocked ? 0.92f : 0.62f), MercuryX - 50.0f, IconY - 10.0f, 18.0f, 4.0f);
    DrawRect(FLinearColor(1.0f, 0.78f, 0.26f, bUnlocked ? 0.92f : 0.62f), MercuryX - 38.0f, IconY - 15.0f, 4.0f, 14.0f);
    DrawText(TEXT("SUN"), FLinearColor(1.0f, 0.90f, 0.56f), SunX - 16.0f, IconY + 17.0f, GEngine->GetSmallFont(), 0.52f, false);
    DrawText(TEXT("MERCURY"), FLinearColor(0.88f, 0.96f, 1.0f), MercuryX - 28.0f, IconY + 17.0f, GEngine->GetSmallFont(), 0.52f, false);
}

void AAstroMissionHUD::DrawPassportFrame(const float X, const float Y, const float W, const float H)
{
    DrawRect(FLinearColor(0.03f, 0.035f, 0.045f, 0.50f), X - 6.0f, Y + 7.0f, W + 12.0f, H);
    DrawRect(FLinearColor(0.86f, 0.72f, 0.42f, 0.94f), X, Y, W, H);
    DrawOwnedTexture(PassportCardTexture, X, Y, W, H, FLinearColor(1.0f, 1.0f, 1.0f, 0.24f));
    DrawRect(FLinearColor(0.26f, 0.14f, 0.09f, 0.84f), X + 8.0f, Y + 8.0f, W - 16.0f, H - 16.0f);
    DrawRect(FLinearColor(0.95f, 0.78f, 0.22f, 0.98f), X, Y, 16.0f, H);
    DrawRect(FLinearColor(0.98f, 0.88f, 0.56f, 0.36f), X + 30.0f, Y + 18.0f, W - 60.0f, 2.0f);
    DrawRect(FLinearColor(0.94f, 0.64f, 0.20f, 0.32f), X + 30.0f, Y + H - 54.0f, W - 60.0f, 2.0f);
}

void AAstroMissionHUD::DrawStampAwardHero(const float X, const float Y, const float W, const float H)
{
    const float StampSize = FMath::Clamp(W * 0.22f, 112.0f, 150.0f);
    const float StampX = X + W - StampSize - 40.0f;
    const float StampY = Y + 38.0f;
    const float CenterX = StampX + StampSize * 0.5f;
    const float CenterY = StampY + StampSize * 0.5f;

    DrawRect(FLinearColor(1.0f, 0.86f, 0.48f, 0.12f), X + 36.0f, Y + 54.0f, W - 72.0f, 2.0f);
    DrawRect(FLinearColor(1.0f, 0.58f, 0.18f, 0.14f), X + 36.0f, Y + H - 70.0f, W - 72.0f, 2.0f);
    DrawSoftEllipse(CenterX, CenterY, StampSize * 0.80f, StampSize * 0.74f, FLinearColor(1.0f, 0.72f, 0.18f, 0.18f), 30);
    DrawSoftEllipse(CenterX, CenterY, StampSize * 0.56f, StampSize * 0.52f, FLinearColor(0.98f, 0.42f, 0.12f, 0.82f), 28);
    if (StampSunTexture)
    {
        DrawOwnedTexture(StampSunTexture, StampX, StampY, StampSize, StampSize, FLinearColor(1.0f, 0.98f, 0.82f, 0.92f));
    }
    else
    {
        DrawSoftEllipse(CenterX, CenterY, StampSize * 0.34f, StampSize * 0.32f, FLinearColor(1.0f, 0.88f, 0.28f, 0.94f), 20);
        DrawSoftEllipse(CenterX + StampSize * 0.10f, CenterY - StampSize * 0.06f, StampSize * 0.18f, StampSize * 0.12f, FLinearColor(0.86f, 0.20f, 0.08f, 0.48f), 10);
    }

    DrawRect(FLinearColor(1.0f, 0.94f, 0.55f, 0.58f), StampX - 8.0f, StampY - 8.0f, StampSize + 16.0f, 4.0f);
    DrawRect(FLinearColor(1.0f, 0.94f, 0.55f, 0.58f), StampX - 8.0f, StampY + StampSize + 4.0f, StampSize + 16.0f, 4.0f);
    DrawText(TEXT("SUN STAMP!"), FLinearColor(1.0f, 0.90f, 0.48f), StampX + 4.0f, StampY + StampSize + 10.0f, GEngine->GetSmallFont(), 0.86f, false);
    DrawText(TEXT("You found a star!"), FLinearColor(1.0f, 0.96f, 0.78f), X + 48.0f, Y + 136.0f, GEngine->GetSmallFont(), 1.04f, false);
    DrawText(TEXT("The Sun makes its own light."), FLinearColor(0.88f, 0.98f, 1.0f), X + 48.0f, Y + 166.0f, GEngine->GetSmallFont(), 0.96f, false);

    const float MercuryX = FMath::Max(X + 356.0f, StampX - 146.0f);
    const float MercuryY = StampY + StampSize * 0.70f;
    DrawRect(FLinearColor(1.0f, 0.78f, 0.26f, 0.78f), MercuryX - 116.0f, MercuryY - 3.0f, 104.0f, 6.0f);
    DrawSoftEllipse(MercuryX, MercuryY, 48.0f, 41.0f, FLinearColor(0.56f, 0.59f, 0.55f, 0.98f), 24);
    DrawSoftEllipse(MercuryX - 16.0f, MercuryY - 11.0f, 14.0f, 10.0f, FLinearColor(0.10f, 0.12f, 0.12f, 0.64f), 10);
    DrawSoftEllipse(MercuryX + 15.0f, MercuryY + 6.0f, 15.0f, 11.0f, FLinearColor(0.12f, 0.13f, 0.13f, 0.58f), 10);
    DrawSoftEllipse(MercuryX - 2.0f, MercuryY + 18.0f, 11.0f, 7.0f, FLinearColor(0.20f, 0.20f, 0.18f, 0.50f), 8);
    DrawText(TEXT("Next: Mercury"), FLinearColor(0.78f, 0.96f, 1.0f), MercuryX - 62.0f, MercuryY + 48.0f, GEngine->GetSmallFont(), 0.88f, false);
    DrawText(TEXT("closest crater planet"), FLinearColor(0.94f, 0.84f, 0.58f), MercuryX - 74.0f, MercuryY + 72.0f, GEngine->GetSmallFont(), 0.72f, false);

    const float BadgeY = Y + H - 52.0f;
    const float BadgeW = FMath::Min(W - 80.0f, 540.0f);
    DrawRect(FLinearColor(0.04f, 0.20f, 0.28f, 0.94f), X + 40.0f, BadgeY, BadgeW, 38.0f);
    DrawRect(FLinearColor(0.80f, 0.96f, 1.0f, 0.28f), X + 48.0f, BadgeY + 5.0f, BadgeW - 16.0f, 2.0f);
    DrawRect(FLinearColor(0.94f, 0.64f, 0.18f, 0.96f), X + 40.0f, BadgeY, 12.0f, 38.0f);
    DrawText(TEXT("NEXT STOP: MERCURY"), FLinearColor(0.86f, 1.0f, 1.0f), X + 62.0f, BadgeY + 6.0f, GEngine->GetSmallFont(), 1.00f, false);
    DrawText(TEXT("Closest planet to the Sun. Look for craters."), FLinearColor(1.0f, 0.92f, 0.66f), X + 288.0f, BadgeY + 10.0f, GEngine->GetSmallFont(), 0.78f, false);
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
    DrawText(TEXT("Stamps"), FLinearColor(1.0f, 0.92f, 0.62f), X, Y + 6.0f, GEngine->GetSmallFont(), 0.78f, false);

    float SlotX = X + LabelW;
    for (int32 Index = 0; Index < VisibleSlots; ++Index)
    {
        DrawStampSlot(SlotX, Y, SlotSize, Index < Stamped, Index);
        SlotX += SlotSize + 5.0f;
    }
}

void AAstroMissionHUD::DrawStampSlot(const float X, const float Y, const float Size, const bool bFilled, const int32 Index)
{
    const FLinearColor Fill = bFilled ? FLinearColor(0.94f, 0.52f, 0.12f, 0.96f) : FLinearColor(0.96f, 0.82f, 0.48f, 0.26f);
    const FLinearColor Mark = bFilled ? FLinearColor(1.0f, 0.94f, 0.66f, 1.0f) : FLinearColor(0.72f, 0.92f, 0.96f, 0.26f);
    DrawRect(Fill, X, Y, Size, Size);
    DrawOwnedTexture(bFilled ? (Index == 0 ? StampSunTexture : Index == 1 ? StampMercuryTexture : StampGenericTexture) : StampGenericTexture, X - 2.0f, Y - 2.0f, Size + 4.0f, Size + 4.0f, bFilled ? FLinearColor(1.0f, 1.0f, 1.0f, 0.82f) : FLinearColor(1.0f, 1.0f, 1.0f, 0.18f));
    DrawRect(FLinearColor(0.05f, 0.12f, 0.14f, 0.55f), X + 2.0f, Y + 2.0f, Size - 4.0f, Size - 4.0f);
    DrawRect(Mark, X + Size * 0.34f, Y + Size * 0.22f, Size * 0.32f, Size * 0.56f);
    if (Index % 2 == 0)
    {
        DrawRect(Mark, X + Size * 0.22f, Y + Size * 0.36f, Size * 0.56f, Size * 0.28f);
    }
}

bool AAstroMissionHUD::DrawDeepDiveSectionLine(const FString& Text, const float X, float& Y, const float W)
{
    FString Label;
    FString Detail;
    if (!Text.Split(TEXT(":"), &Label, &Detail))
    {
        return false;
    }

    Label.TrimStartAndEndInline();
    Detail.TrimStartAndEndInline();
    const bool bCloser = Label.Equals(TEXT("Closer Look"), ESearchCase::IgnoreCase);
    const bool bCompare = Label.Equals(TEXT("Compare"), ESearchCase::IgnoreCase);
    const bool bWord = Label.Equals(TEXT("Word Explorer"), ESearchCase::IgnoreCase);
    if (!bCloser && !bCompare && !bWord)
    {
        return false;
    }

    const FLinearColor Fill = bCloser ? FLinearColor(0.84f, 0.39f, 0.14f, 0.96f)
        : bCompare ? FLinearColor(0.12f, 0.46f, 0.60f, 0.96f)
        : FLinearColor(0.42f, 0.28f, 0.62f, 0.96f);
    const FString BadgeText = bCloser ? TEXT("LOOK") : bCompare ? TEXT("COMPARE") : TEXT("WORD");
    DrawRect(FLinearColor(0.02f, 0.04f, 0.05f, 0.40f), X, Y + 2.0f, W, 48.0f);
    DrawBadge(BadgeText, X + 8.0f, Y + 9.0f, bCompare ? 112.0f : 92.0f, Fill, FLinearColor::White, 0.66f);

    const float TextX = X + (bCompare ? 136.0f : 116.0f);
    float TextY = Y + 9.0f;
    const TArray<FString> Wrapped = AstroWrapTextToWidth(Detail, W - (TextX - X) - 16.0f, 0.88f, 2);
    for (const FString& WrappedLine : Wrapped)
    {
        DrawText(WrappedLine, FLinearColor(0.91f, 0.98f, 1.0f), TextX, TextY, GEngine->GetSmallFont(), 0.88f, false);
        TextY += 19.0f;
    }

    Y = FMath::Max(Y + 54.0f, TextY + 8.0f);
    return true;
}

void AAstroMissionHUD::DrawDeepDiveWorldCue(const float X, const float Y, const float W, const float H)
{
    DrawRect(FLinearColor(0.02f, 0.04f, 0.06f, 0.44f), X + 5.0f, Y + 6.0f, W, H);
    DrawRect(FLinearColor(0.08f, 0.16f, 0.22f, 0.82f), X, Y, W, H);
    DrawRect(FLinearColor(1.0f, 0.76f, 0.24f, 0.82f), X, Y, 8.0f, H);
    DrawText(TEXT("See it in space"), FLinearColor(1.0f, 0.92f, 0.62f), X + 18.0f, Y + 10.0f, GEngine->GetSmallFont(), 0.82f, false);

    const float SunX = X + W - 60.0f;
    const float SunY = Y + 68.0f;
    DrawSoftEllipse(SunX, SunY, 48.0f, 42.0f, FLinearColor(1.0f, 0.48f, 0.08f, 0.20f), 24);
    DrawSoftEllipse(SunX, SunY, 34.0f, 30.0f, FLinearColor(1.0f, 0.66f, 0.14f, 0.94f), 24);
    DrawSoftEllipse(SunX - 7.0f, SunY - 8.0f, 22.0f, 16.0f, FLinearColor(1.0f, 0.88f, 0.30f, 0.64f), 14);
    DrawSoftEllipse(SunX + 12.0f, SunY + 9.0f, 12.0f, 8.0f, FLinearColor(0.72f, 0.15f, 0.04f, 0.36f), 10);

    const float LaneX = X + 20.0f;
    const float LaneW = W - 116.0f;
    DrawBadge(TEXT("LOOK"), LaneX, Y + 42.0f, 76.0f, FLinearColor(0.84f, 0.39f, 0.14f, 0.96f), FLinearColor::White, 0.58f);
    DrawRect(FLinearColor(0.72f, 1.0f, 0.96f, 0.50f), LaneX + 82.0f, Y + 58.0f, FMath::Max(28.0f, LaneW - 84.0f), 3.0f);
    DrawText(TEXT("spot the clue"), FLinearColor(0.82f, 0.96f, 1.0f), LaneX, Y + 72.0f, GEngine->GetSmallFont(), 0.58f, false);

    DrawBadge(TEXT("COMPARE"), LaneX, Y + 98.0f, 112.0f, FLinearColor(0.12f, 0.46f, 0.60f, 0.96f), FLinearColor::White, 0.58f);
    DrawRect(FLinearColor(1.0f, 0.82f, 0.38f, 0.58f), LaneX + 120.0f, Y + 113.0f, FMath::Max(20.0f, LaneW - 122.0f), 4.0f);
    DrawSoftEllipse(LaneX + 126.0f, Y + 115.0f, 7.0f, 7.0f, FLinearColor(0.20f, 0.54f, 1.0f, 0.92f), 8);
    DrawSoftEllipse(SunX - 2.0f, Y + 115.0f, 13.0f, 13.0f, FLinearColor(1.0f, 0.67f, 0.18f, 0.92f), 10);

    DrawBadge(TEXT("WORD"), LaneX, Y + 148.0f, 78.0f, FLinearColor(0.42f, 0.28f, 0.62f, 0.96f), FLinearColor::White, 0.58f);
    DrawRect(FLinearColor(0.72f, 0.92f, 1.0f, 0.18f), LaneX + 88.0f, Y + 148.0f, FMath::Max(36.0f, LaneW - 90.0f), 26.0f);
    DrawText(TEXT("new space word"), FLinearColor(0.86f, 0.96f, 1.0f), LaneX + 98.0f, Y + 154.0f, GEngine->GetSmallFont(), 0.56f, false);
}

void AAstroMissionHUD::DrawAtlasRouteMap(const float X, const float Y, const float W)
{
    const float H = 54.0f;
    DrawRect(FLinearColor(0.04f, 0.08f, 0.09f, 0.72f), X, Y, W, H);
    DrawRect(FLinearColor(0.94f, 0.76f, 0.34f, 0.42f), X + 12.0f, Y + 23.0f, W - 24.0f, 4.0f);
    DrawText(TEXT("Passport map"), FLinearColor(1.0f, 0.92f, 0.62f), X + 16.0f, Y + 6.0f, GEngine->GetSmallFont(), 0.62f, false);

    const TCHAR* Labels[] = { TEXT("Sun"), TEXT("Mercury"), TEXT("Venus"), TEXT("Earth") };
    const FLinearColor NodeColors[] = {
        FLinearColor(1.0f, 0.62f, 0.12f, 0.98f),
        FLinearColor(0.64f, 0.66f, 0.62f, 0.98f),
        FLinearColor(1.0f, 0.74f, 0.36f, 0.98f),
        FLinearColor(0.18f, 0.52f, 0.96f, 0.98f)
    };
    for (int32 Index = 0; Index < 4; ++Index)
    {
        const float T = 0.10f + 0.26f * Index;
        const float NodeX = X + W * T;
        const float NodeY = Y + 25.0f;
        DrawSoftEllipse(NodeX, NodeY, Index == 0 ? 14.0f : 10.0f, Index == 0 ? 14.0f : 10.0f, NodeColors[Index], 12);
        DrawSoftEllipse(NodeX, NodeY, Index == 0 ? 7.0f : 5.0f, Index == 0 ? 7.0f : 5.0f, FLinearColor(1.0f, 0.96f, 0.70f, 0.62f), 8);
        DrawText(Labels[Index], FLinearColor(0.88f, 0.98f, 1.0f), NodeX - 20.0f, Y + 32.0f, GEngine->GetSmallFont(), 0.52f, false);
    }

    DrawText(TEXT("Rocky Worlds route"), FLinearColor(1.0f, 0.92f, 0.62f), X + W - 146.0f, Y + 7.0f, GEngine->GetSmallFont(), 0.58f, false);
}

void AAstroMissionHUD::DrawSoftEllipse(const float CenterX, const float CenterY, const float RadiusX, const float RadiusY, const FLinearColor& Color, const int32 Bands)
{
    const int32 SafeBands = FMath::Clamp(Bands, 8, 64);
    for (int32 Band = 0; Band < SafeBands; ++Band)
    {
        const float T0 = -1.0f + (2.0f * Band) / SafeBands;
        const float T1 = -1.0f + (2.0f * (Band + 1)) / SafeBands;
        const float MidT = (T0 + T1) * 0.5f;
        const float HalfW = RadiusX * FMath::Sqrt(FMath::Max(0.0f, 1.0f - MidT * MidT));
        const float Y = CenterY + T0 * RadiusY;
        const float H = FMath::Max(1.0f, (T1 - T0) * RadiusY + 1.0f);
        DrawRect(Color, CenterX - HalfW, Y, HalfW * 2.0f, H);
    }
}

void AAstroMissionHUD::DrawScanImpactBurst(const float CenterX, const float CenterY, const float Radius)
{
    const float Time = GetWorld() ? GetWorld()->GetTimeSeconds() : 0.0f;
    const float Pulse = 0.5f + 0.5f * FMath::Sin(Time * 9.0f);
    const float OuterRadius = Radius * (1.12f + Pulse * 0.26f);
    const float InnerRadius = Radius * (0.52f + Pulse * 0.10f);

    DrawSoftEllipse(CenterX, CenterY, OuterRadius * 1.18f, OuterRadius * 0.78f, FLinearColor(0.10f, 0.82f, 1.0f, 0.08f), 30);
    DrawSoftEllipse(CenterX, CenterY, OuterRadius, OuterRadius * 0.66f, FLinearColor(0.18f, 0.95f, 1.0f, 0.12f), 26);
    DrawSoftEllipse(CenterX, CenterY, InnerRadius, InnerRadius * 0.56f, FLinearColor(0.54f, 1.0f, 0.78f, 0.26f), 22);
    DrawSoftEllipse(CenterX, CenterY, Radius * 0.18f, Radius * 0.14f, FLinearColor(0.86f, 1.0f, 0.74f, 0.74f), 12);

    const FLinearColor Spark = FLinearColor(0.78f, 1.0f, 0.86f, 0.54f);
    const float SparkScale = Radius * (0.08f + Pulse * 0.02f);
    DrawSoftEllipse(CenterX - Radius * 0.58f, CenterY - Radius * 0.18f, SparkScale, SparkScale * 0.8f, Spark, 8);
    DrawSoftEllipse(CenterX + Radius * 0.52f, CenterY + Radius * 0.16f, SparkScale * 0.9f, SparkScale * 0.7f, Spark, 8);
    DrawSoftEllipse(CenterX + Radius * 0.08f, CenterY - Radius * 0.48f, SparkScale * 0.8f, SparkScale * 0.7f, Spark, 8);
    DrawSoftEllipse(CenterX - Radius * 0.12f, CenterY + Radius * 0.46f, SparkScale * 0.75f, SparkScale * 0.62f, Spark, 8);
}

void AAstroMissionHUD::DrawHomeRouteVignette(const float X, const float Y, const float W, const float H)
{
    const float CenterY = Y + H * 0.50f;
    const float SunX = X + W * 0.28f;
    const float SunY = CenterY - H * 0.03f;
    const float MercuryX = X + W * 0.77f;
    const float MercuryY = CenterY + H * 0.02f;
    const float SunR = FMath::Clamp(W * 0.22f, 70.0f, 104.0f);
    const float MercuryR = FMath::Clamp(W * 0.095f, 31.0f, 48.0f);

    DrawText(TEXT("First route"), FLinearColor(0.90f, 0.98f, 1.0f, 0.94f), X + W * 0.34f, Y - 24.0f, GEngine->GetSmallFont(), 0.90f, false);

    DrawRect(FLinearColor(0.04f, 0.06f, 0.08f, 0.22f), X + W * 0.10f, CenterY - 8.0f, W * 0.80f, 18.0f);
    DrawRect(FLinearColor(1.0f, 0.70f, 0.18f, 0.72f), SunX + SunR * 0.74f, CenterY - 3.0f, MercuryX - SunX - SunR * 0.96f, 6.0f);
    DrawRect(FLinearColor(1.0f, 0.92f, 0.40f, 0.54f), SunX + SunR * 0.74f, CenterY - 1.0f, MercuryX - SunX - SunR * 0.96f, 2.0f);

    DrawSoftEllipse(SunX, SunY, SunR * 1.32f, SunR * 1.20f, FLinearColor(1.0f, 0.55f, 0.10f, 0.10f), 34);
    DrawSoftEllipse(SunX, SunY, SunR, SunR * 0.94f, FLinearColor(1.0f, 0.65f, 0.12f, 0.96f), 34);
    DrawSoftEllipse(SunX - SunR * 0.10f, SunY - SunR * 0.12f, SunR * 0.76f, SunR * 0.66f, FLinearColor(1.0f, 0.84f, 0.22f, 0.72f), 24);
    DrawSoftEllipse(SunX + SunR * 0.24f, SunY + SunR * 0.18f, SunR * 0.38f, SunR * 0.30f, FLinearColor(0.86f, 0.22f, 0.07f, 0.34f), 14);
    DrawSoftEllipse(SunX - SunR * 0.28f, SunY + SunR * 0.16f, SunR * 0.22f, SunR * 0.16f, FLinearColor(0.82f, 0.18f, 0.06f, 0.28f), 12);

    DrawSoftEllipse(MercuryX, MercuryY, MercuryR * 1.20f, MercuryR * 1.06f, FLinearColor(0.62f, 0.74f, 0.80f, 0.16f), 20);
    DrawSoftEllipse(MercuryX, MercuryY, MercuryR, MercuryR * 0.92f, FLinearColor(0.62f, 0.64f, 0.60f, 0.96f), 22);
    DrawSoftEllipse(MercuryX - MercuryR * 0.26f, MercuryY - MercuryR * 0.18f, MercuryR * 0.20f, MercuryR * 0.15f, FLinearColor(0.25f, 0.28f, 0.27f, 0.55f), 8);
    DrawSoftEllipse(MercuryX + MercuryR * 0.22f, MercuryY + MercuryR * 0.12f, MercuryR * 0.26f, MercuryR * 0.20f, FLinearColor(0.28f, 0.30f, 0.29f, 0.50f), 8);
    DrawSoftEllipse(MercuryX - MercuryR * 0.02f, MercuryY + MercuryR * 0.36f, MercuryR * 0.15f, MercuryR * 0.11f, FLinearColor(0.32f, 0.33f, 0.31f, 0.42f), 8);

    DrawText(TEXT("Sun"), FLinearColor(1.0f, 0.88f, 0.42f), SunX - 22.0f, SunY + SunR + 8.0f, GEngine->GetSmallFont(), 1.00f, false);
    DrawText(TEXT("makes light"), FLinearColor(1.0f, 0.96f, 0.75f), SunX - 44.0f, SunY + SunR + 32.0f, GEngine->GetSmallFont(), 0.70f, false);
    DrawText(TEXT("Mercury"), FLinearColor(0.84f, 0.94f, 1.0f), MercuryX - 34.0f, MercuryY + MercuryR + 8.0f, GEngine->GetSmallFont(), 0.78f, false);
    DrawText(TEXT("closest planet"), FLinearColor(0.76f, 0.90f, 0.94f), MercuryX - 46.0f, MercuryY + MercuryR + 28.0f, GEngine->GetSmallFont(), 0.60f, false);
}

void AAstroMissionHUD::DrawActionBar(const EAstroMissionScreen Screen, const float X, const float Y, const float W, const bool bHasQuizRows)
{
    TArray<FString> Actions;

    if (bHasQuizRows)
    {
        AddActionIfMissing(Actions, TEXT("Pick"));
        AddActionIfMissing(Actions, TEXT("Select"));
        AddActionIfMissing(Actions, TEXT("Help"));
    }
    else if (Screen == EAstroMissionScreen::Home)
    {
        AddActionIfMissing(Actions, TEXT("Pick"));
        AddActionIfMissing(Actions, TEXT("Start"));
    }
    else if (Screen == EAstroMissionScreen::AgeSelect)
    {
        AddActionIfMissing(Actions, TEXT("Pick: Arrows"));
        AddActionIfMissing(Actions, TEXT("Select: Enter/Space"));
        AddActionIfMissing(Actions, TEXT("Back: Backspace/B"));
    }
    else if (Screen == EAstroMissionScreen::MissionPrompt)
    {
        AddActionIfMissing(Actions, TEXT("Launch: Enter/Space"));
        AddActionIfMissing(Actions, TEXT("Next: Arrows/WASD"));
        AddActionIfMissing(Actions, TEXT("Back: Esc"));
    }
    else if (Screen == EAstroMissionScreen::PauseMenu)
    {
        AddActionIfMissing(Actions, TEXT("Pick: Arrows"));
        AddActionIfMissing(Actions, TEXT("Start: Enter/Space"));
        AddActionIfMissing(Actions, TEXT("Back: Esc"));
    }
    else if (Screen == EAstroMissionScreen::MissionComplete)
    {
        AddActionIfMissing(Actions, TEXT("Pick: Arrows"));
        AddActionIfMissing(Actions, TEXT("Start: Enter/Space"));
        AddActionIfMissing(Actions, TEXT("Back: Quit"));
    }
    else if (Screen == EAstroMissionScreen::Navigation)
    {
        AddActionIfMissing(Actions, TEXT("Travel: Arrows/WASD"));
        AddActionIfMissing(Actions, TEXT("Scan: Enter/Space"));
        AddActionIfMissing(Actions, TEXT("Passport: P/RT"));
    }
    else if (Screen == EAstroMissionScreen::Scanning)
    {
        AddActionIfMissing(Actions, TEXT("Watch scan"));
        AddActionIfMissing(Actions, TEXT("Back: Backspace/B"));
        AddActionIfMissing(Actions, TEXT("Pause: Esc"));
    }
    else if (Screen == EAstroMissionScreen::Passport || Screen == EAstroMissionScreen::AtlasView)
    {
        AddActionIfMissing(Actions, TEXT("Pick: Arrows"));
        AddActionIfMissing(Actions, TEXT("Start: Enter/Space"));
        AddActionIfMissing(Actions, TEXT("Back: B"));
    }
    else if (Screen == EAstroMissionScreen::DiscoveryCard)
    {
        AddActionIfMissing(Actions, TEXT("Quiz"));
        AddActionIfMissing(Actions, TEXT("More"));
    }
    else if (Screen == EAstroMissionScreen::DeepDive)
    {
        AddActionIfMissing(Actions, TEXT("Quiz"));
        AddActionIfMissing(Actions, TEXT("Back"));
    }
    else if (Screen == EAstroMissionScreen::QuizFeedback)
    {
        AddActionIfMissing(Actions, TEXT("Next"));
        AddActionIfMissing(Actions, TEXT("Help"));
    }
    else if (Screen == EAstroMissionScreen::StampAward)
    {
        AddActionIfMissing(Actions, TEXT("Next"));
        AddActionIfMissing(Actions, TEXT("Passport"));
    }
    else
    {
        AddActionIfMissing(Actions, TEXT("Start: Enter/Space"));
        AddActionIfMissing(Actions, TEXT("Back: B"));
        AddActionIfMissing(Actions, TEXT("Help: Esc"));
    }

    float BadgeX = X;
    const bool bTwoChipScreen = Screen == EAstroMissionScreen::Home
        || Screen == EAstroMissionScreen::DiscoveryCard
        || Screen == EAstroMissionScreen::DeepDive
        || Screen == EAstroMissionScreen::QuizFeedback
        || Screen == EAstroMissionScreen::StampAward;
    const int32 MaxActions = bTwoChipScreen ? 2 : 3;
    for (int32 Index = 0; Index < Actions.Num() && Index < MaxActions; ++Index)
    {
        const float BadgeW = FMath::Clamp(34.0f + Actions[Index].Len() * 6.2f, 96.0f, 188.0f);
        if (BadgeX + BadgeW > X + W)
        {
            break;
        }

        const FLinearColor Fill = Index == 0 ? FLinearColor(0.84f, 0.39f, 0.14f, 0.96f) : FLinearColor(0.18f, 0.25f, 0.36f, 0.94f);
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

    DrawRect(Fill, X, Y, W, 38.0f);
    DrawRect(Stripe, X, Y, bFocused ? 16.0f : 10.0f, 38.0f);
    const FString Verb = bFocused ? AstroActionVerbForChoice(ChoiceText) : TEXT("");
    const float TextX = X + (bFocused ? 88.0f : 28.0f);
    DrawText(Verb, TextColor, X + 22.0f, Y + 10.0f, GEngine->GetSmallFont(), 0.64f, false);
    DrawText(AstroClipTextToWidth(ChoiceText, W - (TextX - X) - 16.0f, 0.98f), TextColor, TextX, Y + 8.0f, GEngine->GetSmallFont(), 0.98f, false);
}

void AAstroMissionHUD::DrawHomeRow(const FString& Text, const float X, const float Y, const float W, const bool bFocused)
{
    FString ChoiceText = FriendlyDetailLine(Text);
    ChoiceText.RemoveFromStart(TEXT(">"));
    ChoiceText.RemoveFromStart(TEXT("READY:"));
    ChoiceText.TrimStartAndEndInline();

    const FLinearColor Fill = bFocused ? FLinearColor(0.96f, 0.66f, 0.18f, 0.96f) : FLinearColor(0.08f, 0.18f, 0.22f, 0.84f);
    const FLinearColor Stripe = bFocused ? FLinearColor(1.0f, 0.95f, 0.62f, 1.0f) : FLinearColor(0.18f, 0.46f, 0.56f, 0.74f);
    const FLinearColor TextColor = bFocused ? FLinearColor(0.05f, 0.06f, 0.07f, 1.0f) : FLinearColor(0.94f, 0.98f, 1.0f, 1.0f);

    DrawRect(Fill, X, Y, W, 42.0f);
    DrawRect(Stripe, X, Y, bFocused ? 18.0f : 12.0f, 42.0f);

    if (bFocused)
    {
        const FString Verb = AstroActionVerbForChoice(ChoiceText);
        DrawText(Verb, TextColor, X + 22.0f, Y + 11.0f, GEngine->GetSmallFont(), 0.82f, false);
        DrawText(AstroClipTextToWidth(ChoiceText, W - 140.0f, 1.14f), TextColor, X + 108.0f, Y + 10.0f, GEngine->GetSmallFont(), 1.14f, false);
    }
    else
    {
        DrawText(AstroClipTextToWidth(ChoiceText, W - 48.0f, 1.02f), TextColor, X + 30.0f, Y + 10.0f, GEngine->GetSmallFont(), 1.02f, false);
    }
}

void AAstroMissionHUD::DrawQuizRow(const FString& Text, const float X, const float Y, const float W, const bool bFocused)
{
    FString ChoiceText = FriendlyDetailLine(Text);
    ChoiceText.RemoveFromStart(TEXT(">"));
    ChoiceText.TrimStartAndEndInline();

    FString ChoiceNumber;
    FString ChoiceBody = ChoiceText;
    if (ChoiceText.Split(TEXT("."), &ChoiceNumber, &ChoiceBody))
    {
        ChoiceNumber.TrimStartAndEndInline();
        ChoiceBody.TrimStartAndEndInline();
        if (ChoiceNumber.Len() > 2)
        {
            ChoiceNumber.Empty();
            ChoiceBody = ChoiceText;
        }
    }

    const FLinearColor Fill = bFocused ? FLinearColor(0.98f, 0.66f, 0.18f, 0.96f) : FLinearColor(0.08f, 0.19f, 0.24f, 0.96f);
    const FLinearColor Stripe = bFocused ? FLinearColor(1.0f, 0.94f, 0.60f, 1.0f) : FLinearColor(0.28f, 0.56f, 0.86f, 0.84f);
    const FLinearColor TextColor = bFocused ? FLinearColor(0.06f, 0.06f, 0.08f, 1.0f) : FLinearColor(0.94f, 0.97f, 1.0f, 1.0f);

    constexpr float RowH = 74.0f;
    DrawRect(FLinearColor(0.02f, 0.04f, 0.05f, bFocused ? 0.42f : 0.24f), X + 5.0f, Y + 6.0f, W, RowH);
    DrawRect(Fill, X, Y, W, RowH);
    DrawRect(Stripe, X, Y, bFocused ? 18.0f : 12.0f, RowH);
    if (bFocused)
    {
        DrawRect(FLinearColor(1.0f, 0.95f, 0.58f, 0.92f), X, Y, W, 4.0f);
        DrawRect(FLinearColor(1.0f, 0.95f, 0.58f, 0.72f), X, Y + RowH - 4.0f, W, 4.0f);
    }
    DrawSoftEllipse(X + 54.0f, Y + RowH * 0.5f, 28.0f, 26.0f, bFocused ? FLinearColor(1.0f, 0.94f, 0.62f, 0.96f) : FLinearColor(0.22f, 0.42f, 0.50f, 0.90f), 18);
    DrawText(ChoiceNumber.IsEmpty() ? TEXT("?") : ChoiceNumber, TextColor, X + 47.0f, Y + 26.0f, GEngine->GetSmallFont(), 1.08f, false);
    DrawText(bFocused ? TEXT("PICK THIS") : TEXT("choice"), TextColor, X + 94.0f, Y + 10.0f, GEngine->GetSmallFont(), bFocused ? 0.72f : 0.62f, false);
    DrawText(AstroClipTextToWidth(ChoiceBody, W - 132.0f, 1.28f), TextColor, X + 94.0f, Y + 35.0f, GEngine->GetSmallFont(), 1.28f, false);
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

    FString GroupLabel;
    FString StateLabel;
    if (Rest.Split(TEXT("|"), &GroupLabel, &StateLabel))
    {
        GroupLabel.TrimStartAndEndInline();
        StateLabel.TrimStartAndEndInline();
    }
    else
    {
        StateLabel = Rest;
    }

    const FString LowerState = StateLabel.ToLower();
    const bool bStamped = LowerState.StartsWith(TEXT("stamped")) || LowerState.Contains(TEXT("stamp"));
    const bool bQuizReady = LowerState.StartsWith(TEXT("ready")) || LowerState.StartsWith(TEXT("quiz ready")) || LowerState.Contains(TEXT("card ready"));
    const FString StampLabel = bStamped ? TEXT("STAMPED") : bQuizReady ? TEXT("CARD READY") : TEXT("VISIT");
    const FLinearColor Fill = bFocused ? FLinearColor(0.91f, 0.58f, 0.18f, 0.94f) : FLinearColor(0.08f, 0.18f, 0.20f, 0.88f);
    const FLinearColor TextColor = bFocused ? FLinearColor(0.05f, 0.06f, 0.06f, 1.0f) : FLinearColor(0.92f, 0.98f, 1.0f, 1.0f);
    const FLinearColor StampColor = bStamped ? FLinearColor(0.96f, 0.45f, 0.16f, 0.98f) : bQuizReady ? FLinearColor(0.12f, 0.56f, 0.64f, 0.98f) : FLinearColor(0.55f, 0.62f, 0.66f, 0.78f);

    DrawRect(Fill, X, Y, W, 34.0f);
    DrawRect(StampColor, X + 8.0f, Y + 5.0f, 104.0f, 24.0f);
    DrawRect(FLinearColor(1.0f, 0.96f, 0.74f, 0.18f), X + 8.0f, Y + 5.0f, 104.0f, 3.0f);
    DrawText(StampLabel, FLinearColor::White, X + 15.0f, Y + 9.0f, GEngine->GetSmallFont(), 0.58f, false);
    DrawText(AstroClipTextToWidth(StopName, W * 0.38f, 0.98f), TextColor, X + 126.0f, Y + 7.0f, GEngine->GetSmallFont(), 0.98f, false);
    if (!GroupLabel.IsEmpty())
    {
        DrawText(AstroClipTextToWidth(GroupLabel, W - 326.0f, 0.70f), bFocused ? FLinearColor(0.10f, 0.18f, 0.18f, 1.0f) : FLinearColor(0.72f, 0.92f, 0.96f, 0.92f), X + W * 0.62f, Y + 10.0f, GEngine->GetSmallFont(), 0.70f, false);
    }
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
    DrawText(AstroClipTextToWidth(Text, BannerW - 116.0f, 1.12f), FLinearColor::White, BannerX + 58.0f, Y + 14.0f, GEngine->GetSmallFont(), 1.12f, false);
}

void AAstroMissionHUD::DrawFeedbackToast(const FString& Text, const FLinearColor& Fill, const float X, const float Y, const float W)
{
    const float ToastY = FMath::Max(74.0f, Y);
    const float ToastW = FMath::Clamp(W, 220.0f, 380.0f);
    DrawRect(FLinearColor(0.02f, 0.04f, 0.05f, 0.54f), X + 4.0f, ToastY + 4.0f, ToastW, 36.0f);
    DrawRect(Fill, X, ToastY, ToastW, 36.0f);
    DrawRect(FLinearColor(0.75f, 0.98f, 1.0f, 0.92f), X, ToastY, 8.0f, 36.0f);
    DrawText(AstroClipTextToWidth(Text, ToastW - 36.0f, 0.86f), FLinearColor::White, X + 18.0f, ToastY + 9.0f, GEngine->GetSmallFont(), 0.86f, false);
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
    return (Trimmed.StartsWith(TEXT(">")) || Trimmed.StartsWith(TEXT("Start")) || Trimmed.StartsWith(TEXT("New Expedition")) || Trimmed.StartsWith(TEXT("Continue"))
            || Trimmed.StartsWith(TEXT("Reset Passport")) || Trimmed.StartsWith(TEXT("Quit")))
        && (Trimmed.Contains(TEXT("Start")) || Trimmed.Contains(TEXT("New Expedition")) || Trimmed.Contains(TEXT("Continue"))
            || Trimmed.Contains(TEXT("Reset Passport")) || Trimmed.Contains(TEXT("Quit")));
}

bool AAstroMissionHUD::IsMenuChoiceLine(const FString& Text) const
{
    const FString Trimmed = Text.TrimStartAndEnd();
    if (!(Trimmed.StartsWith(TEXT(">")) || Trimmed.StartsWith(TEXT("Start")) || Trimmed.StartsWith(TEXT("New Expedition")) || Trimmed.StartsWith(TEXT("Continue"))
        || Trimmed.StartsWith(TEXT("Reset Passport")) || Trimmed.StartsWith(TEXT("Quit"))
        || Trimmed.StartsWith(TEXT("Ages ")) || Trimmed.StartsWith(TEXT("Resume"))
        || Trimmed.StartsWith(TEXT("Restart")) || Trimmed.StartsWith(TEXT("Change age"))
        || Trimmed.StartsWith(TEXT("Explore again")) || Trimmed.StartsWith(TEXT("Open Passport"))))
    {
        return false;
    }

    return Trimmed.Contains(TEXT("Start")) || Trimmed.Contains(TEXT("New Expedition")) || Trimmed.Contains(TEXT("Continue"))
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
        || Lower.Contains(TEXT("visit")) || Lower.Contains(TEXT("quiz ready")) || Lower.Contains(TEXT("not scanned"))
        || Lower.Contains(TEXT("stamp")) || Lower.Contains(TEXT("card")));
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
    Result.ReplaceInline(TEXT("Solar Passport: First Expedition"), TEXT("First Expedition"), ESearchCase::IgnoreCase);
    Result.ReplaceInline(TEXT("Solar Passport discovery log"), TEXT("Passport Stops"), ESearchCase::IgnoreCase);
    Result.ReplaceInline(TEXT("Choose your explorer level"), TEXT("Choose explorer level"), ESearchCase::IgnoreCase);
    Result.ReplaceInline(TEXT("Choose your explorer mode"), TEXT("Choose explorer level"), ESearchCase::IgnoreCase);
    Result.ReplaceInline(TEXT(", then scan its discovery card!"), TEXT(". Scan its card."), ESearchCase::IgnoreCase);
    Result.ReplaceInline(TEXT("Travel to "), TEXT("Next: "), ESearchCase::IgnoreCase);
    Result.ReplaceInline(TEXT("Rescan "), TEXT("Review "), ESearchCase::IgnoreCase);
    Result.ReplaceInline(TEXT(" to review the saved card"), TEXT(" card"), ESearchCase::IgnoreCase);
    return Result;
}

FString AAstroMissionHUD::FriendlyStatusLine(const FString& Text) const
{
    int32 Stamped = 0;
    int32 Total = 0;
    GetStampProgress(Text, Stamped, Total);
    if (Total > 0)
    {
        return FString::Printf(TEXT("%d/%d stamps"), Stamped, Total);
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

    Result.ReplaceInline(TEXT("Click or confirm Start Expedition to launch."), TEXT("Start launches your route."));
    Result.ReplaceInline(TEXT("Start Fresh Expedition clears old stamps for review."), TEXT("Fresh start clears old stamps."));
    Result.ReplaceInline(TEXT("Confirm to launch. You can change this later from Pause."), TEXT("Start launches. You can change this later."));
    Result.ReplaceInline(TEXT("Press M / LT for More Info, or Confirm for the quiz."), TEXT("Help opens Closer Look. Start begins quiz."));
    Result.ReplaceInline(TEXT("Open Passport / RT for the full Atlas route."), TEXT("Passport shows the full route."));
    Result.ReplaceInline(TEXT("Confirm to scan for a discovery card."), TEXT("Scan this stop."));
    Result.ReplaceInline(TEXT("Scan found. Confirm to scan again and reopen its card."), TEXT("Card found. Open it again."));
    Result.ReplaceInline(TEXT("Scan found. Confirm to open its card again."), TEXT("Card found. Open it again."));
    Result.ReplaceInline(TEXT("Stamp saved already. Confirm to rescan and review."), TEXT("Stamped already. Review it."));
    Result.ReplaceInline(TEXT("Stamped already. Pick another stop or open Passport."), TEXT("Stamped already. Pick another stop."));
    Result.ReplaceInline(TEXT("Correct answer. Confirm to add the stamp."), TEXT("Correct. Add your stamp."));
    Result.ReplaceInline(TEXT("Review complete. Confirm for the next stop."), TEXT("Review complete. Next stop."));
    Result.ReplaceInline(TEXT("No worries. Confirm to retry, or ask for a hint."), TEXT("Try again, or ask for Help."));
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
    Result.ReplaceInline(TEXT("Confirm or press Right/D for Next Stop."), TEXT("Next stop is ready."));
    Result.ReplaceInline(TEXT("Confirm for Next Stop."), TEXT("Next stop is ready."));
    Result.ReplaceInline(TEXT("Confirm to celebrate the completed route."), TEXT("Celebrate your completed route."));
    Result.ReplaceInline(TEXT("Stamp saved. You can review this card from Atlas later."), TEXT("Saved in Atlas for later."));
    Result.ReplaceInline(TEXT("Tap Right/D or Up/W for next stop. Tap Left/A or Down/S to go back."), TEXT("Pick another stop when you are ready."));

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
