class AddDataVersion < ActiveRecord::Migration
  def up
    data_version = DataVersion.new
    data_version.version = '1'
    data_version.published_at = DateTime.new(2014, 5, 3, 16, 0, 0)
    data_version.description = 'Initial version'
    data_version.save
  end

  def down
    DataVersion.find_by_version('1').destroy
  end
end
