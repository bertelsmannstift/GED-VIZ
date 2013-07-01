class IndicatorType < ActiveRecord::Base
  has_and_belongs_to_many :units, uniq: true
  has_many :indicator_values
  validates :key, uniqueness: true

  # Filter out internal indicator types, sort by position
  scope :external, where(external: true).order('position ASC')

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
end