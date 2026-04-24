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
        camera.orthographic = true;
        camera.orthographicSize = 5.2f;
        camera.clearFlags = CameraClearFlags.SolidColor;
        camera.backgroundColor = new Color(0.005f, 0.01f, 0.035f);
        cameraObject.transform.position = new Vector3(0f, 0f, -10f);

        var lightObject = new GameObject("Directional Light");
        var light = lightObject.AddComponent<Light>();
        light.type = LightType.Directional;
        light.intensity = 1.05f;
        lightObject.transform.rotation = Quaternion.Euler(45f, -35f, 0f);

        Material shipMaterial = CreateMaterial("M0_Ship", new Color(0.35f, 0.9f, 1f));
        Material focusMaterial = CreateMaterial("M0_FocusDestination", new Color(1f, 0.83f, 0.25f));
        Material destinationMaterial = CreateMaterial("M0_Destination", new Color(0.45f, 0.6f, 1f));
        Material orbitMaterial = CreateMaterial("M0_OrbitGuide", new Color(0.2f, 0.42f, 0.8f, 0.55f));

        CreateStarField();
        CreateOrbitGuide("Inner Orbit", 2.35f, orbitMaterial);
        CreateOrbitGuide("Outer Orbit", 3.65f, orbitMaterial);

        var ship = GameObject.CreatePrimitive(PrimitiveType.Cube);
        ship.name = "Explorer Ship";
        ship.transform.position = new Vector3(0f, -2.2f, 0f);
        ship.transform.localScale = new Vector3(0.42f, 0.28f, 0.28f);
        ship.GetComponent<Renderer>().sharedMaterial = shipMaterial;

        Transform[] destinations =
        {
            CreateDestination("Mercury", new Vector3(-3.2f, 1.05f, 0f), 0.45f, focusMaterial),
            CreateDestination("Mars", new Vector3(0f, 1.75f, 0f), 0.38f, destinationMaterial),
            CreateDestination("Europa", new Vector3(3.2f, 1.05f, 0f), 0.34f, destinationMaterial)
        };

        var title = CreateText("Title", "Astro Adventure M0", new Vector3(-4.65f, 4.15f, 0f), 0.105f);
        title.anchor = TextAnchor.MiddleLeft;

        var subtitle = CreateText("Subtitle", "Controller proof: move, focus, scan", new Vector3(-4.65f, 3.72f, 0f), 0.052f);
        subtitle.anchor = TextAnchor.MiddleLeft;

        var focus = CreateText("Focus Text", "Focus: Mercury", new Vector3(-4.65f, -3.65f, 0f), 0.064f);
        focus.anchor = TextAnchor.MiddleLeft;

        var status = CreateText("Status Text", "Left stick/WASD moves | Bumpers/Q/E cycle | A/Enter scans | B/Esc backs out", new Vector3(-4.65f, -4.08f, 0f), 0.045f);
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

    private static Transform CreateDestination(string name, Vector3 position, float radius, Material material)
    {
        var destination = GameObject.CreatePrimitive(PrimitiveType.Sphere);
        destination.name = name;
        destination.transform.position = position;
        destination.transform.localScale = Vector3.one * radius;
        destination.GetComponent<Renderer>().sharedMaterial = material;

        var label = CreateText(name + " Label", name, position + new Vector3(0f, -0.78f, 0f), 0.052f);
        label.anchor = TextAnchor.MiddleCenter;
        return destination.transform;
    }

    private static TextMesh CreateText(string name, string text, Vector3 position, float size)
    {
        var obj = new GameObject(name);
        obj.transform.position = position;
        var mesh = obj.AddComponent<TextMesh>();
        mesh.text = text;
        mesh.fontSize = 48;
        mesh.characterSize = size;
        mesh.color = Color.white;
        return mesh;
    }

    private static Material CreateMaterial(string name, Color color)
    {
        string path = "Assets/Materials/" + name + ".mat";
        AssetDatabase.DeleteAsset(path);
        var material = new Material(Shader.Find("Standard"));
        material.name = name;
        material.color = color;
        AssetDatabase.CreateAsset(material, path);
        return material;
    }

    private static void CreateStarField()
    {
        Material starMaterial = CreateMaterial("M0_Stars", Color.white);
        Vector3[] positions =
        {
            new(-4.4f, 3.1f, 0.2f), new(-3.8f, -0.8f, 0.2f), new(-2.6f, 3.35f, 0.2f),
            new(-1.7f, -1.2f, 0.2f), new(-0.9f, 2.9f, 0.2f), new(0.9f, 3.25f, 0.2f),
            new(1.8f, -1.05f, 0.2f), new(2.65f, 3.05f, 0.2f), new(3.85f, -0.65f, 0.2f),
            new(4.45f, 2.55f, 0.2f)
        };

        foreach (Vector3 position in positions)
        {
            var star = GameObject.CreatePrimitive(PrimitiveType.Sphere);
            star.name = "Star";
            star.transform.position = position;
            star.transform.localScale = Vector3.one * 0.035f;
            star.GetComponent<Renderer>().sharedMaterial = starMaterial;
        }
    }

    private static void CreateOrbitGuide(string name, float radius, Material material)
    {
        var orbit = new GameObject(name);
        var line = orbit.AddComponent<LineRenderer>();
        line.sharedMaterial = material;
        line.useWorldSpace = false;
        line.loop = true;
        line.widthMultiplier = 0.018f;
        line.positionCount = 96;

        for (int i = 0; i < line.positionCount; i++)
        {
            float angle = Mathf.PI * 2f * i / line.positionCount;
            line.SetPosition(i, new Vector3(Mathf.Cos(angle) * radius, Mathf.Sin(angle) * radius * 0.32f, 0.08f));
        }
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
