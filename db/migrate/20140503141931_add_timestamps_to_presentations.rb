class AddTimestampsToPresentations < ActiveRecord::Migration
  def up
    add_timestamps :presentations
  end
  def down
    remove_timestamps :presentations
  end
end
