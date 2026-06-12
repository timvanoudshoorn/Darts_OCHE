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

`.github/workflows/build-ipa.yml` builds a signed `.ipa` on a macOS GitHub
runner and uploads it as a workflow artifact. To use it you need an Apple ID
(a free account is enough for a development-signed build you can install on
your own registered devices via Xcode or a sideloading tool).

### 1. Create a signing certificate

On a Mac (yours, a friend's, or a rented one — you only need to do this
once):

```sh
# Generates a private key + CSR
openssl genrsa -out ios_dev.key 2048
openssl req -new -key ios_dev.key -out ios_dev.csr -subj "/CN=OCHE Dev/"
```

Upload `ios_dev.csr` at https://developer.apple.com/account/resources/certificates/add
(type "Apple Development"), download the resulting `.cer`, then:

```sh
openssl x509 -in ios_development.cer -inform DER -out ios_dev.pem -outform PEM
openssl pkcs12 -export -inkey ios_dev.key -in ios_dev.pem -out ios_dev.p12 -passout pass:YOUR_P12_PASSWORD
base64 -i ios_dev.p12 | pbcopy   # copy this for the GitHub secret below
```

### 2. Create a provisioning profile

1. Register your iPhone's UDID at
   https://developer.apple.com/account/resources/devices/add
   (Settings → General → About on the device, or via Finder/Xcode).
2. Register an App ID `com.oche.app` at
   https://developer.apple.com/account/resources/identifiers/add
3. Create an **iOS App Development** provisioning profile at
   https://developer.apple.com/account/resources/profiles/add, selecting the
   `com.oche.app` ID, your certificate, and your device. Note the **profile
   name** you give it — update `OCHE/ExportOptions.plist`'s
   `provisioningProfiles` dict value to match it exactly.
4. Download the `.mobileprovision` file and run:
   ```sh
   base64 -i OCHE_Development.mobileprovision | pbcopy
   ```

### 3. Add GitHub repo secrets

In your GitHub repo: **Settings → Secrets and variables → Actions → New
repository secret**:

| Secret | Value |
| --- | --- |
| `IOS_DIST_CERT_P12_BASE64` | output of `base64 -i ios_dev.p12` |
| `IOS_DIST_CERT_PASSWORD` | the password you set with `-passout` above |
| `IOS_PROVISION_PROFILE_BASE64` | output of `base64 -i *.mobileprovision` |
| `IOS_TEAM_ID` | your 10-character Apple Developer Team ID (developer.apple.com → Membership) |
| `IOS_CODE_SIGN_IDENTITY` | `Apple Development: Your Name (XXXXXXXXXX)` — find via `security find-identity -v -p codesigning` on the Mac you used above |

### 4. Run the workflow

Push to `main`, or trigger manually from the **Actions** tab ("Build IPA" →
"Run workflow"). When it finishes, download the `OCHE-ipa` artifact — it
contains `OCHE.ipa`.

### 5. Install the IPA on your device

A development-signed IPA can be installed via:
- Xcode (Window → Devices and Simulators → drag the `.ipa` onto your device), or
- a sideloading tool such as [Sideloadly](https://sideloadly.io/) or
  [AltStore](https://altstore.io/) using your Apple ID.

It will only run on devices whose UDID was included in the provisioning
profile (step 2), and you'll need to re-sign/re-install roughly every 7 days
unless you have a paid Apple Developer Program membership.

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
