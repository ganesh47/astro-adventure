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
    BodyMesh->SetMobility(EComponentMobility::Movable);

    static ConstructorHelpers::FObjectFinder<UStaticMesh> SphereMesh(TEXT("/Engine/BasicShapes/Sphere.Sphere"));
    if (SphereMesh.Succeeded())
    {
        BodyMesh->SetStaticMesh(SphereMesh.Object);
    }

    FocusHalo = CreateDefaultSubobject<UStaticMeshComponent>(TEXT("FocusHalo"));
    FocusHalo->SetupAttachment(Root);
    FocusHalo->SetMobility(EComponentMobility::Movable);
    FocusHalo->SetVisibility(false);
    FocusHalo->SetCollisionEnabled(ECollisionEnabled::NoCollision);
    if (SphereMesh.Succeeded())
    {
        FocusHalo->SetStaticMesh(SphereMesh.Object);
    }

    Label = CreateDefaultSubobject<UTextRenderComponent>(TEXT("Label"));
    Label->SetupAttachment(Root);
    Label->SetHorizontalAlignment(EHTA_Center);
    Label->SetTextRenderColor(FColor::White);
    Label->SetWorldSize(68.0f);
    Label->SetRelativeLocation(FVector(0.0f, 0.0f, 145.0f));
    Label->SetRelativeRotation(FRotator(0.0f, 180.0f, 0.0f));
}

void AAstroDestinationActor::Configure(const FAstroDestinationLesson& Lesson, const FLinearColor& Color, const float VisualScale)
{
    DestinationId = Lesson.DestinationId;
    DisplayName = Lesson.DisplayName;
    BaseColor = Color;
    BaseVisualScale = VisualScale;
#if WITH_EDITOR
    SetActorLabel(DisplayName.ToString());
#endif
    Label->SetText(DisplayName);
    Label->SetRelativeLocation(FVector(0.0f, 0.0f, 115.0f + 45.0f * BaseVisualScale));

    ApplyColor(BodyMesh, BaseColor, 0.22f);
    ApplyColor(FocusHalo, FLinearColor(1.0f, 0.88f, 0.18f, 0.35f), 1.2f);
    SetActorScale3D(FVector(BaseVisualScale));
}

void AAstroDestinationActor::ApplyColor(UStaticMeshComponent* Mesh, const FLinearColor& Color, const float EmissiveStrength)
{
    if (Mesh)
    {
        if (UMaterialInstanceDynamic* Material = Mesh->CreateAndSetMaterialInstanceDynamic(0))
        {
            Material->SetVectorParameterValue(TEXT("Color"), Color);
            Material->SetVectorParameterValue(TEXT("BaseColor"), Color);
            Material->SetVectorParameterValue(TEXT("EmissiveColor"), Color * EmissiveStrength);
        }
    }
}

void AAstroDestinationActor::SetFocused(const bool bFocused)
{
    const float Scale = bFocused ? BaseVisualScale * 1.18f : BaseVisualScale;
    SetActorScale3D(FVector(Scale));
    BodyMesh->SetRenderCustomDepth(bFocused);
    FocusHalo->SetVisibility(bFocused);
    FocusHalo->SetRelativeScale3D(FVector(1.28f, 1.28f, 0.08f));
    Label->SetTextRenderColor(bFocused ? FColor(255, 236, 84) : FColor(190, 220, 255));
}

void AAstroDestinationActor::SetDiscovered(const bool bDiscovered)
{
    bIsDiscovered = bDiscovered;
    const FString Prefix = bIsDiscovered ? TEXT("* ") : TEXT("");
    Label->SetText(FText::FromString(Prefix + DisplayName.ToString()));
}
