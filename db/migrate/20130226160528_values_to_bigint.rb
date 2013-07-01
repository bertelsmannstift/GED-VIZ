class ValuesToBigint < ActiveRecord::Migration
  def up
    change_column :indicator_values, :value, :bigint
    change_column :data_values, :value, :bigint
  end

  def down
  end
end
