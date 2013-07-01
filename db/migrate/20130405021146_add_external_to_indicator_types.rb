class AddExternalToIndicatorTypes < ActiveRecord::Migration
  def up
    add_column :indicator_types, :external, :boolean
  end

  def down
    remove_column :indicator_types, :external
  end
end
