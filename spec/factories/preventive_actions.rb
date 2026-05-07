FactoryBot.define do
  factory :preventive_action do
    premortem
    sequence(:rank) { |n| n }
    description             { "Schedule a dedicated two-hour alignment session with all stakeholders this week." }
    effectiveness_to_effort { 4 }
    started                 { false }

    trait :started do
      started { true }
    end
  end
end
