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

    const float Margin = 48.0f;
    const float HeaderH = 116.0f;
    DrawRect(FLinearColor(0.02f, 0.025f, 0.08f, 0.72f), 0.0f, 0.0f, Canvas->SizeX, HeaderH);

    float Y = 24.0f;
    DrawLine(TEXT("Astro Adventure: Signal Sweep"), Margin, Y, FLinearColor(0.95f, 0.98f, 1.0f), 1.75f);
    DrawLine(GameMode->GetHudStatusLine(), Margin, Y, FLinearColor(0.50f, 0.86f, 1.0f), 1.0f);

    const float CardX = Margin;
    const float CardY = Canvas->SizeY - 350.0f;
    const float CardW = FMath::Min(Canvas->SizeX - Margin * 2.0f, 1180.0f);
    const float CardH = 286.0f;
    DrawRect(FLinearColor(0.04f, 0.055f, 0.12f, 0.86f), CardX, CardY, CardW, CardH);
    DrawRect(FLinearColor(0.18f, 0.42f, 0.72f, 0.90f), CardX, CardY, 10.0f, CardH);

    Y = CardY + 28.0f;
    DrawLine(GameMode->GetHudPrimaryLine(), CardX + 32.0f, Y, FLinearColor(1.0f, 0.96f, 0.78f), 1.45f);

    const TArray<FString> DetailLines = GameMode->GetHudDetailLines();
    for (const FString& Line : DetailLines)
    {
        DrawLine(Line, CardX + 32.0f, Y, FLinearColor(0.92f, 0.95f, 1.0f), 1.05f);
    }

    const float BadgeY = CardY + CardH - 54.0f;
    DrawBadge(TEXT("Arrows / D-pad: steer focus"), CardX + 32.0f, BadgeY, 250.0f, FLinearColor(0.10f, 0.20f, 0.36f, 0.95f), FLinearColor::White);
    DrawBadge(TEXT("Enter / A: scan"), CardX + 298.0f, BadgeY, 160.0f, FLinearColor(0.08f, 0.36f, 0.26f, 0.95f), FLinearColor::White);
    DrawBadge(TEXT("H / Y: hint"), CardX + 474.0f, BadgeY, 132.0f, FLinearColor(0.34f, 0.24f, 0.08f, 0.95f), FLinearColor::White);
    DrawBadge(TEXT("Q / Menu: quit"), CardX + 622.0f, BadgeY, 150.0f, FLinearColor(0.36f, 0.10f, 0.14f, 0.95f), FLinearColor::White);
}

void AAstroMissionHUD::DrawLine(const FString& Text, const float X, float& Y, const FLinearColor& Color, const float Scale)
{
    DrawText(Text, Color, X, Y, GEngine->GetSmallFont(), Scale, false);
    Y += 24.0f * Scale;
}

void AAstroMissionHUD::DrawBadge(const FString& Text, const float X, const float Y, const float W, const FLinearColor& Fill, const FLinearColor& TextColor)
{
    DrawRect(Fill, X, Y, W, 34.0f);
    DrawText(Text, TextColor, X + 12.0f, Y + 7.0f, GEngine->GetSmallFont(), 0.82f, false);
}
