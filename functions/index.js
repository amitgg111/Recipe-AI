const {onCall} = require("firebase-functions/v2/https");
const {setGlobalOptions} = require("firebase-functions/v2");
const {GoogleGenAI} = require("@google/genai");
const admin = require("firebase-admin");

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

const RECIPE_RESPONSE_SCHEMA = {
  type: "OBJECT",
  properties: {
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
    "keywords",
    "ingredients",
    "instructions",
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

const RECIPE_IMAGE_PROMPT = `
You are a world-class chef and recipe developer.

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
      try {
        const prompt = request.data.prompt;

        if (!prompt) {
          throw new Error("Prompt is required");
        }

        const ai = getAI();

        const response = await ai.models.generateContent({
          model: "gemini-2.5-flash",
          contents: prompt,
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

const RECIPE_VIDEO_PROMPT = `
You are a world-class chef and recipe developer.

Watch the cooking video and generate the most accurate complete recipe shown.

CRITICAL — SECTION STRUCTURE (MUST FOLLOW):
- ingredientSections and instructionSections are the PRIMARY structure.
- ALWAYS split multi-component dishes into separate named sections.
- For simple single-component dishes use one section named "Main Recipe".

INGREDIENT FORMAT:
- Every item MUST include quantity: "1 cup rice", "2 tablespoons oil"
- Minimum 8 ingredients total when possible.

INSTRUCTION FORMAT:
- Each step is one clear actionable sentence matching what happens in the video.
- Minimum 5 steps total when possible.
- No step numbers in the text.

FLAT LISTS:
- "ingredients" = ALL items from every ingredientSection combined in order.
- "instructions" = ALL steps from every instructionSection combined in order.

OTHER:
- servings: numeric string only, e.g. "4"
- prepTime/cookTime/totalTime: estimate from the video
- category: Breakfast|Lunch|Dinner|Snack|Dessert|Beverage
- keywords: 8-15 relevant tags
- sourceUrl: use provided source URL if any, else "Social Media Video"
- imageUrl: leave empty string
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
        "User-Agent":
          "Mozilla/5.0 (compatible; RecipeAI/1.0; +https://recipeai.app)",
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
      timeoutSeconds: 120,
      memory: "1GiB",
    },
    async (request) => {
      try {
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
        if (pageContext.imageUrl && !recipe.imageUrl) {
          recipe.imageUrl = pageContext.imageUrl;
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
      timeoutSeconds: 120,
      memory: "1GiB",
    },
    async (request) => {
      try {
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
          },
        });

        let text = response.text.trim();
        text = text.replace(/```json/g, "");
        text = text.replace(/```/g, "");

        const rawRecipe = JSON.parse(text);
        const recipe = normalizeRecipe(rawRecipe);

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
      timeoutSeconds: 120,
      memory: "1GiB",
    },
    async (request) => {
      try {
        const recipeName = String(request.data.recipeName || "").trim();

        if (!recipeName) {
          throw new Error("Recipe name is required");
        }

        const ai = getAI();

        const prompt = `
${RECIPE_SOCIAL_PROMPT}

Generate a complete recipe for: ${recipeName}

Source URL should be: "AI Generated"

Important Instructions for Image:
- Provide ONE high-quality, appetizing food image URL from Unsplash or Pexels.
- Return it in field: imageUrl
- image is also related to recipe and recipes name 
`;

        const recipe = await generateStructuredRecipe(ai, prompt);

        // Better Fallback Image
        if (
          !recipe.imageUrl ||
          recipe.imageUrl === "" ||
          recipe.imageUrl.includes("placeholder") ||
          !recipe.imageUrl.startsWith("http")
        ) {
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
