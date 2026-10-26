# Movo Draw

Kids doodle with their finger. Tap **Bring to Life** and the doodle starts moving — a black-and-red dragon doodle flies like a black-and-red dragon.

Ages **2–12**. Huge buttons, thick brush, playful colors. Offline demo works with no API keys.

## Open & run

1. Open `MovoDraw.xcodeproj` in Xcode (this folder).
2. Pick an iPhone Simulator (e.g. **iPhone 15** or **iPhone 17**).
3. Press **⌘R**.

Or from Terminal:

```bash
cd ~/MovoDraw
xcodebuild -scheme MovoDraw -destination 'platform=iOS Simulator,name=iPhone 15' build
xcrun simctl boot "iPhone 15" 2>/dev/null || true
# Install & launch after build, or just ⌘R in Xcode
```

## What works offline (no keys)

| Feature | Status |
|--------|--------|
| Finger doodle canvas | ✅ Thick brush, colors (black/red/…), undo, clear |
| Export doodle image | ✅ |
| Bring to Life CTA + magic loading | ✅ |
| Living animation | ✅ Local pipeline: analyze colors/shape → SpriteKit flight / bounce / glide using the doodle texture |
| Kid-safety prompt filter | ✅ Blocks scary/violent/sexual terms on any generative prompt |

## What needs API keys (optional)

Set one of these in the environment (or future `Secrets.xcconfig`) to prefer the cloud path:

- `MOVO_DRAW_API_KEY`
- `REPLICATE_API_TOKEN`
- `OPENAI_API_KEY`
- `RUNWAY_API_KEY`

`LifeServiceFactory` selects `CloudLifeService` when a key exists. The cloud adapter is stubbed to keep the app compiling without inventing credentials — wire your image-to-video provider inside `CloudLifeService.bringToLife` and return `.remoteVideo(URL)`. Until then, a detected key still falls back to the local animation so Simulator demos never break.

## Architecture

- `LifeService` protocol — swap local demo ↔ cloud model
- `LocalDemoLifeService` — `DoodleAnalyzer` + SpriteKit `LivingDoodleView`
- `SafetyFilter` — kid-safe prompt suffix + blocked-term gate
- SwiftUI shell + UIKit canvas for reliable drawing

## Safety approach

1. **Default local path** never calls a generative model.
2. Any cloud prompt is built from color/subject heuristics, then run through `SafetyFilter.sanitizePrompt` with an explicit kid-safe style suffix (no violence, horror, weapons, sexual content, gore).
3. Blocked-term list rejects unsafe prompt text before it would leave the device.
4. Full COPPA / App Store parental controls are out of scope for this MVP.

## Repo

- GitHub: https://github.com/leylaarc/movo-draw  
- Local: `~/MovoDraw` (sibling of MovoLearn — **not** inside the movolearn repo)
