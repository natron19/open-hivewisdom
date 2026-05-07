FactoryBot.define do
  factory :premortem do
    initiative
    imagined_failure_date { 3.months.from_now.to_date }
    avoided_truth { "The team's unwillingness to have a direct conversation about the scope has been the real blocker from the start." }
    gemini_raw { '{"imagined_failure_date":"2026-08-01","failure_modes":[],"preventive_actions":[],"avoided_truth":"placeholder"}' }
  end
end
