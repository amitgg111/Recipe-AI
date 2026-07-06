/**
 * OneSignal push notifications, gated by each recipient's Firestore
 * notification preferences (`users/{uid}.notificationPrefs`).
 *
 * Triggers (all check the toggle BEFORE sending — if OFF, nothing is sent):
 *   • onNewFollower  → "New followers"        toggle: newFollowers
 *   • onNewLike      → "Likes & comments"     toggle: likesAndComments
 *   • onNewComment   → "Likes & comments"     toggle: likesAndComments
 *
 * Required environment variables (set as secrets or in functions/.env):
 *   ONESIGNAL_APP_ID        – OneSignal App ID
 *   ONESIGNAL_REST_API_KEY  – OneSignal REST API Key (Settings → Keys & IDs)
 */
const {onDocumentCreated} = require("firebase-functions/v2/firestore");
const admin = require("firebase-admin");

if (!admin.apps.length) {
  admin.initializeApp();
}

const db = () => admin.firestore();

/**
 * Send a push to a single user IF their Firestore toggle is enabled.
 * @param {string} recipientUid  the user to notify
 * @param {string} prefKey       key under notificationPrefs to honour
 * @param {string} title         notification title
 * @param {string} message       notification body
 * @param {Object} data          optional custom data payload
 * @return {Promise<void>}
 */
async function sendIfEnabled(recipientUid, prefKey, title, message, data) {
  const appId = process.env.ONESIGNAL_APP_ID;
  const apiKey = process.env.ONESIGNAL_REST_API_KEY;
  if (!appId || !apiKey) {
    console.warn("OneSignal env vars missing — skipping push");
    return;
  }

  const snap = await db().collection("users").doc(recipientUid).get();
  if (!snap.exists) return;
  const user = snap.data() || {};
  const prefs = user.notificationPrefs || {};

  // Respect the recipient's preference — the whole point of this gate.
  if (prefs[prefKey] === false) return;

  // Target by external id (we call OneSignal.login(uid) on the client) with a
  // fallback to the stored subscription id.
  const body = {
    app_id: appId,
    headings: {en: title},
    contents: {en: message},
    data: data || {},
    target_channel: "push",
  };
  if (user.oneSignalId) {
    body.include_subscription_ids = [user.oneSignalId];
  } else {
    body.include_aliases = {external_id: [recipientUid]};
  }

  const res = await fetch("https://api.onesignal.com/notifications", {
    method: "POST",
    headers: {
      "Content-Type": "application/json; charset=utf-8",
      "Authorization": `Key ${apiKey}`,
    },
    body: JSON.stringify(body),
  });
  if (!res.ok) {
    const text = await res.text();
    console.error(`OneSignal push failed (${res.status}): ${text}`);
  }
}

/**
 * Resolve a user's display name for notification copy.
 * @param {string} uid user id
 * @return {Promise<string>} display name
 */
async function displayName(uid) {
  try {
    const s = await db().collection("users").doc(uid).get();
    const d = s.data() || {};
    return (d.name || d.username || "Someone").toString();
  } catch (e) {
    return "Someone";
  }
}

// ─────────────────────────────── New follower ──────────────────────────────
// Path: users/{targetUid}/followers/{followerUid}
exports.onNewFollower = onDocumentCreated(
    "users/{targetUid}/followers/{followerUid}",
    async (event) => {
      const {targetUid, followerUid} = event.params;
      if (targetUid === followerUid) return;
      const name = await displayName(followerUid);
      await sendIfEnabled(
          targetUid,
          "newFollowers",
          "New follower",
          `${name} started following you`,
          {type: "new_follower", followerUid},
      );
    },
);

// ─────────────────────────────── New like ──────────────────────────────────
// Path: users/{ownerId}/recipes/{recipeId}/likes/{likerUid}
exports.onNewLike = onDocumentCreated(
    "users/{ownerId}/recipes/{recipeId}/likes/{likerUid}",
    async (event) => {
      const {ownerId, recipeId, likerUid} = event.params;
      if (ownerId === likerUid) return;
      const name = await displayName(likerUid);
      await sendIfEnabled(
          ownerId,
          "likesAndComments",
          "New like",
          `${name} liked your recipe`,
          {type: "like", recipeId},
      );
    },
);

// ─────────────────────────────── New comment ───────────────────────────────
// Path: users/{ownerId}/recipes/{recipeId}/comments/{commentId}
exports.onNewComment = onDocumentCreated(
    "users/{ownerId}/recipes/{recipeId}/comments/{commentId}",
    async (event) => {
      const {ownerId, recipeId} = event.params;
      const data = event.data && event.data.data ? event.data.data() : {};
      const commenterUid = data.userId;
      if (!commenterUid || commenterUid === ownerId) return;
      const name = data.userName || (await displayName(commenterUid));
      await sendIfEnabled(
          ownerId,
          "likesAndComments",
          "New comment",
          `${name} commented on your recipe`,
          {type: "comment", recipeId},
      );
    },
);
