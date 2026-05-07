# Phase 7 — RSpec Test Suite

**Goal:** Write request specs for all three new controllers, a unit spec for `PremortemParser`, and verify the full suite passes with zero real API calls.

---

## 1. Fixture JSON

Create a shared fixture for the Gemini response JSON. Used in multiple specs.

```ruby
# spec/support/premortem_fixture.rb
module PremortemFixture
  VALID_JSON = JSON.generate({
    "imagined_failure_date" => "2026-08-15",
    "avoided_truth" => "The team's real constraint is that the engineering lead has already decided to leave.",
    "failure_modes" => (1..5).map do |n|
      {
        "rank" => n,
        "statement" => "Failure mode #{n} statement.",
        "severity" => ["low", "medium", "high"].sample,
        "assumption" => "Assumption #{n} that would have to break.",
        "warning_signals" => [
          { "signal" => "Signal A for mode #{n}.", "measurement_method" => "Method A." },
          { "signal" => "Signal B for mode #{n}.", "measurement_method" => "Method B." }
        ]
      }
    end,
    "preventive_actions" => (1..5).map do |n|
      {
        "rank" => n,
        "description" => "Preventive action #{n} description.",
        "effectiveness_to_effort" => 3
      }
    end
  })
end

RSpec.configure do |config|
  config.include PremortemFixture
end
```

---

## 2. `spec/requests/initiatives_spec.rb`

```ruby
RSpec.describe "Initiatives", type: :request do
  let(:user)  { create(:user) }
  let(:other) { create(:user) }
  let!(:initiative) { create(:initiative, user: user) }

  describe "GET /initiatives" do
    context "when unauthenticated" do
      it "redirects to sign in" do
        get initiatives_path
        expect(response).to redirect_to(sign_in_path)
      end
    end

    context "when signed in" do
      before { sign_in_as(user) }

      it "returns 200 and shows own initiatives" do
        get initiatives_path
        expect(response).to have_http_status(:ok)
        expect(response.body).to include(initiative.name)
      end

      it "does not show another user's initiatives" do
        other_initiative = create(:initiative, user: other)
        get initiatives_path
        expect(response.body).not_to include(other_initiative.name)
      end
    end
  end

  describe "GET /initiatives/new" do
    it "redirects unauthenticated visitors" do
      get new_initiative_path
      expect(response).to redirect_to(sign_in_path)
    end

    it "returns 200 when signed in" do
      sign_in_as(user)
      get new_initiative_path
      expect(response).to have_http_status(:ok)
    end
  end

  describe "POST /initiatives" do
    let(:valid_params) do
      {
        initiative: {
          name:                "My new initiative",
          success_definition:  "A clear definition of what success looks like for this initiative.",
          time_horizon:        "3_months",
          current_state:       "The work is in an early stage with several open questions.",
          team_context:        "Four team members with varied experience in this domain."
        }
      }
    end

    it "redirects unauthenticated visitors" do
      post initiatives_path, params: valid_params
      expect(response).to redirect_to(sign_in_path)
    end

    context "when signed in" do
      before { sign_in_as(user) }

      it "creates the initiative and redirects to show" do
        expect { post initiatives_path, params: valid_params }
          .to change(Initiative, :count).by(1)
        expect(response).to redirect_to(initiative_path(Initiative.last))
        follow_redirect!
        expect(response.body).to include("premortem")
      end

      it "renders the form with errors on invalid params" do
        post initiatives_path, params: { initiative: { name: "" } }
        expect(response).to have_http_status(:unprocessable_entity)
      end
    end
  end

  describe "GET /initiatives/:id" do
    it "redirects unauthenticated visitors" do
      get initiative_path(initiative)
      expect(response).to redirect_to(sign_in_path)
    end

    it "returns 200 for the owner" do
      sign_in_as(user)
      get initiative_path(initiative)
      expect(response).to have_http_status(:ok)
    end

    it "returns 404 for a different signed-in user" do
      sign_in_as(other)
      get initiative_path(initiative)
      expect(response).to have_http_status(:not_found)
    end
  end

  describe "DELETE /initiatives/:id" do
    it "destroys the initiative and redirects to index" do
      sign_in_as(user)
      expect { delete initiative_path(initiative) }.to change(Initiative, :count).by(-1)
      expect(response).to redirect_to(initiatives_path)
    end

    it "returns 404 for a non-owner" do
      sign_in_as(other)
      delete initiative_path(initiative)
      expect(response).to have_http_status(:not_found)
    end
  end
end
```

