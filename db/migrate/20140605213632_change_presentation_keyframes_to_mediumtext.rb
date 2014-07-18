class ChangePresentationKeyframesToMediumtext < ActiveRecord::Migration
  def up
    change_column :presentations, :keyframes, :text, limit: 16777215
  end

  def down
    change_column :presentations, :keyframes, :text, limit: nil
  end
end
