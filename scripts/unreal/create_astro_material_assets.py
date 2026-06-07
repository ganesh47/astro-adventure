"""Create Astro Adventure-owned Unreal texture, material, and material-instance assets.

Run inside Unreal Editor/Cmd with:
UnrealEditor-Cmd.exe AstroAdventureUE.uproject -unattended -nop4 -ExecutePythonScript=scripts/unreal/create_astro_material_assets.py
"""

import unreal


TEXTURE_ROOT = "/Game/Art/AstroAdventureOwned/Textures"
MATERIAL_ROOT = "/Game/Art/AstroAdventureOwned/Materials"
INSTANCE_ROOT = "/Game/Art/AstroAdventureOwned/MaterialInstances"
SCENE_ROOT = "/Game/Art/AstroAdventureOwned/Scene"


TEXTURES = {
    "T_Sun_Surface_Stylized": ("Planets/T_Sun_Surface_Stylized.png", "Planets"),
    "T_Sun_Disk_ChildReadable": ("Planets/T_Sun_Disk_ChildReadable.png", "Planets"),
    "T_Sun_Corona_Soft": ("Planets/T_Sun_Corona_Soft.png", "Planets"),
    "T_Mercury_Craters_Stylized": ("Planets/T_Mercury_Craters_Stylized.png", "Planets"),
    "T_Venus_CloudBands_Stylized": ("Planets/T_Venus_CloudBands_Stylized.png", "Planets"),
    "T_Europa_IceCracks_Stylized": ("Planets/T_Europa_IceCracks_Stylized.png", "Planets"),
    "T_Saturn_RingBands_Stylized": ("Planets/T_Saturn_RingBands_Stylized.png", "Planets"),
    "T_Scanner_Beam_Core": ("FX/T_Scanner_Beam_Core.png", "FX"),
    "T_Scanner_Pulse_Ring": ("FX/T_Scanner_Pulse_Ring.png", "FX"),
    "T_Focus_Ring_Gold": ("FX/T_Focus_Ring_Gold.png", "FX"),
    "T_Starfield_SoftDepth": ("FX/T_Starfield_SoftDepth.png", "FX"),
}


MATERIALS = {
    "M_Planet_Textured": {
        "blend": unreal.BlendMode.BLEND_OPAQUE,
        "texture_param": "BodyTexture",
        "emissive": 0.03,
        "roughness": 0.84,
    },
    "M_Sun_Surface": {
        "blend": unreal.BlendMode.BLEND_OPAQUE,
        "texture_param": "SunSurfaceTexture",
        "emissive": 1.0,
        "roughness": 0.62,
        "unlit": True,
    },
    "M_Star_Textured_Unlit": {
        "blend": unreal.BlendMode.BLEND_OPAQUE,
        "texture_param": "BodyTexture",
        "emissive": 0.55,
        "roughness": 1.0,
        "unlit": True,
    },
    "M_SunTeaching_Unlit": {
        "blend": unreal.BlendMode.BLEND_OPAQUE,
        "texture_param": "SunSurfaceTexture",
        "emissive": 1.15,
        "roughness": 1.0,
        "unlit": True,
    },
    "M_SunTeaching_Solid": {
        "blend": unreal.BlendMode.BLEND_OPAQUE,
        "texture_param": None,
        "emissive": 1.35,
        "roughness": 1.0,
        "unlit": True,
        "default_tint": (1.0, 0.58, 0.1, 1.0),
    },
    "M_Soft_Corona": {
        "blend": unreal.BlendMode.BLEND_TRANSLUCENT,
        "texture_param": "CoronaTexture",
        "emissive": 0.28,
        "roughness": 1.0,
        "opacity": 0.55,
    },
    "M_Focus_Ring": {
        "blend": unreal.BlendMode.BLEND_TRANSLUCENT,
        "texture_param": "RingTexture",
        "emissive": 0.18,
        "roughness": 1.0,
        "opacity": 0.48,
    },
    "M_Scanner_Beam": {
        "blend": unreal.BlendMode.BLEND_TRANSLUCENT,
        "texture_param": "BeamTexture",
        "emissive": 0.22,
        "roughness": 1.0,
        "opacity": 0.62,
    },
    "M_Sky_Backdrop": {
        "blend": unreal.BlendMode.BLEND_OPAQUE,
        "texture_param": "SkyTexture",
        "emissive": 0.08,
        "roughness": 1.0,
    },
    "M_Alpha_Texture_FX": {
        "blend": unreal.BlendMode.BLEND_TRANSLUCENT,
        "texture_param": "AlphaTexture",
        "emissive": 0.08,
        "roughness": 1.0,
        "opacity": 0.5,
        "use_texture_alpha": True,
    },
}


