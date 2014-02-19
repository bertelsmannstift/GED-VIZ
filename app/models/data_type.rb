class DataType < ActiveRecord::Base
  has_and_belongs_to_many :units, uniq: true
  has_many :data_values
  validates :key, uniqueness: true

  def ==(other)
    self.class == other.class &&
      self.key == other.key
  end
  alias_method :eql?, :==
end