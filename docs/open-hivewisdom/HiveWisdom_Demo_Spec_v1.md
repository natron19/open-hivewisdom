# HiveWisdom Demo - GitHub Spec

**Document Version:** 1.0
**Last Updated:** May 4, 2026
**Built On:** Open Demo Starter v2.0
**License:** MIT
**Accent Color:** `#eab308` (golden yellow)
**UX Pattern:** Form-then-result with ranked failure-modes accordion

---

## 1. App Overview

HiveWisdom Demo is an open source Rails 8 app that runs a structured premortem on any initiative the user is about to launch. The user describes the initiative in five short fields (name, success definition, time horizon, current state, team context); the app returns a ranked, structured analysis of how that initiative could fail, what early warning signals to watch for, what preventive actions to take this week, and the one uncomfortable truth most teams avoid naming.

### The Problem

Most initiatives fail for reasons the team could have anticipated. Premortem is one of the highest-leverage foresight practices available, but it gets skipped because running one takes facilitation skill, time, and emotional willingness to look at failure before it has happened. A small AI-assisted tool that reliably produces a structured first draft removes the friction and gives the team something concrete to push back on.

### The Indie Hacker Angle

This demo isolates a single feature from a larger product. HiveWisdom proper is a multi-tenant Living Foresight Platform that combines panels, surveys, prediction markets, and scenario exercises, operationalized through the READY framework (Recruit, Elicit, Analyze, Discuss, Yield). Premortem is one elicitation method inside that platform. The demo extracts only the premortem engine, runs it locally for one signed-in user, and ships under MIT license.

### What This Demo Is Not

- Not the full HiveWisdom platform (no panels, no surveys, no prediction markets, no scenarios, no Foresight Cycle, no READY stage stepper)
- Not multi-tenant (single signed-in user only; the production app is team-collaborative)
- Not deployed (runs on localhost; the README does not include deploy instructions)
- Not connected to the rest of the suite (CollectiveCRM, Coursement, etc. are out of scope)

### Visitor Promise

A visitor who clones the repo can sign in as the seeded admin user, paste a real initiative they are running this quarter, click Run Premortem, and within fifteen seconds see a serious first-draft critique they can take into their next team meeting.

---

## 2. Customizations Applied to the Boilerplate

The boilerplate already provides the layout, the auth flow, the Gemini service, the request log, the gatekeeper, the budget cap, the admin panel, and the RSpec scaffolding. This demo customizes the following:

- **Branding env vars** in `.env.example`: `APP_NAME=HiveWisdom Demo`, `APP_TAGLINE=Describe an initiative. See how it could fail before it actually does.`, `APP_DESCRIPTION` set to a one-paragraph framing of the premortem practice.
- **Accent color** in `app/assets/stylesheets/_accent.scss`: `--accent: #eab308; --accent-hover: #ca8a04;` (golden yellow on the dark Bootstrap theme).
- **Navbar links**: adds "Initiatives" (index of saved initiatives) and "New Premortem" (shortcut to the form).
- **Home page** (`home/index.html.erb`) replaced with a single-column landing pitch: tagline, three-line explanation of premortem, single primary CTA reading "Run Your First Premortem", and a small footer note that this is an open source demo.
- **Dashboard page** (`dashboard/show.html.erb`) replaced with a two-section view: a recent-initiatives list on the left and a prominent "New Initiative" card on the right.
- **UX pattern**: Form-then-result. The new-initiative form posts and the resulting premortem renders on a dedicated show page as a Bootstrap accordion of failure modes plus a ranked checklist of preventive actions.
- **AI templates seeded** in `db/seeds.rb`: `hivewisdom_premortem_v1`. Full content in Section 7.
- **Domain seed data**: two sample initiatives with a saved premortem on one of them so the dashboard does not look empty on first run.

---

## 3. Data Model

This demo adds five domain models on top of `User`, `AiTemplate`, and `LlmRequest` (which the boilerplate provides).

### Initiative

