class CreatePresentations < ActiveRecord::Migration
  def up
    create_table :presentations do |t|
      t.string :title
    end
  end

  def down
    drop_table :presentations
  end
end
