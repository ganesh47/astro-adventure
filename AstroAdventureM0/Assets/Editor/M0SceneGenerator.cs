using System.IO;
using UnityEditor;
using UnityEditor.SceneManagement;
using UnityEngine;
using UnityEngine.InputSystem;

public static class M0SceneGenerator
{
    public static void Generate()
    {
        Directory.CreateDirectory("Assets/Scenes");
        Directory.CreateDirectory("Assets/Materials");
        Directory.CreateDirectory("Assets/Input");

        CreateInputActions();

        var scene = EditorSceneManager.NewScene(NewSceneSetup.EmptyScene, NewSceneMode.Single);

        var cameraObject = new GameObject("Main Camera");
        cameraObject.tag = "MainCamera";
        var camera = cameraObject.AddComponent<Camera>();
        camera.clearFlags = CameraClearFlags.SolidColor;
        camera.backgroundColor = new Color(0.02f, 0.03f, 0.08f);
        cameraObject.transform.position = new Vector3(0f, 0f, -10f);

        var lightObject = new GameObject("Directional Light");
        var light = lightObject.AddComponent<Light>();
        light.type = LightType.Directional;
        light.intensity = 1.2f;
        lightObject.transform.rotation = Quaternion.Euler(45f, -35f, 0f);

        Material shipMaterial = CreateMaterial("M0_Ship", new Color(0.35f, 0.9f, 1f));
        Material focusMaterial = CreateMaterial("M0_FocusDestination", new Color(1f, 0.83f, 0.25f));
        Material destinationMaterial = CreateMaterial("M0_Destination", new Color(0.45f, 0.6f, 1f));

        var ship = GameObject.CreatePrimitive(PrimitiveType.Cube);
        ship.name = "Explorer Ship";
        ship.transform.position = new Vector3(0f, -2.5f, 0f);
        ship.transform.localScale = new Vector3(0.55f, 0.35f, 0.35f);
        ship.GetComponent<Renderer>().sharedMaterial = shipMaterial;

        Transform[] destinations =
        {
            CreateDestination("Mercury", new Vector3(-3.5f, 1.4f, 0f), focusMaterial),
            CreateDestination("Mars", new Vector3(0f, 2f, 0f), destinationMaterial),
            CreateDestination("Europa", new Vector3(3.5f, 1.4f, 0f), destinationMaterial)
        };

        var title = CreateText("Title", "Astro Adventure M0", new Vector3(-4.6f, 4f, 0f), 0.45f);
        title.anchor = TextAnchor.MiddleLeft;

        var focus = CreateText("Focus Text", "Focus: Mercury", new Vector3(-4.6f, -3.7f, 0f), 0.28f);
        focus.anchor = TextAnchor.MiddleLeft;

        var status = CreateText("Status Text", "Use left stick or arrow keys to move. Bumpers/Q/E cycle. A/Enter scans.", new Vector3(-4.6f, -4.25f, 0f), 0.22f);
        status.anchor = TextAnchor.MiddleLeft;

        var controller = ship.AddComponent<M0ControllerTest>();
        SetSerializedObjectReference(controller, "ship", ship.transform);
        SetSerializedObjectReference(controller, "statusText", status);
        SetSerializedObjectReference(controller, "focusText", focus);
        SetSerializedArray(controller, "destinations", destinations);

        EditorSceneManager.SaveScene(scene, "Assets/Scenes/M0_DeploymentProof.unity");
        EditorBuildSettings.scenes = new[] { new EditorBuildSettingsScene("Assets/Scenes/M0_DeploymentProof.unity", true) };
        AssetDatabase.SaveAssets();
        AssetDatabase.Refresh();
    }

    private static Transform CreateDestination(string name, Vector3 position, Material material)
    {
        var destination = GameObject.CreatePrimitive(PrimitiveType.Sphere);
        destination.name = name;
        destination.transform.position = position;
        destination.GetComponent<Renderer>().sharedMaterial = material;

        var label = CreateText(name + " Label", name, position + new Vector3(-0.55f, -0.95f, 0f), 0.25f);
        label.anchor = TextAnchor.MiddleCenter;
        return destination.transform;
    }

    private static TextMesh CreateText(string name, string text, Vector3 position, float size)
    {
        var obj = new GameObject(name);
        obj.transform.position = position;
        var mesh = obj.AddComponent<TextMesh>();
        mesh.text = text;
        mesh.fontSize = 64;
        mesh.characterSize = size;
        mesh.color = Color.white;
        return mesh;
    }

    private static Material CreateMaterial(string name, Color color)
    {
        var material = new Material(Shader.Find("Standard"));
        material.name = name;
        material.color = color;
        AssetDatabase.CreateAsset(material, "Assets/Materials/" + name + ".mat");
        return material;
    }

    private static void CreateInputActions()
    {
        var asset = ScriptableObject.CreateInstance<InputActionAsset>();
        var map = asset.AddActionMap("M0");
        map.AddAction("Move", InputActionType.Value, "<Gamepad>/leftStick").AddCompositeBinding("2DVector")
            .With("Up", "<Keyboard>/w")
            .With("Down", "<Keyboard>/s")
            .With("Left", "<Keyboard>/a")
            .With("Right", "<Keyboard>/d");
        map.AddAction("Confirm", InputActionType.Button, "<Gamepad>/buttonSouth").AddBinding("<Keyboard>/enter");
        map.AddAction("Cancel", InputActionType.Button, "<Gamepad>/buttonEast").AddBinding("<Keyboard>/escape");
        map.AddAction("Scan", InputActionType.Button, "<Gamepad>/buttonWest").AddBinding("<Keyboard>/space");
        map.AddAction("CycleLeft", InputActionType.Button, "<Gamepad>/leftShoulder").AddBinding("<Keyboard>/q");
        map.AddAction("CycleRight", InputActionType.Button, "<Gamepad>/rightShoulder").AddBinding("<Keyboard>/e");

        File.WriteAllText("Assets/Input/AstroAdventureControls.inputactions", asset.ToJson());
    }

    private static void SetSerializedObjectReference(Object target, string propertyName, Object value)
    {
        var serialized = new SerializedObject(target);
        serialized.FindProperty(propertyName).objectReferenceValue = value;
        serialized.ApplyModifiedPropertiesWithoutUndo();
    }

    private static void SetSerializedArray(Object target, string propertyName, Transform[] values)
    {
        var serialized = new SerializedObject(target);
        var property = serialized.FindProperty(propertyName);
        property.arraySize = values.Length;
        for (int i = 0; i < values.Length; i++)
        {
            property.GetArrayElementAtIndex(i).objectReferenceValue = values[i];
        }
        serialized.ApplyModifiedPropertiesWithoutUndo();
    }
}
