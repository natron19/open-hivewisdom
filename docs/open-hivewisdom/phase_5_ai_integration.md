# Phase 5 — AI Integration

**Goal:** Wire up the live Gemini call, build the `PremortemParser` PORO, complete the `PremortemsController#create` action, and enable the two Turbo Stream interactions (reflection save and preventive action toggle).

> **Model note:** The spec document references `gemini-2.0-flash`, but that model is deprecated for new API keys. Use `gemini-2.5-flash` per `docs/ai-templates.md`.

---

## 1. AI Template Seed

Add to `db/seeds.rb`, replacing the `demo_placeholder_v1` block:

```ruby
AiTemplate.find_or_create_by!(name: "hivewisdom_premortem_v1") do |t|
  t.description = "Runs a structured premortem on a user-described initiative. Returns five ranked failure modes with warning signals and a ranked list of preventive actions."
  t.model = "gemini-2.5-flash"
  t.max_output_tokens = 3000
  t.temperature = 0.6

  t.system_prompt = <<~PROMPT.strip
    You are a foresight practitioner running a premortem on an initiative the user is about to commit to. Your job is to imagine that the initiative has already failed and to reconstruct, plausibly, why it failed.

    You will not hedge. You will not soften. You will not tell the user the initiative sounds promising. The user already knows the optimistic case; that is why they brought it to you. They are paying for the pessimistic, structured first draft they cannot easily produce on their own.

    Your output is the analysis a thoughtful skeptic would write after a half-hour reading the brief. It is specific, falsifiable where possible, and grounded in the user's own context (the team, the time horizon, the current state). It does not invoke generic startup failure modes that could apply to any initiative.

    You produce JSON only. No prose preamble, no closing remarks, no markdown fences around the JSON. The schema is provided in the user prompt; deviating from it breaks the application.

    You will populate every field. If a field is hard to fill, fill it with your best plausible guess rather than leaving it empty. The user will calibrate what is useful and what is noise.

    You will name the one uncomfortable truth the team is probably avoiding. This is the highest-leverage item in your output. It is usually a relationship, a missing skill, an unspoken disagreement, or a structural constraint that nobody wants to surface in a planning meeting. If everything else in your output is correct but this field is bland, your output has failed.
  PROMPT

  t.user_prompt_template = <<~PROMPT.strip
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
  PROMPT

  t.notes = <<~NOTES.strip
    This template is the heart of the demo. The system prompt enforces the JSON contract and pushes the model away from default-helpful blandness toward something a real foresight practitioner would write.

    The model occasionally returns JSON inside a markdown code fence despite instructions. PremortemParser strips fences before parsing.

    Watch for too-generic warning signals. If they occur, lower temperature to 0.5 and re-test in the admin panel.

    The avoided_truth being a platitude is a prompt quality issue. The system prompt's last paragraph addresses this directly.
  NOTES
end

puts "Seeded: hivewisdom_premortem_v1 AI template"
```

Run `rails db:seed` and verify the template appears in `/admin/ai_templates`.

---

## 2. PremortemParser PORO

Create `app/lib/premortem_parser.rb`:

