# OCHE

A free, native SwiftUI darts scoring app for iOS — 8 game modes, no account
required, all data stored locally on-device with SwiftData.

## Game modes

- Standard Darts (301 / 501, double-out, checkout suggestions)
- Around the Clock
- Cricket
- Count-Up
- Killer
- Shanghai
- Halve-It
- 170 Practice (WDA drill)

## Requirements

- macOS with Xcode 16+ (iOS 17 deployment target, SwiftUI Charts, SwiftData)
- [XcodeGen](https://github.com/yonaskolb/XcodeGen) to generate the `.xcodeproj`
  (`brew install xcodegen`)

This project was built as plain Swift source files (no `.xcodeproj` is
checked in) so it can be developed without Xcode. `project.yml` describes the
project for XcodeGen, which generates a ready-to-open `.xcodeproj`.

## Setup

```sh
cd OCHE
xcodegen generate
open OCHE.xcodeproj
```

Then in Xcode:

1. Select the **OCHE** scheme and a simulator (iPhone 15 or newer, iOS 17+).
2. Build & run with `Cmd+R`.
3. Run the unit tests with `Cmd+U` (covers the checkout-suggestion algorithm,
   match statistics, and the x01 bust/undo logic).

If you'd rather not install XcodeGen, you can create the project by hand:

1. In Xcode, **File → New → Project → iOS → App**.
   - Product Name: `OCHE`
   - Interface: SwiftUI, Storage: SwiftData, Language: Swift
   - Deployment target: iOS 17
2. Delete the generated `ContentItem.swift`/`Item.swift` and the placeholder
   `ContentView.swift`/`<App>App.swift`.
3. Drag the `OCHE/` folder's contents (DesignSystem, Models, Engines,
   Utilities, Views, OCHEApp.swift, Assets.xcassets) into the app target,
   choosing "Copy items if needed" and "Create groups".
4. Add a new **Unit Testing Bundle** target named `OCHETests`, then drag in
   the contents of `OCHETests/`.

## Building an IPA via GitHub Actions (no Mac required)

`.github/workflows/build-ipa.yml` builds an **unsigned** `.ipa` on a macOS
GitHub runner and uploads it as a workflow artifact — no certificates,
provisioning profiles, or paid Apple Developer account needed. You install it
on your iPhone via **AltStore**, which re-signs it on your behalf using your
free Apple ID.

### 1. Get the IPA from CI

Push to `main`, or trigger manually from your repo's **Actions** tab →
"Build IPA" → "Run workflow". When it finishes, open the run and download the
`OCHE-ipa` artifact (a zip containing `OCHE.ipa`).

### 2. Install AltServer + AltStore

1. On your Windows PC, install **AltServer** from https://altstore.io/ and
   run it (it sits in the system tray). It needs iTunes / Apple Mobile
   Device support installed (the installer handles this).
2. Connect your iPhone via USB (or have it on the same Wi-Fi network) and
   sign in with your Apple ID in AltServer's tray menu (Account →
   "Sign in with Apple ID"). Use an **app-specific password** if you have
   two-factor enabled (generate one at appleid.apple.com).
3. From the tray icon, choose **Install AltStore** → select your device.
   This installs the AltStore app on your iPhone (you'll need to trust the
   developer profile once: Settings → General → VPN & Device Management).

### 3. Sideload OCHE

1. Unzip the downloaded artifact to get `OCHE.ipa`.
2. Open **AltStore** on your iPhone → **My Apps** tab → tap **+** in the
   top-left.
3. If AltStore is running on your PC and connected, you can instead use
   AltServer's tray menu → **Install** → choose your device → pick
   `OCHE.ipa` directly (no need to transfer the file to the phone first).
4. AltServer re-signs the IPA with a certificate from your free Apple ID and
   installs it. OCHE should now appear on your home screen.

### Notes / limitations (free Apple ID)

- Apps signed this way expire after **7 days**. AltStore can auto-refresh
  them in the background as long as AltServer is running on your PC and your
  phone is on the same Wi-Fi (or you can manually re-install via AltServer).
- A free Apple ID can have at most **3 apps** signed this way at a time, and
  apps are limited to **10 free provisioning-profile app IDs per 7 days**
  across your whole account — shouldn't be an issue for just OCHE.
- If you later get a paid Apple Developer Program membership ($99/yr), the
  same `OCHE.ipa` workflow output can be re-signed with a real distribution
  certificate for a year-long install (e.g. via Sideloadly), no workflow
  changes needed.

## Project structure

```
OCHE/
  OCHEApp.swift          App entry point (@main, SwiftData container)
  DesignSystem/          Colors, typography, ambient background
  Models/                Dart, GameMode, CheckoutTable, MatchStatistics,
                          SwiftData models (PlayerProfile, MatchRecord),
                          AppRouter / Route, GameLaunchConfig
  Engines/                One engine per game mode, all built on
                          GameEngineBase<State> for snapshot-based undo
  Utilities/              SettingsStore, HapticManager, SoundManager
  Views/
    Home/                 Mode list
    Setup/                Player/options setup per mode
    Game/                 Shared game UI (NumberPad, ScoreCard, popups,
                          GameOverView, GameRouterView) + per-mode game views
    Stats/                Stats & charts
    Settings/             Settings sheet
OCHETests/                Unit tests (checkout table, stats, x01 engine)
```

## Notes

- **No account, no ads, no IAPs.** Everything runs and is stored locally.
- **Undo** is multi-step and exact: every engine snapshots its full state
  before each mutation, so undo always restores the exact prior state
  (including stats, which are recomputed fresh from the dart log).
- **Checkout suggestions** are generated algorithmically (minimal darts
  first, double-out), not from a hardcoded table — see
  `Models/CheckoutTable.swift`.
- Sound files are optional: `Utilities/SoundManager.swift` looks for
  `.caf`/`.wav` assets by name and silently no-ops if they aren't bundled, so
  the app works fully without adding audio assets.
