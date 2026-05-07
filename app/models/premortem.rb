class Premortem < ApplicationRecord
  belongs_to :initiative
  has_many :failure_modes, dependent: :destroy
  has_many :preventive_actions, dependent: :destroy

  default_scope { order(created_at: :desc) }
end