| Field | Type | Notes |
|---|---|---|
| `id` | uuid | |
| `user_id` | uuid | `belongs_to :user` |
| `name` | string | Required, 3 to 120 chars **(template variable: `initiative_name`)** |
| `success_definition` | text | Required, 20 to 1500 chars **(template variable: `success_definition`)** |
| `time_horizon` | string | Required, enum: `3_months`, `6_months`, `12_months` **(template variable: `time_horizon`)** |
| `current_state` | text | Required, 20 to 2000 chars **(template variable: `current_state`)** |
| `team_context` | text | Required, 20 to 1500 chars **(template variable: `team_context`)** |
| `created_at` | datetime | |
| `updated_at` | datetime | |

Associations: `has_many :premortems, dependent: :destroy`. Ordered by `created_at desc` for index views.

Validations: presence on all five user-facing fields; length bounds as listed; `time_horizon` inclusion in the enum set.

### Premortem

| Field | Type | Notes |
|---|---|---|
| `id` | uuid | |
| `initiative_id` | uuid | `belongs_to :initiative` |
| `imagined_failure_date` | date | Parsed from Gemini JSON |
| `reflection` | text | Optional. Free-form note the user adds after reading the premortem. |
| `avoided_truth` | text | The "one thing the team is probably avoiding" sentence from Gemini |
| `gemini_raw` | text | Full raw JSON response **(Gemini output, used for Show raw response toggle)** |
| `created_at` | datetime | |

Associations: `has_many :failure_modes, dependent: :destroy`, `has_many :preventive_actions, dependent: :destroy`. Always shown most-recent-first per initiative.

### FailureMode

| Field | Type | Notes |
|---|---|---|
| `id` | uuid | |
| `premortem_id` | uuid | `belongs_to :premortem` |
| `statement` | text | One-sentence plausible failure mode |
| `severity` | string | Enum: `low`, `medium`, `high` |
| `assumption` | text | The assumption that would have to break for this failure to occur |
| `rank` | integer | 1 through 5; 1 is most likely |

Associations: `has_many :warning_signals, dependent: :destroy`. Default scope ordered by `rank asc`.

### WarningSignal

| Field | Type | Notes |
|---|---|---|
| `id` | uuid | |
| `failure_mode_id` | uuid | `belongs_to :failure_mode` |
| `signal` | text | The observable thing the team can watch for |
| `measurement_method` | text | How the team would actually observe or measure this signal |

Two to three signals per failure mode is the expected range; not enforced as a constraint.

### PreventiveAction

| Field | Type | Notes |
|---|---|---|
| `id` | uuid | |
| `premortem_id` | uuid | `belongs_to :premortem` |
| `description` | text | Specific action the team could take this week |
| `effectiveness_to_effort` | integer | 1 (low) through 5 (high); used to rank |
| `rank` | integer | 1 through 7; 1 is highest leverage |
| `started` | boolean | Default false. User toggles in the UI as they begin acting. |

Default scope ordered by `rank asc`. Five to seven records per premortem is the expected range.

---

## 4. Routes

| Verb | Path | Controller#Action | Purpose |
|---|---|---|---|
| GET | `/initiatives` | `initiatives#index` | List the signed-in user's initiatives |
| GET | `/initiatives/new` | `initiatives#new` | Form for a new initiative |
| POST | `/initiatives` | `initiatives#create` | Create the initiative; redirect to its show page |
| GET | `/initiatives/:id` | `initiatives#show` | Initiative detail with most recent premortem if any |
| GET | `/initiatives/:id/edit` | `initiatives#edit` | Edit initiative inputs |
| PATCH | `/initiatives/:id` | `initiatives#update` | Update initiative fields |
| DELETE | `/initiatives/:id` | `initiatives#destroy` | Delete initiative and its premortems |
| POST | `/initiatives/:id/premortems` | `premortems#create` | Trigger a Gemini premortem for this initiative |
| GET | `/initiatives/:initiative_id/premortems/:id` | `premortems#show` | Show a specific historical premortem |
| PATCH | `/preventive_actions/:id/toggle` | `preventive_actions#toggle` | Flip the `started` boolean (Turbo Stream response) |
| PATCH | `/premortems/:id/reflection` | `premortems#update_reflection` | Save the user's reflection note (Turbo Stream response) |

