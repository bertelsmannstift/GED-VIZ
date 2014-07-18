class CreateDataVersions < ActiveRecord::Migration
  def change
    create_table :data_versions do |t|
      t.string  :version
      t.timestamp :published_at
      t.string :description
    end
  end
end
