# HiveWisdom Demo

Describe an initiative. See how it could fail before it actually does.

A small open source Rails 8 app that runs a structured premortem on
any initiative you are about to commit to. Sign in, describe the
initiative in five fields, click Run Premortem, and within thirty
seconds get a ranked first-draft analysis of how it could fail, what
warning signals to watch for, what to do this week, and the one
uncomfortable truth most premortems skip past.

![HiveWisdom Demo screenshot](docs/screenshot.png)

## Why I Built This

Most initiatives fail for reasons the team could have anticipated.
Premortem is one of the highest-leverage foresight practices available —
it imagines the failure before it happens, surfaces the assumptions nobody
named, and gives the team something concrete to argue with. Teams that run
premortems ship better outcomes. The practice gets skipped because running
a good one requires facilitation skill, time, and the emotional willingness
to look at failure before it happens.

An AI-assisted first draft removes that friction. This tool produces a
structured premortem in under thirty seconds — five failure modes ranked
by likelihood, early warning signals for each, a ranked list of preventive
actions, and the one uncomfortable truth most teams dance around. The team
still has to do the work of evaluating it. The tool just removes the blank
page.

This is one feature from a larger Living Foresight Platform I am building
called HiveWisdom — a multi-tenant platform that combines panels, surveys,
prediction markets, and scenario exercises, operationalized through a
structured foresight cycle. The demo extracts only the premortem engine,
runs it locally for one signed-in user, and ships under MIT license.

## Demo Credentials

```
Email:    demo@example.com
Password: password123
```

The seeded admin account has two sample initiatives pre-loaded. One already
has a full premortem; the other is ready for you to run live.

## Editable Prompt

The AI prompt for this demo is a seeded database record, not hardcoded.
To tune it:

1. Sign in as the seeded admin (`demo@example.com` / `password123`)
2. Go to `/admin/ai_templates`
3. Click `hivewisdom_premortem_v1` → Edit
4. Adjust the system prompt, temperature, or max tokens
5. Use the **Test This Template** panel on the right to run the prompt without saving

The live test panel writes to the LLM request log but does not save a premortem.
Iteration is cheap.

---

## Quick Start

1. Clone this repo
2. Run `bin/setup`
3. Add your Gemini API key to `.env` (get one free at https://aistudio.google.com/app/apikey)
4. `rails db:seed`
5. `bin/rails server`
6. Visit http://localhost:3000 and sign in with `demo@example.com` / `password123`

## Environment Variables

| Variable | Default | Description |
|---|---|---|
| `APP_NAME` | `"Open Demo Starter"` | Displayed in the navbar and title |
| `APP_TAGLINE` | — | Shown in the footer |
| `APP_DESCRIPTION` | — | Shown on the landing page |
| `GEMINI_API_KEY` | (required) | Your Google Gemini API key |
| `AI_CALLS_PER_USER_PER_DAY` | `50` | Daily AI call budget per user |
| `AI_GLOBAL_TIMEOUT_SECONDS` | `15` | Gemini request timeout in seconds |

## Stack

| Layer | Choice |
|---|---|
| Framework | Rails 8.1 |
| Database | PostgreSQL with UUID primary keys |
| Auth | Rails native (`has_secure_password`, sessions) |
| CSS | Bootstrap 5 dark mode (CDN) |
| JavaScript | Stimulus + Turbo via importmap |
| AI | Google Gemini via `faraday` (REST) |
| Queue / Cache / Cable | Solid Stack (no Redis) |
| Testing | RSpec |

## AI Safety Posture

**What this boilerplate enforces:**
- Per-user daily call cap (default: 50/day, set via `AI_CALLS_PER_USER_PER_DAY`)
- Pre-flight gatekeeper: input length limit, prompt injection patterns, profanity filter
- Hard output token cap per template
- Configurable request timeout (default: 15s)
- Full request log with status, tokens, duration, and cost estimate
- Fail-soft UI: errors render an inline alert, never crash the page
- AI disclaimer in the footer on every page

**Deliberately omitted (with rationale):**
- No PII scrubbing — demo apps have no production user data
- No content moderation API — Gemini's built-in safety filters are sufficient
- No automatic retries — avoids stacking costs on transient failures
- No RAG or vector DB — single-shot prompts only
- No streaming — synchronous calls keep the code simple

See `app/services/ai_gatekeeper.rb` and `app/services/ai_budget_checker.rb` to extend.

## License

MIT — see [LICENSE](LICENSE)
