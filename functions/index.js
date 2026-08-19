const {onCall, HttpsError} = require("firebase-functions/v2/https");
const {setGlobalOptions} = require("firebase-functions/v2");
const {GoogleGenAI} = require("@google/genai");
const admin = require("firebase-admin");
const crypto = require("crypto");
const sharp = require("sharp");
const ffmpegPath = require("ffmpeg-static");
const {spawn} = require("child_process");
const fs = require("fs/promises");
const os = require("os");
const path = require("path");

if (!admin.apps.length) {
  admin.initializeApp();
}

// Notification push triggers (gated by each user's Firestore prefs).
Object.assign(exports, require("./notifications"));

setGlobalOptions({
  maxInstances: 10,
});

const getAI = () => {
  return new GoogleGenAI({
    apiKey: process.env.GEMINI_API_KEY,
  });
};

// ── Cost & abuse controls ───────────────────────────────────────────────────

/**
 * Every AI callable requires a signed-in user and is capped per uid per day.
 * The cap is deliberately far above any legitimate use (Plus included): its
 * job is to bound a stolen-client or scripted loop, not to meter real users —
 * the weekly credit UX stays in the app.
 * @param {Object} request onCall request.
 * @return {Promise<void>}
 */
async function requireAuthAndCap(request) {
  if (!request.auth || !request.auth.uid) {
    throw new HttpsError("unauthenticated", "Sign in to use AI features.");
  }
  const uid = request.auth.uid;
  const day = new Date().toISOString().slice(0, 10).replace(/-/g, "");
  const ref = admin.firestore().collection("usage_daily")
      .doc(`${uid}_${day}`);
  await admin.firestore().runTransaction(async (tx) => {
    const snap = await tx.get(ref);
    const used = (snap.exists && snap.data().count) || 0;
    if (used >= 60) {
      throw new HttpsError(
          "resource-exhausted",
          "Daily AI limit reached. Please try again tomorrow.",
      );
    }
    tx.set(ref, {
      count: used + 1,
      updatedAt: admin.firestore.FieldValue.serverTimestamp(),
    }, {merge: true});
  });
}

/**
 * Enforces the app's real weekly credit system server-side, against the
 * SAME users/{uid} fields the app maintains (isPlus / freeCredits /
 * creditsResetAt). Validate-only by design: the client's consumeCredit()
 * transaction remains the single place a credit is decremented, so nothing
 * is ever charged twice — this simply refuses AI work for a non-Plus user
 * whose 5 weekly credits are spent, even if the client-side check was
 * bypassed or the app reinstalled.
 *
 * Deliberately permissive on edge states (missing doc, missing fields, or
 * an expired week the client hasn't replenished yet): blocking a paying or
 * brand-new user is worse than letting one extra call through — the 60/day
 * cap in requireAuthAndCap still bounds the worst case.
 * @param {string} uid Signed-in user id.
 * @return {Promise<void>}
 */
async function enforceImportCredit(uid) {
  let data = null;
  try {
    const doc = await admin.firestore().collection("users").doc(uid).get();
    data = doc.exists ? (doc.data() || {}) : null;
  } catch (e) {
    console.error("enforceImportCredit read failed:", e.message);
    return;
  }
  if (!data) return;
  if (data.isPlus === true) return;
  if (!("freeCredits" in data)) return;
  const credits = Number(data.freeCredits);
  if (!Number.isFinite(credits)) return;
  const resetAt = data.creditsResetAt;
  const resetDate = resetAt && typeof resetAt.toDate === "function" ?
    resetAt.toDate() : null;
  if (resetDate && Date.now() > resetDate.getTime()) {
    // Week rolled over; the client replenishes to 5 on next open.
    return;
  }
  if (credits <= 0) {
    throw new HttpsError(
        "resource-exhausted",
        "You've used all your free imports for this week. " +
        "Upgrade to Plus for unlimited imports.",
    );
  }
}

/**
 * One-line token accounting per model call, so spend per path is measured
 * instead of estimated. Read it with:
 *   firebase functions:log | grep "\[tokens\]"
 * @param {string} tag Path label.
 * @param {Object} response generateContent response.
 */
function logTokens(tag, response) {
  const u = (response && response.usageMetadata) || {};
  console.log(
      `[tokens] ${tag}`,
      "in=", u.promptTokenCount || 0,
      "think=", u.thoughtsTokenCount || 0,
      "out=", u.candidatesTokenCount || 0,
      "total=", u.totalTokenCount || 0,
  );
}

/**
 * @param {string} title Dish title.
 * @return {string} Registry slug.
 */
function slugifyDish(title) {
  return String(title || "").toLowerCase()
      .replace(/[^a-z0-9]+/g, "-")
      .replace(/(^-|-$)/g, "")
      .slice(0, 80);
}

/**
 * The dish-image registry: every image this backend stores (generated,
 * mirrored thumbnail, or video frame) is recorded under its dish slug, and
 * every request for an image checks here FIRST. "Paneer Butter Masala"
 * imported a hundred times costs one image, ever — the catalog becomes its
 * own stock library and the saving compounds forever.
 * @param {string} slug Dish slug.
 * @return {Promise<string>} Existing image URL, or "".
 */
async function lookupDishImage(slug) {
  if (!slug) return "";
  try {
    const doc = await admin.firestore()
        .collection("dish_images").doc(slug).get();
    return (doc.exists && doc.data().url) || "";
  } catch (e) {
    return "";
  }
}

/**
 * @param {string} slug Dish slug.
 * @param {string} url Stored image URL.
 * @param {string} source generated|mirrored|frame.
 * @return {Promise<void>}
 */
async function registerDishImage(slug, url, source) {
  if (!slug || !url) return;
  try {
    await admin.firestore().collection("dish_images").doc(slug).set({
      url,
      source,
      createdAt: admin.firestore.FieldValue.serverTimestamp(),
    }, {merge: true});
  } catch (e) {
    console.error("dish_images write failed:", e.message);
  }
}

/**
 * Re-encode any image buffer to a 1020px JPEG and store it under
 * recipe_images/ with a download token — the same shape the client's
 * Storage-URL allowlist accepts.
 * @param {Buffer} buffer Raw image bytes.
 * @param {string} seed Filename seed.
 * @return {Promise<string>} Public URL, or "".
 */
async function storeJpegBuffer(buffer, seed) {
  try {
    const jpeg = await sharp(buffer)
        .resize({width: 1020, withoutEnlargement: true})
        .jpeg({quality: 80, mozjpeg: true})
        .toBuffer();
    const bucket = admin.storage().bucket();
    const safeSeed = slugifyDish(seed) || "recipe";
    const fileName =
      `recipe_images/${safeSeed}-${Date.now()}-` +
      `${Math.random().toString(36).slice(2, 8)}.jpg`;
    const file = bucket.file(fileName);
    const downloadToken = crypto.randomUUID();
    await file.save(jpeg, {
      metadata: {
        contentType: "image/jpeg",
        cacheControl: "public, max-age=31536000",
        metadata: {firebaseStorageDownloadTokens: downloadToken},
      },
    });
    return `https://firebasestorage.googleapis.com/v0/b/${bucket.name}` +
      `/o/${encodeURIComponent(fileName)}?alt=media&token=${downloadToken}`;
  } catch (e) {
    console.error("storeJpegBuffer failed:", e.message);
    return "";
  }
}

/**
 * Mirror a social post's real cover image (og:image) into our Storage.
 * Platform CDN URLs are short-lived signed links — hotlinking them breaks in
 * days — and a mirrored copy also passes the client's allowlist, so no AI
 * image is generated at all. Free beats generated.
 * @param {string} url Remote image URL.
 * @param {string} seed Filename seed.
 * @return {Promise<string>} Our Storage URL, or "".
 */
async function mirrorRemoteImage(url, seed) {
  try {
    const res = await fetch(url, {
      headers: {
        "User-Agent": "facebookexternalhit/1.1 " +
          "(+http://www.facebook.com/externalhit_uatext.php)",
      },
      redirect: "follow",
      signal: AbortSignal.timeout(10000),
    });
    if (!res.ok) return "";
    const type = String(res.headers.get("content-type") || "");
    if (!type.startsWith("image/")) return "";
    const buffer = Buffer.from(await res.arrayBuffer());
    const meta = await sharp(buffer).metadata();
    // Reject tiny favicons/badges — a real cover frame is a real photo.
    if (!meta.width || meta.width < 300 || !meta.height) return "";
    return await storeJpegBuffer(buffer, seed);
  } catch (e) {
    console.error("mirrorRemoteImage failed:", e.message);
    return "";
  }
}

