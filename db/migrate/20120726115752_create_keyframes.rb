class CreateKeyframes < ActiveRecord::Migration
  def up
    create_table :keyframes do |t|
      t.string :title
      t.integer :year
      t.string :countries
      t.string :data_type_with_unit
      t.string :indicator_types_with_unit
      t.integer :position
      t.references :presentation
    end
  end

  def down
    drop_table :keyframes
  end
end
