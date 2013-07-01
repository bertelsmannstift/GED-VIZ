class Unit < ActiveRecord::Base
  ABSOLUTE     = 0
  PROPORTIONAL = 1
  RANKING      = 2

  has_and_belongs_to_many :data_types, uniq: true
  has_and_belongs_to_many :indicator_types, uniq: true

  validates :key, uniqueness: true
  validates :representation, inclusion: { in: (0..2) }

  def hash
    [self.class, key].hash
  end

  def eql?(other)
    if other.class == self.class
      self.key.eql?(other.key)
    else
      false
    end
  end

  def is_proportional?
    IndicatorTypeImporter::UNIT_KEY_TO_REPRESENTATION[key] == PROPORTIONAL
  end

end