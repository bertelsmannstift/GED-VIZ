class IndicatorValue < ActiveRecord::Base
  belongs_to :country
  belongs_to :indicator_type
  belongs_to :unit

  validates :tendency, inclusion: { in: (-2..2), allow_nil: true}
end