All HTML responses; the two `PATCH` toggles return Turbo Streams that swap the affected partial in place. No JSON API routes.

Auth routes (`/sign_up`, `/sign_in`, `/passwords`) and admin routes (`/admin/*`) come from the boilerplate and are not redescribed here.

---

## 5. Controllers and Actions

### `InitiativesController`

Inherits from `ApplicationController`. Scopes all queries to `current_user.initiatives`. Uses strong parameters on `name`, `success_definition`, `time_horizon`, `current_state`, `team_context`.

- **`index`**: Lists `current_user.initiatives` ordered most-recent-first. Each row shows name, time horizon, count of premortems, and the date of the most recent premortem if any.
- **`new`**: Builds an unsaved `Initiative` and renders the form. Time horizon is a Bootstrap segmented button group (3 / 6 / 12 months).
- **`create`**: Persists the initiative and redirects to its show page with a flash prompting the user to run the first premortem.
- **`show`**: Loads the initiative and its most recent premortem (with eager-loaded failure modes, warning signals, and preventive actions). Renders the form-then-result layout.
- **`edit`**, **`update`**: Standard. Editing the initiative does not invalidate prior premortems; it just enables a fresh one against the updated context.
- **`destroy`**: Deletes the initiative and its dependent premortems. Confirmation via Turbo Confirm.

### `PremortemsController`

Inherits from `ApplicationController`. Scopes through `current_user.initiatives` to enforce ownership.

- **`create`**: This is the action that triggers the Gemini call. It (1) loads the initiative, (2) calls `GeminiService.generate(template: "hivewisdom_premortem_v1", variables: { ...five fields... })`, (3) parses the returned JSON, (4) wraps the create in a transaction that builds the Premortem, FailureMode records (with nested WarningSignals), and PreventiveAction records, (5) saves the raw JSON on the Premortem's `gemini_raw` field, (6) redirects to the initiative show page with the new premortem highlighted. Catches `GeminiService::GeminiError` and renders the boilerplate's retry-error partial inline.
- **`show`**: For viewing a historical premortem (a different one from the most recent shown on the initiative show page).
- **`update_reflection`**: Saves the user's free-form reflection note via Turbo Stream. The textarea swaps to a confirmed state on success.

### `PreventiveActionsController`

Inherits from `ApplicationController`. Scopes through `current_user.initiatives.joins(:premortems).joins(:preventive_actions)` to enforce ownership.

- **`toggle`**: Flips `started` and returns a Turbo Stream that re-renders the single checklist item with the new visual state.

All three controllers wrap any Gemini call in `rescue GeminiService::GeminiError => e` and use the boilerplate-provided retry partial. Specific subclasses (`BudgetExceededError`, `GatekeeperError`, `TimeoutError`) get specific copy in the alert.

---

## 6. Views

Every view that displays a Gemini-generated output includes a "Show raw response" Bootstrap collapse toggle that reveals the `gemini_raw` JSON. This is inherited UX expectation.

### `home/index.html.erb` (replaces the boilerplate placeholder)

- Single full-width hero section with the app name, tagline, and a 60-word framing of what a premortem is and why it matters
- Single primary button: "Run Your First Premortem"
- Three small icons-with-labels under the hero: "Describe", "Imagine Failing", "Plan This Week"
- Footer note: "Open source under MIT. This is one feature from a larger foresight platform."

### `dashboard/show.html.erb` (replaces the boilerplate placeholder)

- Two-column layout (Bootstrap row with `col-md-8` and `col-md-4`)
- Left column: list group of recent initiatives with name, time horizon badge, and "View" link
- Right column: a card titled "New Initiative" with three bullets describing what to prepare and a primary button linking to `/initiatives/new`

### `initiatives/index.html.erb`

- Page header with "Your Initiatives" and a "New Initiative" button (top right, accent color)
- Bootstrap table with columns: Name, Time Horizon, Premortems, Latest Premortem, Actions
- Empty state: a single Bootstrap alert with a CTA to create the first initiative

### `initiatives/_form.html.erb` (partial, used by `new` and `edit`)

