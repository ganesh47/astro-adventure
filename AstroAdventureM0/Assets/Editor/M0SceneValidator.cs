using System;
using System.Collections.Generic;
using System.IO;
using UnityEditor;
using UnityEditor.SceneManagement;
using UnityEngine;

public static class M0SceneValidator
{
    private const string ScenePath = "Assets/Scenes/M0_DeploymentProof.unity";
    private static readonly List<string> Failures = new();
    private static readonly List<string> Notes = new();

    public static void Run()
    {
        Failures.Clear();
        Notes.Clear();

        string outputDir = GetOutputDirectory();
        Directory.CreateDirectory(outputDir);

        EditorSceneManager.OpenScene(ScenePath, OpenSceneMode.Single);

        ValidateScene();
        CaptureState(outputDir, "01-focus-mercury", 0, "Scan complete: Mercury is ready for a kid-friendly astronomy fact.");
        CaptureState(outputDir, "02-focus-mars", 1, "Focused Mars. Press A or Enter to scan.");
        CaptureState(outputDir, "03-focus-europa", 2, "Focused Europa. Press A or Enter to scan.");
        CaptureState(outputDir, "04-scan-europa", 2, "Scan complete: Europa is ready for a kid-friendly astronomy fact.");
        WriteReport(outputDir);

        if (Failures.Count > 0)
        {
            foreach (string failure in Failures)
            {
                Debug.LogError(failure);
            }

            EditorApplication.Exit(1);
            return;
        }

        Debug.Log("M0 scene validation passed. Artifacts: " + outputDir);
    }

    private static void ValidateScene()
    {
        Assert(File.Exists(ScenePath), "Scene exists: " + ScenePath);

        Camera camera = Camera.main;
        Assert(camera != null, "Main Camera exists and is tagged MainCamera.");
        if (camera != null)
        {
            Assert(camera.orthographic, "Main Camera is orthographic.");
            Assert(camera.orthographicSize >= 4.8f && camera.orthographicSize <= 5.8f, "Main Camera orthographic size is in expected range.");
        }

        GameObject ship = GameObject.Find("Explorer Ship");
        Assert(ship != null, "Explorer Ship exists.");
        Assert(ship != null && ship.GetComponent<M0ControllerTest>() != null, "Explorer Ship has M0ControllerTest.");

        foreach (string destination in new[] { "Mercury", "Mars", "Europa" })
        {
            GameObject target = GameObject.Find(destination);
            Assert(target != null, destination + " destination exists.");
            Assert(target != null && target.GetComponent<Renderer>() != null, destination + " destination renders.");
            TextMesh label = FindText(destination);
            Assert(label != null, destination + " label exists.");
            if (label != null)
            {
                Assert(label.characterSize <= 0.08f, destination + " label is not oversized.");
            }
        }

        TextMesh title = FindText("Astro Adventure M0");
        Assert(title != null, "Title text exists.");
        if (title != null)
        {
            Assert(title.characterSize <= 0.12f, "Title text is not oversized.");
        }

        Assert(FindTextPrefix("Focus:") != null, "Focus status text exists.");
        Assert(FindTextPrefix("Left stick") != null || FindTextPrefix("Scan complete") != null, "Instruction/status text exists.");
        Assert(GameObject.Find("Inner Orbit") != null, "Inner orbit guide exists.");
        Assert(GameObject.Find("Outer Orbit") != null, "Outer orbit guide exists.");

        string inputActionsPath = "Assets/Input/AstroAdventureControls.inputactions";
        Assert(File.Exists(inputActionsPath), "Input actions asset exists.");
        if (File.Exists(inputActionsPath))
        {
            string inputActions = File.ReadAllText(inputActionsPath);
            Assert(inputActions.Contains("<Gamepad>/leftStick"), "Input actions include gamepad movement.");
            Assert(inputActions.Contains("<Gamepad>/buttonSouth"), "Input actions include confirm/scan button.");
            Assert(inputActions.Contains("<Keyboard>/w"), "Input actions include keyboard fallback.");
        }

        ValidateCameraFraming(camera);
    }

    private static void ValidateCameraFraming(Camera camera)
    {
        if (camera == null) return;

        float aspect = 16f / 9f;
        float halfHeight = camera.orthographicSize;
        float halfWidth = halfHeight * aspect;

        foreach (TextMesh text in UnityEngine.Object.FindObjectsByType<TextMesh>(FindObjectsSortMode.None))
        {
            Vector3 p = text.transform.position;
            Assert(p.x >= -halfWidth && p.x <= halfWidth, text.name + " is inside horizontal camera bounds.");
            Assert(p.y >= -halfHeight && p.y <= halfHeight, text.name + " is inside vertical camera bounds.");
        }

        foreach (string name in new[] { "Mercury", "Mars", "Europa", "Explorer Ship" })
        {
            GameObject obj = GameObject.Find(name);
            if (obj == null) continue;
            Vector3 p = obj.transform.position;
            Assert(p.x >= -halfWidth && p.x <= halfWidth, name + " is inside horizontal camera bounds.");
            Assert(p.y >= -halfHeight && p.y <= halfHeight, name + " is inside vertical camera bounds.");
        }
    }