---

## 3. `spec/requests/premortems_spec.rb`

```ruby
RSpec.describe "Premortems", type: :request do
  let(:user)      { create(:user) }
  let(:other)     { create(:user) }
  let(:initiative) { create(:initiative, user: user) }

  describe "POST /initiatives/:initiative_id/premortems" do
    it "redirects unauthenticated visitors to sign in" do
      post initiative_premortems_path(initiative)
      expect(response).to redirect_to(sign_in_path)
    end

    context "when signed in as owner" do
      before { sign_in_as(user) }

      context "when Gemini returns valid JSON" do
        before { gemini_returns(PremortemFixture::VALID_JSON) }

        it "creates a Premortem with 5 FailureModes" do
          expect { post initiative_premortems_path(initiative) }
            .to change(Premortem, :count).by(1)
            .and change(FailureMode, :count).by(5)
        end

        it "creates the expected number of WarningSignals (2 per failure mode = 10)" do
          expect { post initiative_premortems_path(initiative) }
            .to change(WarningSignal, :count).by(10)
        end

        it "creates 5 PreventiveActions" do
          expect { post initiative_premortems_path(initiative) }
            .to change(PreventiveAction, :count).by(5)
        end

        it "stores the raw JSON on the Premortem" do
          post initiative_premortems_path(initiative)
          expect(Premortem.last.gemini_raw).to eq(PremortemFixture::VALID_JSON)
        end

        it "writes an LlmRequest record" do
          expect { post initiative_premortems_path(initiative) }
            .to change(LlmRequest, :count).by(1)
        end

        it "redirects to the initiative show page" do
          post initiative_premortems_path(initiative)
          expect(response).to redirect_to(initiative_path(initiative))
        end
      end

      context "when Gemini raises GeminiError" do
        before { gemini_raises(GeminiService::GeminiError) }

        it "does not create a Premortem" do
          expect { post initiative_premortems_path(initiative) }
            .not_to change(Premortem, :count)
        end

        it "renders the error partial" do
          post initiative_premortems_path(initiative)
          expect(response.body).to include("error")
        end
      end

      context "when Gemini raises TimeoutError" do
        before { gemini_raises(GeminiService::TimeoutError) }

        it "renders the timeout error partial" do
          post initiative_premortems_path(initiative)
          expect(response.body).to include("timed out")
        end
      end

      context "when Gemini raises BudgetExceededError" do
        before { gemini_raises(GeminiService::BudgetExceededError) }

        it "renders the budget error partial" do
          post initiative_premortems_path(initiative)
          expect(response.body).to include("budget")
        end
      end
    end

    context "when signed in as a different user" do
      it "returns 404" do
        sign_in_as(other)
        post initiative_premortems_path(initiative)
        expect(response).to have_http_status(:not_found)
      end
    end
  end

  describe "PATCH /premortems/:id/reflection" do
    let!(:premortem) { create(:premortem, initiative: initiative) }

    before { sign_in_as(user) }

    it "saves the reflection text" do
      patch reflection_premortem_path(premortem),
            params: { reflection: "This resonates with what I've been observing." },
            headers: { "Accept" => "text/vnd.turbo-stream.html" }
      expect(premortem.reload.reflection).to eq("This resonates with what I've been observing.")
    end

    it "returns a Turbo Stream response" do
      patch reflection_premortem_path(premortem),
            params: { reflection: "Some reflection." },
            headers: { "Accept" => "text/vnd.turbo-stream.html" }
      expect(response.media_type).to eq("text/vnd.turbo-stream.html")
    end
  end
end
```

---

## 4. `spec/requests/preventive_actions_spec.rb`

