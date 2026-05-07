require "rails_helper"

RSpec.describe PremortemParser do
  let(:valid_json) { PremortemFixture::VALID_JSON }

  describe "#parse!" do
    it "returns a hash with all required top-level keys from valid JSON" do
      result = described_class.new(valid_json).parse!
      expect(result.keys).to include("imagined_failure_date", "failure_modes", "preventive_actions", "avoided_truth")
    end

    it "strips leading markdown code fences with language tag" do
      fenced = "```json\n#{valid_json}\n```"
      result = described_class.new(fenced).parse!
      expect(result["avoided_truth"]).to be_present
    end

    it "strips plain code fences without language tag" do
      fenced = "```\n#{valid_json}\n```"
      result = described_class.new(fenced).parse!
      expect(result["avoided_truth"]).to be_present
    end

    it "extracts JSON that has prose text prepended" do
      with_prose = "Here is the premortem analysis:\n\n#{valid_json}"
      result = described_class.new(with_prose).parse!
      expect(result["avoided_truth"]).to be_present
    end

    it "raises GeminiError on malformed JSON" do
      expect { described_class.new("this is not json").parse! }
        .to raise_error(GeminiService::GeminiError, /parse failed/)
    end

    it "raises GeminiError when required top-level keys are missing" do
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
