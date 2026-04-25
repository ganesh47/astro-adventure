#include "AstroMissionHUD.h"

#include "AstroAdventureGameModeBase.h"
#include "Engine/Canvas.h"
#include "Engine/Engine.h"
#include "Engine/World.h"

void AAstroMissionHUD::DrawHUD()
{
    Super::DrawHUD();

    AAstroAdventureGameModeBase* GameMode = GetWorld()->GetAuthGameMode<AAstroAdventureGameModeBase>();
    if (!Canvas || !GameMode)
    {
        return;
    }

    DrawRect(FLinearColor(0.01f, 0.01f, 0.03f, 0.82f), 24.0f, 24.0f, Canvas->SizeX - 48.0f, 300.0f);

    float Y = 44.0f;
    DrawLine(TEXT("Astro Adventure - Signal Sweep"), 48.0f, Y, FLinearColor(0.92f, 0.96f, 1.0f), 1.45f);
    DrawLine(GameMode->GetHudStatusLine(), 48.0f, Y, FLinearColor(0.70f, 0.90f, 1.0f), 1.05f);
    DrawLine(GameMode->GetHudPrimaryLine(), 48.0f, Y, FLinearColor::White, 1.0f);

    const TArray<FString> DetailLines = GameMode->GetHudDetailLines();
    for (const FString& Line : DetailLines)
    {
        DrawLine(Line, 48.0f, Y, FLinearColor(0.88f, 0.88f, 0.78f), 0.9f);
    }

    Y += 8.0f;
    DrawLine(TEXT("Controls: Arrow/D-pad move focus or answers | Enter/A scan/confirm | H/Y hint | Esc/B back | 1-3 answer"), 48.0f, Y, FLinearColor(0.70f, 0.78f, 0.85f), 0.78f);
}

void AAstroMissionHUD::DrawLine(const FString& Text, const float X, float& Y, const FLinearColor& Color, const float Scale)
{
    DrawText(Text, Color, X, Y, GEngine->GetSmallFont(), Scale, false);
    Y += 24.0f * Scale;
}
