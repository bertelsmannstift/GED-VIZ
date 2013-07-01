if Rails.env.production? || Rails.env.staging?
  GedViz::Application.config.middleware.use ExceptionNotifier,
    :email_prefix => '[ERROR] ',
    :sender_address => %{"Visualizer" <sender@invalid>},
    :exception_recipients => %w(recipient@invalid)
end