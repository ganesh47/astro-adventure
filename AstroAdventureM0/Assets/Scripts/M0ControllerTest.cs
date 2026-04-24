using UnityEngine;
using UnityEngine.InputSystem;

public class M0ControllerTest : MonoBehaviour
{
    [SerializeField] private Transform ship;
    [SerializeField] private Transform[] destinations;
    [SerializeField] private TextMesh statusText;
    [SerializeField] private TextMesh focusText;

    private int focusedIndex;
    private float nextCycleTime;
    private float hapticEndTime;

    private void Start()
    {
        UpdateFocus("Use left stick or arrow keys to move. Bumpers/Q/E cycle. A/Enter scans.");
    }

    private void Update()
    {
        Vector2 move = ReadMove();
        if (ship != null && move.sqrMagnitude > 0.01f)
        {
            Vector3 delta = new Vector3(move.x, move.y, 0f) * (3f * Time.deltaTime);
            ship.position += delta;
        }

        if (Time.time >= nextCycleTime)
        {
            if (WasPressed(Gamepad.current?.leftShoulder) || Keyboard.current?.qKey.wasPressedThisFrame == true)
            {
                Cycle(-1);
            }
            else if (WasPressed(Gamepad.current?.rightShoulder) || Keyboard.current?.eKey.wasPressedThisFrame == true)
            {
                Cycle(1);
            }
        }

        if (WasPressed(Gamepad.current?.buttonSouth) || Keyboard.current?.enterKey.wasPressedThisFrame == true || Keyboard.current?.spaceKey.wasPressedThisFrame == true)
        {
            ScanFocusedDestination();
        }

        if (WasPressed(Gamepad.current?.buttonEast) || Keyboard.current?.escapeKey.wasPressedThisFrame == true)
        {
            SetStatus("Back/cancel detected. The proof scene stayed active.");
        }

        if (hapticEndTime > 0f && Time.time >= hapticEndTime)
        {
            Gamepad.current?.SetMotorSpeeds(0f, 0f);
            hapticEndTime = 0f;
        }
    }

    private Vector2 ReadMove()
    {
        Vector2 move = Gamepad.current?.leftStick.ReadValue() ?? Vector2.zero;
        if (Keyboard.current != null)
        {
            Vector2 keyboard = Vector2.zero;
            if (Keyboard.current.leftArrowKey.isPressed || Keyboard.current.aKey.isPressed) keyboard.x -= 1f;
            if (Keyboard.current.rightArrowKey.isPressed || Keyboard.current.dKey.isPressed) keyboard.x += 1f;
            if (Keyboard.current.downArrowKey.isPressed || Keyboard.current.sKey.isPressed) keyboard.y -= 1f;
            if (Keyboard.current.upArrowKey.isPressed || Keyboard.current.wKey.isPressed) keyboard.y += 1f;
            if (keyboard.sqrMagnitude > 0f) move = keyboard.normalized;
        }

        return Vector2.ClampMagnitude(move, 1f);
    }

    private static bool WasPressed(ButtonControlWrapper control)
    {
        return control.WasPressed;
    }

    private void Cycle(int direction)
    {
        if (destinations == null || destinations.Length == 0) return;
        focusedIndex = (focusedIndex + direction + destinations.Length) % destinations.Length;
        nextCycleTime = Time.time + 0.2f;
        UpdateFocus("Focused " + destinations[focusedIndex].name + ". Press A or Enter to scan.");
    }

    private void ScanFocusedDestination()
    {
        if (destinations == null || destinations.Length == 0) return;
        string destination = destinations[focusedIndex].name;
        SetStatus("Scan complete: " + destination + " is ready for a kid-friendly astronomy fact.");
        if (Gamepad.current != null)
        {
            Gamepad.current.SetMotorSpeeds(0.08f, 0.12f);
            hapticEndTime = Time.time + 0.15f;
        }
    }

    private void UpdateFocus(string message)
    {
        for (int i = 0; i < destinations.Length; i++)
        {
            destinations[i].localScale = i == focusedIndex ? Vector3.one * 1.35f : Vector3.one;
        }

        if (focusText != null)
        {
            focusText.text = "Focus: " + destinations[focusedIndex].name;
        }

        SetStatus(message);
    }

    private void SetStatus(string message)
    {
        if (statusText != null)
        {
            statusText.text = message;
        }
    }

    private readonly struct ButtonControlWrapper
    {
        private readonly UnityEngine.InputSystem.Controls.ButtonControl control;

        public ButtonControlWrapper(UnityEngine.InputSystem.Controls.ButtonControl control)
        {
            this.control = control;
        }

        public bool WasPressed => control != null && control.wasPressedThisFrame;

        public static implicit operator ButtonControlWrapper(UnityEngine.InputSystem.Controls.ButtonControl control)
        {
            return new ButtonControlWrapper(control);
        }
    }
}
