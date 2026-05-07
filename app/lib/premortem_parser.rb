class PremortemParser
  REQUIRED_KEYS = %w[imagined_failure_date failure_modes preventive_actions avoided_truth].freeze

  def initialize(raw_json)
    @raw_json = raw_json
  end

  def parse!
    json = extract_json(@raw_json)
    data = JSON.parse(json)
    validate_keys!(data)
    data
  rescue JSON::ParserError => e
    Rails.logger.error "[PremortemParser] JSON parse failed: #{e.message}. Raw (first 500): #{@raw_json.to_s[0, 500].inspect}"
    raise GeminiService::GeminiError, "Premortem JSON parse failed: #{e.message}"
  end

  private

  # Strips markdown fences, then finds the outermost JSON object in the text.
  # Gemini 2.5 Flash (thinking mode) occasionally prepends a prose sentence before
  # the JSON even when instructed not to.
  def extract_json(text)
    cleaned = text.gsub(/```(?:json)?/i, "").gsub(/```/, "").strip

    # Fast path: the whole string is already valid-looking JSON
    return cleaned if cleaned.start_with?("{")

    # Fallback: grab the substring from the first { to the last }
    first = cleaned.index("{")
    last  = cleaned.rindex("}")
    return cleaned.slice(first..last) if first && last && first < last

    cleaned
  end

  def validate_keys!(data)
    missing = REQUIRED_KEYS - data.keys
    return if missing.empty?
    Rails.logger.error "[PremortemParser] Missing keys: #{missing.join(', ')}. Keys present: #{data.keys.inspect}"
    raise GeminiService::GeminiError, "Premortem JSON missing required keys: #{missing.join(', ')}"
  end
end
