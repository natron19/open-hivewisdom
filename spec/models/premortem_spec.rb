require "rails_helper"

RSpec.describe Premortem, type: :model do
  describe "associations" do
    it "belongs to an initiative" do
      premortem = create(:premortem)
      expect(premortem.initiative).to be_a(Initiative)
    end

    it "destroys failure_modes when destroyed" do
      premortem = create(:premortem)
      create(:failure_mode, premortem: premortem)
      expect { premortem.destroy }.to change(FailureMode, :count).by(-1)
    end

    it "destroys preventive_actions when destroyed" do
      premortem = create(:premortem)
      create(:preventive_action, premortem: premortem)
      expect { premortem.destroy }.to change(PreventiveAction, :count).by(-1)
    end
  end

  describe "default scope" do
    it "orders premortems most-recent-first" do
      initiative = create(:initiative)
      older = create(:premortem, initiative: initiative, created_at: 2.days.ago)
      newer = create(:premortem, initiative: initiative, created_at: 1.hour.ago)
      expect(initiative.premortems.first).to eq(newer)
    end
  end

  describe "gemini_raw persistence" do
    it "stores and retrieves the raw JSON string" do
      json = '{"imagined_failure_date":"2026-08-01","failure_modes":[],"preventive_actions":[],"avoided_truth":"test"}'
      premortem = create(:premortem, gemini_raw: json)
      expect(premortem.reload.gemini_raw).to eq(json)
    end
  end
end
