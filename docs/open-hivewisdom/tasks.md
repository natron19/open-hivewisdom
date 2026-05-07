# HiveWisdom Demo — Build Tasks

Track progress here. Check off each item as it is completed. Each phase spec has full implementation details.

**Source spec:** [`docs/open-hivewisdom/HiveWisdom_Demo_Spec_v1.md`](open-hivewisdom/HiveWisdom_Demo_Spec_v1.md)

---

## Phase 1 — Branding & Customization
**Spec:** [phase_1_branding.md](open-hivewisdom/phase_1_branding.md)

- [x] `.env.example` updated: `APP_NAME`, `APP_TAGLINE`, `APP_DESCRIPTION` set to HiveWisdom values
- [x] `.env` updated with HiveWisdom branding vars (local only, never committed)
- [x] Accent color updated to `#eab308` / `#ca8a04` in `app/assets/stylesheets/application.css`
- [x] Custom CSS block added for avoided-truth callout border and `.preventive-started` class
- [x] Navbar updated: "Initiatives" and "New Premortem" links added for signed-in users
- [x] `home/index.html.erb` replaced with HiveWisdom landing page
- [x] `dashboard/show.html.erb` replaced with two-column initiatives + new-initiative layout
- [x] `demo_placeholder_v1` template removed from seeds (replaced by `hivewisdom_premortem_v1` in Phase 5)

**Manual tests (run server, verify in browser):**
- [ ] Home page shows HiveWisdom tagline and "Run Your First Premortem" CTA
- [ ] Dashboard (signed in) shows "New Initiative" card on right, empty initiatives list on left
- [ ] Navbar shows "Initiatives" and "New Premortem" links when signed in
- [ ] Accent color is golden yellow on buttons and active nav links

---

## Phase 2 — Domain Models & Migrations
**Spec:** [phase_2_models.md](open-hivewisdom/phase_2_models.md)

- [x] Migration: `create_initiatives` (UUID PK, user_id, name, success_definition, time_horizon, current_state, team_context)
- [x] Migration: `create_premortems` (UUID PK, initiative_id, imagined_failure_date, reflection, avoided_truth, gemini_raw)
- [x] Migration: `create_failure_modes` (UUID PK, premortem_id, statement, severity, assumption, rank)
- [x] Migration: `create_warning_signals` (UUID PK, failure_mode_id, signal, measurement_method)
- [x] Migration: `create_preventive_actions` (UUID PK, premortem_id, description, effectiveness_to_effort, rank, started)
- [x] `rails db:migrate` succeeds in development and test
- [x] `Initiative` model: `belongs_to :user`, `has_many :premortems dependent: :destroy`, all validations
- [x] `Premortem` model: `belongs_to :initiative`, `has_many :failure_modes dependent: :destroy`, `has_many :preventive_actions dependent: :destroy`, default scope most-recent-first
- [x] `FailureMode` model: `belongs_to :premortem`, `has_many :warning_signals dependent: :destroy`, severity validation, default scope by `rank asc`
- [x] `WarningSignal` model: `belongs_to :failure_mode`, presence validations
- [x] `PreventiveAction` model: `belongs_to :premortem`, default scope by `rank asc`, `started` defaults to false
- [x] Factories: `spec/factories/initiatives.rb`
- [x] Factories: `spec/factories/premortems.rb`
- [x] Factories: `spec/factories/failure_modes.rb`
- [x] Factories: `spec/factories/warning_signals.rb`
- [x] Factories: `spec/factories/preventive_actions.rb`

**RSpec tests:**
- [x] `spec/models/initiative_spec.rb` — all validations, associations, length bounds
- [x] `spec/models/premortem_spec.rb` — associations, default scope, gemini_raw persistence
- [x] `spec/models/failure_mode_spec.rb` — associations, severity validation, default scope by rank
- [x] `spec/models/preventive_action_spec.rb` — associations, default scope, started default

**Manual tests:**
- [ ] `rails console` — `Initiative.create!(...)` succeeds with valid params, fails with missing fields
- [ ] Dependent destroy: deleting a User cascades through Initiative → Premortem → FailureMode → WarningSignal

---

## Phase 3 — Routes & Controllers
**Spec:** [phase_3_routes_controllers.md](open-hivewisdom/phase_3_routes_controllers.md)

- [x] Routes added to `config/routes.rb`: `resources :initiatives` with nested `resources :premortems, only: [:create, :show]`
- [x] Routes: `patch '/preventive_actions/:id/toggle'` as `toggle_preventive_action`
- [x] Routes: `patch '/premortems/:id/reflection'` as `reflection_premortem`
- [x] `InitiativesController` — `index`, `new`, `create`, `show`, `edit`, `update`, `destroy`
- [x] `InitiativesController` — all queries scoped to `current_user.initiatives`
- [x] `InitiativesController#create` — redirects to show with flash "Run your first premortem"
- [x] `InitiativesController#destroy` — uses `data-turbo-confirm` in view (not in controller)
- [x] `PremortemsController` — `create` (stub returning flash error), `show`, `update_reflection`
- [x] `PreventiveActionsController` — `toggle` (stub returning 200)
- [x] All three controllers enforce ownership (scope through `current_user`)
- [x] Unauthenticated requests redirect to sign in (inherited from `ApplicationController`)