/**
 * Grab one frame from an uploaded cooking video with ffmpeg — the actual
 * dish, for $0, instead of an AI's imagination for $0.04.
 * @param {string} base64 Video bytes, base64.
 * @param {string} seed Filename seed.
 * @return {Promise<string>} Our Storage URL, or "".
 */
async function extractVideoFrame(base64, seed) {
  const dir = await fs.mkdtemp(path.join(os.tmpdir(), "vid-"));
  const inFile = path.join(dir, "in.mp4");
  const outFile = path.join(dir, "frame.jpg");
  try {
    await fs.writeFile(inFile, Buffer.from(base64, "base64"));
    await new Promise((resolve, reject) => {
      const p = spawn(ffmpegPath, [
        "-ss", "1", "-i", inFile,
        "-frames:v", "1", "-q:v", "3", "-y", outFile,
      ]);
      p.on("error", reject);
      p.on("close", (code) => {
        if (code === 0) resolve();
        else reject(new Error(`ffmpeg exit ${code}`));
      });
    });
    const frame = await fs.readFile(outFile);
    return await storeJpegBuffer(frame, seed);
  } catch (e) {
    console.error("extractVideoFrame failed:", e.message);
    return "";
  } finally {
    fs.rm(dir, {recursive: true, force: true}).catch(() => {});
  }
}

const RECIPE_RESPONSE_SCHEMA = {
  type: "OBJECT",
  properties: {
    // False when the source image/content is not a food/recipe at all — the
    // client then aborts the import instead of saving a made-up recipe.
    isRecipe: {type: "BOOLEAN"},
    title: {type: "STRING"},
    description: {type: "STRING"},
    imageUrl: {type: "STRING"},
    sourceUrl: {type: "STRING"},
    prepTime: {type: "STRING"},
    cookTime: {type: "STRING"},
    totalTime: {type: "STRING"},
    servings: {type: "STRING"},
    category: {type: "STRING"},
    cuisine: {type: "STRING"},
    imagePrompt: {
      type: "STRING",
      description:
      "Generate ONE detailed, self-contained prompt for an AI food " +
      "image generator. The prompt must recreate the EXACT finished " +
      "dish from this recipe with maximum visual accuracy. Describe " +
      "the dish in enough detail that another AI can generate a " +
      "nearly identical result. " +

      "Include ALL visible characteristics: exact food colour, " +
      "browning level, sauce or gravy thickness, texture, " +
      "crispiness, moisture, visible ingredients, ingredient " +
      "placement, garnish type and exact garnish placement, " +
      "portion size, food shape, layering, height, arrangement, " +
      "serving bowl or plate type, plate colour, plate material, " +
      "camera angle, zoom level, framing and lighting. " +

      "The food must fill about 90% of the frame and show ONLY one " +
      "finished dish. " +

      "Do NOT redesign the recipe. Do NOT improve presentation. " +
      "Do NOT change colours. Do NOT change garnish. Do NOT change " +
      "ingredient proportions. Do NOT add extra ingredients. " +
      "Do NOT change the serving vessel. Do NOT add side dishes, " +
      "drinks, cutlery, napkins or decorations. " +

      "Food only. Never include people, hands, tables, " +
      "restaurants, kitchens, scenery, landscapes, buildings, " +
      "text, logos or watermarks. " +

      "Always end the prompt with: ultra realistic DSLR " +
      "professional food photography, macro food details, " +
      "authentic colours, shallow depth of field, natural " +
      "lighting, 4K, 45-degree close-up hero shot.",
    },
    keywords: {type: "ARRAY", items: {type: "STRING"}},
    ingredients: {type: "ARRAY", items: {type: "STRING"}},
    instructions: {type: "ARRAY", items: {type: "STRING"}},
    ingredientSections: {
      type: "ARRAY",
      items: {
        type: "OBJECT",
        properties: {
          name: {type: "STRING"},
          items: {type: "ARRAY", items: {type: "STRING"}},
        },
        required: ["name", "items"],
      },
    },
    instructionSections: {
      type: "ARRAY",
      items: {
        type: "OBJECT",
        properties: {
          name: {type: "STRING"},
          steps: {type: "ARRAY", items: {type: "STRING"}},
        },
        required: ["name", "steps"],
      },
    },
    nutrition: {
      type: "OBJECT",
      properties: {
        calories: {type: "STRING"},
        protein: {type: "STRING"},
        carbs: {type: "STRING"},
        fat: {type: "STRING"},
      },
      required: ["calories", "protein", "carbs", "fat"],
    },
  },
  required: [
    // Without this the model may omit isRecipe entirely (OpenAPI semantics:
    // unlisted properties are optional), and `rawRecipe.isRecipe === false`
    // evaluates undefined === false -> the non-recipe guard silently never
    // fires. This was the "imports a hallucinated recipe" bug.
    "isRecipe",
    "title",
    "description",
    "imageUrl",
    "sourceUrl",
    "prepTime",
    "cookTime",
    "totalTime",
    "servings",
    "category",
    "cuisine",
    "imagePrompt",
    "keywords",
    "ingredients",
    "instructions",
    "ingredientSections",
    "instructionSections",
    "nutrition",
  ],
};

// analyzeRecipeImage uses the USER'S OWN PHOTO, so paying the model to
// author a ~450-word image-generation prompt — schema description on input,
// long generated string on output — was pure waste on the app's highest-
// volume path. Identical schema, minus that one field.
const RECIPE_PHOTO_SCHEMA = (() => {
  const clone = JSON.parse(JSON.stringify(RECIPE_RESPONSE_SCHEMA));
  delete clone.properties.imagePrompt;
  clone.required = clone.required.filter((k) => k !== "imagePrompt");
  return clone;
})();

/**
 * @param {unknown} item
 * @return {string}
 */
function normalizeIngredientItem(item) {
  if (typeof item === "string") return item.trim();
  if (item && typeof item === "object") {
    const obj = /** @type {Record<string, unknown>} */ (item);
    const parts = [
      obj.quantity || obj.amount || obj.qty || "",
      obj.unit || "",
      obj.name || obj.ingredient || obj.item || obj.text || "",
    ]
        .map((p) => String(p).trim())
        .filter(Boolean);
    if (parts.length > 0) return parts.join(" ");
  }
  return String(item || "").trim();
}

/**
 * @param {unknown} item
 * @return {string}
 */
function normalizeInstructionStep(item) {
  if (typeof item === "string") {
    return item
        .replace(/^\s*(step\s*\d+[.:]?\s*|\d+[.):]\s*|[-•*]\s*)/i, "")
        .trim();
  }
  if (item && typeof item === "object") {
    const obj = /** @type {Record<string, unknown>} */ (item);
    const text = obj.text || obj.step || obj.instruction || obj.name || "";
    return normalizeInstructionStep(String(text));
  }
  return String(item || "").trim();
}

/**
 * @param {string} text
 * @return {boolean}
 */
function isSectionHeader(text) {
  const t = text.trim();
  if (!t) return false;
  if (/^for\b/i.test(t) && (t.endsWith(":") || t.split(" ").length <= 6)) {
    return !/\d/.test(t);
  }
  if (t.endsWith(":") && t.length <= 80 && !/\d/.test(t)) return true;
  if (t === t.toUpperCase() && t.length <= 50 && !/\d/.test(t)) return true;
  return false;
}

/**
 * @param {string[]} flatList
 * @return {{name: string, items: string[]}[]}
 */
function detectIngredientSections(flatList) {
  const sections = [];
  let currentName = "";
  let currentItems = [];

  const flush = () => {
    if (currentItems.length === 0) return;
    sections.push({name: currentName, items: [...currentItems]});
    currentItems = [];
  };

  for (const item of flatList) {
    if (isSectionHeader(item)) {
      flush();
      currentName = item.endsWith(":") ?
        item.slice(0, -1).trim() :
        item.trim();
    } else {
      currentItems.push(item);
    }
  }
  flush();

  if (
    sections.length > 1 ||
    (sections.length === 1 && sections[0].name)
  ) {
    return sections;
  }
  return [{name: "", items: flatList}];
}

/**
 * @param {string[]} flatList
 * @return {{name: string, steps: string[]}[]}
 */
function detectInstructionSections(flatList) {
  const sections = [];
  let currentName = "";
  let currentSteps = [];

  const flush = () => {
    if (currentSteps.length === 0) return;
    sections.push({name: currentName, steps: [...currentSteps]});
    currentSteps = [];
  };

  for (const step of flatList) {
    if (isSectionHeader(step)) {
      flush();
      currentName = step.endsWith(":") ?
        step.slice(0, -1).trim() :
        step.trim();
    } else {
      currentSteps.push(step);
    }
  }
  flush();

  if (
    sections.length > 1 ||
    (sections.length === 1 && sections[0].name)
  ) {
    return sections;
  }
  return [{name: "", steps: flatList}];
}

