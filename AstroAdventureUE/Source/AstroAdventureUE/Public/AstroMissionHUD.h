#pragma once

#include "CoreMinimal.h"
#include "GameFramework/HUD.h"
#include "AstroMissionHUD.generated.h"

UCLASS()
class ASTROADVENTUREUE_API AAstroMissionHUD : public AHUD
{
    GENERATED_BODY()

public:
    virtual void DrawHUD() override;

private:
    void DrawLine(const FString& Text, float X, float& Y, const FLinearColor& Color, float Scale = 1.0f);
    void DrawBadge(const FString& Text, float X, float Y, float W, const FLinearColor& Fill, const FLinearColor& TextColor, float Scale = 0.82f);
    void DrawQuizRow(const FString& Text, float X, float Y, float W, bool bFocused);
    void DrawFeedbackBanner(const FString& Text, const FLinearColor& Fill, float Y);
    bool IsQuizChoiceLine(const FString& Text) const;
    FString FriendlyDetailLine(const FString& Text) const;
};
