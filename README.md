# Sol for iPhone

Voice dictation on iOS. Because iOS apps can't type into other apps, Sol ships as a **custom keyboard**
(the "Sol Keyboard") plus a **host app**. Tap the keyboard's mic button in any app, speak, and the text
is inserted into the focused field. A **thin client**: audio goes to the [Sol proxy](https://github.com/wiseant-co/sol-proxy),
which holds the provider keys and does the transcription + language handling. **No API key on device.**

> ⚠️ **Unverified scaffold.** Authored on Linux; **not** compiled or run. The structure and the core
> pieces (App Group config, proxy client, AVAudioEngine capture → 16 kHz WAV, the keyboard's
> insert-text flow) are real first-pass code — expect to fix compile/runtime issues in Xcode. Build &
> test on a Mac.

## Two iOS constraints baked into the design

- **Full Access** — the keyboard needs *Allow Full Access* (in Settings) to reach the network (proxy)
  and the mic. `RequestsOpenAccess` is set to `true` in the project.
- **App Group** — the host app and keyboard share the proxy URL + token via
  `group.co.wiseant.sol` (`SolConfig`). You must create this App Group in your Apple developer account
  and enable it on both targets (the project references it; provisioning is per-account).

## Build (on a Mac)

The Xcode project is generated with [XcodeGen](https://github.com/yonaskolb/XcodeGen) so it isn't
committed (avoids a fragile `project.pbxproj`).

```bash
brew install xcodegen
cd sol-ios
xcodegen generate         # → Sol.xcodeproj (Info.plists + entitlements generated from project.yml)
open Sol.xcodeproj
```

In Xcode:
1. Set `DEVELOPMENT_TEAM` (project.yml or the Signing tab) on all three targets.
2. Create the App Group `group.co.wiseant.sol` and enable it on **Sol** and **SolKeyboard**.
3. Run **Sol** on a device (the keyboard mic needs a real device, not the simulator).
4. In the app: enter the **proxy URL + token**, **Allow microphone**, then enable the keyboard:
   Settings → General → Keyboard → Keyboards → Add New Keyboard → **Sol** → turn on **Allow Full Access**.
5. In any app, long-press 🌐, pick **Sol**, tap the mic.

## Targets

| Target | Type | Role |
|---|---|---|
| `SolKit` | framework | shared: `SolConfig` (App Group), `ProxyClient` (`/v1/transcribe`), `AudioRecorder` (AVAudioEngine → 16 kHz WAV), `WAV` |
| `Sol` | app | onboarding/setup + a standalone dictate-and-copy screen |
| `SolKeyboard` | app-extension | the keyboard: mic button → proxy → `textDocumentProxy.insertText` |

## Known TODOs (before a TestFlight)

- **Extension memory (~48–64 MB):** long recordings must stream/chunk rather than buffer whole; the
  scaffold buffers Int16 samples — fine for short dictation, revisit for long.
- **Mic in the extension:** allowed only with Full Access; validate the AVAudioSession category works
  inside the keyboard process on-device.
- **Language picker in the keyboard** (currently taken from the app's saved setting).
- **Auth:** token is entered manually in Setup; real issuance comes from the account flow.
- **App Store review:** dictation keyboards are allowed; you must justify Full Access + add privacy
  labels. No streaming/partial results yet.
- **Icon/design polish**, error states, haptics.