/**
 * @param {Record<string, unknown>} raw
 * @return {Record<string, unknown>}
 */
function normalizeRecipe(raw) {
  const recipe = {...raw};
  const decodeHtmlEntities = (value) =>
    String(value || "")
        .trim()
        .replaceAll("&amp;", "&")
        .replaceAll("&#x2F;", "/")
        .replaceAll("&#47;", "/")
        .replaceAll("&quot;", "\"")
        .replaceAll("&#39;", "'");

  recipe.title = String(
      recipe.title || recipe.recipeName || recipe.name || "",
  ).trim();

  recipe.description = String(recipe.description || "").trim();
  recipe.imageUrl = decodeHtmlEntities(recipe.imageUrl);
  recipe.sourceUrl = String(recipe.sourceUrl || "AI Generated").trim();
  recipe.prepTime = String(recipe.prepTime || "").trim();
  recipe.cookTime = String(recipe.cookTime || "").trim();
  recipe.totalTime = String(recipe.totalTime || "").trim();
  recipe.servings = String(recipe.servings || "4").trim();
  recipe.category = String(recipe.category || "").trim();
  recipe.cuisine = String(recipe.cuisine || "").trim();
  recipe.imagePrompt = String(recipe.imagePrompt || "").trim();

  recipe.keywords = Array.isArray(recipe.keywords) ?
    recipe.keywords.map((k) => String(k).trim()).filter(Boolean) :
    [];

  let ingredientSections = Array.isArray(recipe.ingredientSections) ?
    recipe.ingredientSections.map((section) => {
      const s = /** @type {Record<string, unknown>} */ (section || {});
      return {
        name: String(s.name || s.title || s.heading || "").trim(),
        items: (Array.isArray(s.items) ? s.items : [])
            .map(normalizeIngredientItem)
            .filter(Boolean),
      };
    }).filter((s) => s.items.length > 0) :
    [];

  const flatIngredients = (Array.isArray(recipe.ingredients) ?
    recipe.ingredients :
    [])
      .map(normalizeIngredientItem)
      .filter(Boolean);

  if (ingredientSections.length === 0 && flatIngredients.length > 0) {
    ingredientSections = detectIngredientSections(flatIngredients);
  }

  if (ingredientSections.length === 0) {
    ingredientSections = [{name: "Main Recipe", items: flatIngredients}];
  }

  recipe.ingredientSections = ingredientSections;
  recipe.ingredients = ingredientSections.flatMap((s) => s.items);

  let instructionSections = Array.isArray(recipe.instructionSections) ?
    recipe.instructionSections.map((section) => {
      const s = /** @type {Record<string, unknown>} */ (section || {});
      return {
        name: String(s.name || s.title || s.heading || "").trim(),
        steps: (Array.isArray(s.steps) ? s.steps : [])
            .map(normalizeInstructionStep)
            .filter(Boolean),
      };
    }).filter((s) => s.steps.length > 0) :
    [];

  const flatInstructions = (Array.isArray(recipe.instructions) ?
    recipe.instructions :
    [])
      .map(normalizeInstructionStep)
      .filter(Boolean);

  if (instructionSections.length === 0 && flatInstructions.length > 0) {
    instructionSections = detectInstructionSections(flatInstructions);
  }

  if (instructionSections.length === 0) {
    instructionSections = [{name: "Main Recipe", steps: flatInstructions}];
  }

  recipe.instructionSections = instructionSections;
  recipe.instructions = instructionSections.flatMap((s) => s.steps);

  recipe.nutrition = recipe.nutrition && typeof recipe.nutrition === "object" ?
    {
      calories: String(recipe.nutrition.calories || "").trim(),
      protein: String(recipe.nutrition.protein || "").trim(),
      carbs: String(recipe.nutrition.carbs || "").trim(),
      fat: String(recipe.nutrition.fat || "").trim(),
    } :
    {calories: "", protein: "", carbs: "", fat: ""};

  return recipe;
}

// ── AI Image Generation ──────────────────────────────────────────────────────
// Generates a real food photo for a recipe using Imagen (via @google/genai),
// uploads it to Firebase Storage, and returns a public URL. This replaces the
// old approach of asking Gemini's text model to "guess" an Unsplash/Pexels
// URL, which frequently produced broken or non-existent links.

/**
 * Fallback image prompt — used ONLY if Gemini did not supply
 * `recipe.imagePrompt`. Kept short and food-anchored; the primary prompt is
 * authored by Gemini alongside the recipe (RECIPE_RESPONSE_SCHEMA.imagePrompt),
 * so there is no separate prompt-building pipeline.
 * @param {Object} recipe Recipe object.
 * @return {string} Imagen prompt.
 */
function buildImagePrompt(recipe) {
  const r = recipe || {};
  const title = String(r.title || "dish").trim();
  const cuisine = String(r.cuisine || "").trim();
  const desc = String(r.description || "").trim();
  const cuisineTag = cuisine ? ` (${cuisine})` : "";
  return [
    "Ultra-realistic close-up FOOD PHOTOGRAPH of the finished, cooked",
    `dish "${title}"${cuisineTag}, plated and filling almost the entire`,
    "frame. This is food photography ONLY — never a landscape, scenery,",
    "nature, people, buildings or any other dish. Generate exactly this",
    `dish. ${desc}`,
    "Professional restaurant-quality DSLR photo, 4K, natural lighting,",
    "45-degree hero angle, shallow depth of field, authentic colours,",
    "no text, no watermark, no logo, no illustration, no cartoon.",
  ].join("\n").trim();
}

/**
 * Builds an image prompt straight from a social-media caption, for the PARALLEL
 * import path where the image is generated ALONGSIDE recipe extraction (so it
 * doesn't wait for the recipe). The caption names the dish, so the image model
 * identifies and renders the correct dish — no separate title needed.
 * @param {string} caption Social post caption.
 * @return {string} Image prompt.
 */
function buildCaptionImagePrompt(caption) {
  const c = String(caption || "")
      .replace(/\s+/g, " ")
      .trim()
      .slice(0, 1000);
  return [
    "The finished, plated dish that this social-media recipe caption is about.",
    "Identify the exact dish named in the caption and show ONLY that dish —",
    "never text, people, hands, packaging, a collage, or a different dish.",
    `CAPTION: ${c}`,
  ].join("\n");
}

/**
 * Generates an image with Imagen and stores it in Firebase Storage.
 * Returns "" (empty string) on any failure so callers can fall back safely.
 *
 * @param {Object} ai GoogleGenAI client instance.
 * @param {Object} recipe Recipe object.
 * @return {Promise<string>} Public image URL, or "" on failure.
 */
