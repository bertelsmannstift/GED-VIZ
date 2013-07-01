class RemoveKeyframes < ActiveRecord::Migration
  def up
    drop_table :keyframes
    add_column :presentations, :keyframes, :text
  end

  def down
    # remove_column :presentations, :keyframes
    raise ActiveRecord::IrreversibleMigration
  end
end