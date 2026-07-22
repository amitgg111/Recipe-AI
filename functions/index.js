const {onCall, HttpsError} = require("firebase-functions/v2/https");
const {setGlobalOptions} = require("firebase-functions/v2");
const {GoogleGenAI} = require("@google/genai");
const admin = require("firebase-admin");
const crypto = require("crypto");

if (!admin.apps.length) {
  admin.initializeApp();
}

// Notification push triggers (gated by each user's Firestore prefs).
Object.assign(exports, require("./notifications"));

setGlobalOptions({
  maxInstances: 10,
  // Deploy in Mumbai for low latency to India-based users. Functions still
  // serve users worldwide (just with higher RTT for far regions). The Flutter
  // client must call FirebaseFunctions.instanceFor(region: "asia-south1").
  region: "asia-south1",
});

// Reuse one client across warm invocations instead of rebuilding per request.
let _ai;
const getAI = () => {
  _ai ||= new GoogleGenAI({apiKey: process.env.GEMINI_API_KEY});
  return _ai;
};

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
        "A single, self-contained food-photography prompt for an AI " +
        "image generator that shows ONLY the finished, cooked dish of " +
        "THIS exact recipe, plated and filling the frame. Describe its " +
        "real appearance, colours, textures, main visible ingredients, " +
        "garnish and serving vessel. Food only — never landscapes, " +
        "scenery, nature, people, buildings, text or another dish. Add: " +
        "ultra realistic professional restaurant food photo, DSLR, 4K, " +
        "natural lighting, 45-degree close-up hero shot.",
    },
    keywords: {type: "ARRAY", items: {type: "STRING"}},
    // Flat ingredients/instructions are DERIVED from sections in
    // normalizeRecipe — don't make the model emit them twice (output tokens).
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
    "ingredientSections",
    "instructionSections",
    "nutrition",
  ],
};

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

  recipe.title = String(
      recipe.title || recipe.recipeName || recipe.name || "",
  ).trim();

  recipe.description = String(recipe.description || "").trim();
  recipe.imageUrl = String(recipe.imageUrl || "").trim();
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

    // Prefer the image prompt Gemini authored alongside the recipe (it knows
    // the exact dish); fall back to a short built prompt. A fixed food anchor
    // is prepended so Imagen can never drift to a non-food subject.
    const base = String(recipe.imagePrompt || "").trim() ||
      buildImagePrompt(recipe);
    const prompt =
      "Ultra-realistic FOOD PHOTOGRAPH, food only. The single finished " +
      "cooked dish fills almost the entire frame. " + base + " Never " +
      "generate landscapes, scenery, nature, sky, people, buildings, " +
      "text, watermark or any non-food subject.";

    const response = await ai.models.generateImages({
      model: "imagen-4.0-fast-generate-001",
      prompt,
      config: {
        numberOfImages: 1,
        aspectRatio: "4:3",
      },
    });

    const generatedImages = response && response.generatedImages;
    const first = Array.isArray(generatedImages) ? generatedImages[0] : null;
    const imageBytes = first && first.image && first.image.imageBytes;

    if (!imageBytes) {
      console.error("Image generation returned no image bytes.");
      return "";
    }

    const buffer = Buffer.from(imageBytes, "base64");
    const bucket = admin.storage().bucket();
    const safeSeed = recipe.title
        .toLowerCase()
        .replace(/[^a-z0-9]+/g, "-")
        .replace(/(^-|-$)/g, "")
        .slice(0, 60) || "recipe";
    const fileName =
      `recipe_images/${safeSeed}-${Date.now()}-` +
      `${Math.random().toString(36).slice(2, 8)}.png`;
    const file = bucket.file(fileName);

    const downloadToken = crypto.randomUUID();

    await file.save(buffer, {
      metadata: {
        contentType: "image/png",
        cacheControl: "public, max-age=31536000",
        metadata: {
          firebaseStorageDownloadTokens: downloadToken,
        },
      },
    });

    return `https://firebasestorage.googleapis.com/v0/b/${bucket.name}/o/${encodeURIComponent(fileName)}?alt=media&token=${downloadToken}`;
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

  Burger: sections for Patty, Sauce, Assembly.
  Pizza: sections for Dough, Sauce, Toppings.
  Cake: sections for Batter, Frosting.

  For simple single-component dishes use one section named "Main Recipe".

  INGREDIENT FORMAT:
  - Every item MUST include quantity: "1 cup rice", "2 tablespoons oil"
  - List every ingredient the dish genuinely needs (usually 8 or more).

  INSTRUCTION FORMAT:
  - Each step is one clear actionable sentence.
  - Write every step the dish genuinely needs (usually 5 or more).
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
      try {
        if (!request.auth) {
          throw new HttpsError(
              "unauthenticated", "Please sign in to continue.");
        }
        const prompt = request.data.prompt;

        if (!prompt) {
          throw new Error("Prompt is required");
        }

        const ai = getAI();

        const response = await ai.models.generateContent({
          // Assistant Q&A / swaps: cheaper + faster lite model, no thinking.
          model: "gemini-2.5-flash-lite",
          contents: prompt,
          config: {
            thinkingConfig: {thinkingBudget: 0},
          },
        });

        return {
          success: true,
          text: response.text,
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

const RECIPE_SOCIAL_PROMPT = `
You are a world-class chef and recipe developer.

Extract a complete structured recipe from the social media post context below.
The content may come from Instagram, Facebook, TikTok, YouTube, or similar
platforms.

Use ALL available context: caption text, page title, description, hashtags,
and URL.
If the post shows a cooking video or food image description, infer the full
recipe.
If information is incomplete, use culinary knowledge to fill reasonable gaps.

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

Burger: sections for Patty, Sauce, Assembly.
Pizza: sections for Dough, Sauce, Toppings.
Cake: sections for Batter, Frosting.

For simple single-component dishes use one section named "Main Recipe".

INGREDIENT FORMAT:
- Every item MUST include quantity: "1 cup rice", "2 tablespoons oil"
- List every ingredient the dish genuinely needs (usually 8 or more).

INSTRUCTION FORMAT:
- Each step is one clear actionable sentence.
- Write every step the dish genuinely needs (usually 5 or more).
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
You are an expert chef and recipe developer. 
Extract a structured recipe
from the provided source.
Return ONLY valid JSON
matching this schema.
No markdown.
No commentary: 
 {
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
  "imageUrl": string,      // fill ONLY if a real thumbnail/
 // frame URL is given in context; else ""
   "imageSearchQuery": string
// ALWAYS non-empty.
// Use a 3-6 word
// food-photography
// search phrase
// for this dish.
 }
 
  RULES:
- Sections are primary.
- Split multi-component dishes
  (e.g. sauce, filling, garnish)
- Capture every ingredient actually used.
- Do not pad or omit ingredients
  to hit a target count.   
- Every instruction is one clear action.
- No step numbers.
- Capture every distinct action shown.
- Do not merge or split actions artificially.
 - Capture every ingredient actually used 
 — do not pad or omit to hit a target count.
 - Every instruction is one clear action, no step numbers.
  Capture every distinct action shown
  — do not merge or split artificially.
- "ingredients" and "instructions"
  must be the exact concatenation
  of all section items and steps,
  preserving order. - servings: digits only, no units.
  - If a detail is genuinely missing or unclear,
  infer the most likely value using
  culinary knowledge.
- Do not leave fields blank.
- Exception: imageUrl follows the
  rule above.
 - Never fabricate a URL. If you don't have a real one, use "".`;
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
      signal: AbortSignal.timeout(6000),
    });

    if (!response.ok) {
      return {fetchError: `HTTP ${response.status}`};
    }

    const html = await response.text();
    const meta = extractPageMeta(html);

    return {
      pageTitle: meta.title || meta["og:title"] || "",
      description: meta["og:description"] || meta.description || "",
      imageUrl: meta["og:image"] || meta["twitter:image"] || "",
      siteName: meta["og:site_name"] || "",
    };
  } catch (error) {
    return {fetchError: error.message};
  }
}

