// Secure market FX fetch.
// Secrets (optional, set via `supabase secrets set`):
//   MARKET_API_PROVIDER = open_er_api | frankfurter | exchangerate_api
//                         (default: open_er_api — no key, includes PKR/AED)
//   MARKET_API_KEY      = required only for exchangerate_api
// Never expose these to Flutter.

import "jsr:@supabase/functions-js/edge-runtime.d.ts";
import { createClient } from "jsr:@supabase/supabase-js@2";

type SettingsRow = {
  market_enabled: boolean;
  market_base_currency: string;
  market_quote_currencies: string;
  default_currency: string;
};

type RateRow = {
  symbol: string;
  base_currency: string;
  currency: string;
  value: number;
  source: string;
  fetched_at: string;
};

const corsHeaders: Record<string, string> = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers":
    "authorization, x-client-info, apikey, content-type",
};

function jsonResponse(body: unknown, status = 200): Response {
  return new Response(JSON.stringify(body), {
    status,
    headers: { ...corsHeaders, "Content-Type": "application/json" },
  });
}

function parseQuotes(raw: string, base: string): string[] {
  const parts = raw
    .split(",")
    .map((s) => s.trim().toUpperCase())
    .filter((s) => s.length === 3 && s !== base);
  return [...new Set(parts)];
}

function pickQuotes(
  conversion: Record<string, number>,
  quotes: string[],
): Record<string, number> {
  const rates: Record<string, number> = {};
  for (const q of quotes) {
    if (typeof conversion[q] === "number") rates[q] = conversion[q];
  }
  return rates;
}

async function fetchWithTimeout(
  url: string,
  timeoutMs = 10000,
): Promise<Response> {
  const controller = new AbortController();
  const timer = setTimeout(() => controller.abort(), timeoutMs);
  try {
    return await fetch(url, { signal: controller.signal });
  } catch (error) {
    if (error instanceof DOMException && error.name === "AbortError") {
      throw new Error("Market API request timed out.");
    }
    throw error;
  } finally {
    clearTimeout(timer);
  }
}

async function fetchOpenErApi(
  base: string,
  quotes: string[],
): Promise<{ source: string; rates: Record<string, number> }> {
  const url =
    `https://open.er-api.com/v6/latest/${encodeURIComponent(base)}`;
  const res = await fetchWithTimeout(url);
  if (!res.ok) {
    throw new Error(`Open ER API error (${res.status})`);
  }
  const data = await res.json();
  if (data?.result !== "success") {
    throw new Error(data?.["error-type"] ?? "Open ER API failed");
  }
  const conversion = (data?.rates ?? {}) as Record<string, number>;
  return { source: "open.er-api.com", rates: pickQuotes(conversion, quotes) };
}

async function fetchFrankfurter(
  base: string,
  quotes: string[],
): Promise<{ source: string; rates: Record<string, number> }> {
  const to = quotes.join(",");
  const url =
    `https://api.frankfurter.app/latest?from=${encodeURIComponent(base)}` +
    (to ? `&to=${encodeURIComponent(to)}` : "");
  const res = await fetchWithTimeout(url);
  if (!res.ok) {
    throw new Error(`Frankfurter API error (${res.status})`);
  }
  const data = await res.json();
  const rates = (data?.rates ?? {}) as Record<string, number>;
  return { source: "frankfurter.app", rates: pickQuotes(rates, quotes) };
}

async function fetchExchangeRateApi(
  base: string,
  quotes: string[],
  apiKey: string,
): Promise<{ source: string; rates: Record<string, number> }> {
  const url =
    `https://v6.exchangerate-api.com/v6/${encodeURIComponent(apiKey)}/latest/${encodeURIComponent(base)}`;
  const res = await fetchWithTimeout(url);
  if (!res.ok) {
    throw new Error(`ExchangeRate-API error (${res.status})`);
  }
  const data = await res.json();
  if (data?.result !== "success") {
    throw new Error(data?.["error-type"] ?? "ExchangeRate-API failed");
  }
  const conversion = (data?.conversion_rates ?? {}) as Record<string, number>;
  return {
    source: "exchangerate-api.com",
    rates: pickQuotes(conversion, quotes),
  };
}

