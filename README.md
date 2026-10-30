# Movo Draw

Kids doodle with their finger. Tap **Bring to Life** and AI turns the doodle into a **realistic, kid-safe image** that matches what they drew (black+red dragon doodle → realistic black+red dragon).

Ages **2–12**. Huge buttons, playful crayons, and a simple tools tray (size, stroke, opacity).

## Open & run

1. Open `MovoDraw.xcodeproj` in Xcode.
2. Pick an iPhone Simulator (e.g. **iPhone 15** / OS 17.5).
3. Set an API key (below) for realistic images.
4. Press **⌘R**.

```bash
cd ~/MovoDraw
xcodebuild -scheme MovoDraw -destination 'platform=iOS Simulator,name=iPhone 15,OS=17.5' build
```

## API key setup (required for realistic images)

**Primary provider: [fal.ai](https://fal.ai)** — `FAL_KEY`  
Model: `fal-ai/flux-kontext/dev` (FLUX Kontext image-to-image). Accepts the doodle as `image_url` (data URI) + a kid-safe prompt.

### Option A — Xcode scheme (recommended for Simulator)

1. Create a key at https://fal.ai/dashboard/keys  
2. Xcode → **Product → Scheme → Edit Scheme… → Run → Arguments → Environment Variables**  
3. Add:
   - Name: `FAL_KEY`
   - Value: your key  
4. Or alias: `MOVO_DRAW_API_KEY` (same value; app accepts either)

### Option B — Keychain (optional)

```bash
security add-generic-password -a FAL_KEY -s com.movodraw.app -w 'YOUR_FAL_KEY' -U
```

### Option C — OpenAI fallback

If `FAL_KEY` is missing but `OPENAI_API_KEY` is set, the app uses **OpenAI Images edits** (`gpt-image-1`) with `moderation=auto`.

**Never commit keys.** `Secrets.xcconfig` is gitignored. See `Secrets.xcconfig.example`.

> Production note: shipping a key inside a client app is unsafe. For App Store, proxy through your backend. Simulator / TestFlight MVP may use scheme env for convenience.

## Drawing tools

- **Tools menu** — color, type, size, and opacity live in one sheet so the canvas stays big
- **Colors** — quick swatches + **More Colors** (gradient color wheel + Bright / Soft / Skin / Earth / Neutrals crayons)
- **Stroke** — Pen (solid ink) · Marker (flat translucent highlighter) · Crayon (waxy / speckled) · Eraser
- **Size** — Fine / Tiny / Small / Medium / Large / X-Large / Huge
- **Opacity** — continuous scale from Faint → Solid
- Slim Draw dock: **Tools** · Undo · Clear · Bring to Life
- Each stroke stores color, width, opacity, and style so undo / clear / export stay correct

## What works

| Feature | Needs key? | Notes |
|--------|------------|--------|
| Draw canvas (colors, sizes, stroke styles, opacity, undo, clear) | No | Offline; collapsible tray keeps canvas dominant |
| Bring to Life → **realistic image** | **Yes** (`FAL_KEY` or `OPENAI_API_KEY`) | Primary result |
| Offline fallback (SpriteKit flight) | No | Clearly labeled **Offline** — secondary only |
| Kid-safe prompt filter | Always | Blocks scary/violent/sexual terms; fal safety checker / OpenAI moderation |

## Why fal.ai FLUX Kontext

| Provider | Fit for crude doodles | Safety | Latency / cost | iOS |
|----------|----------------------|--------|----------------|-----|
| **fal.ai FLUX Kontext** ✅ | Excellent img2img from sketch | `enable_safety_checker` + our prompts; Pro has `safety_tolerance` | Fast queue; pay-per-megapixel | REST + data URI |
| fal Flux + ControlNet scribble | Strongest line adherence | Same | Slightly more setup | Supported later |
| OpenAI gpt-image-1 edits | Strong reinterpretation | Built-in `moderation=auto` | Good; usage-priced | Multipart REST |
| Replicate ControlNet scribble | Classic scribble | Prompt-only | ~$0.05 / ~40s | REST |
| Stability / Recraft / BFL | Good quality | Varies | Varies | Extra accounts |

**Pick for this MVP:** fal Kontext — simple doodle reference API, solid realism, safety checker, data-URI friendly (no file host). OpenAI is wired as secondary when only `OPENAI_API_KEY` is present.

## Architecture

- `LifeService` → `CloudLifeService` (fal / OpenAI) or `LocalDemoLifeService` (fallback)
- `FalImageClient` / `OpenAIImageClient`
- `SafetyFilter` — creative prompt + kid-safe style suffix + negative prompt
- `APIKeyStore` — env → Keychain (never Info.plist)

## Safety

1. Client blocked-term gate before any request.  
2. Kid-safe style suffix + negative prompt.  
3. Provider safety: fal `enable_safety_checker`; OpenAI `moderation=auto`.  
4. NSFW flags from fal → refuse.  
5. Full COPPA / parental Gatekeeper still out of scope for this pass.

## Demo launch arg

```bash
xcrun simctl launch booted com.movodraw.app -DemoDragon
```

Seeds a black/red dragon doodle and runs Bring to Life.

## Repo

- GitHub: https://github.com/leylaarc/movo-draw  
- Local: `~/MovoDraw` (not inside MovoLearn)
