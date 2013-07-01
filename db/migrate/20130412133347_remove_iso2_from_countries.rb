class RemoveIso2FromCountries < ActiveRecord::Migration
  def up
    remove_column :countries, :iso2
  end

  def down
    add_column :countries, :iso2, :string
  end
end
