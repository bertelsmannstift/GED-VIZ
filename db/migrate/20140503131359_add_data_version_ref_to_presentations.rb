class AddDataVersionRefToPresentations < ActiveRecord::Migration
  def change
    add_column :presentations, :data_version_id, :integer
  end
  def down
    remove_column :presentations, :data_version_id
  end
end
