import { NextResponse } from "next/server";
import Replicate from "replicate";
import { FLUX_MODEL, MAGIC_PROMPT } from "@/lib/prompt";

export const runtime = "nodejs";
export const dynamic = "force-dynamic";
export const maxDuration = 120;

const MAX_IMAGE_CHARS = 8_000_000;

let busy = false;

export async function GET() {
  return NextResponse.json(
    { configured: Boolean(process.env.REPLICATE_API_TOKEN?.trim()) },
    { headers: { "Cache-Control": "no-store" } },
  );
}

export async function POST(request: Request) {
  const token = process.env.REPLICATE_API_TOKEN?.trim();
  if (!token) {
    return NextResponse.json(
      { error: "A grown-up needs to add a Replicate key before the magic can run." },
      { status: 503 },
    );
  }

  if (busy) {
    return NextResponse.json(
      { error: "Magic is already working on a picture." },
      { status: 429 },
    );
  }

  const body = (await request.json().catch(() => null)) as { image?: unknown } | null;
  const image = body?.image;
  if (typeof image !== "string") {
    return NextResponse.json(
      { error: "The drawing did not come through. Try again." },
      { status: 400 },
    );
  }

  const match = /^data:image\/png;base64,([A-Za-z0-9+/=\r\n]+)$/.exec(image);
  if (!match) {
    return NextResponse.json(
      { error: "The drawing did not come through. Try again." },
      { status: 400 },
    );
  }
  if (match[1].length > MAX_IMAGE_CHARS) {
    return NextResponse.json(
      { error: "That drawing is too big. Try a simpler picture." },
      { status: 413 },
    );
  }

  busy = true;
  try {
    const bytes = Buffer.from(match[1], "base64");
    const drawing = new File([new Uint8Array(bytes)], "drawing.png", { type: "image/png" });
    const replicate = new Replicate({ auth: token });
    const output = await replicate.run(FLUX_MODEL, {
      input: {
        prompt: MAGIC_PROMPT,
        input_images: [drawing],
        aspect_ratio: "match_input_image",
        resolution: "1 MP",
        output_format: "jpg",
        output_quality: 90,
        safety_tolerance: 2,
        prompt_upsampling: false,
      },
    });

    const picture = await outputToDataUrl(output);
    return NextResponse.json({ image: picture }, { headers: { "Cache-Control": "no-store" } });
  } catch (error) {
    console.error("Flux request failed:", error instanceof Error ? error.message : error);
    return NextResponse.json({ error: friendlyFailure(error) }, { status: 502 });
  } finally {
    busy = false;
  }
}

async function outputToDataUrl(output: unknown): Promise<string> {
  const value = Array.isArray(output) ? output[0] : output;
  if (!value) throw new Error("The model did not return an image.");

  if (hasBlobMethod(value)) {
    const blob = await value.blob();
    return blobToDataUrl(blob);
  }

  if (typeof Blob !== "undefined" && value instanceof Blob) {
    return blobToDataUrl(value);
  }

  const remote = await readUrl(value);
  const response = await fetch(remote);
  if (!response.ok) throw new Error(`Could not download the picture (${response.status}).`);
  const bytes = Buffer.from(await response.arrayBuffer());
  const type = response.headers.get("content-type")?.split(";")[0] || "image/jpeg";
  return `data:${type};base64,${bytes.toString("base64")}`;
}

function hasBlobMethod(value: unknown): value is { blob: () => Promise<Blob> } {
  return Boolean(
    value &&
      typeof value === "object" &&
      "blob" in value &&
      typeof (value as { blob?: unknown }).blob === "function",
  );
}

async function blobToDataUrl(blob: Blob): Promise<string> {
  const bytes = Buffer.from(await blob.arrayBuffer());
  const type = blob.type || "image/jpeg";
  return `data:${type};base64,${bytes.toString("base64")}`;
}

async function readUrl(value: unknown): Promise<string> {
  if (typeof value === "string") return value;
  if (value instanceof URL) return value.href;
  if (value && typeof value === "object" && "url" in value) {
    const url = (value as { url: unknown }).url;
    const resolved = typeof url === "function" ? await url.call(value) : url;
    if (typeof resolved === "string") return resolved;
    if (resolved instanceof URL) return resolved.href;
    if (resolved && typeof resolved === "object" && "href" in resolved) {
      return String((resolved as { href: unknown }).href);
    }
  }
  throw new Error("The model did not return an image.");
}

function friendlyFailure(error: unknown): string {
  const message = (error instanceof Error ? error.message : String(error)).toLowerCase();
  if (message.includes("401") || message.includes("unauth") || message.includes("invalid token")) {
    return "The Replicate key was not accepted. A grown-up should check it.";
  }
  if (message.includes("402") || message.includes("credit") || message.includes("billing")) {
    return "The Replicate account needs credits before the magic can run.";
  }
  if (message.includes("safety") || message.includes("nsfw")) {
    return "The magic skipped this drawing. Try a different picture.";
  }
  return "The magic got tangled. Try again in a moment.";
}
