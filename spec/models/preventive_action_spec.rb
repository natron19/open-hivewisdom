require "rails_helper"

RSpec.describe PreventiveAction, type: :model do
  describe "associations" do
    it "belongs to a premortem" do
      action = create(:preventive_action)
      expect(action.premortem).to be_a(Premortem)
    end
  end

  describe "validations" do
    it "is valid with valid attributes" do
      expect(build(:preventive_action)).to be_valid
    end

    it "requires description" do
      expect(build(:preventive_action, description: nil)).not_to be_valid
    end

    it "rejects effectiveness_to_effort below 1" do
      expect(build(:preventive_action, effectiveness_to_effort: 0)).not_to be_valid
    end

    it "rejects effectiveness_to_effort above 5" do
      expect(build(:preventive_action, effectiveness_to_effort: 6)).not_to be_valid
    end

    it "accepts effectiveness_to_effort values 1 through 5" do
      (1..5).each do |n|
        expect(build(:preventive_action, effectiveness_to_effort: n)).to be_valid
      end
    end
  end

  describe "defaults" do
    it "defaults started to false" do
      action = create(:preventive_action)
      expect(action.started).to be false
    end
  end

  describe "default scope" do
    it "orders by rank ascending" do
      premortem = create(:premortem)
      create(:preventive_action, premortem: premortem, rank: 3)
      a1 = create(:preventive_action, premortem: premortem, rank: 1)
      expect(premortem.preventive_actions.first).to eq(a1)
    end
  end

  describe "#high_leverage?" do
    it { expect(build(:preventive_action, effectiveness_to_effort: 4).high_leverage?).to be true }
    it { expect(build(:preventive_action, effectiveness_to_effort: 3).high_leverage?).to be false }
  end
end
