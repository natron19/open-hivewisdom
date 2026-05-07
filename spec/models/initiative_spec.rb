require "rails_helper"

RSpec.describe Initiative, type: :model do
  describe "associations" do
    it "belongs to a user" do
      initiative = create(:initiative)
      expect(initiative.user).to be_a(User)
    end

    it "destroys premortems when destroyed" do
      initiative = create(:initiative)
      create(:premortem, initiative: initiative)
      expect { initiative.destroy }.to change(Premortem, :count).by(-1)
    end
  end

  describe "validations" do
    it "is valid with valid attributes" do
      expect(build(:initiative)).to be_valid
    end

    it "requires name" do
      expect(build(:initiative, name: nil)).not_to be_valid
    end

    it "requires name to be at least 3 characters" do
      expect(build(:initiative, name: "ab")).not_to be_valid
    end

    it "requires name to be at most 120 characters" do
      expect(build(:initiative, name: "a" * 121)).not_to be_valid
    end

    it "requires success_definition" do
      expect(build(:initiative, success_definition: nil)).not_to be_valid
    end

    it "requires success_definition to be at least 20 characters" do
      expect(build(:initiative, success_definition: "too short")).not_to be_valid
    end

    it "requires success_definition to be at most 1500 characters" do
      expect(build(:initiative, success_definition: "a" * 1501)).not_to be_valid
    end

    it "requires time_horizon" do
      expect(build(:initiative, time_horizon: nil)).not_to be_valid
    end

    it "rejects invalid time_horizon values" do
      expect(build(:initiative, time_horizon: "invalid")).not_to be_valid
    end

    it "accepts all valid time_horizon values" do
      Initiative::TIME_HORIZONS.each do |horizon|
        expect(build(:initiative, time_horizon: horizon)).to be_valid
      end
    end

    it "requires current_state" do
      expect(build(:initiative, current_state: nil)).not_to be_valid
    end

    it "requires current_state to be at least 20 characters" do
      expect(build(:initiative, current_state: "too short")).not_to be_valid
    end

    it "requires current_state to be at most 2000 characters" do
      expect(build(:initiative, current_state: "a" * 2001)).not_to be_valid
    end

    it "requires team_context" do
      expect(build(:initiative, team_context: nil)).not_to be_valid
    end

    it "requires team_context to be at least 20 characters" do
      expect(build(:initiative, team_context: "too short")).not_to be_valid
    end

    it "requires team_context to be at most 1500 characters" do
      expect(build(:initiative, team_context: "a" * 1501)).not_to be_valid
    end
  end

  describe "#most_recent_premortem" do
    it "returns the most recently created premortem" do
      initiative = create(:initiative)
      _old   = create(:premortem, initiative: initiative, created_at: 2.days.ago)
      recent = create(:premortem, initiative: initiative, created_at: 1.hour.ago)
      expect(initiative.most_recent_premortem).to eq(recent)
    end

    it "returns nil when no premortems exist" do
      initiative = create(:initiative)
      expect(initiative.most_recent_premortem).to be_nil
    end
  end
end
