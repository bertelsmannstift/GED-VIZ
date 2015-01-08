class AddParentKeyToDataTypes < ActiveRecord::Migration
  def change
    add_column :data_types, :parent_key, :string
  end
end
