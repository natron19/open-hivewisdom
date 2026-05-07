# Phase 2 — Domain Models & Migrations

**Goal:** Create all five domain models, their migrations, validations, associations, and RSpec factories. No controllers or views yet.

---

## 1. Migrations

Run in order. All use UUID primary keys (inherited from `config/application.rb`).

### Initiative

```ruby
# db/migrate/TIMESTAMP_create_initiatives.rb
class CreateInitiatives < ActiveRecord::Migration[8.1]
  def change
    create_table :initiatives, id: :uuid do |t|
      t.references :user, null: false, foreign_key: true, type: :uuid
      t.string  :name,                null: false
      t.text    :success_definition,  null: false
      t.string  :time_horizon,        null: false
      t.text    :current_state,       null: false
      t.text    :team_context,        null: false
      t.timestamps null: false
    end

    add_index :initiatives, [:user_id, :created_at]
  end
end
```

### Premortem

```ruby
class CreatePremortems < ActiveRecord::Migration[8.1]
  def change
    create_table :premortems, id: :uuid do |t|
      t.references :initiative, null: false, foreign_key: true, type: :uuid
      t.date   :imagined_failure_date
      t.text   :reflection
      t.text   :avoided_truth
      t.text   :gemini_raw
      t.timestamps null: false
    end

    add_index :premortems, [:initiative_id, :created_at]
  end
end
```

### FailureMode

```ruby
class CreateFailureModes < ActiveRecord::Migration[8.1]
  def change
    create_table :failure_modes, id: :uuid do |t|
      t.references :premortem, null: false, foreign_key: true, type: :uuid
      t.text    :statement,   null: false
      t.string  :severity,    null: false
      t.text    :assumption,  null: false
      t.integer :rank,        null: false
      t.timestamps null: false
    end

    add_index :failure_modes, [:premortem_id, :rank]
  end
end
```

### WarningSignal

```ruby
class CreateWarningSignals < ActiveRecord::Migration[8.1]
  def change
    create_table :warning_signals, id: :uuid do |t|
      t.references :failure_mode, null: false, foreign_key: true, type: :uuid
      t.text :signal,             null: false
      t.text :measurement_method, null: false
      t.timestamps null: false
    end
  end
end
```

### PreventiveAction

```ruby
class CreatePreventiveActions < ActiveRecord::Migration[8.1]
  def change
    create_table :preventive_actions, id: :uuid do |t|
      t.references :premortem, null: false, foreign_key: true, type: :uuid
      t.text    :description,             null: false
      t.integer :effectiveness_to_effort, null: false
      t.integer :rank,                    null: false
      t.boolean :started,                 null: false, default: false
      t.timestamps null: false
    end

    add_index :preventive_actions, [:premortem_id, :rank]
  end
end
```

Generate all five migrations via `rails generate migration CreateInitiatives ...` or write them directly. Then:

```bash
rails db:migrate
```

---

## 2. Models

### `app/models/initiative.rb`

```ruby
class Initiative < ApplicationRecord
  belongs_to :user
  has_many :premortems, dependent: :destroy

  TIME_HORIZONS = %w[3_months 6_months 12_months].freeze

  validates :name,                presence: true, length: { minimum: 3, maximum: 120 }
  validates :success_definition,  presence: true, length: { minimum: 20, maximum: 1500 }
  validates :time_horizon,        presence: true, inclusion: { in: TIME_HORIZONS }
  validates :current_state,       presence: true, length: { minimum: 20, maximum: 2000 }
  validates :team_context,        presence: true, length: { minimum: 20, maximum: 1500 }

  scope :recent, -> { order(created_at: :desc) }

  def most_recent_premortem
    premortems.order(created_at: :desc).first
  end

  def time_horizon_label
    time_horizon.gsub("_", " ").capitalize
  end
end
```

### `app/models/premortem.rb`

```ruby
class Premortem < ApplicationRecord
  belongs_to :initiative
  has_many :failure_modes, dependent: :destroy
  has_many :preventive_actions, dependent: :destroy

  default_scope { order(created_at: :desc) }
end
```

### `app/models/failure_mode.rb`

