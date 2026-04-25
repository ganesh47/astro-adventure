using UnrealBuildTool;
using System.Collections.Generic;

public class AstroAdventureUETarget : TargetRules
{
    public AstroAdventureUETarget(TargetInfo Target) : base(Target)
    {
        Type = TargetType.Game;
        DefaultBuildSettings = BuildSettingsVersion.Latest;
        IncludeOrderVersion = EngineIncludeOrderVersion.Latest;
        ExtraModuleNames.Add("AstroAdventureUE");
    }
}
