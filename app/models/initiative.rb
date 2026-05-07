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