```ruby
class FailureMode < ApplicationRecord
  belongs_to :premortem
  has_many :warning_signals, dependent: :destroy

  SEVERITIES = %w[low medium high].freeze

  validates :statement,  presence: true
  validates :severity,   presence: true, inclusion: { in: SEVERITIES }
  validates :assumption, presence: true
  validates :rank,       presence: true, numericality: { only_integer: true, greater_than: 0 }

  default_scope { order(rank: :asc) }

  def severity_badge_class
    case severity
    when "low"    then "bg-secondary"
    when "medium" then "bg-warning text-dark"
    when "high"   then "bg-danger"
    end
  end
end
```

### `app/models/warning_signal.rb`

```ruby
class WarningSignal < ApplicationRecord
  belongs_to :failure_mode

  validates :signal,             presence: true
  validates :measurement_method, presence: true
end
```

### `app/models/preventive_action.rb`

```ruby
class PreventiveAction < ApplicationRecord
  belongs_to :premortem

  validates :description,             presence: true
  validates :effectiveness_to_effort, presence: true, numericality: { only_integer: true, in: 1..5 }
  validates :rank,                    presence: true, numericality: { only_integer: true, greater_than: 0 }

  default_scope { order(rank: :asc) }

  def high_leverage?
    effectiveness_to_effort >= 4
  end
end
```

---

## 3. Factories

### `spec/factories/initiatives.rb`

```ruby
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
```

### `spec/factories/premortems.rb`

```ruby
FactoryBot.define do
  factory :premortem do
    initiative
    imagined_failure_date { 3.months.from_now.to_date }
    avoided_truth { "The team's unwillingness to have a direct conversation about the scope has been the real blocker from the start." }
    gemini_raw { '{"imagined_failure_date":"2026-08-01","failure_modes":[],"preventive_actions":[],"avoided_truth":"placeholder"}' }
  end
end
```

### `spec/factories/failure_modes.rb`

```ruby
FactoryBot.define do
  factory :failure_mode do
    premortem
    sequence(:rank) { |n| n }
    statement  { "The team ran out of time before reaching agreement on the core requirements." }
    severity   { "high" }
    assumption { "All stakeholders would converge on requirements within the first two weeks." }
  end
end
```

### `spec/factories/warning_signals.rb`

```ruby
FactoryBot.define do
  factory :warning_signal do
    failure_mode
    signal             { "Recurring unresolved items on the shared tracking document." }
    measurement_method { "Check the tracker weekly; flag any item that remains open for more than two weeks." }
  end
end
```

### `spec/factories/preventive_actions.rb`

```ruby
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
```

---

## 4. RSpec Model Specs

### `spec/models/initiative_spec.rb`

```ruby
RSpec.describe Initiative, type: :model do
  describe "associations" do
    it { is_expected.to belong_to(:user) }
    it { is_expected.to have_many(:premortems).dependent(:destroy) }
  end

  describe "validations" do
    it { is_expected.to validate_presence_of(:name) }
    it { is_expected.to validate_presence_of(:success_definition) }
    it { is_expected.to validate_presence_of(:time_horizon) }
    it { is_expected.to validate_presence_of(:current_state) }
    it { is_expected.to validate_presence_of(:team_context) }
    it { is_expected.to validate_length_of(:name).is_at_least(3).is_at_most(120) }
    it { is_expected.to validate_length_of(:success_definition).is_at_least(20).is_at_most(1500) }
    it { is_expected.to validate_length_of(:current_state).is_at_least(20).is_at_most(2000) }
    it { is_expected.to validate_length_of(:team_context).is_at_least(20).is_at_most(1500) }
    it { is_expected.to validate_inclusion_of(:time_horizon).in_array(Initiative::TIME_HORIZONS) }
  end

  describe "#most_recent_premortem" do
    it "returns the most recently created premortem" do
      initiative = create(:initiative)
      old = create(:premortem, initiative: initiative, created_at: 2.days.ago)
      recent = create(:premortem, initiative: initiative, created_at: 1.hour.ago)
      expect(initiative.most_recent_premortem).to eq(recent)
    end

    it "returns nil when no premortems exist" do
      initiative = create(:initiative)
      expect(initiative.most_recent_premortem).to be_nil
    end
  end

  describe "dependent destroy" do
    it "destroys premortems when initiative is deleted" do
      initiative = create(:initiative)
      create(:premortem, initiative: initiative)
      expect { initiative.destroy }.to change(Premortem, :count).by(-1)
    end
  end
end
```

