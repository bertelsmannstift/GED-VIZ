class AddIndizes < ActiveRecord::Migration
  def up
    add_index :countries, :iso3, :unique => true
    add_index :data_types, :key, :unique => true
    add_index :indicator_types, :key, :unique => true
  end

  def down
    remove_index :countries, :iso3
    remove_index :data_types, :key
    remove_index :indicator_types, :key
  end
end