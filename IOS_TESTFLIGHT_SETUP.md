# iOS TestFlight — Setup & Upload Guide

This documents the iOS TestFlight configuration for **Recipe AI** and the exact
steps to upload a build. Everything that can be automated is **already done and
verified** — a signed, App-Store-ready `.ipa` builds cleanly.

---

## ✅ What is already done (verified)

| Item | Value / Status |
|------|----------------|
| Xcode / CocoaPods | 26.5 / 1.16.2 |
| Bundle identifier | `com.ai.recipe.community` (matches `GoogleService-Info.plist` + Firebase project `recipeai-32ae9`) |
| Development team | `LRP3TNDFPR`, **Automatic** signing |
| Version / build | `1.0.0 (1)` — from `pubspec.yaml` `version: 1.0.0+1` |
| Display name | **Recipe AI** (was "Recipe Ai") |
| Deployment target | iOS **15.0** (Runner target + Podfile now consistent) |
| App Store icon | 1024×1024, opaque (no alpha) ✓ |
| Capabilities | Push (`aps-environment`), Sign in with Apple — signed cleanly |
| **Signed IPA** | `build/ios/ipa/recipe_ai.ipa` (≈47 MB) — **ready to upload** |

**Fixes applied this session (so there are no runtime crashes / App Store rejections):**
- **Google Sign-In URL scheme** added to `Info.plist` (reversed client id) — Google
  Sign-In crashes on iOS without it.
- **Privacy usage descriptions** added: `NSCameraUsageDescription`,
  `NSMicrophoneUsageDescription`, `NSPhotoLibraryAddUsageDescription`
  (image_picker crashes / gets rejected without them; PhotoLibrary was already there).
- **`share_handler` → `receive_sharing_intent` migration.** `share_handler` does
  **not compile on Xcode 26.5** (Swift-6 module errors). It was replaced with the
  maintained `receive_sharing_intent` (same "share into app" capability). Android
  is unchanged (its share intent-filters are plugin-agnostic). After this, the iOS
  build succeeds.

> The only build warning is "Launch image is the default placeholder" — this is
> **cosmetic and does not block TestFlight**. Customise the splash later if you want.

---

## 🚀 Upload the build to TestFlight

You already have `build/ios/ipa/recipe_ai.ipa`. To (re)generate it any time:

```bash
flutter build ipa
```

Then upload it — pick **one**:

### Option A — Transporter app (easiest, no CLI)
1. Install **Transporter** from the Mac App Store.
2. Sign in with your Apple ID (the one on team `LRP3TNDFPR`).
3. Drag `build/ios/ipa/recipe_ai.ipa` into Transporter → **Deliver**.

### Option B — Xcode Organizer
1. `open ios/Runner.xcworkspace`
2. Product ▸ Archive (uses the same automatic signing that already worked).
3. In Organizer: **Distribute App ▸ App Store Connect ▸ Upload**.

### Option C — Command line (App Store Connect API key)
```bash
xcrun altool --upload-app --type ios \
  -f build/ios/ipa/recipe_ai.ipa \
  --apiKey <KEY_ID> --apiIssuer <ISSUER_ID>
```

### First-time prerequisites in App Store Connect
1. Create the app record at https://appstoreconnect.apple.com → **Apps ▸ +** →
   platform iOS, bundle id `com.ai.recipe.community`.
2. After the upload finishes processing (~5–15 min), open **TestFlight**, add
   internal testers, and (if using external testers) submit for Beta App Review.

> Push notifications in TestFlight: TestFlight uses the **production** APNs
> environment. `ios/Runner/Runner.entitlements` currently has
> `aps-environment = development`. If push doesn't arrive in a TestFlight build,
> change that value to `production` and re-archive.

---

## 📥 (Optional) Enable "Share into Recipe AI" on iOS — Share Extension

Android already supports sharing a link/reel into the app. iOS additionally
requires a **Share Extension** target (this was never set up — `share_handler`
had no extension either). The ready-to-use files are already staged in
`ios/Share Extension/`. Because a Share Extension needs an **App Group** and its
own signing (which require your Apple account), finish it in Xcode:

**Do NOT apply the Podfile / entitlements changes below until after step 1 —
otherwise the currently-working signed build will fail to sign.**

### 1. Register the App Group
- Xcode ▸ Runner target ▸ **Signing & Capabilities** ▸ **+ Capability** ▸ **App Groups**.
- Add a group named **`group.com.ai.recipe.community`** (Xcode registers it in your
  Apple Developer account automatically).

### 2. Create the Share Extension target
- File ▸ New ▸ Target… ▸ **Share Extension**. Name it exactly **`Share Extension`**.
- Set its **Deployment Target to 15.0** (same as Runner) and Team to `LRP3TNDFPR`.
- When prompted "Activate scheme?", choose **Cancel** (keep the Runner scheme).

### 3. Use the staged files
Replace the 4 files Xcode generated for the extension with the ones already in
`ios/Share Extension/` (drag them in / "Replace"):
- `ShareViewController.swift` (inherits `RSIShareViewController`)
- `Info.plist`
- `Share Extension.entitlements`
- `Base.lproj/MainInterface.storyboard`

### 4. App Group on the extension too
- Select the **Share Extension** target ▸ Signing & Capabilities ▸ **+ Capability**
  ▸ **App Groups** ▸ check **`group.com.ai.recipe.community`**.

### 5. `CUSTOM_GROUP_ID` build setting (BOTH targets)
- For **Runner** and **Share Extension**: Build Settings ▸ **+ ▸ Add User-Defined Setting**
  → name `CUSTOM_GROUP_ID`, value `group.com.ai.recipe.community`.

### 6. Runner `Info.plist` — add the app-group key
Add inside `ios/Runner/Info.plist`:
```xml
<key>AppGroupId</key>
<string>$(CUSTOM_GROUP_ID)</string>
```

### 7. Runner `Runner.entitlements` — add the app group
Add inside `ios/Runner/Runner.entitlements`:
```xml
<key>com.apple.security.application-groups</key>
<array>
	<string>group.com.ai.recipe.community</string>
</array>
```

### 8. Podfile — add the extension target
In `ios/Podfile`, inside `target 'Runner' do … end`, add:
```ruby
  target 'Share Extension' do
    inherit! :search_paths
  end
```

### 9. Fix the embed-phase order (avoids "No such module 'receive_sharing_intent'")
- Runner target ▸ **Build Phases** ▸ drag **Embed Foundation Extensions** ABOVE the
  **Thin Binary** phase.

### 10. Rebuild
```bash
cd ios && pod install && cd ..
flutter build ipa
```
Share a link/photo from Safari/Photos → **Recipe AI** should appear in the share
sheet and open the app to import.

---

## Notes
- `checkEmailRegistered` Cloud Function (for the forgot-password "no account"
  error) is still **not deployed**: `cd functions && firebase deploy --only functions:checkEmailRegistered`.
