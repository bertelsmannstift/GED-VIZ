class JavascriptExceptionsController < ApplicationController

  def create
    logger = Logger.new(Rails.root.join('log', 'javascript.log'), 1, 5.megabytes)
    str = "#{Time.now}\n#{params.to_yaml}"
    logger.error(str)
    logger.close()
    render nothing: true
  end

  protected

    def handle_unverified_request
      # raise ActionController::InvalidAuthenticityToken
    end

end
