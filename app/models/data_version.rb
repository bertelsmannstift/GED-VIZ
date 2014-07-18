class DataVersion < ActiveRecord::Base
  has_many :presentations

  def self.most_recent
    order('published_at').last
  end
end