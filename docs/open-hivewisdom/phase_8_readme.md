# Phase 8 — README & Polish

**Goal:** Update README.md with HiveWisdom-specific content, add the screenshot placeholder, and run a final security audit.

---

## 1. README Updates

The boilerplate README has sections for Stack, Setup, License, AI Safety Posture, and About the Author. Prepend or replace the top of the file with HiveWisdom-specific content, keeping the boilerplate sections below.

### Heading Block (replaces any existing heading)

```markdown
# HiveWisdom Demo

Describe an initiative. See how it could fail before it actually does.

A small open source Rails 8 app that runs a structured premortem on
any initiative you are about to commit to. Sign in, describe the
initiative in five fields, click Run Premortem, and within fifteen
seconds get a ranked first-draft analysis of how it could fail, what
warning signals to watch for, what to do this week, and the one
uncomfortable truth most premortems skip past.

![HiveWisdom Demo screenshot](docs/screenshot.png)
```

### Why I Built This

```markdown
## Why I Built This

Most initiatives fail for reasons the team could have anticipated.
Premortem is one of the highest-leverage foresight practices available —
it imagines the failure before it happens, surfaces the assumptions nobody
named, and gives the team something concrete to argue with. Teams that run
premortems ship better outcomes. The practice gets skipped because running
a good one requires facilitation skill, time, and the emotional willingness
to look at failure before it happens.

An AI-assisted first draft removes that friction. This tool produces a
structured premortem in under fifteen seconds — five failure modes ranked
by likelihood, early warning signals for each, a ranked list of preventive
actions, and the one uncomfortable truth most teams dance around. The team
still has to do the work of evaluating it. The tool just removes the blank
page.

This is one feature from a larger Living Foresight Platform I am building
called HiveWisdom — a multi-tenant platform that combines panels, surveys,
prediction markets, and scenario exercises, operationalized through a
structured foresight cycle. The demo extracts only the premortem engine,
runs it locally for one signed-in user, and ships under MIT license.
If you want to see the full platform, it is at [hivewisdom.app](https://hivewisdom.app) (placeholder).
```

### Demo Credentials

```markdown
## Demo Credentials

```
Email:    demo@example.com
Password: password123
```

The seeded admin account has two sample initiatives pre-loaded. One already
has a full premortem; the other is ready for you to run live.
```

### Editable Prompt Note

```markdown
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
```

---

## 2. Screenshot Placeholder

Add a placeholder image file at `docs/screenshot.png`. This can be a blank PNG or a genuine screenshot taken after Phase 6 seed data is loaded and a live premortem is run.

To create a minimal placeholder (1x1 transparent PNG):

```bash
# From project root — creates a valid 1x1 PNG placeholder
printf '\x89PNG\r\n\x1a\n\x00\x00\x00\rIHDR\x00\x00\x00\x01\x00\x00\x00\x01\x08\x06\x00\x00\x00\x1f\x15\xc4\x89\x00\x00\x00\nIDATx\x9cc\x00\x01\x00\x00\x05\x00\x01\r\n-\xb4\x00\x00\x00\x00IEND\xaeB`\x82' > docs/screenshot.png
```

Replace with a real screenshot before making the repo public.

---

## 3. Final Security Audit Checklist

Run each of the following from the project root before tagging the release:

```bash
# No real API keys in any committed file
grep -r "GEMINI_API_KEY" . --include="*.rb" --include="*.yml" --include="*.env*" \
  | grep -v ".env.example" | grep -v ".gitignore"
# Expected: zero matches outside .env.example and docs

# No .env in git index
git ls-files | grep -E "^\.env$"
# Expected: empty output

# No debug statements
grep -r "binding\.pry\|byebug\|debugger" app/ spec/
# Expected: zero matches

# No hardcoded app name (should always come from ENV)
grep -r "HiveWisdom Demo\|Open Demo Starter" app/views/ app/mailers/
# Expected: zero matches (all names come from ENV.fetch)

# No password123 outside of seeds, docs, and test fixtures
grep -r "password123" app/
# Expected: zero matches
```

---

## 4. .env.example Final Version

Ensure `.env.example` matches the final set of required variables:

```
# App branding — customize per demo
APP_NAME="HiveWisdom Demo"
APP_TAGLINE="Describe an initiative. See how it could fail before it actually does."
APP_DESCRIPTION="HiveWisdom Demo runs a structured premortem on any initiative you are about to commit to. Fill in five fields, click Run Premortem, and get a ranked analysis of how it could fail, what to watch for, and what to do this week."

# Gemini API — get your key at https://aistudio.google.com
GEMINI_API_KEY=your_key_here

# AI operational settings
AI_CALLS_PER_USER_PER_DAY=50
AI_GLOBAL_TIMEOUT_SECONDS=15
```

---

## Acceptance Criteria

- README heading, "Why I Built This", demo credentials, and editable prompt sections are present
- `docs/screenshot.png` exists (even as a placeholder)
- `git ls-files | grep "^\.env$"` returns empty
- `grep -r "binding.pry" app/ spec/` returns empty
- `grep -r "GEMINI_API_KEY" . | grep -v ".env.example" | grep -v "docs/"` returns empty
- Full end-to-end happy path: clone → `bin/setup` → `rails db:seed` → sign in → create initiative → run premortem → accordion renders
