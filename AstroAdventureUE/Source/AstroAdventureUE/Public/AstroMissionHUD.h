#pragma once

#include "CoreMinimal.h"
#include "GameFramework/HUD.h"
#include "AstroLearningTypes.h"
#include "AstroMissionHUD.generated.h"

class UTexture2D;

UCLASS()
class ASTROADVENTUREUE_API AAstroMissionHUD : public AHUD
{
    GENERATED_BODY()

public:
    virtual void DrawHUD() override;

private:
    UPROPERTY(Transient)
    UTexture2D* PassportCardTexture = nullptr;

    UPROPERTY(Transient)
    UTexture2D* ActionChipTexture = nullptr;

    UPROPERTY(Transient)
    UTexture2D* StampSunTexture = nullptr;

    UPROPERTY(Transient)
    UTexture2D* StampMercuryTexture = nullptr;

    UPROPERTY(Transient)
    UTexture2D* StampGenericTexture = nullptr;

    UPROPERTY(Transient)
    UTexture2D* SunSurfaceTexture = nullptr;

    UPROPERTY(Transient)
    UTexture2D* MercurySurfaceTexture = nullptr;

    UPROPERTY(Transient)
    UTexture2D* StarfieldTexture = nullptr;

    void EnsureOwnedTexturesLoaded();
    UTexture2D* LoadOwnedTexture(const FString& RelativePath) const;
    void DrawOwnedTexture(UTexture2D* Texture, float X, float Y, float W, float H, const FLinearColor& Tint);
    void DrawLine(const FString& Text, float X, float& Y, const FLinearColor& Color, float Scale = 1.0f);
    void DrawBadge(const FString& Text, float X, float Y, float W, const FLinearColor& Fill, const FLinearColor& TextColor, float Scale = 0.82f);
    void DrawMiniLearningIcon(const FString& Icon, float CenterX, float CenterY, float Size);
    void DrawLearningBadge(const FString& Icon, const FString& Label, const FString& Detail, float X, float Y, float W, const FLinearColor& Fill);
    void DrawLearningBadgeRow(EAstroMissionScreen Screen, float X, float Y, float W);
    void DrawFirstRouteCue(float X, float Y, float W, bool bUnlocked);
    void DrawPassportFrame(float X, float Y, float W, float H);
    void DrawStampAwardHero(float X, float Y, float W, float H);
    void DrawStampStrip(const FString& StatusLine, float X, float Y, float W);
    void DrawStampSlot(float X, float Y, float Size, bool bFilled, int32 Index);
    bool DrawDeepDiveSectionLine(const FString& Text, float X, float& Y, float W);
    void DrawDeepDiveWorldCue(float X, float Y, float W, float H);
    void DrawAtlasRouteMap(float X, float Y, float W);
    void DrawActionBar(EAstroMissionScreen Screen, float X, float Y, float W, bool bHasQuizRows);
    void DrawHomeRouteVignette(float X, float Y, float W, float H);
    void DrawSoftEllipse(float CenterX, float CenterY, float RadiusX, float RadiusY, const FLinearColor& Color, int32 Bands = 28);
    void DrawScanImpactBurst(float CenterX, float CenterY, float Radius);
    void DrawQuizRow(const FString& Text, float X, float Y, float W, bool bFocused);
    void DrawHomeRow(const FString& Text, float X, float Y, float W, bool bFocused);
    void DrawMenuRow(const FString& Text, float X, float Y, float W, bool bFocused);
    void DrawPassportRow(const FString& Text, float X, float Y, float W);
    void DrawFeedbackBanner(const FString& Text, const FLinearColor& Fill, float Y);
    void DrawFeedbackToast(const FString& Text, const FLinearColor& Fill, float X, float Y, float W);
    void AddActionIfMissing(TArray<FString>& Actions, const FString& Action) const;
    void GetStampProgress(const FString& StatusLine, int32& OutStamped, int32& OutTotal) const;
    bool IsMenuScreen(EAstroMissionScreen Screen) const;
    bool IsHomeChoiceLine(const FString& Text) const;
    bool IsMenuChoiceLine(const FString& Text) const;
    bool LooksLikeRawTechnicalLine(const FString& Text) const;
    bool IsQuizChoiceLine(const FString& Text) const;
    bool IsPassportRouteLine(const FString& Text) const;
    FString FriendlyPrimaryLine(const FString& Text) const;
    FString FriendlyStatusLine(const FString& Text) const;
    FString FriendlyDetailLine(const FString& Text) const;
};
