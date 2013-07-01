class AddTendencyPercentToIndicatorValues < ActiveRecord::Migration
  def up
    add_column :indicator_values, :tendency_percent, :decimal, :precision => 8, :scale => 4
  end

  def down
    remove_column :indicator_values, :tendency_percent
  end
end
