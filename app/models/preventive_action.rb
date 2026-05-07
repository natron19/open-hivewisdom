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