    private static void CaptureState(string outputDir, string fileName, int focusIndex, string status)
    {
        string[] names = { "Mercury", "Mars", "Europa" };
        for (int i = 0; i < names.Length; i++)
        {
            GameObject destination = GameObject.Find(names[i]);
            if (destination == null) continue;
            float baseScale = names[i] == "Mercury" ? 0.45f : names[i] == "Mars" ? 0.38f : 0.34f;
            destination.transform.localScale = Vector3.one * (i == focusIndex ? baseScale * 1.35f : baseScale);
        }

        TextMesh focus = FindTextPrefix("Focus:");
        if (focus != null)
        {
            focus.text = "Focus: " + names[focusIndex];
        }

        TextMesh statusText = FindTextPrefix("Left stick") ?? FindTextPrefix("Scan complete") ?? FindTextPrefix("Focused");
        if (statusText != null)
        {
            statusText.text = status;
        }

        CaptureCamera(Path.Combine(outputDir, fileName + ".png"));
    }

    private static void CaptureCamera(string path)
    {
        Camera camera = Camera.main;
        if (camera == null)
        {
            Failures.Add("Cannot capture screenshot because Main Camera is missing.");
            return;
        }

        const int width = 1280;
        const int height = 720;
        RenderTexture renderTexture = new(width, height, 24);
        Texture2D screenshot = new(width, height, TextureFormat.RGB24, false);

        RenderTexture previous = RenderTexture.active;
        camera.targetTexture = renderTexture;
        RenderTexture.active = renderTexture;
        camera.Render();
        screenshot.ReadPixels(new Rect(0, 0, width, height), 0, 0);
        screenshot.Apply();
        File.WriteAllBytes(path, screenshot.EncodeToPNG());

        camera.targetTexture = null;
        RenderTexture.active = previous;
        UnityEngine.Object.DestroyImmediate(renderTexture);
        UnityEngine.Object.DestroyImmediate(screenshot);
    }

    private static void WriteReport(string outputDir)
    {
        string reportPath = Path.Combine(outputDir, "report.md");
        using StreamWriter writer = new(reportPath);
        writer.WriteLine("# M0 Scene Validation Report");
        writer.WriteLine();
        writer.WriteLine("- Scene: `" + ScenePath + "`");
        writer.WriteLine("- Unity: `" + Application.unityVersion + "`");
        writer.WriteLine("- Result: `" + (Failures.Count == 0 ? "pass" : "fail") + "`");
        writer.WriteLine();
        writer.WriteLine("## Checks");
        writer.WriteLine();
        foreach (string note in Notes)
        {
            writer.WriteLine("- " + note);
        }

        if (Failures.Count > 0)
        {
            writer.WriteLine();
            writer.WriteLine("## Failures");
            writer.WriteLine();
            foreach (string failure in Failures)
            {
                writer.WriteLine("- " + failure);
            }
        }

        writer.WriteLine();
        writer.WriteLine("## Screenshots");
        writer.WriteLine();
        writer.WriteLine("- `01-focus-mercury.png`");
        writer.WriteLine("- `02-focus-mars.png`");
        writer.WriteLine("- `03-focus-europa.png`");
        writer.WriteLine("- `04-scan-europa.png`");
    }

    private static TextMesh FindText(string exactText)
    {
        foreach (TextMesh text in UnityEngine.Object.FindObjectsByType<TextMesh>(FindObjectsSortMode.None))
        {
            if (text.text == exactText)
            {
                return text;
            }
        }

        return null;
    }

    private static TextMesh FindTextPrefix(string prefix)
    {
        foreach (TextMesh text in UnityEngine.Object.FindObjectsByType<TextMesh>(FindObjectsSortMode.None))
        {
            if (text.text.StartsWith(prefix, StringComparison.Ordinal))
            {
                return text;
            }
        }

        return null;
    }

    private static string GetOutputDirectory()
    {
        string fromEnv = Environment.GetEnvironmentVariable("ASTRO_SCENE_VALIDATION_DIR");
        if (!string.IsNullOrWhiteSpace(fromEnv))
        {
            return fromEnv;
        }

        string projectRoot = Directory.GetParent(Application.dataPath)?.FullName;
        string repoRoot = Directory.GetParent(projectRoot ?? Application.dataPath)?.FullName ?? projectRoot;
        return Path.Combine(repoRoot, "artifacts", "scene-validation");
    }

    private static void Assert(bool condition, string message)
    {
        if (condition)
        {
            Notes.Add("[pass] " + message);
        }
        else
        {
            Failures.Add("[fail] " + message);
        }
    }
}