- Vertical stacked form
- Name field (single-line input)
- Success definition (textarea, 4 rows, helper text "What does success look like in one paragraph?")
- Time horizon (Bootstrap segmented button group with values 3 / 6 / 12 months)
- Current state (textarea, 4 rows, helper text "Where is this work today?")
- Team context (textarea, 3 rows, helper text "Who is involved? What is the team's history?")
- Submit button: "Save Initiative" or "Update Initiative"

### `initiatives/show.html.erb`

The form-then-result page. Three sections rendered in order:

1. **Initiative summary card**: name (h1), time horizon badge, and the four user-supplied text fields rendered as labeled paragraphs. "Edit" button (top right).
2. **Run-premortem call to action** if no premortem yet: a card with a single button "Run Premortem". If a premortem exists, this section becomes a subtle "Re-run premortem" link below the result.
3. **Most recent premortem** (renders the `_premortem.html.erb` partial), only present if the initiative has at least one premortem.

The premortem render is wrapped in a Turbo Frame so re-running can swap the result without a full page reload.

### `initiatives/_premortem.html.erb` (partial)

The accordion. Rendered in this order:

1. **Imagined Failure Date banner**: a prominent header card with the date in a large font and the phrase "By this date, this initiative has failed because..." Used to anchor the analysis emotionally.
2. **Top 5 Failure Modes accordion** (Bootstrap accordion with five items):
   - Each item header: rank number, the one-sentence statement, and a severity badge (low / medium / high; color-coded gray / yellow / red)
   - Each item body: the assumption that would have to break (paragraph, italic), then "Early Warning Signals" as an unordered list of two to three items with the measurement method shown as muted text under each signal
3. **Preventive Actions This Week**: a ranked checklist of five to seven items. Each item is a row with a checkbox (toggles the `started` boolean via Turbo Stream), the description, and a small "leverage" badge showing the effectiveness-to-effort score. Items the user has marked started render with a strikethrough and a faded color.
4. **The Avoided Truth**: a callout card with a quote-style left border in the accent color. Single italicized paragraph.
5. **Reflection** (optional, user-editable): a textarea with a "Save Reflection" button that posts to `update_reflection` and swaps to a saved-state badge on success.
6. **Show raw response** toggle (Bootstrap collapse) that reveals the `gemini_raw` JSON in a `<pre>` block at the bottom.

### `premortems/show.html.erb`

For viewing a historical premortem. Renders the same `_premortem.html.erb` partial above the initiative summary, plus a back link to the initiative.

### `shared/_gemini_error.html.erb`

Comes from the boilerplate. Used in the `create` action's rescue clause. The retry button posts back to the same `premortems#create` endpoint.

---

## 7. AI Templates and Gemini Integration

This demo seeds one `AiTemplate` record. The boilerplate's `GeminiService` looks it up by name; this section specifies its full content.

### Template `hivewisdom_premortem_v1`

**Description:** Runs a structured premortem on a user-described initiative. Returns five ranked failure modes with warning signals and a ranked list of preventive actions.

**Model:** `gemini-2.0-flash`

**`max_output_tokens`:** 3000

The default 2000 is too tight; a structured premortem with five failure modes (each with an assumption and two-to-three signals) plus seven preventive actions plus the avoided truth comfortably exceeds 2000 tokens. 3000 leaves headroom without inviting padding.

**`temperature`:** 0.6

Slightly below the default 0.7. The structure is fixed (JSON schema) but the content benefits from some creative leap to surface non-obvious failure modes. 0.6 keeps the output disciplined while preserving variation across runs.

**Variables consumed:**

- `{{initiative_name}}` from `Initiative#name`
- `{{success_definition}}` from `Initiative#success_definition`
- `{{time_horizon}}` from `Initiative#time_horizon` (string `3_months`, `6_months`, or `12_months`)
- `{{current_state}}` from `Initiative#current_state`
- `{{team_context}}` from `Initiative#team_context`

**`system_prompt`:**

