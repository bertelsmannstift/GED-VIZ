class AddPositionToUnits < ActiveRecord::Migration
  def up
    add_column :units, :position, :integer
  end
  def down
    remove_column :units, :position
  end
end