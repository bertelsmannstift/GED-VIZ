class ChangeDataAndIndicatorValueTypes < ActiveRecord::Migration
  def up
    change_column :data_values, :value, :decimal, precision: 16, scale: 4
    change_column :indicator_values, :value, :decimal, precision: 16, scale: 4
    remove_column :units, :decimals
  end

  def down
  end
end