### `spec/models/premortem_spec.rb`

```ruby
RSpec.describe Premortem, type: :model do
  describe "associations" do
    it { is_expected.to belong_to(:initiative) }
    it { is_expected.to have_many(:failure_modes).dependent(:destroy) }
    it { is_expected.to have_many(:preventive_actions).dependent(:destroy) }
  end

  describe "default scope" do
    it "orders premortems most-recent-first" do
      initiative = create(:initiative)
      older  = create(:premortem, initiative: initiative, created_at: 2.days.ago)
      newer  = create(:premortem, initiative: initiative, created_at: 1.hour.ago)
      expect(initiative.premortems.first).to eq(newer)
    end
  end

  describe "gemini_raw persistence" do
    it "stores and retrieves the raw JSON string" do
      json = '{"imagined_failure_date":"2026-08-01","failure_modes":[],"preventive_actions":[],"avoided_truth":"test"}'
      premortem = create(:premortem, gemini_raw: json)
      expect(premortem.reload.gemini_raw).to eq(json)
    end
  end
end
```

### `spec/models/failure_mode_spec.rb`

```ruby
RSpec.describe FailureMode, type: :model do
  describe "associations" do
    it { is_expected.to belong_to(:premortem) }
    it { is_expected.to have_many(:warning_signals).dependent(:destroy) }
  end

  describe "validations" do
    it { is_expected.to validate_presence_of(:statement) }
    it { is_expected.to validate_presence_of(:assumption) }
    it { is_expected.to validate_inclusion_of(:severity).in_array(FailureMode::SEVERITIES) }
  end

  describe "default scope" do
    it "orders failure modes by rank ascending" do
      premortem = create(:premortem)
      fm3 = create(:failure_mode, premortem: premortem, rank: 3)
      fm1 = create(:failure_mode, premortem: premortem, rank: 1)
      fm2 = create(:failure_mode, premortem: premortem, rank: 2)
      expect(premortem.failure_modes.map(&:rank)).to eq([1, 2, 3])
    end
  end

  describe "#severity_badge_class" do
    it { expect(build(:failure_mode, severity: "low").severity_badge_class).to eq("bg-secondary") }
    it { expect(build(:failure_mode, severity: "medium").severity_badge_class).to eq("bg-warning text-dark") }
    it { expect(build(:failure_mode, severity: "high").severity_badge_class).to eq("bg-danger") }
  end
end
```

### `spec/models/preventive_action_spec.rb`

```ruby
RSpec.describe PreventiveAction, type: :model do
  describe "associations" do
    it { is_expected.to belong_to(:premortem) }
  end

  describe "validations" do
    it { is_expected.to validate_presence_of(:description) }
    it { is_expected.to validate_numericality_of(:effectiveness_to_effort).is_greater_than_or_equal_to(1).is_less_than_or_equal_to(5) }
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
      a3 = create(:preventive_action, premortem: premortem, rank: 3)
      a1 = create(:preventive_action, premortem: premortem, rank: 1)
      expect(premortem.preventive_actions.first).to eq(a1)
    end
  end

  describe "#high_leverage?" do
    it { expect(build(:preventive_action, effectiveness_to_effort: 4).high_leverage?).to be true }
    it { expect(build(:preventive_action, effectiveness_to_effort: 3).high_leverage?).to be false }
  end
end
```

---

## Acceptance Criteria

- `rails db:migrate` succeeds with no errors
- `rails console`: `Initiative.create!(user: User.first, name: "Test", success_definition: "A long enough definition of what success looks like here.", time_horizon: "3_months", current_state: "The work is currently in an early stage.", team_context: "Four team members with mixed backgrounds.")` — persists and is retrievable
- `bundle exec rspec spec/models/` — all model specs pass
- No N+1 queries in association traversal (use `includes` in controllers, not required in models)