INSTANCES = {
    # Use a fresh unlit star parent so the Sun keeps its warm surface detail
    # without the harsh black shadow cap seen on lit planet fallbacks.
    "MI_Sun_Surface": ("M_Star_Textured_Unlit", "BodyTexture", "T_Sun_Surface_Stylized", (1.0, 0.58, 0.12, 1.0), 0.82),
    "MI_Sun_Disk": ("M_Alpha_Texture_FX", "AlphaTexture", "T_Sun_Disk_ChildReadable", (1.0, 0.86, 0.42, 1.0), 0.32),
    "MI_SunTeaching_Body": ("M_SunTeaching_Unlit", "SunSurfaceTexture", "T_Sun_Surface_Stylized", (1.0, 0.66, 0.18, 1.0), 1.45),
    "MI_Sun_Corona": ("M_Soft_Corona", "CoronaTexture", "T_Sun_Corona_Soft", (1.0, 0.64, 0.20, 0.30), 0.10),
    "MI_Focus_Ring": ("M_Alpha_Texture_FX", "AlphaTexture", "T_Focus_Ring_Gold", (1.0, 0.66, 0.18, 0.24), 0.025),
    "MI_Scanner_Beam": ("M_Alpha_Texture_FX", "AlphaTexture", "T_Scanner_Beam_Core", (0.22, 1.0, 0.82, 0.48), 0.08),
    "MI_Sky_Backdrop": ("M_Sky_Backdrop", "SkyTexture", "T_Starfield_SoftDepth", (0.72, 0.78, 1.0, 1.0), 0.42),
    "MI_Mercury_Surface": ("M_Planet_Textured", "BodyTexture", "T_Mercury_Craters_Stylized", (0.94, 0.88, 0.76, 1.0), 0.045),
    "MI_Venus_Surface": ("M_Planet_Textured", "BodyTexture", "T_Venus_CloudBands_Stylized", (1.0, 0.72, 0.34, 1.0), 0.03),
    "MI_Europa_Surface": ("M_Planet_Textured", "BodyTexture", "T_Europa_IceCracks_Stylized", (0.72, 0.92, 1.0, 1.0), 0.03),
    "MI_Saturn_Surface": ("M_Planet_Textured", "BodyTexture", "T_Saturn_RingBands_Stylized", (1.0, 0.86, 0.48, 1.0), 0.03),
    "MI_Uranus_Surface": ("M_Planet_Textured", "BodyTexture", "T_Europa_IceCracks_Stylized", (0.52, 0.95, 1.0, 1.0), 0.03),
    "MI_Neptune_Surface": ("M_Planet_Textured", "BodyTexture", "T_Europa_IceCracks_Stylized", (0.2, 0.38, 1.0, 1.0), 0.04),
}


def ensure_directory(path):
    if not unreal.EditorAssetLibrary.does_directory_exist(path):
        unreal.EditorAssetLibrary.make_directory(path)


def asset_path(root, name):
    return f"{root}/{name}.{name}"


def create_or_load_asset(name, package_path, asset_class, factory):
    path = asset_path(package_path, name)
    asset = unreal.EditorAssetLibrary.load_asset(path)
    if asset:
        return asset
    return unreal.AssetToolsHelpers.get_asset_tools().create_asset(name, package_path, asset_class, factory)


