class Unit < ActiveRecord::Base
  ABSOLUTE     = 0
  PROPORTIONAL = 1

  has_and_belongs_to_many :data_types, uniq: true
  has_and_belongs_to_many :indicator_types, uniq: true

  validates :key, uniqueness: true
  validates :representation, inclusion: { in: (0..2) }

  scope :ordered_by_position, -> { order('position ASC') }

  def ==(other)
    self.class == other.class &&
      self.key == other.key
  end
  alias_method :eql?, :==

  def is_proportional?
    IndicatorTypes.unit_definitions[key][:representation] == PROPORTIONAL
  end

end