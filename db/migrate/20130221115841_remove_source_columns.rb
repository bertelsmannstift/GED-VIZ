class RemoveSourceColumns < ActiveRecord::Migration
  def up
    remove_column :data_values, :source
    remove_column :indicator_values, :source
  end

  def down
    add_column :data_values, :source, :string
    add_column :indicator_values, :source, :string
  end
end
