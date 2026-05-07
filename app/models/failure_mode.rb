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