def import_textures():
    project_content = unreal.Paths.project_content_dir()
    imported = {}
    asset_tools = unreal.AssetToolsHelpers.get_asset_tools()
    for name, (relative_file, subdir) in TEXTURES.items():
        destination = f"{TEXTURE_ROOT}/{subdir}"
        ensure_directory(destination)
        import_data = unreal.AutomatedAssetImportData()
        import_data.destination_path = destination
        import_data.filenames = [unreal.Paths.convert_relative_path_to_full(f"{project_content}Art/AstroAdventureOwned/Textures/{relative_file}")]
        import_data.replace_existing = True
        results = asset_tools.import_assets_automated(import_data)
        texture = results[0] if results else unreal.EditorAssetLibrary.load_asset(asset_path(destination, name))
        if texture:
            imported[name] = texture
            texture.set_editor_property("sRGB", True)
            texture.set_editor_property("compression_settings", unreal.TextureCompressionSettings.TC_DEFAULT)
            texture.set_editor_property("mip_gen_settings", unreal.TextureMipGenSettings.TMGS_FROM_TEXTURE_GROUP)
            unreal.EditorAssetLibrary.save_loaded_asset(texture)
        else:
            unreal.log_warning(f"Could not import Astro Adventure texture {name} from {relative_file}")
    return imported


def clear_material(material):
    try:
        unreal.MaterialEditingLibrary.delete_all_material_expressions(material)
    except Exception:
        # Older editor scripting builds may not expose this; assets are created fresh in normal use.
        pass


def create_texture_material(name, config):
    ensure_directory(MATERIAL_ROOT)
    existing = unreal.EditorAssetLibrary.load_asset(asset_path(MATERIAL_ROOT, name))
    if existing:
        existing.set_editor_property("blend_mode", config["blend"])
        if config["blend"] == unreal.BlendMode.BLEND_TRANSLUCENT or name == "M_Sky_Backdrop":
            existing.set_editor_property("two_sided", True)
        try:
            existing.set_editor_property(
                "shading_model",
                unreal.MaterialShadingModel.MSM_UNLIT if config.get("unlit", False) else unreal.MaterialShadingModel.MSM_DEFAULT_LIT,
            )
        except Exception:
            unreal.log_warning(f"Could not update shading model for {name}; keeping existing graph.")
        unreal.EditorAssetLibrary.save_loaded_asset(existing)
        return existing

    material = create_or_load_asset(name, MATERIAL_ROOT, unreal.Material, unreal.MaterialFactoryNew())
    material.set_editor_property("blend_mode", config["blend"])
    if config["blend"] == unreal.BlendMode.BLEND_TRANSLUCENT or name == "M_Sky_Backdrop":
        material.set_editor_property("two_sided", True)
    try:
        material.set_editor_property(
            "shading_model",
            unreal.MaterialShadingModel.MSM_UNLIT if config.get("unlit", False) else unreal.MaterialShadingModel.MSM_DEFAULT_LIT,
        )
    except Exception:
        unreal.log_warning(f"Could not update shading model for {name}; continuing with graph rebuild.")
    clear_material(material)

    tint = unreal.MaterialEditingLibrary.create_material_expression(
        material, unreal.MaterialExpressionVectorParameter, -520, 80)
    tint.set_editor_property("parameter_name", "BodyTint")
    tint.set_editor_property("default_value", unreal.LinearColor(*config.get("default_tint", (1.0, 1.0, 1.0, 1.0))))

    if config.get("texture_param"):
        tex = unreal.MaterialEditingLibrary.create_material_expression(
            material, unreal.MaterialExpressionTextureSampleParameter2D, -520, -120)
        tex.set_editor_property("parameter_name", config["texture_param"])

        color_source = unreal.MaterialEditingLibrary.create_material_expression(
            material, unreal.MaterialExpressionMultiply, -260, -60)
        unreal.MaterialEditingLibrary.connect_material_expressions(tex, "RGB", color_source, "A")
        unreal.MaterialEditingLibrary.connect_material_expressions(tint, "", color_source, "B")
    else:
        tex = None
        color_source = tint

    unreal.MaterialEditingLibrary.connect_material_property(color_source, "", unreal.MaterialProperty.MP_BASE_COLOR)

    emissive = unreal.MaterialEditingLibrary.create_material_expression(
        material, unreal.MaterialExpressionScalarParameter, -260, 120)
    emissive.set_editor_property("parameter_name", "EmissiveStrength")
    emissive.set_editor_property("default_value", config["emissive"])
    emissive_multiply = unreal.MaterialEditingLibrary.create_material_expression(
        material, unreal.MaterialExpressionMultiply, -40, 40)
    unreal.MaterialEditingLibrary.connect_material_expressions(color_source, "", emissive_multiply, "A")
    unreal.MaterialEditingLibrary.connect_material_expressions(emissive, "", emissive_multiply, "B")
    unreal.MaterialEditingLibrary.connect_material_property(emissive_multiply, "", unreal.MaterialProperty.MP_EMISSIVE_COLOR)

    roughness = unreal.MaterialEditingLibrary.create_material_expression(
        material, unreal.MaterialExpressionScalarParameter, -260, 260)
    roughness.set_editor_property("parameter_name", "Roughness")
    roughness.set_editor_property("default_value", config["roughness"])
    unreal.MaterialEditingLibrary.connect_material_property(roughness, "", unreal.MaterialProperty.MP_ROUGHNESS)

    if config["blend"] == unreal.BlendMode.BLEND_TRANSLUCENT:
        opacity = unreal.MaterialEditingLibrary.create_material_expression(
            material, unreal.MaterialExpressionScalarParameter, -260, 410)
        opacity.set_editor_property("parameter_name", "Opacity")
        opacity.set_editor_property("default_value", config.get("opacity", 0.5))
        if config.get("use_texture_alpha", False) and tex:
            alpha_multiply = unreal.MaterialEditingLibrary.create_material_expression(
                material, unreal.MaterialExpressionMultiply, -40, 340)
            unreal.MaterialEditingLibrary.connect_material_expressions(tex, "A", alpha_multiply, "A")
            unreal.MaterialEditingLibrary.connect_material_expressions(opacity, "", alpha_multiply, "B")
            unreal.MaterialEditingLibrary.connect_material_property(alpha_multiply, "", unreal.MaterialProperty.MP_OPACITY)
        else:
            unreal.MaterialEditingLibrary.connect_material_property(opacity, "", unreal.MaterialProperty.MP_OPACITY)

    unreal.MaterialEditingLibrary.recompile_material(material)
    unreal.EditorAssetLibrary.save_loaded_asset(material)
    return material


