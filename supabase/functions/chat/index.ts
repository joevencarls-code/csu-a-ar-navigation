// Supabase Edge Function: proxies chatbot messages to Claude (Anthropic) so
// the Anthropic API key never has to live inside the kiosk app binary.
//
// Deploy via supabase CLI:  supabase functions deploy chat --project-ref <ref>
// or via the Supabase Dashboard (Edge Functions -> chat -> paste this file).
//
// Required secret: ANTHROPIC_API_KEY (set with `supabase secrets set
// ANTHROPIC_API_KEY=sk-ant-...` or in Project Settings -> Edge Functions).
// Get a key from console.anthropic.com.
//
// The kiosk app calls this via Supabase.instance.client.functions.invoke('chat', ...),
// which automatically attaches the app's anon key as the Authorization header —
// that's what Supabase uses to verify the request is allowed to reach the function.
//
// NOTE: This deliberately calls the Anthropic REST API with plain fetch()
// rather than importing `npm:@anthropic-ai/sdk`. The SDK has a history of
// import/bootstrap failures inside the Deno edge runtime, which is the usual
// reason this assistant shows "something went wrong" in the kiosk.

import { createClient } from "https://esm.sh/@supabase/supabase-js@2";

const ANTHROPIC_API_KEY = Deno.env.get("ANTHROPIC_API_KEY");
const SUPABASE_URL = Deno.env.get("SUPABASE_URL")!;
const SUPABASE_SERVICE_ROLE_KEY = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!;

const MODEL = "claude-opus-4-8";

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

  if (!ANTHROPIC_API_KEY) {
    return json(
      { error: "Chat is not configured. Ask the administrator to set the ANTHROPIC_API_KEY secret." },
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

    // Claude requires the message list to start with a "user" turn. The
    // client's history includes the assistant's static greeting first, so
    // drop everything before the first real user message.
    const rawHistory = Array.isArray(history) ? history : [];
    const firstUserIndex = rawHistory.findIndex(
      (m: { role?: string }) => m?.role === "user",
    );
    const trimmedHistory = firstUserIndex === -1
      ? []
      : rawHistory.slice(firstUserIndex);

    const apiMessages = [
      ...trimmedHistory.map((m: { role: string; content: string }) => ({
        role: m.role === "assistant" ? "assistant" as const : "user" as const,
        content: m.content,
      })),
      { role: "user" as const, content: message },
    ];

    const apiRes = await fetch("https://api.anthropic.com/v1/messages", {
      method: "POST",
      headers: {
        "x-api-key": ANTHROPIC_API_KEY,
        "anthropic-version": "2023-06-01",
        "content-type": "application/json",
      },
      body: JSON.stringify({
        model: MODEL,
        max_tokens: 300,
        system: systemPrompt,
        messages: apiMessages,
      }),
    });

    const apiBody = await apiRes.text();
    let parsed: { content?: { type: string; text?: string }[] };
    try {
      parsed = apiBody ? JSON.parse(apiBody) : {};
    } catch {
      parsed = {};
    }

    if (!apiRes.ok) {
      console.error(
        "Anthropic error",
        apiRes.status,
        JSON.stringify(parsed).slice(0, 2000),
      );
      const msg = parsed &&
          typeof parsed === "object" &&
          "error" in parsed &&
          (parsed as { error?: unknown }).error
        ? JSON.stringify((parsed as { error: unknown }).error)
        : `Anthropic API returned status ${apiRes.status}`;
      return json({ error: `AI assistant error: ${msg}` }, 502);
    }

    const textBlock = parsed.content?.find((b) => b.type === "text");
    const reply = textBlock?.text?.trim() ||
      "Sorry, I couldn't come up with a response.";

    return json({ reply });
  } catch (e) {
    console.error("Chat function error", e);
    return json({ error: `AI assistant error: ${String(e)}` }, 500);
  }
});