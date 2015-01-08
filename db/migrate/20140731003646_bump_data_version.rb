class BumpDataVersion < ActiveRecord::Migration
  def up
    data_version = DataVersion.new
    data_version.version = '2'
    data_version.published_at = DateTime.new(2014, 7, 31, 20, 0, 0)
    data_version.description = 'Data update from Prognos with new and corrected data from 2000-2012. Update of both bilateral and unilateral indicators.'
    data_version.save
  end

  def down
  end
end
