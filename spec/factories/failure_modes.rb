FactoryBot.define do
  factory :failure_mode do
    premortem
    sequence(:rank) { |n| n }
    statement  { "The team ran out of time before reaching agreement on the core requirements." }
    severity   { "high" }
    assumption { "All stakeholders would converge on requirements within the first two weeks." }
  end
end