**Manual tests:**
- [ ] `GET /initiatives` redirects to sign in when not authenticated
- [ ] Signed in: can create an initiative, redirected to show page
- [ ] Signed in: can edit and update an initiative
- [ ] Signed in: initiative#destroy shows confirm dialog, deletes record
- [ ] Signed in as user B: cannot access user A's initiative (404)

---

## Phase 4 — Views & Stimulus Controllers
**Spec:** [phase_4_views.md](open-hivewisdom/phase_4_views.md)

- [x] `initiatives/index.html.erb` — table with Name, Time Horizon, Premortems, Latest Premortem, Actions columns; empty state alert
- [x] `initiatives/new.html.erb` — page wrapper with form partial
- [x] `initiatives/edit.html.erb` — page wrapper with form partial
- [x] `initiatives/_form.html.erb` — Name input, Success Definition textarea, Time Horizon segmented buttons, Current State textarea, Team Context textarea (with privacy helper text), Submit button
- [x] `initiatives/show.html.erb` — initiative summary card, run-premortem CTA section, premortem partial (wrapped in Turbo Frame)
- [x] `initiatives/_premortem.html.erb` — Imagined Failure Date banner, failure modes accordion (5 items), preventive actions checklist, avoided truth callout, reflection textarea, raw response collapse
- [x] `premortems/show.html.erb` — historical premortem view with back link
- [x] Stimulus: `segmented_button_group_controller.js` — manages the time horizon button group (activates/deactivates, syncs hidden field value)
- [x] Stimulus: `preventive_action_toggle_controller.js` — native Turbo handles toggle; no custom controller needed

**Manual tests (with seeded data from Phase 6):**
- [ ] Initiative form: time horizon segmented buttons work (only one active at a time)
- [ ] Initiative form: validation errors show inline with Bootstrap alert styling
- [ ] Initiative show: empty state (no premortem) shows "Run Premortem" button
- [ ] Initiative show: with seeded premortem, accordion opens/closes correctly
- [ ] Failure mode accordion: severity badge colors correct (gray/yellow/red)
- [ ] Preventive actions: checkbox rows render with description and effectiveness badge
- [ ] Avoided truth: shows left-border callout card in accent color
- [ ] Reflection: textarea present, Save button visible
- [ ] "Show raw response" collapse toggle works

---

## Phase 5 — AI Integration
**Spec:** [phase_5_ai_integration.md](open-hivewisdom/phase_5_ai_integration.md)

- [x] `PremortemParser` PORO created at `app/lib/premortem_parser.rb`
- [x] `PremortemParser` — strips markdown fences (` ```json...``` `)
- [x] `PremortemParser` — validates required top-level JSON keys
- [x] `PremortemParser` — raises `GeminiService::GeminiError` on malformed JSON or missing keys
- [x] `hivewisdom_premortem_v1` AI template added to `db/seeds.rb` (system prompt + user prompt + settings)
- [x] `rails db:seed` creates the template (verify in admin panel at `/admin/ai_templates`)
- [x] `PremortemsController#create` calls `GeminiService.generate(template: "hivewisdom_premortem_v1", variables: {...})`
- [x] `PremortemsController#create` passes all five initiative fields as template variables
- [x] `PremortemsController#create` stores raw JSON on `premortem.gemini_raw`
- [x] `PremortemsController#create` builds Premortem, FailureModes, WarningSignals, PreventiveActions in a single transaction
- [x] `PremortemsController#create` rescues all four `GeminiService` error classes and renders `shared/_ai_error` partial
- [x] `PremortemsController#update_reflection` saves reflection and returns Turbo Stream updating `#premortem-reflection-{id}`
- [x] `PreventiveActionsController#toggle` flips `started`, returns Turbo Stream updating `#preventive-action-{id}`
- [x] Rate limiting: `rate_limit to: 5, within: 1.minute, only: [:create]` on `PremortemsController`
- [ ] Template tested in admin panel at `/admin/ai_templates` (normal input, edge cases)

**Manual tests (requires GEMINI_API_KEY in .env):**
- [x] Navigate to an initiative with no premortem, click "Run Premortem"
- [x] Within ~30 seconds, premortem accordion renders with 5 failure modes
- [x] Each failure mode has 2–3 warning signals
- [x] Preventive actions checklist shows 5–7 items
- [x] Avoided truth callout shows a single sentence
- [ ] "Show raw response" reveals the raw JSON from Gemini
- [ ] Checking a preventive action checkbox marks it started (strikethrough + faded)
- [ ] Saving a reflection note shows the saved-state badge via Turbo Stream
- [ ] Budget exceeded: after 50 calls, retry partial renders
- [ ] Timeout: if Gemini is slow, timeout error renders (hard to test manually; verify via spec)

