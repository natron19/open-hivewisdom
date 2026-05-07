require "rails_helper"

RSpec.describe "Premortems", type: :request do
  let(:user)       { create(:user) }
  let(:other)      { create(:user) }
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

        it "creates 2 WarningSignals per failure mode (10 total)" do
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
          expect(response.body).to include("Something went wrong")
        end
      end

      context "when Gemini raises TimeoutError" do
        before { gemini_raises(GeminiService::TimeoutError) }

        it "renders the timeout error partial" do
          post initiative_premortems_path(initiative)
          expect(response.body).to include("too long")
        end
      end

      context "when Gemini raises BudgetExceededError" do
        before { gemini_raises(GeminiService::BudgetExceededError) }

        it "renders the budget error partial" do
          post initiative_premortems_path(initiative)
          expect(response.body).to include("daily")
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
