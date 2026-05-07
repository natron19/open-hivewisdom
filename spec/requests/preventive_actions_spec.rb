require "rails_helper"

RSpec.describe "PreventiveActions", type: :request do
  let(:user)       { create(:user) }
  let(:other)      { create(:user) }
  let(:initiative) { create(:initiative, user: user) }
  let(:premortem)  { create(:premortem, initiative: initiative) }
  let!(:action)    { create(:preventive_action, premortem: premortem, started: false) }

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
