require "rails_helper"

RSpec.describe FailureMode, type: :model do
  describe "associations" do
    it "belongs to a premortem" do
      fm = create(:failure_mode)
      expect(fm.premortem).to be_a(Premortem)
    end

    it "destroys warning_signals when destroyed" do
      fm = create(:failure_mode)
      create(:warning_signal, failure_mode: fm)
      expect { fm.destroy }.to change(WarningSignal, :count).by(-1)
    end
  end

  describe "validations" do
    it "is valid with valid attributes" do
      expect(build(:failure_mode)).to be_valid
    end

    it "requires statement" do
      expect(build(:failure_mode, statement: nil)).not_to be_valid
    end

    it "requires assumption" do
      expect(build(:failure_mode, assumption: nil)).not_to be_valid
    end

    it "rejects invalid severity values" do
      expect(build(:failure_mode, severity: "extreme")).not_to be_valid
    end

    it "accepts all valid severity values" do
      FailureMode::SEVERITIES.each do |s|
        expect(build(:failure_mode, severity: s)).to be_valid
      end
    end
  end

  describe "default scope" do
    it "orders failure modes by rank ascending" do
      premortem = create(:premortem)
      create(:failure_mode, premortem: premortem, rank: 3)
      create(:failure_mode, premortem: premortem, rank: 1)
      create(:failure_mode, premortem: premortem, rank: 2)
      expect(premortem.failure_modes.map(&:rank)).to eq([1, 2, 3])
    end
  end

  describe "#severity_badge_class" do
    it { expect(build(:failure_mode, severity: "low").severity_badge_class).to eq("bg-secondary") }
    it { expect(build(:failure_mode, severity: "medium").severity_badge_class).to eq("bg-warning text-dark") }
    it { expect(build(:failure_mode, severity: "high").severity_badge_class).to eq("bg-danger") }
  end
end
