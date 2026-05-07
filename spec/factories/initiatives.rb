FactoryBot.define do
  factory :initiative do
    user
    sequence(:name) { |n| "Initiative #{n}" }
    success_definition { "We will have successfully completed this initiative when all key milestones are reached and stakeholders are aligned on the outcome." }
    time_horizon { "3_months" }
    current_state { "The work has begun but is at an early stage with several open questions remaining before we can proceed." }
    team_context { "A small team of four people including a lead and three contributors with mixed experience in this domain." }
  end
end
