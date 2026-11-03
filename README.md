# Movo Draw

A drawing studio for children. Draw on the page, pick pen sizes and colors from the wheel, then turn the picture into a realistic magical version with Flux on Replicate.

## Setup

1. Install dependencies with `npm install`.
2. Copy `.env.example` to `.env.local`.
3. Add a token from [replicate.com/account/api-tokens](https://replicate.com/account/api-tokens) as `REPLICATE_API_TOKEN`.
4. Start the app with `npm run dev` and open [http://localhost:3000](http://localhost:3000).

The token stays on the server. A drawing is sent to `black-forest-labs/flux-2-pro` only when someone presses **Make it magical**. Each picture uses the Replicate account.

Keep the dev server on a trusted network. The magic route can spend Replicate credits for anyone who can reach it.
