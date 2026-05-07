FactoryBot.define do
  factory :warning_signal do
    failure_mode
    signal             { "Recurring unresolved items on the shared tracking document." }
    measurement_method { "Check the tracker weekly; flag any item that remains open for more than two weeks." }
  end
end
