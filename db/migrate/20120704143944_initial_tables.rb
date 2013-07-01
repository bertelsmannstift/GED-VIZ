class InitialTables < ActiveRecord::Migration
  def up
    create_table :data_types do |t|
      t.string :key
    end

    create_table :units do |t|
      t.string  :key
      t.integer :decimals
      t.integer :representation
    end

    create_table :data_types_units do |t|
      t.integer :data_type_id
      t.integer :unit_id
    end
    # TODO INDEX

    create_table :countries do |t|
      t.string :name
      t.string :iso3
      t.string :iso2
    end

    create_table :data_values do |t|
      t.references :data_type
      t.references :unit
      t.integer :country_from_id
      t.integer :country_to_id
      t.integer :year
      t.integer :value
      t.string  :source
    end

    create_table :indicator_types do |t|
      t.string     :key
    end

    create_table :indicator_types_units do |t|
      t.integer :indicator_type_id
      t.integer :unit_id
    end

    create_table :indicator_values do |t|
      t.references :indicator_type
      t.references :unit
      t.references :country
      t.integer :year
      t.integer :value
      t.string :source
      t.integer :tendency
    end
  end

  def down
  end
end
