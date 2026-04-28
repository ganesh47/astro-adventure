#pragma once

#include "CoreMinimal.h"
#include "GameFramework/HUD.h"
#include "AstroLearningTypes.h"
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
    void DrawPassportFrame(float X, float Y, float W, float H);
    void DrawStampStrip(const FString& StatusLine, float X, float Y, float W);
    void DrawStampSlot(float X, float Y, float Size, bool bFilled, int32 Index);
    void DrawActionBar(EAstroMissionScreen Screen, float X, float Y, float W, bool bHasQuizRows);
    void DrawQuizRow(const FString& Text, float X, float Y, float W, bool bFocused);
    void DrawMenuRow(const FString& Text, float X, float Y, float W, bool bFocused);
    void DrawPassportRow(const FString& Text, float X, float Y, float W);
    void DrawFeedbackBanner(const FString& Text, const FLinearColor& Fill, float Y);
    void AddActionIfMissing(TArray<FString>& Actions, const FString& Action) const;
    void GetStampProgress(const FString& StatusLine, int32& OutStamped, int32& OutTotal) const;
    bool IsMenuScreen(EAstroMissionScreen Screen) const;
    bool IsMenuChoiceLine(const FString& Text) const;
    bool LooksLikeRawTechnicalLine(const FString& Text) const;
    bool IsQuizChoiceLine(const FString& Text) const;
    bool IsPassportRouteLine(const FString& Text) const;
    FString FriendlyPrimaryLine(const FString& Text) const;
    FString FriendlyStatusLine(const FString& Text) const;
    FString FriendlyDetailLine(const FString& Text) const;
};
