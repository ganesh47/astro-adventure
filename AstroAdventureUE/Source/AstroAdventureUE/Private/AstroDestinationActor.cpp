#include "AstroDestinationActor.h"

#include "Components/StaticMeshComponent.h"
#include "Components/TextRenderComponent.h"
#include "Materials/MaterialInstanceDynamic.h"
#include "UObject/ConstructorHelpers.h"

AAstroDestinationActor::AAstroDestinationActor()
{
    PrimaryActorTick.bCanEverTick = false;

    Root = CreateDefaultSubobject<USceneComponent>(TEXT("Root"));
    SetRootComponent(Root);

    BodyMesh = CreateDefaultSubobject<UStaticMeshComponent>(TEXT("BodyMesh"));
    BodyMesh->SetupAttachment(Root);

    static ConstructorHelpers::FObjectFinder<UStaticMesh> SphereMesh(TEXT("/Engine/BasicShapes/Sphere.Sphere"));
    if (SphereMesh.Succeeded())
    {
        BodyMesh->SetStaticMesh(SphereMesh.Object);
    }

    Label = CreateDefaultSubobject<UTextRenderComponent>(TEXT("Label"));
    Label->SetupAttachment(Root);
    Label->SetHorizontalAlignment(EHTA_Center);
    Label->SetTextRenderColor(FColor::White);
    Label->SetWorldSize(52.0f);
    Label->SetRelativeLocation(FVector(0.0f, 0.0f, 110.0f));
}

void AAstroDestinationActor::Configure(const FAstroDestinationLesson& Lesson, const FLinearColor& Color)
{
    DestinationId = Lesson.DestinationId;
    DisplayName = Lesson.DisplayName;
    BaseColor = Color;
#if WITH_EDITOR
    SetActorLabel(DisplayName.ToString());
#endif
    Label->SetText(DisplayName);

    if (UMaterialInstanceDynamic* Material = BodyMesh->CreateAndSetMaterialInstanceDynamic(0))
    {
        Material->SetVectorParameterValue(TEXT("Color"), BaseColor);
    }
}

void AAstroDestinationActor::SetFocused(const bool bFocused)
{
    const float Scale = bFocused ? 1.28f : 1.0f;
    SetActorScale3D(FVector(Scale));
    BodyMesh->SetRenderCustomDepth(bFocused);
    Label->SetTextRenderColor(bFocused ? FColor::Yellow : FColor::White);
}

void AAstroDestinationActor::SetDiscovered(const bool bDiscovered)
{
    bIsDiscovered = bDiscovered;
    const FString Prefix = bIsDiscovered ? TEXT("[Discovered] ") : TEXT("");
    Label->SetText(FText::FromString(Prefix + DisplayName.ToString()));
}
