# Sign in with Apple — Setup & Reference

Complete Sign in with Apple has been implemented on top of the existing Firebase
Authentication system. **Google, Email/Password and every other existing flow are
unchanged.** Apple is added as an additional provider only.

---

## 1. What was implemented (code)

| File | Change |
|------|--------|
| `pubspec.yaml` | Added `sign_in_with_apple: ^6.1.0` and `crypto: ^3.0.3`. |
| `lib/Service/auth_service.dart` | Added `AuthService.signInWithApple()`, the `AppleSignInResult` result type, `_syncAppleUser()`, `_generateNonce()`, `_sha256OfString()`. |
| `lib/screens/auth/create_account_screen.dart` | "Continue with Apple" now calls the real flow (loading state + error handling). |
| `lib/screens/auth/login_screen.dart` | "Apple" social button now calls the real flow. |
| `ios/Runner/Runner.entitlements` | New file — declares the `com.apple.developer.applesignin` entitlement. |
| `ios/Runner.xcodeproj/project.pbxproj` | `CODE_SIGN_ENTITLEMENTS = Runner/Runner.entitlements;` added to the Debug / Release / Profile configs of the Runner target. |

### How the flow works
1. **Nonce** — a secure random `rawNonce` is generated; its **SHA-256 hash** is sent
   to Apple, and the **raw** value is handed to Firebase. Firebase verifies they match,
   which prevents token replay attacks.
2. The native Apple sheet is shown via `SignInWithApple.getAppleIDCredential(...)`.
3. Apple's identity token becomes a Firebase `OAuthProvider('apple.com')` credential
   (with `rawNonce`), and we call `signInWithCredential`.
4. **Firestore:** first-time users get a full `users/{uid}` document
   (`provider: 'apple'`, `createdAt`). Returning users only have *missing* fields
   back-filled — **existing name/email/photo are never overwritten** (important because
   Apple only returns the name/email on the very first authorization).

### Error handling (all mapped to `AppleSignInResult`, never thrown)
- **Cancelled** (`AuthorizationErrorCode.canceled`) → `result.cancelled == true`, UI stays silent.
- **Network** (`SocketException`) → friendly "no internet" message.
- **Firebase** (`FirebaseAuthException`) → surfaces Firebase's code/message.
- **Unavailable** (Android / iOS < 13) → `SignInWithApple.isAvailable()` guard returns a clean failure instead of crashing.
- **Unknown** → generic fallback.

---

## 2. pubspec.yaml dependencies

```yaml
dependencies:
  sign_in_with_apple: ^6.1.0   # resolved: 6.1.4
  crypto: ^3.0.3               # resolved: 3.0.7 — SHA-256 for the nonce
```
Run: `flutter pub get`

---

## 3. iOS — Entitlements (REQUIRED)

`ios/Runner/Runner.entitlements` (already created):

```xml
<key>com.apple.developer.applesignin</key>
<array>
    <string>Default</string>
</array>
```

The `CODE_SIGN_ENTITLEMENTS` build setting is already wired into the pbxproj, so the
capability is applied at signing time. **In Xcode**, confirm it appears under
`Runner → Signing & Capabilities → Sign in with Apple`. If it is missing, click
**+ Capability → Sign in with Apple** (Xcode will reuse the existing entitlements file).

---

## 4. iOS — Info.plist

**No changes required.** The native iOS flow uses `ASAuthorizationController` and does
**not** need a custom URL scheme (unlike Google Sign In). Your existing `Info.plist`
already contains everything needed.

---

## 5. iOS — AppDelegate

**No changes required.** `sign_in_with_apple` handles presentation internally on
iOS 13+; there is no URL callback to forward. `AppDelegate.swift` is left as-is.

---

## 6. iOS — Deployment target

- `ios/Podfile` is already `platform :ios, '15.0'` ✅ (Apple Sign In needs iOS 13+).
- The Runner target min in Xcode is `12.0`; the runtime `isAvailable()` guard covers
  older OS versions gracefully. Optionally bump `IPHONEOS_DEPLOYMENT_TARGET` to `13.0`
  in Xcode → Runner → Build Settings for consistency.

---

## 7. Firebase configuration

Firebase Console → **Authentication → Sign-in method → Apple → Enable → Save**.

- For an **iOS-only** app, enabling the provider is all that's required — the OAuth
  handshake happens on-device via the Apple ID token.
- (Only needed for **Web/Android** Apple sign-in) fill in **Services ID**, **Apple team
  ID**, **Key ID**, and the **private key**. Not required for the native iOS flow.

No `GoogleService-Info.plist` change is needed.

---

## 8. Apple Developer configuration

1. **App ID** (developer.apple.com → Certificates, Identifiers & Profiles → Identifiers):
   - Select your app's App ID and **enable the "Sign in with Apple" capability**, then Save.
   - ⚠️ The bundle identifier is currently the placeholder **`com.example.recipeAi`**.
     Replace it with your real, registered bundle ID (in Xcode → Runner → General, and in
     the App ID) before shipping — Apple Sign In will not work with an unregistered ID.
2. **Provisioning profile** — regenerate/allow Xcode to auto-manage signing so the new
   entitlement is included. (`DEVELOPMENT_TEAM = ARX5JSVNWV` is already set.)
3. **(Web/Android only)** create a **Services ID**, configure the return URL to your
   Firebase handler `https://<project>.firebaseapp.com/__/auth/handler`, and create a
   **Sign in with Apple key** — then paste these into Firebase (step 7). Skip for iOS-only.

---

## 9. Testing instructions

**Platform:** Apple Sign In runs on a real iOS device or the iOS Simulator (iOS 13+)
signed into an Apple ID. On Android the button returns a clean "not available on this
device" message (by design).

1. `flutter run` on an iOS device/simulator.
2. Create Account **or** Login screen → tap **Continue with Apple / Apple**.
3. Authenticate (Face ID / Touch ID / passcode); optionally choose **Hide My Email**.
4. **First-time user:** expect to land in the app authenticated. In Firestore, confirm
   `users/{uid}` exists with `provider: 'apple'`, `name`, `email`, `createdAt`.
5. **Cancellation:** open the sheet and dismiss it → no error snackbar, spinner stops.
6. **Returning user:** sign out, sign in again → you are recognized, and your existing
   `name`/`email` in Firestore are **not** wiped (Apple sends no name on repeat logins).
7. Firebase Console → Authentication → **Users** shows the account with the **Apple**
   provider.
8. **Existing flows unaffected:** verify Google and Email/Password sign-in still work.

### Quick verification already done
- `flutter pub get` ✅
- `flutter analyze` (auth files) ✅ — no errors
- `flutter build apk --debug` ✅ — full app compiles with the new provider