async function generateAndStoreRecipeImage(ai, recipe) {
  try {
    if (!recipe || !recipe.title) return "";

    // Free before paid: if ANY image for this dish already exists in the
    // registry (generated, mirrored or a video frame), reuse it.
    const dishSlug = slugifyDish(recipe.title);
    const existing = await lookupDishImage(dishSlug);
    if (existing) {
      console.log("[dish_images] reuse:", dishSlug);
      return existing;
    }

    // Prefer the image prompt Gemini authored alongside the recipe (it knows
    // the exact dish); fall back to a short built prompt. A fixed food anchor
    // is prepended so Imagen can never drift to a non-food subject.
    const base = String(recipe.imagePrompt || "").trim() ||
      buildImagePrompt(recipe);
    const prompt = `
Generate ONLY a photorealistic image of the EXACT finished recipe described
below.

CRITICAL REQUIREMENTS

- Recreate the exact cooked dish.
- Do NOT redesign the recipe.
- Do NOT improve the presentation.
- Do NOT invent ingredients.
- Do NOT change colours.
- Do NOT change garnish.
- Do NOT change plating.
- Do NOT change bowl, plate or serving vessel.
- Do NOT change sauce consistency.
- Do NOT change food texture.
- Do NOT change ingredient proportions.
- The generated dish must look as close as possible to the original recipe
  description.

FOOD COMPOSITION

- Show ONLY one finished dish.
- Fill approximately 90% of the frame with the food.
- Close-up hero shot.
- 45-degree camera angle.
- Natural shadows.
- Realistic reflections.
- Restaurant-quality plating only if the recipe explicitly describes it.
- Authentic homemade appearance.
- No extra side dishes.
- No drinks.
- No cutlery.
- No napkins.
- No table decorations.
- No flowers.
- No hands.
- No people.
- No background objects.

IMAGE STYLE

- Ultra realistic
- DSLR
- Professional food photography
- Macro food details
- Natural lighting
- High dynamic range
- Extremely realistic textures
- 4K
- Sharp focus
- No illustration
- No CGI
- No cartoon
- No painting
- No text
- No logo
- No watermark

Recipe Description:

${base}
`.trim();
    // NOTE: imagen-4.0-generate-001 was removed by Google (404 NOT_FOUND —
    // "no longer available"). Image generation now runs through the Gemini
    // image model via generateContent with an IMAGE response modality; the
    // picture comes back as an inline data part, not a generatedImages array.
    const response = await ai.models.generateContent({
      model: "gemini-3.1-flash-image",
      contents: prompt,
      config: {
        responseModalities: ["IMAGE"],
      },
    });

    logTokens("image-gen", response);
    const parts =
      (response &&
        response.candidates &&
        response.candidates[0] &&
        response.candidates[0].content &&
        response.candidates[0].content.parts) ||
      [];
    let imageBytes = "";
    for (const part of parts) {
      if (part && part.inlineData && part.inlineData.data) {
        imageBytes = part.inlineData.data;
        break;
      }
    }

    if (!imageBytes) {
      console.error("Image generation returned no image bytes.");
      return "";
    }

    let buffer = Buffer.from(imageBytes, "base64");
    // The image model returns a PNG that is typically 1-2MB. Re-encode to a
    // 1020px-wide JPEG (~100-150KB) before storing — the card renders at
    // ~1000px, so nothing visible is lost, and every future feed load
    // downloads a tenth of the bytes. Failure falls back to the raw PNG.
    try {
      buffer = await sharp(buffer)
          .resize({width: 1020, withoutEnlargement: true})
          .jpeg({quality: 80, mozjpeg: true})
          .toBuffer();
    } catch (e) {
      console.error("Generated-image JPEG re-encode failed, storing PNG:", e);
    }
    const bucket = admin.storage().bucket();
    const safeSeed = recipe.title
        .toLowerCase()
        .replace(/[^a-z0-9]+/g, "-")
        .replace(/(^-|-$)/g, "")
        .slice(0, 60) || "recipe";
    const fileName =
      `recipe_images/${safeSeed}-${Date.now()}-` +
      `${Math.random().toString(36).slice(2, 8)}.jpg`;
    const file = bucket.file(fileName);

    const downloadToken = crypto.randomUUID();

    await file.save(buffer, {
      metadata: {
        contentType: "image/jpeg",
        cacheControl: "public, max-age=31536000",
        metadata: {
          firebaseStorageDownloadTokens: downloadToken,
        },
      },
    });

    const publicUrl =
      `https://firebasestorage.googleapis.com/v0/b/${bucket.name}` +
      `/o/${encodeURIComponent(fileName)}?alt=media&token=${downloadToken}`;
    await registerDishImage(dishSlug, publicUrl, "generated");
    return publicUrl;
  } catch (error) {
    console.error("generateAndStoreRecipeImage failed:", error);
    return "";
  }
}

const RECIPE_IMAGE_PROMPT = `
  You are a world-class chef and recipe developer.

  STEP 0 — IS THIS A FOOD / RECIPE IMAGE?
  First decide whether the image actually shows food: a cooked dish, plated
  food, a food or drink item, raw ingredients, or a written/printed recipe.
  - If it does NOT (e.g. a person or selfie, an animal, a landscape, a building,
    a screenshot of non-food content, a random object, or a document that is not
    a recipe), return EXACTLY:
    {"isRecipe": false, "title": "", "description": "", "ingredients": [],
     "instructions": [], "ingredientSections": [], "instructionSections": []}
    and DO NOT invent, guess, or hallucinate a recipe.
  - Only if it clearly shows food or a recipe, set "isRecipe": true and produce
    the full structured recipe described below.

  Analyze the food image and generate the most accurate complete recipe.

  CRITICAL — SECTION STRUCTURE (MUST FOLLOW):
- ingredientSections and instructionSections are the PRIMARY structure.
- ALWAYS split multi-component dishes into separate named sections.
- NEVER put all ingredients in one section when the dish has distinct parts.
- NEVER put all steps in one section when the dish has distinct cooking phases.

  Examples of REQUIRED section splits:

  Veg Manchurian:
  ingredientSections: [
    {"name":"For Manchurian Balls","items":[
      "1¼ cup cabbage finely chopped","½ cup carrot grated", "..."
    ]},
    {"name":"For Manchurian Sauce","items":[
      "1½ tablespoons oil","¾ tablespoon garlic", "..."
    ]}
  ]
  instructionSections: [
    {"name":"Prepare Manchurian Balls","steps":[
      "Mix vegetables...", "Shape into balls...", "..."
    ]},
    {"name":"Prepare Manchurian Sauce","steps":[
      "Heat oil...", "Add sauces...", "..."
    ]},
    {"name":"Combine and Serve","steps":[
      "Toss balls in sauce...", "..."
    ]}
  ]
NUTRITION:
- Calculate approximate nutrition based on all ingredients and quantities.
- Return values for the complete recipe per serving.
- Estimate:
  calories in kcal
  protein in grams
  carbs in grams
  fat in grams
- Use realistic culinary nutrition estimates.
  Burger: sections for Patty, Sauce, Assembly.
  Pizza: sections for Dough, Sauce, Toppings.
  Cake: sections for Batter, Frosting.

  For simple single-component dishes use one section named "Main Recipe".

  INGREDIENT FORMAT:
  - Every item MUST include quantity: "1 cup rice", "2 tablespoons oil"
  - Minimum 8 ingredients total.

  INSTRUCTION FORMAT:
  - Each step is one clear actionable sentence.
  - Minimum 5 steps total.
  - No step numbers in the text.

  FLAT LISTS:
  - "ingredients" = ALL items from every ingredientSection combined in order.
  - "instructions" = ALL steps from every instructionSection combined in order.

  TITLE:
  - Use proper dish name: "Veg Manchurian", "Paneer Butter Masala", etc.

  OTHER:
  - servings: numeric string only, e.g. "4"
  - prepTime/cookTime/totalTime: e.g. "20 mins", "30 mins", "50 mins"
  - category: Breakfast|Lunch|Dinner|Snack|Dessert|Beverage
  - keywords: 8-15 relevant tags
  - sourceUrl: "AI Generated"
  - imageUrl: leave empty string
  `;

// TEXT PROMPT
exports.askGemini = onCall(
    {
      secrets: ["GEMINI_API_KEY"],
    },
    async (request) => {
      const startTime = Date.now();

      try {
        await requireAuthAndCap(request);
        console.log("API CALL STARTED");

        const prompt = request.data.prompt;

        if (!prompt) {
          throw new Error("Prompt is required");
        }

        const ai = getAI();

        const response = await ai.models.generateContent({
          model: "gemini-3.5-flash-lite",
          contents: prompt,
          config: {
            maxOutputTokens: 2000,
            temperature: 0.7,
          },
        });

        logTokens("askGemini", response);
        const responseTime = Date.now() - startTime;

        console.log(`API RESPONSE TIME: ${responseTime} ms`);
        console.log(
            `API RESPONSE TIME: ${(responseTime / 1000).toFixed(2)} seconds`,
        );

        return {
          success: true,
          text: response.text,
        };
      } catch (error) {
        console.error("API ERROR:", error);

        return {
          success: false,
          error: error.message,
        };
      }
    },
);

