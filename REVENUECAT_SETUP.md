# RevenueCat — Full Setup Guide (Android + iOS)

This is the complete, step-by-step guide to make the **Plus subscription** live.
The Flutter code is already finished — you only have to configure the three
dashboards (RevenueCat, Google Play, App Store) and paste two keys.

- **Monthly plan:** ₹199 / month
- **Yearly plan:** ₹1,700 / year
- The **price and plan name shown in the paywall are fetched live from the
  store through RevenueCat** — you set the real prices in Google Play and App
  Store Connect, and the app displays whatever those stores return (already
  localized per country).

---

## 0. How it all fits together (read this first)

```
  Your app  ──►  RevenueCat SDK  ──►  RevenueCat backend
                                         │
                 ┌───────────────────────┴───────────────────────┐
                 ▼                                                 ▼
        Google Play Billing                              Apple StoreKit
       (Android subscriptions)                          (iOS subscriptions)
```

- You create the **subscription products** in Google Play and App Store Connect
  (this is where the ₹199 / ₹1,700 prices actually live).
- **RevenueCat** sits in the middle. You tell it about those products, group
  them under one **Entitlement** called `plus`, and expose them in one
  **Offering** with a *Monthly* and an *Annual* package.
- The **app** asks RevenueCat "what can I sell?" (the Offering) and "is the user
  Plus?" (the `plus` entitlement). When the entitlement is active, the app's
  `SubscriptionService.isPlus` becomes `true` and every Plus feature unlocks.

You will use **one product id per plan, reused everywhere**. Decide them now and
keep them identical across all three dashboards:

| Plan    | Product ID (use everywhere) | Duration | Price  |
|---------|-----------------------------|----------|--------|
| Monthly | `plus_monthly`              | 1 month  | ₹199   |
| Yearly  | `plus_yearly`               | 1 year   | ₹1,700 |

- **Entitlement identifier:** `plus`
- **Offering identifier:** `default`

> The app reads the entitlement id from `lib/Service/revenuecat_config.dart`
> (`entitlementId = 'plus'`). If you name it something else, change it there too.

---

## 1. Prerequisites (accounts you must have)

1. **Google Play Developer account** (one-time $25) with the app already created
   under package name **`com.ai.recipe.community`**.
2. A **Google payments/merchant profile** set up in Play Console
   (Setup → Payments profile) — required to sell anything.
3. **Apple Developer Program** membership ($99/yr) with the app's **bundle id**
   registered.
4. **Paid Applications Agreement** active in App Store Connect
   (Business → Agreements) — with banking + tax filled in. Nothing sells until
   this says "Active".
5. A **RevenueCat account** (free): https://app.revenuecat.com

---

## 2. Google Play Console — create the subscriptions

Open https://play.google.com/console → your app.

### 2.1 Create the Monthly subscription
1. Left menu → **Monetize → Products → Subscriptions**.
2. **Create subscription**.
3. **Product ID:** `plus_monthly`  ← (cannot be changed later, type carefully)
4. **Name:** `Recipe AI Plus – Monthly` (shown to users).
5. **Create**.
6. Now add a **Base plan**:
   - **Base plan ID:** `monthly` (lowercase, no spaces).
   - **Type:** Auto-renewing.
   - **Billing period:** Monthly.
   - **Price:** set ₹199 for India, and either set prices for other countries
     or let Google auto-convert.
   - **Save** and **Activate** the base plan.
7. **Activate** the subscription.

### 2.2 Create the Yearly subscription
Repeat 2.1 with:
- **Product ID:** `plus_yearly`
- **Name:** `Recipe AI Plus – Yearly`
- **Base plan ID:** `yearly`, **Billing period:** Yearly, **Price:** ₹1,700.
- (Optional) add a **free trial** or **intro offer** on this base plan — the app
  automatically shows "Start free trial" when an intro offer exists.
- Activate the base plan and the subscription.

### 2.3 Give RevenueCat access to Google Play
RevenueCat needs a service account to read purchases.
1. Play Console → **Setup → API access**.
2. Follow the link to create/choose a **Google Cloud project**, then create a
   **Service account** (Google Cloud Console → IAM → Service Accounts →
   Create). Give it a name like `revenuecat`.
