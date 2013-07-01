class PresentationKeys < ActiveRecord::Migration
  def up
    add_column :presentations, :read_key, :string
    add_column :presentations, :write_key, :string
    add_index :presentations, :read_key, :unique => true
    add_index :presentations, :write_key
  end

  def down
    remove_index :presentations, :write_key
    remove_index :presentations, :read_key
    remove_column :presentations, :write_key
    remove_column :presentations, :read_key
  end
end