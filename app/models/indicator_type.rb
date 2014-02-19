class IndicatorType < ActiveRecord::Base
  has_and_belongs_to_many :units, uniq: true
  has_many :indicator_values
  validates :key, uniqueness: true

  # Filter out internal indicator types, sort by position
  scope :external, where(external: true).order('position ASC')

  def ==(other)
    self.class == other.class &&
      self.key == other.key
  end
  alias_method :eql?, :==
end