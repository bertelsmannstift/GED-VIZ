module ApplicationHelper
  def application_configuration
    {
      locale: I18n.locale,
      latest_data_version: DataVersion.most_recent.version
    }
  end
end