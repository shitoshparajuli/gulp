// suggest-dish-names
//
// Takes a dish photo (base64 JPEG) and returns a short list of likely, specific
// dish names for the add-rating flow. The Anthropic API key stays server-side;
// the client calls this via `supabase.functions.invoke`.
//
// Request body:  { image: string (base64 jpeg), restaurantName?: string, existingDishNames?: string[] }
// Response body: { suggestions: string[] }
//
// Best-effort: any failure (bad input, model refusal, upstream error) returns
// { suggestions: [] } with 200 so the client UI degrades silently.

const ANTHROPIC_API_KEY = Deno.env.get("ANTHROPIC_API_KEY");
const MODEL = "claude-sonnet-4-6";

function json(body: unknown, status = 200): Response {
  return new Response(JSON.stringify(body), {
    status,
    headers: { "content-type": "application/json" },
  });
}

interface RequestBody {
  image?: string;
  restaurantName?: string;
  existingDishNames?: string[];
}

Deno.serve(async (req) => {
  if (req.method !== "POST") return json({ suggestions: [] }, 405);
  if (!ANTHROPIC_API_KEY) {
    console.error("ANTHROPIC_API_KEY is not set");
    return json({ suggestions: [] });
  }

  let payload: RequestBody;
  try {
    payload = await req.json();
  } catch {
    return json({ suggestions: [] }, 400);
  }

  const { image, restaurantName, existingDishNames } = payload;
  if (!image || typeof image !== "string") return json({ suggestions: [] }, 400);

  const contextLines = [
    restaurantName ? `Restaurant: ${restaurantName}.` : "",
    existingDishNames && existingDishNames.length > 0
      ? `Dishes already known at this restaurant: ${existingDishNames.join(", ")}.`
      : "",
  ]
    .filter(Boolean)
    .join(" ");

  const prompt =
    "Identify the most likely specific dish name(s) shown in this food photo, " +
    "written the way they would appear on a restaurant menu " +
    '(e.g. "Margherita Pizza", "Pad See Ew", "Chicken Tikka Masala") — not generic ' +
    'categories like "pizza" or "noodles". Return 3 to 5 candidates, most likely first. ' +
    (contextLines ? contextLines + " " : "") +
    "If a candidate matches one of the dishes already known here, use that exact name. " +
    "If the photo is not food or you cannot tell, return an empty list.";

  try {
    const res = await fetch("https://api.anthropic.com/v1/messages", {
      method: "POST",
      headers: {
        "content-type": "application/json",
        "x-api-key": ANTHROPIC_API_KEY,
        "anthropic-version": "2023-06-01",
      },
      body: JSON.stringify({
        model: MODEL,
        max_tokens: 512,
        thinking: { type: "disabled" },
        output_config: {
          format: {
            type: "json_schema",
            schema: {
              type: "object",
              properties: {
                suggestions: { type: "array", items: { type: "string" } },
              },
              required: ["suggestions"],
              additionalProperties: false,
            },
          },
        },
        messages: [
          {
            role: "user",
            content: [
              {
                type: "image",
                source: { type: "base64", media_type: "image/jpeg", data: image },
              },
              { type: "text", text: prompt },
            ],
          },
        ],
      }),
    });

    if (!res.ok) {
      console.error("Anthropic error", res.status, await res.text());
      return json({ suggestions: [] });
    }

    const data = await res.json();
    if (data.stop_reason === "refusal" || !Array.isArray(data.content)) {
      return json({ suggestions: [] });
    }

    const text = data.content.find((b: { type: string }) => b.type === "text")?.text ?? "{}";
    const parsed = JSON.parse(text);
    const suggestions = Array.isArray(parsed.suggestions)
      ? parsed.suggestions
          .filter((s: unknown): s is string => typeof s === "string")
          .map((s: string) => s.trim())
          .filter((s: string) => s.length > 0)
          .slice(0, 5)
      : [];

    return json({ suggestions });
  } catch (e) {
    console.error("suggest-dish-names failed", e);
    return json({ suggestions: [] });
  }
});
