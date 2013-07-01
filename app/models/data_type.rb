class DataType < ActiveRecord::Base
  has_and_belongs_to_many :units, uniq: true
  has_many :data_values
  validates :key, uniqueness: true

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