const RECIPE_SOCIAL_PROMPT = `
You are a world-class chef and recipe developer.

You are given a social media post: its caption/text, page metadata, and — when
available — the post's actual cover image is attached alongside this prompt.
The content may come from Instagram, Facebook, TikTok, YouTube, or similar.

STEP 0 — IS THIS ACTUALLY A FOOD / RECIPE POST?
Decide whether the caption text and the attached image genuinely show or
describe a food or drink recipe (a cooked dish, food being prepared, or a
recipe written out).
- If it is clearly NOT food/recipe content (a generic vlog, selfie, meme,
  product ad, landscape, or unrelated post), return EXACTLY:
  {"isRecipe": false, "title": "", "description": "", "ingredients": [],
   "instructions": [], "ingredientSections": [], "instructionSections": []}
  and DO NOT invent, guess, or hallucinate a recipe.
- Only if it clearly shows/describes food, set "isRecipe": true and produce the
  full structured recipe below.

ACCURACY RULE (IMPORTANT — do not hallucinate):
- Identify the REAL dish from the attached image and the caption text. Use ALL
  available context: caption, page title, description, hashtags, and URL.
- Once you have confidently identified the dish, you MAY use culinary knowledge
  to complete standard ingredients/steps for THAT dish.
- Do NOT invent a different dish, and do NOT fabricate a recipe when the post
  is not clearly about food. When the image and caption disagree, trust what
  the image actually shows.

CRITICAL — SECTION STRUCTURE (MUST FOLLOW):
- ingredientSections and instructionSections are the PRIMARY structure.
- ALWAYS split multi-component dishes into separate named sections.
- For simple single-component dishes use one section named "Main Recipe".

INGREDIENT FORMAT:
- Every item MUST include quantity: "1 cup rice", "2 tablespoons oil"
- Minimum 8 ingredients total when possible.

INSTRUCTION FORMAT:
- Each step is one clear actionable sentence.
- Minimum 5 steps total when possible.
- No step numbers in the text.

NUTRITION:
- Estimate nutrition per serving using all available ingredients and quantities.
- Return approximate values for calories, protein, carbohydrates, and fat.
- Do not leave any nutrition field empty.

FLAT LISTS:
- "ingredients" = ALL items from every ingredientSection combined in order.
- "instructions" = ALL steps from every instructionSection combined in order.

OTHER:
- servings: numeric string only, e.g. "4"
- prepTime/cookTime/totalTime: e.g. "20 mins", "30 mins", "50 mins"
- category: Breakfast|Lunch|Dinner|Snack|Dessert|Beverage
- keywords: 8-15 relevant tags
- sourceUrl: use the provided post URL if available, else "Social Media Import"
- imageUrl: leave empty string unless a thumbnail URL is provided in context
`;


const RECIPE_TEXT_PROMPT = `
You are a world-class chef and recipe developer.

You will be given ONLY the name of a dish (no image, no video, no caption).
Using your culinary knowledge, generate the most accurate, authentic,
complete recipe for that dish.

CRITICAL — SECTION STRUCTURE (MUST FOLLOW):
- ingredientSections and instructionSections are the PRIMARY structure.
- ALWAYS split multi-component dishes into separate named sections.
- NEVER put all ingredients in one section when the dish has distinct parts.
- NEVER put all steps in one section when the dish has distinct cooking
  phases.

Examples of REQUIRED section splits:

Veg Manchurian:
ingredientSections: [
  {"name":"For Manchurian Balls","items":[
    "1¼ cup cabbage finely chopped","½ cup carrot grated", "..."
  ]},
  {"name":"For Manchurian Sauce","items":[
    "1½ tablespoons oil","¾ tablespoon garlic", "..."
  ]}
]
instructionSections: [
  {"name":"Prepare Manchurian Balls","steps":[
    "Mix vegetables...", "Shape into balls...", "..."
  ]},
  {"name":"Prepare Manchurian Sauce","steps":[
    "Heat oil...", "Add sauces...", "..."
  ]},
  {"name":"Combine and Serve","steps":[
    "Toss balls in sauce...", "..."
  ]}
]
NUTRITION:
- Calculate approximate nutrition for one serving based
  on the ingredients and quantities.
- Return realistic estimated values.
- calories: e.g. "450 kcal"
- protein: e.g. "18 g"
- carbs: e.g. "55 g"
- fat: e.g. "20 g"
Burger: sections for Patty, Sauce, Assembly.
Pizza: sections for Dough, Sauce, Toppings.
Cake: sections for Batter, Frosting.

For simple single-component dishes use one section named "Main Recipe".

INGREDIENT FORMAT:
- Every item MUST include quantity: "1 cup rice", "2 tablespoons oil"
- Minimum 8 ingredients total.

INSTRUCTION FORMAT:
- Each step is one clear actionable sentence.
- Minimum 5 steps total.
- No step numbers in the text.

FLAT LISTS:
- "ingredients" = ALL items from every ingredientSection combined in order.
- "instructions" = ALL steps from every instructionSection combined in order.

IMAGE PROMPT (VERY IMPORTANT — this text is sent directly to an AI image
generator, no other context is given to it):
- Fill "imagePrompt" with a single, self-contained food-photography
  description of THIS exact finished dish — plated, filling the frame.
- Name the dish and describe its real, specific appearance: colours,
  textures, shape, sauce/gravy consistency, garnish, and the type of plate
  or bowl it is served in.
  Example for Veg Manchurian: "Glossy dark-brown fried vegetable
  Manchurian balls tossed in a thick, shiny soy-chili-garlic sauce,
  garnished with chopped spring onions and sesame seeds, served in a
  black ceramic bowl."
- Food only — never landscapes, scenery, nature, people, buildings, text,
  or a different dish.
- Always end the imagePrompt with: "ultra realistic professional
  restaurant food photo, DSLR, 4K, natural lighting, 45-degree close-up
  hero shot."
- This field must NEVER be left empty.

TITLE:
- Use the proper, correctly-spelled dish name.

OTHER:
- servings: numeric string only, e.g. "4"
- prepTime/cookTime/totalTime: e.g. "20 mins", "30 mins", "50 mins"
- category: Breakfast|Lunch|Dinner|Snack|Dessert|Beverage
- cuisine: e.g. "Indo-Chinese", "Italian", "Gujarati"
- keywords: 8-15 relevant tags
- sourceUrl: "AI Generated"
- imageUrl: leave empty string — the image is generated separately from
  imagePrompt.
`;

const RECIPE_VIDEO_PROMPT = `
You are an expert chef and recipe developer analyzing a cooking video.

STEP 0 — IS THIS ACTUALLY A RECIPE VIDEO?
Decide whether the video genuinely shows or narrates a food/drink recipe
(ingredients being used, cooking steps being performed, a finished dish, or
a recipe being read out / displayed on screen).
- If it does NOT (unrelated vlog, no cooking shown, a person just talking,
  a landscape, a product review, etc.), return EXACTLY this JSON and
  nothing else:
  {"isRecipe": false, "title": "", "description": "", "servings": "",
   "prepTime": "", "cookTime": "", "totalTime": "", "category": "Snack",
   "keywords": [], "ingredientSections": [], "instructionSections": [],
   "ingredients": [], "instructions": [], "sourceUrl": "", "imageUrl": "",
   "imageSearchQuery": ""}
  Do NOT invent, guess, or hallucinate a recipe in this case.
- Only if the video clearly shows/describes a real recipe, set
  "isRecipe": true and produce the full structured recipe below.

STRICT ACCURACY RULE (MOST IMPORTANT — READ CAREFULLY):
- Base the recipe ONLY on what is actually shown, said, or written in the
  video: ingredients visibly used, quantities shown/mentioned, and steps
  actually performed or narrated.
- Do NOT invent ingredients that never appear in the video.
- Do NOT invent cooking steps that never happen in the video.
- Do NOT pad ingredient/instruction lists to hit a "minimum" count — capture
  exactly what's there, nothing more, nothing less.
- If an ingredient is clearly used but its exact quantity isn't shown/stated,
  you may estimate a reasonable quantity for THAT ingredient only — never use
  this as license to add ingredients or steps with no basis in the video.
- If the audio/visual is unclear on a minor detail (e.g. exact cook time),
  infer the most likely value using culinary knowledge, but never fabricate
  entire ingredients, steps, or dish identity.

Return ONLY valid JSON matching this schema. No markdown. No commentary:
{
  "isRecipe": boolean,
  "title": string,
  "description": string,
  "servings": string,            // numeric only, e.g. "4"
  "prepTime": string,            // e.g. "15 mins"
  "cookTime": string,
  "totalTime": string,
  "category": "Breakfast"|"Lunch"|"Dinner"|"Snack"|"Dessert"|"Beverage",
  "keywords": string[],          // 8-15 tags
  "ingredientSections": [{ "name": string, "items": string[] }],
  "instructionSections": [{ "name": string, "steps": string[] }],
  "ingredients": string[],       // flattened, all sections in order
  "instructions": string[],      // flattened, all sections in order
  "sourceUrl": string,
  "imageUrl": string,            // fill ONLY if a real thumbnail/frame URL
                                  // is given in context; else ""
  "imageSearchQuery": string     // ALWAYS non-empty. 3-6 word food-photo
                                  // search phrase for this dish.
}

NUTRITION:
- Estimate nutrition per serving using only the ingredients/quantities you
  actually captured from the video.
- Return approximate values for calories, protein, carbohydrates, and fat.

RULES:
- Sections are primary. Split multi-component dishes (e.g. sauce, filling,
  garnish) into separate named sections; use "Main Recipe" for simple dishes.
- Every instruction is one clear action, no step numbers.
- "ingredients" and "instructions" must be the exact concatenation of all
  section items and steps, preserving order.
- servings: digits only, no units.
- Never fabricate a URL. If you don't have a real one, use "".
`;
/**
 * @param {string} html
 * @return {Record<string, string>}
 */
