class ImportNewCountries < ActiveRecord::Migration
  def up
    CountryImporter.new.import
  end

  def down
  end
end
