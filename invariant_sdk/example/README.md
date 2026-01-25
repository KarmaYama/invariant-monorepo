# Invariant SDK Example App

This example application demonstrates the capabilities of the Invariant SDK. It features a "Terminal" style UI that allows you to simulate different network conditions and device environments to see how the SDK responds.

## 🛠️ Getting Started

1.  **Navigate to the example directory:**
    ```bash
    cd invariant_sdk/example
    ```

2.  **Install dependencies:**
    ```bash
    flutter pub get
    ```

3.  **Run the app:**
    ```bash
    flutter run
    ```

## 🎮 How to Use the Demo

The app initializes the SDK in **SHADOW MODE** by default. It provides a dropdown menu to toggle between **Real Network** calls and **Simulated** responses.

### 1. Real Network (Default)
This attempts to perform a real Hardware Attestation with the Invariant Cloud.
* *Note:* This requires a valid API key and an Android device with a secure lock screen enabled.
* If running on a simulator, this will likely return `EMULATOR` or fail with a hardware error.

### 2. Simulation Modes
Use the dropdown in the top right to force specific SDK outcomes. This helps you test your UI's reaction to different trust tiers.

* **SIM: ALLOW:** Simulates a `STRONGBOX` verified device (Pixel 8 Pro).
    * *Result:* Green Status (Verified).
* **SIM: SHADOW:** Simulates a high-risk device (Software-backed) while the SDK is in Shadow Mode.
    * *Result:* Amber Status (Warning).
* **SIM: DENY:** Simulates an Emulator detection.
    * *Result:* Red Status (Blocked).

## 🔍 Key Code Snippets

### Verification Logic (`main.dart`)
This demonstrates how to handle the `InvariantResult` object properly.

```dart
final result = await _verifier.verify();

switch (result.decision) {
  case InvariantDecision.allow:
     // Success
     print("Verified: ${result.tier}");
     break;
  case InvariantDecision.allowShadow:
     // Risk detected, but allowed via config
     print("Shadow Allow: ${result.reason}");
     break;
  case InvariantDecision.deny:
     // Blocked
     print("Blocked: ${result.reason}");
     break;
}

```

### Analyzing the Result

The demo includes a "View Manifest" feature. In a real app, you would use this data for analytics:

```dart
// Access granular hardware details
print(result.deviceModel); // e.g. "Pixel 8"
print(result.bootLocked);  // true/false
print(result.score);       // 0.0 - 100.0
