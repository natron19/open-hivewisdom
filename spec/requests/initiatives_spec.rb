require "rails_helper"

RSpec.describe "Initiatives", type: :request do
  let(:user)        { create(:user) }
  let(:other)       { create(:user) }
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
          name:               "My new initiative",
          success_definition: "A clear definition of what success looks like for this initiative.",
          time_horizon:       "3_months",
          current_state:      "The work is in an early stage with several open questions.",
          team_context:       "Four team members with varied experience in this domain."
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
        created = Initiative.find_by!(name: valid_params[:initiative][:name])
        expect(response).to redirect_to(initiative_path(created))
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