Deno.serve(async (req) => {
  if (req.method === "OPTIONS") {
    return new Response("ok", { headers: corsHeaders });
  }

  try {
    const supabaseUrl = Deno.env.get("SUPABASE_URL");
    const anonKey = Deno.env.get("SUPABASE_ANON_KEY");
    const serviceKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY");
    if (!supabaseUrl || !anonKey || !serviceKey) {
      return jsonResponse({ error: "Server misconfigured." }, 500);
    }

    const authHeader = req.headers.get("Authorization");
    if (!authHeader) {
      return jsonResponse({ error: "Missing authorization." }, 401);
    }

    const userClient = createClient(supabaseUrl, anonKey, {
      global: { headers: { Authorization: authHeader } },
    });
    const {
      data: { user },
      error: userError,
    } = await userClient.auth.getUser();
    if (userError || !user) {
      return jsonResponse({ error: "Unauthorized." }, 401);
    }

    const admin = createClient(supabaseUrl, serviceKey);

    const { data: settings, error: settingsError } = await admin
      .from("app_settings")
      .select(
        "market_enabled, market_base_currency, market_quote_currencies, default_currency",
      )
      .eq("id", 1)
      .maybeSingle();

    if (settingsError) {
      return jsonResponse({ error: settingsError.message }, 500);
    }

    const row = (settings ?? {
      market_enabled: true,
      market_base_currency: "USD",
      market_quote_currencies: "PKR,EUR,GBP,AED",
      default_currency: "PKR",
    }) as SettingsRow;

    if (!row.market_enabled) {
      return jsonResponse({ error: "Market data is disabled." }, 403);
    }

    let body: { base?: string; quotes?: string[] } = {};
    if (req.method !== "GET") {
      try {
        body = await req.json();
      } catch {
        body = {};
      }
    }

    const base = (body.base ?? row.market_base_currency ?? "USD")
      .trim()
      .toUpperCase();
    const quotes = Array.isArray(body.quotes) && body.quotes.length > 0
      ? body.quotes.map((q) => String(q).trim().toUpperCase()).filter(Boolean)
      : parseQuotes(row.market_quote_currencies, base);

    if (quotes.length === 0) {
      return jsonResponse({ error: "No quote currencies configured." }, 400);
    }

    const provider = (Deno.env.get("MARKET_API_PROVIDER") ?? "open_er_api")
      .trim()
      .toLowerCase();
    const apiKey = Deno.env.get("MARKET_API_KEY") ?? "";

    let fetched: { source: string; rates: Record<string, number> };
    if (provider === "exchangerate_api") {
      if (!apiKey) {
        return jsonResponse(
          {
            error:
              "MARKET_API_KEY secret is required for exchangerate_api provider.",
          },
          500,
        );
      }
      fetched = await fetchExchangeRateApi(base, quotes, apiKey);
    } else if (provider === "frankfurter") {
      fetched = await fetchFrankfurter(base, quotes);
    } else {
      fetched = await fetchOpenErApi(base, quotes);
    }

    const fetchedAt = new Date().toISOString();
    const insertRows = Object.entries(fetched.rates).map(([currency, value]) => ({
      source: fetched.source,
      data_type: "fx_rate",
      symbol: `${base}/${currency}`,
      base_currency: base,
      value,
      currency,
      meta: { provider },
      fetched_at: fetchedAt,
    }));

    if (insertRows.length === 0) {
      return jsonResponse(
        {
          error:
            "No rates returned for the configured currencies. Check base/quote settings or provider coverage.",
        },
        502,
      );
    }

    const { error: insertError } = await admin.from("market_data").insert(
      insertRows,
    );
    if (insertError) {
      return jsonResponse({ error: insertError.message }, 500);
    }

    const rates: RateRow[] = insertRows.map((r) => ({
      symbol: r.symbol,
      base_currency: r.base_currency,
      currency: r.currency,
      value: r.value,
      source: r.source,
      fetched_at: r.fetched_at,
    }));

    return jsonResponse({
      base,
      source: fetched.source,
      provider,
      fetched_at: fetchedAt,
      rates,
    });
  } catch (error) {
    const message = error instanceof Error ? error.message : "Unexpected error";
    return jsonResponse({ error: message }, 500);
  }
});
