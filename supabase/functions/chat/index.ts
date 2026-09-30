// Supabase Edge Function: proxies chatbot messages to OpenRouter so the
// OpenRouter API key never has to live inside the kiosk app binary.
//
// Deploy via supabase CLI:  supabase functions deploy chat --project-ref <ref>
// or via the Supabase Dashboard (Edge Functions -> chat -> paste this file).
//
// Required secret: OPENROUTER_API_KEY (set with `supabase secrets set
// OPENROUTER_API_KEY=sk-or-v1-...` or in Project Settings -> Edge Functions).
// Get a key from openrouter.ai.
//
// The kiosk app calls this via Supabase.instance.client.functions.invoke('chat', ...),
// which automatically attaches the app's anon key as the Authorization header —
// that's what Supabase uses to verify the request is allowed to reach the function.
//
// NOTE: This deliberately calls the OpenRouter REST API with plain fetch()
// rather than importing `npm:@openai/sdk`. The SDK has a history of
// import/bootstrap failures inside the Deno edge runtime, which is the usual
// reason this assistant shows "something went wrong" in the kiosk.

import { createClient } from "https://esm.sh/@supabase/supabase-js@2";

const OPENROUTER_API_KEY = Deno.env.get("OPENROUTER_API_KEY");
const SUPABASE_URL = Deno.env.get("SUPABASE_URL")!;
const SUPABASE_SERVICE_ROLE_KEY = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!;

const MODEL = "nvidia/nemotron-3-super-120b-a12b:free";

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers":
    "authorization, x-client-info, apikey, content-type",
};

function json(payload: unknown, status = 200): Response {
  return new Response(JSON.stringify(payload), {
    status,
    headers: { ...corsHeaders, "Content-Type": "application/json" },
  });
}

async function buildCampusContext(): Promise<string> {
  const supabase = createClient(SUPABASE_URL, SUPABASE_SERVICE_ROLE_KEY);
  const [buildingsRes, officesRes, servicesRes, faqsRes] = await Promise.all([
    supabase.from("buildings").select("name, description, location, offices"),
    supabase.from("offices").select("name, abbreviation, location, purpose"),
    supabase.from("services").select("name, description"),
    supabase.from("faqs").select("question, answer"),
  ]);

  const lines: string[] = [];

  lines.push("Buildings:");
  for (const b of buildingsRes.data ?? []) {
    lines.push(
      `- ${b.name} (${b.location ?? "location unknown"}): ${b.description ?? ""}`,
    );
  }

  lines.push("\nOffices:");
  for (const o of officesRes.data ?? []) {
    lines.push(
      `- ${o.name}${o.abbreviation ? ` (${o.abbreviation})` : ""} at ${
        o.location ?? "unknown location"
      }: ${o.purpose ?? ""}`,
    );
  }

  lines.push("\nServices:");
  for (const s of servicesRes.data ?? []) {
    lines.push(`- ${s.name}: ${s.description ?? ""}`);
  }

  lines.push("\nFrequently Asked Questions:");
  for (const f of faqsRes.data ?? []) {
    lines.push(`Q: ${f.question}\nA: ${f.answer ?? ""}`);
  }

  return lines.join("\n");
}

Deno.serve(async (req: Request) => {
  // CORS preflight
  if (req.method === "OPTIONS") {
    return new Response(null, { headers: corsHeaders });
  }

  if (!OPENROUTER_API_KEY) {
    return json(
      { error: "Chat is not configured. Ask the administrator to set the OPENROUTER_API_KEY secret." },
      500,
    );
  }

  try {
    const { message, history } = await req.json();
    if (!message || typeof message !== "string") {
      return json({ error: "Missing 'message'" }, 400);
    }

    const campusContext = await buildCampusContext();

    const systemPrompt =
      "You are the CSU-A Navigation Assistant, a helpful kiosk chatbot for " +
      "Cagayan State University - Aparri Campus. Answer questions about campus " +
      "buildings, offices, services, and FAQs using the information below. " +
      "Keep answers short and friendly (2-3 sentences), suitable for a kiosk " +
      "screen. If asked about something not covered by the data below, say you " +
      "don't have that information and suggest visiting the Administration " +
      "Building.\n\n" + campusContext;

    // The client's history includes the assistant's static greeting first, so
    // drop everything before the first real user message.
    const rawHistory = Array.isArray(history) ? history : [];
    const firstUserIndex = rawHistory.findIndex(
      (m: { role?: string }) => m?.role === "user",
    );
    const trimmedHistory = firstUserIndex === -1
      ? []
      : rawHistory.slice(firstUserIndex);

    const apiMessages = [
      { role: "system" as const, content: systemPrompt },
      ...trimmedHistory.map((m: { role: string; content: string }) => ({
        role: m.role === "assistant" ? "assistant" as const : "user" as const,
        content: m.content,
      })),
      { role: "user" as const, content: message },
    ];

    const apiRes = await fetch("https://openrouter.ai/api/v1/chat/completions", {
      method: "POST",
      headers: {
        Authorization: `Bearer ${OPENROUTER_API_KEY}`,
        "content-type": "application/json",
      },
      body: JSON.stringify({
        model: MODEL,
        max_tokens: 300,
        messages: apiMessages,
      }),
    });

    const apiBody = await apiRes.text();
    let parsed: {
      choices?: { message?: { content?: string } }[];
      error?: unknown;
    };
    try {
      parsed = apiBody ? JSON.parse(apiBody) : {};
    } catch {
      parsed = {};
    }

    if (!apiRes.ok) {
      console.error(
        "OpenRouter error",
        apiRes.status,
        JSON.stringify(parsed).slice(0, 2000),
      );
      const msg = parsed && parsed.error
        ? JSON.stringify(parsed.error)
        : `OpenRouter API returned status ${apiRes.status}`;
      return json({ error: `AI assistant error: ${msg}` }, 502);
    }

    const reply = parsed.choices?.[0]?.message?.content?.trim() ||
      "Sorry, I couldn't come up with a response.";

    return json({ reply });
  } catch (e) {
    console.error("Chat function error", e);
    return json({ error: `AI assistant error: ${String(e)}` }, 500);
  }
});