```
You are a foresight practitioner running a premortem on an initiative the user is about to commit to. Your job is to imagine that the initiative has already failed and to reconstruct, plausibly, why it failed.

You will not hedge. You will not soften. You will not tell the user the initiative sounds promising. The user already knows the optimistic case; that is why they brought it to you. They are paying for the pessimistic, structured first draft they cannot easily produce on their own.

Your output is the analysis a thoughtful skeptic would write after a half-hour reading the brief. It is specific, falsifiable where possible, and grounded in the user's own context (the team, the time horizon, the current state). It does not invoke generic startup failure modes that could apply to any initiative.

You produce JSON only. No prose preamble, no closing remarks, no markdown fences around the JSON. The schema is provided in the user prompt; deviating from it breaks the application.

You will populate every field. If a field is hard to fill, fill it with your best plausible guess rather than leaving it empty. The user will calibrate what is useful and what is noise.

You will name the one uncomfortable truth the team is probably avoiding. This is the highest-leverage item in your output. It is usually a relationship, a missing skill, an unspoken disagreement, or a structural constraint that nobody wants to surface in a planning meeting. If everything else in your output is correct but this field is bland, your output has failed.
```

**`user_prompt_template`:**

```
Run a premortem on the following initiative. Imagine you are looking back from the failure date you choose; the initiative has failed; you are explaining why.

INITIATIVE NAME:
{{initiative_name}}

WHAT SUCCESS LOOKS LIKE:
{{success_definition}}

TIME HORIZON:
{{time_horizon}}

CURRENT STATE OF THE WORK:
{{current_state}}

TEAM AND COMMUNITY INVOLVED:
{{team_context}}

Return JSON only, no markdown fences, conforming exactly to this schema:

{
  "imagined_failure_date": "YYYY-MM-DD (a specific date by which it has become clear this initiative failed; choose a date inside the time horizon)",
  "failure_modes": [
    {
      "rank": 1,
      "statement": "One sentence describing how this initiative failed.",
      "severity": "low | medium | high",
      "assumption": "The assumption baked into the current plan that would have to break for this failure to occur.",
      "warning_signals": [
        {
          "signal": "An observable thing the team could see in the weeks before the failure becomes obvious.",
          "measurement_method": "How the team would actually observe or measure this signal."
        }
      ]
    }
  ],
  "preventive_actions": [
    {
      "rank": 1,
      "description": "A specific action the team could take this week.",
      "effectiveness_to_effort": 1
    }
  ],
  "avoided_truth": "One sentence naming the uncomfortable truth most premortems for an initiative like this would skip past."
}

Constraints:
- Exactly 5 entries in failure_modes, ranked 1 (most likely) through 5
- Each failure_mode contains 2 or 3 warning_signals
- Between 5 and 7 entries in preventive_actions, ranked 1 (highest leverage) through N
- effectiveness_to_effort is an integer from 1 (low leverage) to 5 (high leverage)
- avoided_truth is exactly one sentence
- All fields populated, no nulls
```