def create_materials():
    return {name: create_texture_material(name, config) for name, config in MATERIALS.items()}


def create_instances(materials, textures):
    ensure_directory(INSTANCE_ROOT)
    instances = {}
    factory = unreal.MaterialInstanceConstantFactoryNew()
    for name, (parent_name, texture_param, texture_name, tint, emissive) in INSTANCES.items():
        instance = create_or_load_asset(name, INSTANCE_ROOT, unreal.MaterialInstanceConstant, factory)
        instance.set_editor_property("parent", materials[parent_name])
        unreal.MaterialEditingLibrary.set_material_instance_texture_parameter_value(instance, texture_param, textures[texture_name])
        unreal.MaterialEditingLibrary.set_material_instance_vector_parameter_value(instance, "BodyTint", unreal.LinearColor(*tint))
        unreal.MaterialEditingLibrary.set_material_instance_scalar_parameter_value(instance, "EmissiveStrength", emissive)
        unreal.EditorAssetLibrary.save_loaded_asset(instance)
        instances[name] = instance
    return instances


def create_scene_assets():
    ensure_directory(SCENE_ROOT)
    backdrop_path = asset_path(SCENE_ROOT, "SM_Backdrop_Quad")
    existing = unreal.EditorAssetLibrary.load_asset(backdrop_path)
    if existing:
        unreal.EditorAssetLibrary.save_loaded_asset(existing)
        return existing

    source_plane = "/Engine/BasicShapes/Plane.Plane"
    duplicated = unreal.EditorAssetLibrary.duplicate_asset(source_plane, backdrop_path)
    if duplicated:
        unreal.EditorAssetLibrary.save_loaded_asset(duplicated)
    return duplicated


def main():
    ensure_directory(TEXTURE_ROOT)
    ensure_directory(MATERIAL_ROOT)
    ensure_directory(INSTANCE_ROOT)
    textures = import_textures()
    materials = create_materials()
    create_instances(materials, textures)
    create_scene_assets()
    unreal.EditorAssetLibrary.save_directory("/Game/Art/AstroAdventureOwned", only_if_is_dirty=False, recursive=True)
    unreal.log("Astro Adventure material asset authoring complete.")


if __name__ == "__main__":
    main()
