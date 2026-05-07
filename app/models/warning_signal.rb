class WarningSignal < ApplicationRecord
  belongs_to :failure_mode

  validates :signal,             presence: true
  validates :measurement_method, presence: true
end