```ruby
class PremortemParser
  REQUIRED_KEYS = %w[imagined_failure_date failure_modes preventive_actions avoided_truth].freeze

  def initialize(raw_json)
    @raw_json = raw_json
  end

  def parse!
    json = strip_fences(@raw_json)
    data = JSON.parse(json)
    validate_keys!(data)
    data
  rescue JSON::ParserError => e
    raise GeminiService::GeminiError, "Premortem JSON parse failed: #{e.message}"
  end

  private

  def strip_fences(text)
    text.gsub(/\A\s*```(?:json)?\s*/i, "").gsub(/\s*```\s*\z/, "").strip
  end

  def validate_keys!(data)
    missing = REQUIRED_KEYS - data.keys
    return if missing.empty?
    raise GeminiService::GeminiError, "Premortem JSON missing required keys: #{missing.join(', ')}"
  end
end
```

---

## 3. Full `PremortemsController#create`

Replace the Phase 3 stub with the real implementation:

```ruby
def create
  raw = GeminiService.generate(
    template:  "hivewisdom_premortem_v1",
    variables: {
      initiative_name:    @initiative.name,
      success_definition: @initiative.success_definition,
      time_horizon:       @initiative.time_horizon,
      current_state:      @initiative.current_state,
      team_context:       @initiative.team_context
    }
  )

  data = PremortemParser.new(raw).parse!

  premortem = ActiveRecord::Base.transaction do
    pm = @initiative.premortems.create!(
      imagined_failure_date: Date.parse(data["imagined_failure_date"]),
      avoided_truth:         data["avoided_truth"],
      gemini_raw:            raw
    )

    data["failure_modes"].each do |fm_data|
      fm = pm.failure_modes.create!(
        rank:       fm_data["rank"],
        statement:  fm_data["statement"],
        severity:   fm_data["severity"],
        assumption: fm_data["assumption"]
      )
      fm_data["warning_signals"].each do |ws_data|
        fm.warning_signals.create!(
          signal:             ws_data["signal"],
          measurement_method: ws_data["measurement_method"]
        )
      end
    end

    data["preventive_actions"].each do |pa_data|
      pm.preventive_actions.create!(
        rank:                    pa_data["rank"],
        description:             pa_data["description"],
        effectiveness_to_effort: pa_data["effectiveness_to_effort"]
      )
    end

    pm
  end

  redirect_to @initiative, notice: "Premortem complete."

rescue GeminiService::BudgetExceededError
  render partial: "shared/ai_error", locals: { error_type: :budget_exceeded }, status: :unprocessable_entity
rescue GeminiService::GatekeeperError
  render partial: "shared/ai_error", locals: { error_type: :gatekeeper_blocked }, status: :unprocessable_entity
rescue GeminiService::TimeoutError
  render partial: "shared/ai_error", locals: { error_type: :timeout }, status: :unprocessable_entity
rescue GeminiService::GeminiError
  render partial: "shared/ai_error", locals: { error_type: :error }, status: :unprocessable_entity
end
```

Add rate limiting to the controller class body:

```ruby
rate_limit to: 5, within: 1.minute, only: [:create],
           with: -> { redirect_to @initiative, alert: "Please wait before running another premortem." }
```

---

## 4. `update_reflection` Turbo Stream

The controller action from Phase 3 is already complete. Add the missing partial.

Create `app/views/premortems/_reflection_saved.html.erb`:

```erb
<h6 class="mb-2">Your Reflection</h6>
<div class="border rounded p-3 text-body-secondary">
  <%= premortem.reflection.presence || "No reflection saved." %>
</div>
<span class="badge bg-success mt-2">Saved</span>
```

The controller renders:

```ruby
render turbo_stream: turbo_stream.update(
  "premortem-reflection-#{@premortem.id}",
  partial: "premortems/reflection_saved",
  locals: { premortem: @premortem }
)
```

---

## 5. Preventive Action Toggle

The `PreventiveActionsController#toggle` from Phase 3 is complete. The view partial (`initiatives/_preventive_action.html.erb`) from Phase 4 is already set up with the correct `id="preventive-action-#{action.id}"` target.

The Turbo Stream response re-renders the partial:

```ruby
render turbo_stream: turbo_stream.update(
  "preventive-action-#{@action.id}",
  partial: "initiatives/preventive_action",
  locals: { action: @action }
)
```

---

## 6. Admin Panel Test

Before marking this phase done:

1. Sign in as `demo@example.com`
2. Go to `/admin/ai_templates`
3. Click `hivewisdom_premortem_v1` → Edit
4. Fill in test values (initiative name, one paragraph for each field, select a time horizon)
5. Click "Run Test" — result should render in the right-hand test panel
6. Check `/admin/llm_requests` — a new row should appear with status `success`

---

## Acceptance Criteria

- Navigate to an initiative, click "Run Premortem" — full accordion renders within 15 seconds
- Accordion has exactly 5 failure modes, each with 2–3 warning signals
- Preventive actions checklist has 5–7 items
- Checking a preventive action marks it started (strikethrough) via Turbo Stream with no page reload
- Saving a reflection replaces the textarea with the saved-state badge via Turbo Stream
- "Show raw response" reveals the raw JSON Gemini returned
- On a simulated timeout (lower `AI_GLOBAL_TIMEOUT_SECONDS` to 1 in `.env`), error partial renders
- `/admin/llm_requests` shows a new row for each premortem run
