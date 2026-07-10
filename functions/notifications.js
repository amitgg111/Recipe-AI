/**
 * Social notifications — both the OneSignal PUSH (gated by each recipient's
 * `users/{uid}.notificationPrefs`) AND the in-app FEED document written to the
 * top-level `notifications` collection.
 *
 * Triggers (all skip self-actions and honour the push toggle):
 *   • onNewFollower  → "New followers"        toggle: newFollowers
 *   • onNewLike      → "Likes & comments"     toggle: likesAndComments
 *   • onNewComment   → "Likes & comments"     toggle: likesAndComments
 *
 * Notification docs are created ONLY here (trusted backend), so clients can be
 * denied create access in the security rules. Like/follow docs use a
 * deterministic id so re-liking or re-following updates the SAME document —
 * exactly one active notification, never a duplicate — while un-liking leaves
 * the existing doc untouched.
 *
 * Required environment variables (functions/.env or secrets):
 *   ONESIGNAL_APP_ID        – OneSignal App ID
 *   ONESIGNAL_REST_API_KEY  – OneSignal REST API Key
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
 * Resolve a user's name + avatar for notification copy / tiles.
 * @param {string} uid user id
 * @return {Promise<{name: string, photo: string}>} brief profile
 */
async function getUserBrief(uid) {
  try {
    const s = await db().collection("users").doc(uid).get();
    const d = s.data() || {};
    return {
      name: (d.name || d.username || "Someone").toString(),
      photo: (d.photoUrl || "").toString(),
    };
  } catch (e) {
    return {name: "Someone", photo: ""};
  }
}

/**
 * Resolve a recipe's title + image for like/comment notification tiles.
 * @param {string} ownerId recipe owner id
 * @param {string} recipeId recipe id
 * @return {Promise<{title: string, image: string}>} brief recipe
 */
async function getRecipeBrief(ownerId, recipeId) {
  try {
    const s = await db().collection("users").doc(ownerId)
        .collection("recipes").doc(recipeId).get();
    const d = s.data() || {};
    return {
      title: (d.title || "").toString(),
      image: (d.imageUrl || "").toString(),
    };
  } catch (e) {
    return {title: "", image: ""};
  }
}

/**
 * Create (or refresh) an in-app notification document. Never self-notifies.
 * A deterministic [docId] makes like/follow notifications idempotent (one
 * active doc per relationship); pass null to auto-generate (comments).
 * @param {Object} n notification fields
 * @return {Promise<void>}
 */
async function writeNotification(n) {
  if (!n.receiverUserId || !n.senderUserId) return;
  if (n.receiverUserId === n.senderUserId) return; // never notify yourself

  const col = db().collection("notifications");
  const ref = n.docId ? col.doc(n.docId) : col.doc();
  await ref.set({
    id: ref.id,
    receiverUserId: n.receiverUserId,
    senderUserId: n.senderUserId,
    type: n.type,
    recipeId: n.recipeId || null,
    commentId: n.commentId || null,
    title: n.title,
    message: n.message,
    senderName: n.sender.name,
    senderPhoto: n.sender.photo,
    recipeImage: n.recipe ? n.recipe.image : null,
    recipeTitle: n.recipe ? n.recipe.title : null,
    isRead: false,
    createdAt: admin.firestore.FieldValue.serverTimestamp(),
  });
}

// ─────────────────────────────── New follower ──────────────────────────────
// Path: users/{targetUid}/followers/{followerUid}
exports.onNewFollower = onDocumentCreated(
    "users/{targetUid}/followers/{followerUid}",
    async (event) => {
      const {targetUid, followerUid} = event.params;
      if (targetUid === followerUid) return;
      const sender = await getUserBrief(followerUid);
      await Promise.all([
        writeNotification({
          docId: `follow_${targetUid}_${followerUid}`,
          receiverUserId: targetUid,
          senderUserId: followerUid,
          type: "follow",
          title: "New Follower",
          message: `${sender.name} started following you.`,
          sender,
        }),
        sendIfEnabled(
            targetUid,
            "newFollowers",
            "New Follower",
            `👤 ${sender.name} started following you`,
            {type: "new_follower", followerUid},
        ),
      ]);
    },
);

// ─────────────────────────────── New like ──────────────────────────────────
// Path: users/{ownerId}/recipes/{recipeId}/likes/{likerUid}
exports.onNewLike = onDocumentCreated(
    "users/{ownerId}/recipes/{recipeId}/likes/{likerUid}",
    async (event) => {
      const {ownerId, recipeId, likerUid} = event.params;
      if (ownerId === likerUid) return;
      const [sender, recipe] = await Promise.all([
        getUserBrief(likerUid),
        getRecipeBrief(ownerId, recipeId),
      ]);
      await Promise.all([
        writeNotification({
          // Deterministic → re-liking never creates a duplicate.
          docId: `like_${ownerId}_${recipeId}_${likerUid}`,
          receiverUserId: ownerId,
          senderUserId: likerUid,
          type: "like",
          recipeId,
          title: "New Like",
          message: `${sender.name} liked your recipe.`,
          sender,
          recipe,
        }),
        sendIfEnabled(
            ownerId,
            "likesAndComments",
            "New Like",
            `❤️ ${sender.name} liked your recipe`,
            {type: "like", recipeId},
        ),
      ]);
    },
);

// ─────────────────────────────── New comment ───────────────────────────────
// Path: users/{ownerId}/recipes/{recipeId}/comments/{commentId}
exports.onNewComment = onDocumentCreated(
    "users/{ownerId}/recipes/{recipeId}/comments/{commentId}",
    async (event) => {
      const {ownerId, recipeId, commentId} = event.params;
      const data = event.data && event.data.data ? event.data.data() : {};
      const commenterUid = data.userId;
      if (!commenterUid || commenterUid === ownerId) return;
      const [sender, recipe] = await Promise.all([
        getUserBrief(commenterUid),
        getRecipeBrief(ownerId, recipeId),
      ]);
      // Prefer the name stored on the comment; fall back to the profile.
      const name = (data.userName || sender.name).toString();
      const senderWithName = {name, photo: sender.photo};
      await Promise.all([
        writeNotification({
          docId: `comment_${commentId}`,
          receiverUserId: ownerId,
          senderUserId: commenterUid,
          type: "comment",
          recipeId,
          commentId,
          title: "New Comment",
          message: `${name} commented on your recipe.`,
          sender: senderWithName,
          recipe,
        }),
        sendIfEnabled(
            ownerId,
            "likesAndComments",
            "New Comment",
            `💬 ${name} commented on your recipe`,
            {type: "comment", recipeId, commentId},
        ),
      ]);
    },
);