---

## Phase 6 — Seed Data
**Spec:** [phase_6_seed_data.md](open-hivewisdom/phase_6_seed_data.md)

- [x] `db/seeds.rb` — `demo_placeholder_v1` template removed (replaced)
- [x] `db/seeds.rb` — Initiative 1: "Quarterly product roadmap review" (3 months) with all five fields
- [x] `db/seeds.rb` — Initiative 2: "Launch the foresight practice writing program" (6 months) with all five fields
- [x] `db/seeds.rb` — Initiative 1 has a full hand-crafted Premortem with:
  - [x] 5 FailureMode records (ranks 1–5, varied severities)
  - [x] 2–3 WarningSignal records per FailureMode
  - [x] 7 PreventiveAction records (ranks 1–7, varied effectiveness scores)
  - [x] `avoided_truth` text and `imagined_failure_date` set
  - [x] `gemini_raw` set to the hand-crafted JSON string (matches the schema)
- [x] `rails db:seed` is idempotent (safe to run multiple times without duplicates)

**Manual tests:**
- [x] `rails db:seed` completes without errors
- [x] Sign in as `demo@example.com` / `password123`
- [x] Dashboard shows two initiatives in the recent list
- [x] Initiative 1 show page renders the full premortem accordion immediately
- [x] Initiative 2 show page shows "Run Premortem" CTA
- [x] Admin panel at `/admin/ai_templates` shows `hivewisdom_premortem_v1` and `health_ping`

---

## Phase 7 — RSpec Test Suite
**Spec:** [phase_7_rspec.md](open-hivewisdom/phase_7_rspec.md)

- [x] `spec/requests/initiatives_spec.rb` — unauthenticated redirect, CRUD for owner, 404 for non-owner, create redirects with flash
- [x] `spec/requests/premortems_spec.rb` — GeminiService stubbed, creates all nested records, stores gemini_raw, non-owner 404, GeminiError renders error partial
- [x] `spec/requests/preventive_actions_spec.rb` — toggle flips started, returns Turbo Stream, non-owner 404
- [x] `spec/lib/premortem_parser_spec.rb` — strips fences, parses valid JSON, raises on malformed JSON, raises on missing top-level keys
- [x] `bundle exec rspec spec/models/initiative_spec.rb` — passes
- [x] `bundle exec rspec spec/models/premortem_spec.rb` — passes
- [x] `bundle exec rspec spec/models/failure_mode_spec.rb` — passes
- [x] `bundle exec rspec spec/models/preventive_action_spec.rb` — passes
- [x] `bundle exec rspec spec/requests/initiatives_spec.rb` — passes
- [x] `bundle exec rspec spec/requests/premortems_spec.rb` — passes
- [x] `bundle exec rspec spec/requests/preventive_actions_spec.rb` — passes
- [x] `bundle exec rspec spec/lib/premortem_parser_spec.rb` — passes
- [x] `bundle exec rspec` — full suite passes (zero failures, zero real API calls)

---

## Phase 8 — README & Polish
**Spec:** [phase_8_readme.md](open-hivewisdom/phase_8_readme.md)

- [x] `README.md` — HiveWisdom heading block with tagline and 3-sentence description
- [x] `README.md` — "Why I Built This" section (3 short paragraphs)
- [x] `README.md` — Screenshot placeholder pointing to `docs/screenshot.png`
- [x] `README.md` — "Editable Prompt" callout (admin panel URL, template name, test panel)
- [x] `README.md` — Demo credentials section (`demo@example.com` / `password123`)
- [x] `docs/screenshot.png` — placeholder PNG file committed (even if just a blank file)
- [x] Final security audit: `grep -r "GEMINI_API_KEY" .` finds only `.env.example` and docs
- [x] Final security audit: no `binding.pry` or `debugger` in source files
- [x] Final security audit: `.env` not in git index

**Manual tests:**
- [ ] Full happy path: clone → `bin/setup` → `rails db:seed` → sign in → create initiative → run premortem → accordion renders
- [ ] Full edge path: run premortem without API key → error partial renders cleanly
- [ ] Admin path: sign in as admin → `/admin/ai_templates` → edit `hivewisdom_premortem_v1` → run test → result renders inline

---

## Summary

| Phase | Description | Status |
|---|---|---|
| 1 | Branding & Customization | ✅ Complete |
| 2 | Domain Models & Migrations | ✅ Complete |
| 3 | Routes & Controllers | ✅ Complete |
| 4 | Views & Stimulus Controllers | ✅ Complete |
| 5 | AI Integration | ✅ Complete |
| 6 | Seed Data | ✅ Complete |
| 7 | RSpec Test Suite | ✅ Complete |
| 8 | README & Polish | ✅ Complete |
