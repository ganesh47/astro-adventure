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
    DrawRect(FLinearColor(0.02f, 0.025f, 0.10f, 0.76f), 0.0f, 0.0f, Canvas->SizeX, HeaderH);
    DrawRect(FLinearColor(0.12f, 0.28f, 0.58f, 0.35f), 0.0f, HeaderH - 8.0f, Canvas->SizeX, 8.0f);

    float Y = 24.0f;
    DrawLine(TEXT("Astro Adventure: Solar Passport"), Margin, Y, FLinearColor(0.95f, 0.98f, 1.0f), 1.75f);
    DrawLine(GameMode->GetHudStatusLine(), Margin, Y, FLinearColor(0.50f, 0.86f, 1.0f), 1.0f);

    const float CardX = Margin;
    const float CardY = Canvas->SizeY - 390.0f;
    const float CardW = FMath::Min(Canvas->SizeX - Margin * 2.0f, 1280.0f);
    const float CardH = 326.0f;
    DrawRect(FLinearColor(0.04f, 0.055f, 0.12f, 0.86f), CardX, CardY, CardW, CardH);
    DrawRect(FLinearColor(0.18f, 0.42f, 0.72f, 0.90f), CardX, CardY, 10.0f, CardH);
    if (GameMode->IsScanEffectActive())
    {
        DrawRect(FLinearColor(0.1f, 0.8f, 1.0f, 0.12f), 0.0f, 0.0f, Canvas->SizeX, Canvas->SizeY);
        float ScanY = Canvas->SizeY * 0.35f;
        DrawLine(TEXT("SCAN COMPLETE"), Canvas->SizeX * 0.40f, ScanY, FLinearColor(0.56f, 0.94f, 1.0f), 2.0f);
    }

    Y = CardY + 28.0f;
    DrawLine(GameMode->GetHudPrimaryLine(), CardX + 32.0f, Y, FLinearColor(1.0f, 0.96f, 0.78f), 1.45f);

    const TArray<FString> DetailLines = GameMode->GetHudDetailLines();
    for (const FString& Line : DetailLines)
    {
        DrawLine(Line, CardX + 32.0f, Y, FLinearColor(0.92f, 0.95f, 1.0f), 1.05f);
    }

    const float BadgeY = CardY + CardH - 54.0f;
    DrawBadge(TEXT("Arrows / D-pad: travel"), CardX + 32.0f, BadgeY, 218.0f, FLinearColor(0.10f, 0.20f, 0.36f, 0.95f), FLinearColor::White);
    DrawBadge(TEXT("Enter / A: confirm"), CardX + 266.0f, BadgeY, 172.0f, FLinearColor(0.08f, 0.36f, 0.26f, 0.95f), FLinearColor::White);
    DrawBadge(TEXT("M / LT: more"), CardX + 454.0f, BadgeY, 126.0f, FLinearColor(0.24f, 0.16f, 0.38f, 0.95f), FLinearColor::White);
    DrawBadge(TEXT("P / RT: passport"), CardX + 596.0f, BadgeY, 158.0f, FLinearColor(0.18f, 0.30f, 0.50f, 0.95f), FLinearColor::White);
    DrawBadge(TEXT("Esc / Menu: pause"), CardX + 770.0f, BadgeY, 170.0f, FLinearColor(0.36f, 0.10f, 0.14f, 0.95f), FLinearColor::White);
}

void AAstroMissionHUD::DrawLine(const FString& Text, const float X, float& Y, const FLinearColor& Color, const float Scale)
{
    DrawText(Text, Color, X, Y, GEngine->GetSmallFont(), Scale, false);
    Y += 26.0f * Scale;
}

void AAstroMissionHUD::DrawBadge(const FString& Text, const float X, const float Y, const float W, const FLinearColor& Fill, const FLinearColor& TextColor)
{
    DrawRect(Fill, X, Y, W, 34.0f);
    DrawText(Text, TextColor, X + 12.0f, Y + 7.0f, GEngine->GetSmallFont(), 0.82f, false);
}
