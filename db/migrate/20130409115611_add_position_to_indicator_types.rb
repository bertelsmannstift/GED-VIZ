class AddPositionToIndicatorTypes < ActiveRecord::Migration
  def up
    add_column :indicator_types, :position, :integer
  end

  def down
    remove_column :indicator_types, :position
  end
end