function extractPageMeta(html) {
  const meta = {};
  const titleMatch = html.match(/<title[^>]*>([^<]*)<\/title>/i);
  if (titleMatch) meta.title = titleMatch[1].trim();

  const metaTagPattern = new RegExp(
      "<meta[^>]+(?:property|name)=['\"]([^'\"]+)['\"]" +
      "[^>]+content=['\"]([^'\"]*)['\"][^>]*>",
      "gi",
  );
  const metaTags = html.matchAll(metaTagPattern);
  for (const match of metaTags) {
    meta[match[1].toLowerCase()] = match[2].trim();
  }

  const reverseMetaPattern = new RegExp(
      "<meta[^>]+content=['\"]([^'\"]*)['\"]" +
      "[^>]+(?:property|name)=['\"]([^'\"]+)['\"][^>]*>",
      "gi",
  );
  const reverseMetaTags = html.matchAll(reverseMetaPattern);
  for (const match of reverseMetaTags) {
    meta[match[2].toLowerCase()] = match[1].trim();
  }

  return meta;
}

/**
 * @param {string} url
 * @return {Promise<Record<string, string>>}
 */
async function fetchUrlContext(url) {
  try {
    const response = await fetch(url, {
      headers: {
        // Instagram / TikTok / etc. only serve their og:image (the post
        // thumbnail) to recognised link-preview crawlers — a generic bot UA
        // gets a login wall with no image. Identify as facebookexternalhit.
        "User-Agent":
          "facebookexternalhit/1.1 " +
          "(+http://www.facebook.com/externalhit_uatext.php)",
        "Accept": "text/html,application/xhtml+xml",
      },
      redirect: "follow",
      signal: AbortSignal.timeout(15000),
    });

    if (!response.ok) {
      return {fetchError: `HTTP ${response.status}`};
    }

    const html = await response.text();
    const meta = extractPageMeta(html);
    const contentType = String(
        response.headers.get("content-type") || "",
    ).toLowerCase();

    const socialType = (() => {
      const ogType = String(meta["og:type"] || "").toLowerCase();
      const twitterCard = String(meta["twitter:card"] || "").toLowerCase();
      const hasVideoMeta = Boolean(
          meta["og:video"] ||
          meta["og:video:url"] ||
          meta["twitter:player"] ||
          meta["twitter:player:stream"],
      );

      if (contentType.startsWith("video/")) return "video";
      if (contentType.startsWith("image/")) return "image";
      if (ogType.startsWith("video")) return "video";
      if (ogType.startsWith("image")) return "image";
      if (twitterCard.includes("player")) return "video";
      if (hasVideoMeta) return "video";
      return "unknown";
    })();

    return {
      pageTitle: meta.title || meta["og:title"] || "",
      description: meta["og:description"] || meta.description || "",
      imageUrl: meta["og:image"] || meta["twitter:image"] || "",
      siteName: meta["og:site_name"] || "",
      contentType: socialType,
    };
  } catch (error) {
    return {fetchError: error.message};
  }
}

/**
 * True for any YouTube watch / Shorts / youtu.be link. Gemini can ingest a
 * YouTube URL directly (it actually watches the video), so these get the
 * accurate video-analysis path instead of text-only metadata guessing.
 * @param {string} url
 * @return {boolean}
 */
function isYouTubeUrl(url) {
  return /(?:youtube\.com\/|youtu\.be\/)/i.test(String(url || ""));
}

/**
 * Downloads a social post's cover image (og:image) and returns it as an inline
 * Gemini image part so the model can SEE the real dish instead of guessing from
 * caption text alone. Returns null on any failure (caller falls back to
 * text-only), and skips anything that isn't a reasonably-sized image.
 * @param {string} imageUrl
 * @return {Promise<{inlineData: {mimeType: string, data: string}}|null>}
 */
async function fetchImageAsInlinePart(imageUrl) {
  try {
    if (!imageUrl) return null;
    const res = await fetch(imageUrl, {
      headers: {
        "User-Agent":
          "facebookexternalhit/1.1 " +
          "(+http://www.facebook.com/externalhit_uatext.php)",
        "Accept": "image/*",
      },
      redirect: "follow",
      signal: AbortSignal.timeout(15000),
    });
    if (!res.ok) return null;

    const contentType = String(
        res.headers.get("content-type") || "",
    ).toLowerCase();
    if (!contentType.startsWith("image/")) return null;

    const bytes = Buffer.from(await res.arrayBuffer());
    // Keep the request small; a post thumbnail should never be this big.
    if (bytes.length === 0 || bytes.length > 7 * 1024 * 1024) return null;

    return {
      inlineData: {
        mimeType: contentType.split(";")[0].trim() || "image/jpeg",
        data: bytes.toString("base64"),
      },
    };
  } catch (error) {
    console.error("fetchImageAsInlinePart failed:", error.message);
    return null;
  }
}

/**
 * Runs Gemini structured recipe extraction. `contents` may be a plain string
 * (text-only) OR an array of parts (text + inline image / YouTube fileData),
 * so the same JSON schema + normalisation is reused for every source.
 *
 * Reasoning is kept LOW for speed and reliability. NOTE: Gemini 3.x models
 * use `thinkingLevel` (semantic: minimal/low/medium/high) instead of the
 * Gemini 2.5-era `thinkingBudget` (numeric token budget) — the two params
 * are NOT interchangeable and mixing them throws a 400 INVALID_ARGUMENT.
 * The output cap stays generous so a fully-sectioned recipe + nutrition can
 * never be truncated mid-JSON.
 * @param {object} ai
 * @param {string|Array<object>} contents
 * @param {string} model Gemini model id.
 * @return {Promise<Record<string, unknown>>}
 */
async function generateStructuredRecipe(
    ai, contents, model = "gemini-3.5-flash-lite") {
  const response = await ai.models.generateContent({
    model,
    contents,
    config: {
      responseMimeType: "application/json",
      responseSchema: RECIPE_RESPONSE_SCHEMA,
      temperature: 0.2,
      maxOutputTokens: 8192,
      // Gemini 3.x has no "off" — "low" is the cheapest/fastest available
      // level and is the closest equivalent to the old thinkingBudget:0.
      thinkingConfig: {thinkingLevel: "low"},
    },
  });

  logTokens("extract", response);

  let text = response.text.trim();
  text = text.replace(/```json/g, "");
  text = text.replace(/```/g, "");

  const rawRecipe = JSON.parse(text);
  return normalizeRecipe(rawRecipe);
}

