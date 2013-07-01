class AddIndices < ActiveRecord::Migration
  def up
    add_index :units, :key, :unique => true

    add_index :data_values, [ :data_type_id, :unit_id, :year ]

    add_index :indicator_values,
              [ :indicator_type_id, :unit_id, :country_id, :year ],
              name: 'index_value_query'
  end

  def down
    remove_index :units, :key

    remove_index :data_values, [ :data_type_id, :unit_id, :year ]

    remove_index :indicator_values,
              [ :indicator_type_id, :unit_id, :country_id, :year ]
  end
end