3. Create a **JSON key** for that service account and download it.
4. Back in Play Console → **API access** → find the service account →
   **Grant access** with at least: *View financial data*, *Manage orders and
   subscriptions* (and *View app information*).
5. Keep the downloaded JSON — you upload it to RevenueCat in step 4.2.
6. (Recommended) Later, paste RevenueCat's **Pub/Sub topic** into Play Console →
   **Monetization setup → Real-time developer notifications** so renewals/cancels
   sync instantly.

### 2.4 Prepare a testing build + testers
1. **Testing → Internal testing → Create release**, upload a **signed AAB**
   (`flutter build appbundle`), roll it out, and add your tester emails.
2. **Setup → License testing** → add the same Gmail accounts as **license
   testers** (their purchases are free / test purchases, not real charges).
3. Testers must open the app **through the Play internal-testing link** at least
   once (not a sideloaded APK) for prices and purchases to work.

> Products can take **a few hours** to become "purchasable" after activation.

---

## 3. App Store Connect — create the subscriptions

Open https://appstoreconnect.apple.com → **My Apps → (your app)**.

### 3.1 Create a subscription group
1. Left menu → **Monetization → Subscriptions**.
2. **Create** a **Subscription Group**, name it `Recipe AI Plus`.
   (Both plans live in the same group so users can switch/upgrade between them.)

### 3.2 Create the Monthly subscription
1. Inside the group → **Create** a subscription.
2. **Reference Name:** `Recipe AI Plus Monthly` (internal only).
3. **Product ID:** `plus_monthly` (must match everywhere).
4. **Subscription Duration:** 1 Month.
5. **Subscription Prices:** add a price → choose the ₹199 price point for India
   (Apple shows the equivalent in each country automatically).
6. **App Store Localization:** add a Display Name (`Monthly`) and Description.
7. **Review Information:** upload a screenshot (required the first time).
8. Save.

### 3.3 Create the Yearly subscription
Repeat 3.2 inside the same group:
- **Product ID:** `plus_yearly`, **Duration:** 1 Year, **Price:** ₹1,700.
- (Optional) add an **Introductory Offer** (e.g. 7-day free trial).

### 3.4 Give RevenueCat access to Apple
Two things RevenueCat needs:
1. **App-Specific Shared Secret:** App Store Connect → your app →
   **App Information → App-Specific Shared Secret → Generate**. Copy it.
2. (Recommended) **In-App Purchase key (.p8):** Users and Access → **Integrations
   → In-App Purchase** → generate a key, download the `.p8`, note the **Key ID**
   and **Issuer ID**. RevenueCat uses this for accurate status.

### 3.5 Sandbox testers
- **Users and Access → Sandbox → Testers → +** — create a test Apple ID
  (use an email you control that is NOT a real Apple ID).
- On the test device: Settings → App Store → sign OUT of the real account; you'll
  be prompted to sign in with the sandbox tester when you buy.

### 3.6 Xcode capability
- Open `ios/Runner.xcworkspace` in Xcode → **Runner target → Signing &
  Capabilities → + Capability → In-App Purchase**.
- Deployment target is already iOS 15 (RevenueCat needs 13+), so nothing to bump.

---

## 4. RevenueCat dashboard — tie it together

Open https://app.revenuecat.com and create a **Project** (e.g. "Recipe AI").

### 4.1 Add the two apps
- **Project settings → Apps → + New → Play Store**: package
  `com.ai.recipe.community`; upload the **service-account JSON** from step 2.3.
- **+ New → App Store**: enter the **bundle id**; paste the **App-Specific Shared
  Secret** (and add the **In-App Purchase .p8 key / Key ID / Issuer ID** from
  step 3.4 if you made one).