// SOCIAL URL / CAPTION TO RECIPE
exports.extractRecipeFromSocialContent = onCall(
    {
      secrets: ["GEMINI_API_KEY"],
      timeoutSeconds: 300,
      memory: "1GiB",
    },
    async (request) => {
      try {
        await requireAuthAndCap(request);
        await enforceImportCredit(request.auth.uid);
        const url = String(request.data.url || "").trim();
        const caption = String(request.data.caption || "").trim();

        if (!url && !caption) {
          throw new Error("URL or caption is required");
        }

        const ai = getAI();

        // One viral reel imported by N users used to mean N extractions
        // and N images. Cache the finished recipe by URL hash — repeat
        // imports of the same post cost zero Gemini calls and reuse the
        // same stored image.
        const cacheKey = url ?
          crypto.createHash("sha1").update(url).digest("hex") : "";
        if (cacheKey) {
          try {
            const hit = await admin.firestore()
                .collection("extraction_cache").doc(cacheKey).get();
            if (hit.exists && hit.data().recipe) {
              console.log("[cache] extraction hit:", url);
              return {success: true, recipe: hit.data().recipe};
            }
          } catch (e) {
            console.error("extraction_cache read failed:", e.message);
          }
        }

        let pageContext = {};
        if (url) {
          pageContext = await fetchUrlContext(url);
        }

        let recipe = null;

        // ── Route 1: YouTube — Gemini watches the ACTUAL video ──────────────
        // A YouTube URL can be passed to Gemini directly; it analyses the real
        // footage, so we use the strict video prompt instead of guessing from
        // metadata. Falls back to the multimodal route if that call fails
        // (private / age-gated video, etc.).
        if (url && isYouTubeUrl(url)) {
          try {
            const ytPrompt = caption ?
              `${RECIPE_VIDEO_PROMPT}\n\nSource URL: ${url}\n` +
                `Caption:\n${caption}` :
              `${RECIPE_VIDEO_PROMPT}\n\nSource URL: ${url}`;
            recipe = await generateStructuredRecipe(ai, [
              {text: ytPrompt},
              {fileData: {fileUri: url, mimeType: "video/*"}},
            ]);
          } catch (ytError) {
            console.error(
                "YouTube video analysis failed, using metadata:",
                ytError.message,
            );
            recipe = null;
          }
        }

        // ── Route 2: caption + the post's ACTUAL cover image ────────────────
        // For Instagram / TikTok / Facebook the raw video is not fetchable from
        // a server, but the cover frame (og:image) IS. Attaching it lets Gemini
        // SEE the dish instead of hallucinating a recipe from caption text.
        if (!recipe) {
          const contextParts = [
            url ? `Post URL: ${url}` : "",
            caption ? `Shared caption/text:\n${caption}` : "",
            pageContext.pageTitle ?
              `Page title: ${pageContext.pageTitle}` :
              "",
            pageContext.description ?
              `Page description: ${pageContext.description}` :
              "",
            pageContext.siteName ?
              `Platform: ${pageContext.siteName}` :
              "",
            pageContext.fetchError ?
              `Note: Could not fetch URL (${pageContext.fetchError}). ` +
              "Use caption text only." :
              "",
          ].filter(Boolean);

          const promptText =
            `${RECIPE_SOCIAL_PROMPT}\n\n---\nPOST CONTEXT:\n${
              contextParts.join("\n")
            }`;
          const parts = [{text: promptText}];

          const imagePart = pageContext.imageUrl ?
            await fetchImageAsInlinePart(pageContext.imageUrl) :
            null;
          if (imagePart) parts.push(imagePart);

          recipe = await generateStructuredRecipe(ai, parts);
        }

        // ── Not a recipe → tell the client, don't save a hallucination ──────
        const hasContent =
          (Array.isArray(recipe.ingredients) &&
            recipe.ingredients.length > 0) ||
          (Array.isArray(recipe.instructions) &&
            recipe.instructions.length > 0);
        const gateTitle = String(recipe.title || "").trim().toLowerCase();
        const placeholderTitle =
          ["", "unknown", "unknown recipe", "untitled", "n/a"]
              .includes(gateTitle);

        if (recipe.isRecipe === false || !hasContent || placeholderTitle) {
          return {success: true, recipe: {isRecipe: false}};
        }
        recipe.isRecipe = true;

        if (url && (!recipe.sourceUrl ||
            recipe.sourceUrl === "AI Generated")) {
          recipe.sourceUrl = url;
        }

        // Speed: never block the response on server-side image generation. Use
        // the post's real cover image (og:image) when available — for a reel
        // that's the creator's chosen thumbnail of the dish. The client shows
        // it instantly and persists it to Firebase in the background, so the
        // recipe returns without waiting on any image work.
        // Image priority: dish registry -> mirrored real cover image ->
        // nothing (client falls back to one AI generation). The og:image is
        // the creator's own thumbnail of the dish; mirroring it into our
        // Storage makes it durable (platform CDN links expire) and lets the
        // client's allowlist accept it, so no image is generated at all.
        const dishSlug = slugifyDish(recipe.title);
        let ownedImage = await lookupDishImage(dishSlug);
        if (!ownedImage && pageContext.imageUrl) {
          ownedImage = await mirrorRemoteImage(
              pageContext.imageUrl, recipe.title);
          if (ownedImage) {
            await registerDishImage(dishSlug, ownedImage, "mirrored");
          }
        }
        if (ownedImage) {
          recipe.imageUrl = ownedImage;
        } else if (pageContext.imageUrl) {
          recipe.imageUrl = pageContext.imageUrl;
        }

        if (cacheKey) {
          try {
            await admin.firestore()
                .collection("extraction_cache").doc(cacheKey).set({
                  recipe,
                  url,
                  createdAt: admin.firestore.FieldValue.serverTimestamp(),
                });
          } catch (e) {
            console.error("extraction_cache write failed:", e.message);
          }
        }

        return {success: true, recipe};
      } catch (error) {
        console.error(error);
        return {success: false, error: error.message};
      }
    },
);

