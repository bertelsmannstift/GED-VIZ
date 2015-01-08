module ApplicationHelper
  def application_configuration
    {
      locale: I18n.locale,
      available_locales: I18n.available_locales.sort,
      latest_data_version: DataVersion.most_recent.version
    }
  end
end