### 4.2 Add the products
- Left menu → **Products → + New**. Add each product id for the matching store:
  - `plus_monthly` (Play) and `plus_monthly` (App Store)
  - `plus_yearly` (Play) and `plus_yearly` (App Store)
  (You'll have 4 product rows total — 2 ids × 2 stores.)

### 4.3 Create the entitlement
- **Entitlements → + New**. Identifier: **`plus`**.
- Open it → **Attach** all four products (both monthly + both yearly).

### 4.4 Create the offering + packages
- **Offerings → + New**. Identifier: **`default`**. Make it the **Current** offering.
- Inside it, **+ Add Package** twice:
  - Package **Monthly** (`$rc_monthly`) → attach the `plus_monthly` products.
  - Package **Annual** (`$rc_annual`) → attach the `plus_yearly` products.
- The app reads `offering.monthly` and `offering.annual` — using these standard
  package types means no code change is needed.

### 4.5 Copy the public API keys
- **Project settings → API keys → Public app-specific keys**.
- Copy the **`goog_…`** key (Android) and the **`appl_…`** key (iOS).
- ⚠️ Use the **public** keys, never the secret key.

---

## 5. Paste the keys into the app

Open `lib/Service/revenuecat_config.dart` and fill in:

```dart
static const String androidApiKey = 'goog_PASTE_YOUR_ANDROID_KEY';
static const String iosApiKey     = 'appl_PASTE_YOUR_IOS_KEY';
static const String entitlementId = 'plus'; // keep in sync with the dashboard
```

That's the only code change. Rebuild the app.

> While the keys are still `goog_YOUR_…` / `appl_YOUR_…`, the SDK stays off and
> the paywall shows fallback prices + a dev unlock, so the app never breaks
> before setup is done.

---

## 6. Test on Android

1. `flutter build appbundle` → upload the AAB to **Internal testing** (step 2.4).
2. On a device signed in with a **license-tester** Gmail, open the app **via the
   Play internal-testing link**.
3. Go to **More → Upgrade to Plus**.
   - Prices should now show the **real store values** (localized).
4. Tap **Subscribe** → complete the (test) purchase → the app returns and shows
   Plus; the "4/5 imports" badge becomes PLUS and all Plus features unlock.
5. Kill & reopen the app, or tap **Restore** → still Plus. ✅

## 7. Test on iOS

1. Run on a **real device** from Xcode (or via TestFlight).
2. Go to **More → Upgrade to Plus** → prices show real values.
3. Tap **Subscribe** → sign in with the **sandbox tester** when prompted →
   confirm → app flips to Plus.
4. Reopen / **Restore** → still Plus. ✅

> Local shortcut for iOS: you can add a **StoreKit configuration file** in Xcode
> to test prices/purchases in the simulator without App Store Connect — optional.

---

## 8. Troubleshooting

| Symptom | Cause / fix |
|---|---|
| Paywall shows fallback ₹199/₹1,700 on a real build | Keys not pasted, or offering not marked **Current**, or products still propagating (wait a few hours). |
| "There are no products registered in the RevenueCat dashboard" | Product ids in RevenueCat don't exactly match the store, or products aren't attached to the offering. |
| Offering is `null` / no packages | Offering not set as **Current**, or packages have no products attached. |
| Purchase succeeds but app stays Free | Products not attached to the **`plus`** entitlement, or `entitlementId` in config ≠ dashboard. |
| Android: prices never load | App opened as a sideload instead of via the **Play testing link**, or the base plan isn't **Active**, or license tester not added. |
| iOS: "Cannot connect to iTunes Store" | **Paid Apps agreement** not Active, not signed into a **sandbox** tester, or IAP capability missing in Xcode. |
| Nothing works for a few hours after creating products | Normal store propagation delay — wait and retry. |

---

## 9. Go-live checklist

- [ ] Play: both subscriptions + base plans **Active**; app promoted from testing
      to Production (or in review).
- [ ] Apple: both subscriptions **Ready to Submit / Approved**; submitted **with**
      the app build for review (first IAP submission requires it).
- [ ] Paid Apps agreement **Active**; banking + tax complete.
- [ ] RevenueCat: entitlement `plus` has all products; `default` offering is
      **Current**.
- [ ] Real `goog_…` / `appl_…` keys pasted in `revenuecat_config.dart`.
- [ ] Tested a real (test) purchase on both platforms + Restore.
- [ ] (Optional) Remove the dev-unlock fallback in
      `upgrade_plus_screen.dart._subscribe` (the `if (pkg == null) setPlus(true)`
      branch) before the public release, so nobody can unlock Plus without paying
      if offerings ever fail to load.

---

### Files in the app you may touch
- `lib/Service/revenuecat_config.dart` — the **only** file you must edit (keys).
- `lib/Service/revenuecat_service.dart` — SDK logic (no change needed).
- `lib/View/Home/settings/upgrade_plus_screen.dart` — paywall (no change needed).
- `lib/main.dart` — initialization (no change needed).