**`notes` (author's notes):**

```
This template is the heart of the demo. The system prompt is doing two jobs at once: enforcing the JSON contract and pushing the model away from default-helpful blandness toward something a real foresight practitioner would write.

Iteration log:
- v0 was overly polite and produced generic startup failure modes. Adding the explicit "you will not hedge" line pulled it toward sharper output.
- The "avoided_truth" field was added late and is the single most useful output. It often surfaces the team-dynamic problem the rest of the analysis dances around.
- Severity is included even though we could compute it because the model's intuition about severity is part of the analysis, and surfacing it gives the user something to argue with.

Watch for:
- The model occasionally returns the JSON inside a markdown code fence despite instructions. The parser strips fences before parsing.
- Too-generic warning signals (e.g., "team morale drops"). When this happens, lower the temperature to 0.5 and re-test.
- The avoided_truth being a platitude ("communication will be a challenge"). When this happens, the system prompt's last paragraph needs reinforcement.
```

**Where it's called:** `PremortemsController#create`.

**Expected output format:** JSON. Schema is shown in full in the user prompt template above.

**Parsing:** The controller uses a small `PremortemParser` PORO that (a) strips any ` ``` ` markdown fences, (b) calls `JSON.parse`, (c) validates the top-level keys, (d) builds the nested ActiveRecord objects in a transaction. If parsing fails, the controller raises a `GeminiService::GeminiError` so the standard fail-soft retry UI kicks in and the parse failure is logged to the `LlmRequest` record's `error_message` field.

**Raw response storage:** `Premortem#gemini_raw` holds the full JSON text exactly as Gemini returned it. The "Show raw response" toggle in the UI displays this in a `<pre>` block.

This demo does not use Gemini's function calling or any agent loop. It is a single-shot prompt with a structured JSON response.

---

## 8. AI Safety Considerations (Specific to This App)

The boilerplate's gatekeeper, budget cap, request log, timeout, fail-soft UI, and raw-response toggle apply automatically to every Gemini call in this demo. The considerations below are app-specific.

### Content Sensitivity

Premortems analyze projects, products, programs, and community initiatives. They are not therapy, not medical, not legal. The inputs are rarely sensitive. The most sensitive case is when "team_context" contains names or descriptions of specific people; users should not paste real names of people who have not consented to being characterized in an AI tool. The footer's general AI disclaimer covers the broader caveat, and the new-initiative form adds a specific helper line under the team-context field: "Avoid pasting names or identifying details of specific team members. Describe roles instead."

### Consequential Outputs

A user who acts on a premortem's preventive actions is taking action on their own initiative; the worst case is wasted effort or a misallocated week. The model's failure mode predictions are not authoritative; they are a structured first draft. The output page's accent-colored callout card (the "avoided truth") includes a single line of disclaimer copy: "These are AI-generated hypotheses, not predictions. Treat them as starting points for your team's discussion, not conclusions."

### Domain Accuracy Requirements

The premortem is not factual; it is generative. Accuracy in the traditional sense does not apply. The relevant question is whether the failure modes are plausible, specific, and useful. The demo deliberately surfaces the raw JSON so the user can see what the model produced and judge its quality, rather than treating the rendered accordion as the source of truth.

### App-Specific Disclaimer Copy

Three places carry app-specific disclaimer treatment beyond the boilerplate's footer:

- The new-initiative form's team-context field has the helper text noted above.
- The avoided-truth callout has the single line about AI-generated hypotheses.
- The "Show raw response" toggle is labeled "Show raw response (what the AI actually returned)" so the user understands they can audit the output, not just admire it.

### Tightened Settings (None Justified Here)

This demo does not justify a lower per-user daily cap or a stricter gatekeeper. Premortems are not abusable in a way that mainstream content generation is; the input format (five fields about an initiative) is awkward to weaponize. The default 50 calls per user per day is generous enough for genuine iteration and tight enough that runaway costs are bounded.

`max_output_tokens` is raised to 3000 (above the boilerplate default of 2000) because the structured JSON output reliably needs more room. This is a targeted increase justified by the schema, not a relaxation of safety posture.

### What This Demo Deliberately Does NOT Do

- **No team-collaboration features.** The production HiveWisdom platform has shared cycles, panel members, and discussion records. The demo runs the analysis for one user and stops there. Sharing analyses about colleagues would create a category of social risk this demo deliberately avoids.
- **No psychometric or personality-style outputs.** A premortem is about the initiative, not about the people. The system prompt is constructed to keep the analysis at the level of structures and assumptions, not personalities.
- **No prediction calibration tracking.** The production app records what was predicted and compares it to what happened later, which creates pressure to be cautious about predictions. The demo runs once and does not follow up; this is fine because the demo is presented as a thinking aid, not a forecasting tool.
- **No export to PDF or shareable link.** Adding sharing creates an attack surface (an AI-generated document of failure modes for a real initiative being passed around) that a single-feature demo does not need.

---

## 9. RSpec Outline

The boilerplate provides specs for `User`, `AiTemplate`, `LlmRequest`, `GeminiService`, `AiGatekeeper`, `AiBudgetChecker`, and the auth flows. The demo adds the following.

### `spec/models/initiative_spec.rb`

- Validates presence of `name`, `success_definition`, `time_horizon`, `current_state`, `team_context`
- Validates length bounds on text fields
- Validates `time_horizon` inclusion in the enum set
- `belongs_to :user`, `has_many :premortems` with dependent destroy

### `spec/models/premortem_spec.rb`

- `belongs_to :initiative`, `has_many :failure_modes` and `has_many :preventive_actions` with dependent destroy
- Default scope orders premortems most-recent-first
- `gemini_raw` is persisted as a string and survives parsing

### `spec/models/failure_mode_spec.rb`

- `belongs_to :premortem`, `has_many :warning_signals` with dependent destroy
- Severity inclusion validation
- Default scope orders by `rank asc`
- Rank uniqueness within a premortem

### `spec/models/preventive_action_spec.rb`

- `belongs_to :premortem`
- Default scope orders by `rank asc`
- `started` defaults to false

### `spec/requests/initiatives_spec.rb`

- Unauthenticated requests redirect to sign in
- A signed-in user can list, create, update, and delete their own initiatives
- A signed-in user CANNOT see another user's initiatives (returns 404)
- `create` redirects to the show page with a flash prompting a premortem run

### `spec/requests/premortems_spec.rb`

- Stubs `GeminiService.generate` via the boilerplate's test double, returning fixture JSON
- `POST /initiatives/:id/premortems` creates a Premortem with five FailureMode records, the right number of WarningSignal records per failure mode, and five-to-seven PreventiveAction records
- Verifies the raw JSON is stored on `Premortem#gemini_raw`
- Verifies an `LlmRequest` record is created on each AI call (linked to the user and to the template)
- Verifies a different signed-in user cannot trigger a premortem on someone else's initiative (returns 404)
- On a `GeminiError`, the retry partial is rendered with the appropriate message; no Premortem is created

### `spec/requests/preventive_actions_spec.rb`

- `PATCH /preventive_actions/:id/toggle` flips the `started` field
- Returns a Turbo Stream response
- A different signed-in user cannot toggle someone else's action (returns 404)

### `spec/lib/premortem_parser_spec.rb`

- Strips ` ```json ... ``` ` markdown fences cleanly
- Parses well-formed JSON into the expected nested hash
- Raises a parse error on malformed JSON (which the controller translates to a `GeminiError`)
- Validates required top-level keys are present

No system specs in v1.0. Stimulus controllers (the segmented button group, the toggle handlers) are simple enough that request-spec coverage of the resulting state changes is sufficient.

---

## 10. Seed Data

`db/seeds.rb` extends the boilerplate's seeded admin user with the following.

### AiTemplate Seed

One record, fully specified above in Section 7. The seed file creates `AiTemplate.find_or_create_by!(name: "hivewisdom_premortem_v1")` with the description, system_prompt, user_prompt_template, model, max_output_tokens, temperature, and notes. The full text is in the seed file so a visitor cloning the repo can read it without diving into the admin UI.

### Domain Seed Data

Two sample initiatives owned by the seeded `demo@example.com` user, plus one saved premortem on the first initiative. The initiatives are realistic:

**Initiative 1: "Quarterly product roadmap review with the engineering team"**

- Time horizon: 3 months
- Success definition: a paragraph about getting alignment on the next two releases and identifying the one project to cut
- Current state: a paragraph describing the current backlog and the friction with the engineering lead
- Team context: a paragraph describing the four-person team and recent turnover

This initiative has a saved premortem (with all five FailureMode records, their WarningSignals, and seven PreventiveAction records) so the dashboard does not look empty on first run. The premortem is a hand-crafted realistic example, not a Gemini-generated one, so the demo does not consume an API call on seeding.

**Initiative 2: "Launch the foresight practice writing program"**

- Time horizon: 6 months
- Success definition: a paragraph about reaching 100 paid subscribers
- Current state: a paragraph about the current draft pipeline
- Team context: a paragraph about working solo with a part-time editor

This initiative has no saved premortem; the user can run the first one to see the live Gemini integration.

---

## 11. README Additions

The boilerplate provides a README template with Stack, Setup, License, AI Safety Posture, and About the Author sections. This demo extends with the following.

### Heading Block

```
# HiveWisdom Demo

Describe an initiative. See how it could fail before it actually does.

A small open source Rails 8 app that runs a structured premortem on
any initiative you are about to commit to. Sign in, describe the
initiative in five fields, click Run Premortem, and within fifteen
seconds get a ranked first-draft analysis of how it could fail, what
warning signals to watch for, what to do this week, and the one
uncomfortable truth most premortems skip past.
```

### Screenshot Placeholder

A note in the README points to `docs/screenshot.png` (placeholder file in the repo) showing the initiative show page with a populated premortem accordion.

### Why I Built This

Indie hacker voice, three short paragraphs covering: (1) most initiatives fail for reasons the team could have anticipated, and premortem is one of the highest-leverage practices for catching them, (2) running a real premortem requires facilitation skill and emotional willingness most teams skip, so an AI-assisted first draft removes the friction, (3) this is one feature from a larger Living Foresight Platform I am building called HiveWisdom; if you want the full multi-tenant platform with panels, surveys, prediction markets, and scenarios, the production version is at `https://hivewisdom.example.com` (placeholder). The demo is open source under MIT license.

### Editable Prompt Note

A short callout: the AI prompt for this demo is a seeded record. Sign in as the seeded admin (`demo@example.com` / `password123`), open `/admin/ai_templates`, click `hivewisdom_premortem_v1`, and tune the system prompt or temperature. The live test panel on the right runs the prompt against Gemini without saving, so iteration is cheap.

### App-Specific Setup Steps

None beyond `bin/setup`. The only secret required is `GEMINI_API_KEY`, which is documented in `.env.example` (copied from the boilerplate). The demo has no Serper.dev key, no Stripe key, no email provider; it runs from a single Gemini key.

The boilerplate's standard sections (Stack, Setup, License, AI Safety Posture, About the Author) are not rewritten.

---

## 12. Bootstrap Dark Mode and Accent Color Notes

### Component Choices

This app's UX pattern is form-then-result. The Bootstrap components used are:

- **Forms**: standard floating-labels and stacked layout for the new-initiative form
- **Segmented button group** for the time horizon selector (three buttons: 3, 6, 12 months)
- **Cards** for the initiative summary, the new-initiative dashboard widget, and the avoided-truth callout
- **Accordion** for the five failure modes (Bootstrap 5's standard accordion component)
- **Badges** for severity (`bg-secondary` low, `bg-warning` medium, `bg-danger` high) and for time horizon
- **List groups** for the recent-initiatives sidebar and for warning signals inside each accordion item
- **Form-check (custom)** for the preventive-actions ranked checklist; checkboxes use the accent color for the checked state
- **Alerts** for the empty state on the initiatives index and for the Gemini error retry partial

The app does not use Bootstrap modals (Turbo Confirm handles destroy confirmations) and does not use Bootstrap's offcanvas, carousel, or navs-and-tabs components.

### Accent Color Application

The accent color `#eab308` is applied consistently in these places:

- Primary buttons (`btn-primary` overridden via `_accent.scss`): "Run Premortem", "Save Initiative", "New Initiative"
- The active state on the navbar links
- The left border on the avoided-truth callout card
- The checked state on preventive-action checkboxes
- The leverage badge background on highly-rated preventive actions (effectiveness-to-effort of 4 or 5)
- The "Imagined Failure Date" banner uses a subtle accent-toned background gradient to anchor the eye

`var(--accent-hover)` (`#ca8a04`, a slightly darker gold) is used on button hover states.

### Custom CSS Beyond the Boilerplate

The custom CSS for this demo is intentionally small. Additions in `app/assets/stylesheets/_hivewisdom.scss`:

- A two-line rule on the avoided-truth callout (left border in accent color, slight padding adjustment)
- A subtle hexagonal SVG background on the "Imagined Failure Date" banner card (a single inline SVG in the partial, no asset pipeline change)
- A `.preventive-started` class that applies strikethrough and a 60% opacity to checked items in the preventive-actions list

No custom JavaScript beyond the two Stimulus controllers (`segmented-button-group` for the time horizon selector and `preventive-action-toggle` for the checkbox state). Both controllers are under 30 lines.

---

*v1.0 - HiveWisdom Demo spec. Built on Open Demo Starter v2.0. Open source under MIT license.*