/**
 * @param {object} ai
 * @param {string} prompt
 * @return {Promise<Record<string, unknown>>}
 */
async function generateStructuredRecipe(ai, prompt) {
  const response = await ai.models.generateContent({
    model: "gemini-2.5-flash",
    contents: prompt,
    config: {
      responseMimeType: "application/json",
      responseSchema: RECIPE_RESPONSE_SCHEMA,
      // Thinking off + a generous output cap — output tokens dominate cost.
      thinkingConfig: {thinkingBudget: 0},
      maxOutputTokens: 4096,
    },
  });

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
        if (!request.auth) {
          throw new HttpsError(
              "unauthenticated", "Please sign in to continue.");
        }
        const url = String(request.data.url || "").trim();
        const caption = String(request.data.caption || "").trim();

        if (!url && !caption) {
          throw new Error("URL or caption is required");
        }

        let pageContext = {};
        if (url) {
          pageContext = await fetchUrlContext(url);
        }

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
          pageContext.imageUrl ?
            `Thumbnail URL: ${pageContext.imageUrl}` :
            "",
          pageContext.fetchError ?
            `Note: Could not fetch URL (${pageContext.fetchError}). ` +
            "Use caption text only." :
            "",
        ].filter(Boolean);

        const ai = getAI();
        const prompt = `${RECIPE_SOCIAL_PROMPT}\n\n---\nPOST CONTEXT:\n${
          contextParts.join("\n")
        }`;

        const recipe = await generateStructuredRecipe(ai, prompt);

        if (url && (!recipe.sourceUrl ||
            recipe.sourceUrl === "AI Generated")) {
          recipe.sourceUrl = url;
        }

        // Prefer a real thumbnail scraped from the post; otherwise generate
        // an AI food photo so the recipe never ships without an image.
        if (pageContext.imageUrl && !recipe.imageUrl) {
          recipe.imageUrl = pageContext.imageUrl;
        }
        if (!recipe.imageUrl) {
          const generatedUrl = await generateAndStoreRecipeImage(ai, recipe);
          if (generatedUrl) {
            recipe.imageUrl = generatedUrl;
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
exports.analyzeRecipeVideo = onCall(
    {
      secrets: ["GEMINI_API_KEY"],
      timeoutSeconds: 300,
      memory: "2GiB",
    },
    async (request) => {
      try {
        if (!request.auth) {
          throw new HttpsError(
              "unauthenticated", "Please sign in to continue.");
        }
        const videoBase64 = request.data.video;
        const storagePath = String(request.data.storagePath || "").trim();
        const mimeType = String(request.data.mimeType || "video/mp4").trim();
        const sourceUrl = String(request.data.sourceUrl || "").trim();

        let videoData = videoBase64;
        let resolvedMimeType = mimeType;

        if (!videoData && storagePath) {
          const bucket = admin.storage().bucket();
          const file = bucket.file(storagePath);
          const [buffer] = await file.download();
          videoData = buffer.toString("base64");

          const [metadata] = await file.getMetadata();
          if (metadata.contentType) {
            resolvedMimeType = metadata.contentType;
          }
        }

        if (!videoData) {
          throw new Error("Video data or storagePath is required");
        }

        // Cap video size — video is by far the most expensive Gemini input
        // (billed per second/token). base64 is ~1.37x the raw bytes, so ~40MB
        // of base64 ≈ ~30MB video. Reject larger clips with a clear message.
        if (videoData.length > 40 * 1024 * 1024) {
          throw new HttpsError(
              "invalid-argument",
              "This video is too large to import. Please trim it to a short " +
              "clip (under ~30 MB) and try again.",
          );
        }

        const ai = getAI();
        const promptText = sourceUrl ?
          `${RECIPE_VIDEO_PROMPT}\n\nSource URL: ${sourceUrl}` :
          RECIPE_VIDEO_PROMPT;

        const response = await ai.models.generateContent({
          model: "gemini-2.5-flash",
          contents: [
            {text: promptText},
            {
              inlineData: {
                mimeType: resolvedMimeType,
                data: videoData,
              },
            },
          ],
          config: {
            responseMimeType: "application/json",
            responseSchema: RECIPE_RESPONSE_SCHEMA,
            thinkingConfig: {thinkingBudget: 0},
            maxOutputTokens: 4096,
          },
        });

        let text = response.text.trim();
        text = text.replace(/```json/g, "");
        text = text.replace(/```/g, "");

        const rawRecipe = JSON.parse(text);
        const recipe = normalizeRecipe(rawRecipe);

        if (sourceUrl) {
          recipe.sourceUrl = sourceUrl;
        }

        // Video frames aren't a great thumbnail; generate a clean AI photo
        // whenever no image was already provided.
        if (!recipe.imageUrl) {
          const generatedUrl = await generateAndStoreRecipeImage(ai, recipe);
          if (generatedUrl) {
            recipe.imageUrl = generatedUrl;
          }
        }

        return {success: true, recipe};
      } catch (error) {
        console.error(error);
        return {success: false, error: error.message};
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
        if (!request.auth) {
          throw new HttpsError(
              "unauthenticated", "Please sign in to continue.");
        }
        const imageBase64 = request.data.image;

        if (!imageBase64) {
          throw new Error("Image is required");
        }

        const ai = getAI();

        const response = await ai.models.generateContent({
          model: "gemini-2.5-flash",
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
            responseSchema: RECIPE_RESPONSE_SCHEMA,
            thinkingConfig: {thinkingBudget: 0},
            maxOutputTokens: 4096,
          },
        });

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
        if (!request.auth) {
          throw new HttpsError(
              "unauthenticated", "Please sign in to continue.");
        }
        const recipeName = String(request.data.recipeName || "").trim();

        if (!recipeName) {
          throw new Error("Recipe name is required");
        }

        // Cache: identical dish names otherwise re-run two AI calls (recipe +
        // image) every time. Serve a stored copy when we already have one.
        const cacheKey = recipeName.toLowerCase().replace(/[^a-z0-9]+/g, "-")
            .replace(/(^-|-$)/g, "").slice(0, 120) || "recipe";
        const cacheRef = admin.firestore()
            .collection("aiRecipeCache").doc(cacheKey);
        try {
          const cachedDoc = await cacheRef.get();
          if (cachedDoc.exists) {
            return {success: true, recipe: cachedDoc.data(), cached: true};
          }
        } catch (cacheErr) {
          console.error("recipe cache read failed:", cacheErr);
        }

        const ai = getAI();

        const prompt = `
${RECIPE_TEXT_PROMPT}

Generate a complete recipe for: ${recipeName}
`;

        const recipe = await generateStructuredRecipe(ai, prompt);

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

        // Store for next time (best-effort — a write failure must not break
        // the import).
        try {
          await cacheRef.set(recipe);
        } catch (cacheErr) {
          console.error("recipe cache write failed:", cacheErr);
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
