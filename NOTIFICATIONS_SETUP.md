# Notifications — setup & how it works

Push (OneSignal) + local notifications are fully wired in code. The steps below
are the **account/dashboard steps that need your credentials** — do these once
and notifications go live. Nothing about the existing UI was changed.

---

## 1. The one value you MUST fill in

`lib/Service/notification_service.dart`:

```dart
static const String oneSignalAppId = 'YOUR_ONESIGNAL_APP_ID';
```

Paste your **OneSignal App ID** (OneSignal Dashboard → Settings → Keys & IDs).
Until this is set, push is a no-op (local notifications still work; the app runs
normally).

---

## 2. OneSignal dashboard

1. Create an app at https://onesignal.com (or reuse one).
2. **Android**: add the **Firebase Cloud Messaging** channel.
   - Firebase Console → Project `recipeai-32ae9` → Project Settings → Cloud
     Messaging → enable the **Firebase Cloud Messaging API (V1)**.
   - Service Accounts → Generate new private key → upload that JSON into
     OneSignal (Android/FCM config).
3. **iOS**: add the **Apple Push (APNs)** channel — upload an APNs **.p8** auth
   key (Apple Developer → Keys) with Key ID, Team ID, bundle id.
4. Copy the **App ID** and **REST API Key** from Settings → Keys & IDs.

---

## 3. Android (already done in code)

- `pubspec.yaml`: `onesignal_flutter`, `flutter_local_notifications`,
  `timezone`, `flutter_timezone`, `app_settings`.
- `AndroidManifest.xml`: `POST_NOTIFICATIONS`, `RECEIVE_BOOT_COMPLETED`,
  `VIBRATE`, and the local-notification boot receivers.
- `android/app/build.gradle.kts`: core-library desugaring
  (`desugar_jdk_libs`) — required by `flutter_local_notifications`.
- `google-services.json` is already present.

Nothing else to do for Android.

## 4. iOS (do in Xcode)

- `Info.plist`: `UIBackgroundModes → remote-notification` (already added).
- Open `ios/Runner.xcworkspace` → Runner target → **Signing & Capabilities**:
  - add **Push Notifications**
  - add **Background Modes** → check **Remote notifications**
- (Recommended for confirmed delivery / rich media) add a **OneSignal
  Notification Service Extension** target — follow OneSignal's iOS SDK guide.
- Run `cd ios && pod install`.

---

## 5. Cloud Functions (push that respects the toggles)

Push for **Likes & comments**, **New followers** is sent server-side so it can
check the recipient's Firestore toggle first — see `functions/notifications.js`
(`onNewFollower`, `onNewLike`, `onNewComment`). Each reads
`users/{uid}.notificationPrefs` and **does not send if the toggle is OFF**.

Set the OneSignal credentials for functions and deploy:

```bash
cd functions
# functions/.env  (or use firebase functions:secrets:set)
printf 'ONESIGNAL_APP_ID=xxxx\nONESIGNAL_REST_API_KEY=xxxx\n' > .env
firebase deploy --only functions:onNewFollower,functions:onNewLike,functions:onNewComment
```

**Product news & tips** is a broadcast: send it from the OneSignal dashboard
targeting the segment `product_news = "1"` (the app sets this tag from the
toggle, so opted-out users are automatically excluded).

---

## How it works (client)

- **Init** (`main.dart`): OneSignal + local notifications initialise on startup
  **without** prompting. On auth change the OneSignal user is linked
  (`OneSignal.login(uid)`), the **Subscription/Player ID is saved to
  `users/{uid}.oneSignalId`**, and the toggles are loaded from Firestore and
  reconciled with the OS.
- **Permission** (`NotificationsScreen` / `NotificationSettingsScreen`): the OS
  permission is requested the **first time the screen opens**. If denied, an
  **"Open" (app settings)** banner is shown instead of re-prompting. Returning
  from settings re-checks the state. It never prompts twice.
- **Toggles** (`SettingsController`): each toggle loads from Firestore, updates
  Firestore instantly on change, updates only its own switch (reactive `RxBool`
  + `Obx` — no full-screen rebuild), and persists across restarts (Firestore +
  GetStorage cache).
- **Gating**: a notification is only shown when **permission is granted AND the
  matching toggle is ON**.
  - Local (Cook timer / Meal plan / Weekly grocery): turning a toggle OFF
    cancels that type's pending notifications; ON allows scheduling.
  - Push (Likes & comments / New followers / Product news): the toggle is
    mirrored to OneSignal tags and stored in Firestore; the Cloud Functions
    check Firestore before sending.

## Firestore shape

```
users/{uid}
  oneSignalId: "<subscription id>"
  notificationPrefs:
    cookTimerAlerts, mealPlanReminders, weeklyGroceryReminder,
    likesAndComments, newFollowers, productNews   // all bool
```