// VIDEO TO RECIPE
// VIDEO TO RECIPE
exports.analyzeRecipeVideo = onCall(
    {
      secrets: ["GEMINI_API_KEY"],
      timeoutSeconds: 300,
      memory: "2GiB",
    },
    async (request) => {
      const startTime = Date.now();

      try {
        await requireAuthAndCap(request);
        await enforceImportCredit(request.auth.uid);
        console.log("VIDEO ANALYSIS STARTED");

        const videoBase64 = request.data.video;
        const storagePath = String(
            request.data.storagePath || "",
        ).trim();
        const mimeType = String(
            request.data.mimeType || "video/mp4",
        ).trim();
        const sourceUrl = String(
            request.data.sourceUrl || "",
        ).trim();

        let videoData = videoBase64;
        let resolvedMimeType = mimeType;

        // Download video from Storage only when base64 is not available.
        if (!videoData && storagePath) {
          console.log("Downloading video from Storage...");

          const bucket = admin.storage().bucket();
          const file = bucket.file(storagePath);

          const [buffer, metadataResult] = await Promise.all([
            file.download(),
            file.getMetadata(),
          ]);

          videoData = buffer[0].toString("base64");

          const metadata = metadataResult[0];
          if (metadata.contentType) {
            resolvedMimeType = metadata.contentType;
          }

          console.log(
              "Video downloaded in:",
              Date.now() - startTime,
              "ms",
          );
        }

        if (!videoData) {
          throw new Error("Video data or storagePath is required");
        }

        const ai = getAI();

        const promptText = sourceUrl ?
          `${RECIPE_VIDEO_PROMPT}\n\nSource URL: ${sourceUrl}` :
          RECIPE_VIDEO_PROMPT;

        console.log("Gemini video analysis started");

        const response = await ai.models.generateContent({
          model: "gemini-3.5-flash-lite",
          contents: [
            {text: promptText},
            {
              inlineData: {
                mimeType: resolvedMimeType,
                data: videoData,
              },
              // Sample 1 frame every 2s instead of every second. Cooking
              // steps span seconds, so adjacent frames are near-duplicates;
              // this halves the VISUAL token cost of every video import
              // (audio is billed flat at 32 tokens/sec regardless of fps).
              videoMetadata: {fps: 0.5},
            },
          ],
          config: {
            responseMimeType: "application/json",
            responseSchema: RECIPE_RESPONSE_SCHEMA,
            // Reasoning left ON (medium/high default for gemini-3.x) since
            // this model does NOT set thinkingConfig here — reading
            // ingredients/steps out of a fast cooking video is a hard
            // multimodal task and needs real thinking. Output cap raised
            // 2500 -> 8192 so a fully-sectioned recipe + nutrition can never
            // be cut off mid-JSON (which was throwing a JSON.parse error and
            // surfacing as a generic import failure).
            maxOutputTokens: 8192,
            temperature: 0.2,
          },
        });

        logTokens("video-import", response);
        console.log(
            "Gemini response received in:",
            Date.now() - startTime,
            "ms",
        );

        let text = response.text.trim();
        text = text
            .replace(/^```json\s*/i, "")
            .replace(/^```\s*/i, "")
            .replace(/\s*```$/i, "")
            .trim();

        const rawRecipe = JSON.parse(text);

        // Not a recipe video → bail out early instead of returning a
        // hallucinated recipe. Require the flag AND real content AND a
        // real title, since a hallucinated non-recipe result often still
        // has an empty/placeholder title.
        const hasContent =
          (Array.isArray(rawRecipe.ingredients) &&
            rawRecipe.ingredients.length > 0) ||
          (Array.isArray(rawRecipe.instructions) &&
            rawRecipe.instructions.length > 0);
        const title = (rawRecipe.title || "").toString().trim().toLowerCase();
        const placeholderTitle =
          ["", "unknown", "unknown recipe", "untitled", "n/a"]
              .includes(title);

        if (rawRecipe.isRecipe === false || !hasContent || placeholderTitle) {
          return {
            success: true,
            recipe: {isRecipe: false},
          };
        }

        const recipe = normalizeRecipe(rawRecipe);
        recipe.isRecipe = true;

        if (sourceUrl) {
          recipe.sourceUrl = sourceUrl;
        }

        // A real frame of the user's own video beats a $0.04 AI imagining
        // of it. Registry first, then ffmpeg; only if both fail does the
        // client fall back to generation.
        if (!recipe.imageUrl) {
          const vSlug = slugifyDish(recipe.title);
          let vImage = await lookupDishImage(vSlug);
          if (!vImage && videoData) {
            vImage = await extractVideoFrame(videoData, recipe.title);
            if (vImage) {
              await registerDishImage(vSlug, vImage, "frame");
            }
          }
          if (vImage) {
            recipe.imageUrl = vImage;
          }
        }

        if (!recipe.imageUrl) {
          recipe.imageUrl = "";
        }

        console.log("Recipe generated:", recipe.title);
        console.log(
            "TOTAL VIDEO ANALYSIS TIME:",
            Date.now() - startTime,
            "ms",
        );

        return {
          success: true,
          recipe,
        };
      } catch (error) {
        console.error("analyzeRecipeVideo failed:", error);

        return {
          success: false,
          error: error.message,
        };
      }
    },
);

exports.generateRecipeImage = onCall(
    {
      secrets: ["GEMINI_API_KEY"],
      timeoutSeconds: 300,
      memory: "1GiB",
    },
    async (request) => {
      try {
        await requireAuthAndCap(request);
        let recipe = request.data.recipe;
        const caption = String(request.data.caption || "").trim();

        // PARALLEL path: when only a caption is provided (no extracted recipe
        // yet), generate straight from the caption — the dish is named in it —
        // so the image can run alongside recipe extraction instead of after it.
        if ((!recipe || !recipe.title) && caption) {
          recipe = {
            title: "recipe",
            imagePrompt: buildCaptionImagePrompt(caption),
          };
        }

        if (!recipe || !recipe.title) {
          throw new Error("Recipe data is required");
        }

        const ai = getAI();

        const imageUrl = await generateAndStoreRecipeImage(ai, recipe);

        if (!imageUrl) {
          throw new Error("Image generation failed");
        }

        return {
          success: true,
          imageUrl: imageUrl,
        };
      } catch (error) {
        console.error("generateRecipeImage failed:", error);

        return {
          success: false,
          error: error.message,
        };
      }
    },
);


// IMAGE TO RECIPE
exports.analyzeRecipeImage = onCall(
    {
      secrets: ["GEMINI_API_KEY"],
      timeoutSeconds: 300,
      memory: "1GiB",
    },
    async (request) => {
      try {
        await requireAuthAndCap(request);
        await enforceImportCredit(request.auth.uid);
        const imageBase64 = request.data.image;

        if (!imageBase64) {
          throw new Error("Image is required");
        }

        const ai = getAI();

        const response = await ai.models.generateContent({
          model: "gemini-3.5-flash-lite",
          contents: [
            {text: RECIPE_IMAGE_PROMPT},
            {
              inlineData: {
                mimeType: "image/jpeg",
                data: imageBase64,
              },
            },
          ],
          config: {
            responseMimeType: "application/json",
            responseSchema: RECIPE_PHOTO_SCHEMA,
            // Gemini 3.x uses thinkingLevel (minimal/low/medium/high), NOT
            // the Gemini 2.5-era thinkingBudget (numeric). Passing
            // thinkingBudget here against a gemini-3.x model is what threw
            // "400 INVALID_ARGUMENT" — the two params are not interchangeable.
            thinkingConfig: {
              thinkingLevel: "low",
            },
          },
        });
        logTokens("photo-import", response);

        let text = response.text.trim();
        text = text.replace(/```json/g, "");
        text = text.replace(/```/g, "");

        const rawRecipe = JSON.parse(text);

        // Not a food/recipe image → bail out early. No image upload, no
        // generation, no made-up recipe. The client aborts on this flag.
        // Require the flag, real content AND a real title — a hallucinated
        // non-food result typically has an empty/placeholder title.
        const hasContent =
          (Array.isArray(rawRecipe.ingredients) &&
            rawRecipe.ingredients.length > 0) ||
          (Array.isArray(rawRecipe.instructions) &&
            rawRecipe.instructions.length > 0);
        const title = (rawRecipe.title || "").toString().trim().toLowerCase();
        const placeholderTitle =
          ["", "unknown", "unknown recipe", "untitled", "n/a"].includes(title);
        if (rawRecipe.isRecipe === false || !hasContent || placeholderTitle) {
          return {success: true, recipe: {isRecipe: false}};
        }

        const recipe = normalizeRecipe(rawRecipe);
        recipe.isRecipe = true;

        // The user already supplied a real photo of the dish — use it
        // directly instead of generating a new one, unless it's missing.
        if (!recipe.imageUrl) {
          try {
            const bucket = admin.storage().bucket();
            const buffer = Buffer.from(imageBase64, "base64");
            const safeSeed = (recipe.title || "recipe")
                .toLowerCase()
                .replace(/[^a-z0-9]+/g, "-")
                .replace(/(^-|-$)/g, "")
                .slice(0, 60) || "recipe";
            const fileName =
              `recipe_images/${safeSeed}-${Date.now()}-` +
              `${Math.random().toString(36).slice(2, 8)}.jpg`;
            const file = bucket.file(fileName);
            const downloadToken = crypto.randomUUID();
            await file.save(buffer, {
              metadata: {
                contentType: "image/jpeg",
                cacheControl: "public, max-age=31536000",
                metadata: {
                  firebaseStorageDownloadTokens: downloadToken,
                },
              },
            });
            recipe.imageUrl =
              `https://firebasestorage.googleapis.com/v0/b/${bucket.name}` +
              `/o/${encodeURIComponent(fileName)}?alt=media&token=` +
              downloadToken;
          } catch (uploadError) {
            console.error("Uploading source image failed:", uploadError);
            // Fall back to AI-generated image if the upload fails.
            const generatedUrl =
              await generateAndStoreRecipeImage(ai, recipe);
            if (generatedUrl) {
              recipe.imageUrl = generatedUrl;
            }
          }
        }

        console.log("Recipe title:", recipe.title);
        console.log(
            "Ingredient sections:",
            recipe.ingredientSections.length,
        );
        console.log(
            "Instruction sections:",
            recipe.instructionSections.length,
        );

        return {
          success: true,
          recipe,
        };
      } catch (error) {
        console.error(error);

        return {
          success: false,
          error: error.message,
        };
      }
    },
);

// TEXT TO RECIPE
exports.generateRecipeFromName = onCall(
    {
      secrets: ["GEMINI_API_KEY"],
      timeoutSeconds: 300,
      memory: "1GiB",
    },
    async (request) => {
      try {
        await requireAuthAndCap(request);
        await enforceImportCredit(request.auth.uid);
        const recipeName =
          String(request.data.recipeName || "").trim();

        if (!recipeName) {
          throw new Error("Recipe name is required");
        }

        const ai = getAI();

        const prompt = `
${RECIPE_TEXT_PROMPT}

Generate a complete recipe for: ${recipeName}
`;

        // flash-lite: name -> recipe is pure culinary knowledge, no
        // vision. Cheapest text-only path.
        const recipe = await generateStructuredRecipe(
            ai, prompt, "gemini-3.5-flash-lite");

        console.log(
            "generateRecipeFromName: title=",
            recipe.title,
            "imagePrompt=",
            recipe.imagePrompt ? recipe.imagePrompt.slice(0, 80) : "(empty)",
        );

        // Always try a real AI-generated food photo first.
        const generatedUrl = await generateAndStoreRecipeImage(ai, recipe);
        if (generatedUrl) {
          recipe.imageUrl = generatedUrl;
        } else {
          console.error(
              "generateRecipeFromName: image generation failed for",
              recipeName,
              "— falling back to picsum placeholder.",
          );
          // Deterministic fallback so the UI never shows a broken image.
          const seed = encodeURIComponent(
              recipeName.trim().toLowerCase().replace(/ /g, "-"),
          );
          recipe.imageUrl = `https://picsum.photos/seed/${seed}/800/600`;
        }

        return {
          success: true,
          recipe,
        };
      } catch (error) {
        console.error(error);
        return {
          success: false,
          error: error.message,
        };
      }
    },
);


// ── Email existence check ────────────────────────────────────────────────────
// Returns whether an email is already registered. Used by "Forgot password" so
// the app can show a clear "no account found" error even when Firebase email
// enumeration protection is enabled (which deliberately hides existence from
// the client). Runs server-side with the Admin SDK.
exports.checkEmailRegistered = onCall(async (request) => {
  const email = ((request.data && request.data.email) || "").toString().trim();
  if (!email) {
    return {registered: false};
  }
  try {
    await admin.auth().getUserByEmail(email);
    return {registered: true};
  } catch (e) {
    if (e && e.code === "auth/user-not-found") {
      return {registered: false};
    }
    // Unknown error: do not block the flow — treat as registered so the normal
    // reset-email path still runs.
    return {registered: true};
  }
});
