class AssociatePresentationsWithDataVersions < ActiveRecord::Migration
  def up
    latest_version = DataVersion.most_recent
    assigment = ActiveRecord::Base.send(
      :sanitize_sql_for_assignment,
      data_version_id: latest_version
    )
    sql = "UPDATE presentations SET #{assigment}"
    ActiveRecord::Base.connection.execute(sql)
  end

  def down
  end
end
