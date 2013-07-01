class DataValue < ActiveRecord::Base
  belongs_to :data_type
  belongs_to :unit

  belongs_to :country_from, class_name: 'Country', foreign_key: 'country_from_id'
  belongs_to :country_to, class_name: 'Country', foreign_key: 'country_to_id'

  def <=>(other)
    self.value <=> other.value
  end
end