module PremortemFixture
  VALID_JSON = JSON.generate({
    "imagined_failure_date" => "2026-08-15",
    "avoided_truth"         => "The team's real constraint is that the engineering lead has already decided to leave.",
    "failure_modes"         => (1..5).map do |n|
      {
        "rank"      => n,
        "statement" => "Failure mode #{n} statement.",
        "severity"  => %w[low medium high][n % 3],
        "assumption" => "Assumption #{n} that would have to break.",
        "warning_signals" => [
          { "signal" => "Signal A for mode #{n}.", "measurement_method" => "Method A." },
          { "signal" => "Signal B for mode #{n}.", "measurement_method" => "Method B." }
        ]
      }
    end,
    "preventive_actions" => (1..5).map do |n|
      {
        "rank"                    => n,
        "description"             => "Preventive action #{n} description.",
        "effectiveness_to_effort" => 3
      }
    end
  })
end

RSpec.configure do |config|
  config.include PremortemFixture
end