```ruby
RSpec.describe "PreventiveActions", type: :request do
  let(:user)            { create(:user) }
  let(:other)           { create(:user) }
  let(:initiative)      { create(:initiative, user: user) }
  let(:premortem)       { create(:premortem, initiative: initiative) }
  let!(:action)         { create(:preventive_action, premortem: premortem, started: false) }

  describe "PATCH /preventive_actions/:id/toggle" do
    it "redirects unauthenticated visitors" do
      patch toggle_preventive_action_path(action)
      expect(response).to redirect_to(sign_in_path)
    end

    context "when signed in as owner" do
      before { sign_in_as(user) }

      it "flips started from false to true" do
        patch toggle_preventive_action_path(action),
              headers: { "Accept" => "text/vnd.turbo-stream.html" }
        expect(action.reload.started).to be true
      end

      it "returns a Turbo Stream response" do
        patch toggle_preventive_action_path(action),
              headers: { "Accept" => "text/vnd.turbo-stream.html" }
        expect(response.media_type).to eq("text/vnd.turbo-stream.html")
      end

      it "flips started back from true to false on second toggle" do
        action.update!(started: true)
        patch toggle_preventive_action_path(action),
              headers: { "Accept" => "text/vnd.turbo-stream.html" }
        expect(action.reload.started).to be false
      end
    end

    context "when signed in as a different user" do
      it "returns 404" do
        sign_in_as(other)
        patch toggle_preventive_action_path(action)
        expect(response).to have_http_status(:not_found)
      end
    end
  end
end
```

---

## 5. `spec/lib/premortem_parser_spec.rb`

```ruby
require "rails_helper"

RSpec.describe PremortemParser do
  let(:valid_json) { PremortemFixture::VALID_JSON }

  describe "#parse!" do
    it "returns a hash with required top-level keys from valid JSON" do
      result = described_class.new(valid_json).parse!
      expect(result.keys).to include("imagined_failure_date", "failure_modes", "preventive_actions", "avoided_truth")
    end

    it "strips leading markdown code fences" do
      fenced = "```json\n#{valid_json}\n```"
      result = described_class.new(fenced).parse!
      expect(result["avoided_truth"]).to be_present
    end

    it "strips plain code fences without language tag" do
      fenced = "```\n#{valid_json}\n```"
      result = described_class.new(fenced).parse!
      expect(result["avoided_truth"]).to be_present
    end

    it "raises GeminiError on malformed JSON" do
      expect { described_class.new("this is not json").parse! }
        .to raise_error(GeminiService::GeminiError, /parse failed/)
    end

    it "raises GeminiError when a required top-level key is missing" do
      incomplete = JSON.generate({ "imagined_failure_date" => "2026-08-15", "failure_modes" => [] })
      expect { described_class.new(incomplete).parse! }
        .to raise_error(GeminiService::GeminiError, /missing required keys/)
    end

    it "raises GeminiError on empty string input" do
      expect { described_class.new("").parse! }
        .to raise_error(GeminiService::GeminiError)
    end
  end
end
```

---

## Running the Suite

```bash
# All new HiveWisdom specs
bundle exec rspec spec/models/initiative_spec.rb spec/models/premortem_spec.rb \
  spec/models/failure_mode_spec.rb spec/models/preventive_action_spec.rb \
  spec/requests/initiatives_spec.rb spec/requests/premortems_spec.rb \
  spec/requests/preventive_actions_spec.rb spec/lib/premortem_parser_spec.rb

# Full suite
bundle exec rspec
```

Expected outcome: all existing boilerplate specs plus all new HiveWisdom specs pass. Zero real Gemini API calls during the run.

---

## Acceptance Criteria

- `bundle exec rspec spec/lib/premortem_parser_spec.rb` — all parser specs pass
- `bundle exec rspec spec/requests/initiatives_spec.rb` — all access control and CRUD specs pass
- `bundle exec rspec spec/requests/premortems_spec.rb` — nested record creation verified with fixture JSON
- `bundle exec rspec spec/requests/preventive_actions_spec.rb` — toggle behavior verified
- `bundle exec rspec` — full suite passes, zero failures
- Zero "real API call" warnings in output (GeminiService.generate is always stubbed)
