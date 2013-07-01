class IndicatorTypeGroups < ActiveRecord::Migration
  def up
    add_column :indicator_types, :group, :string
  end

  def down
    remove_column :indicator_types, :group
  end
end