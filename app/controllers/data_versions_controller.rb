class DataVersionsController < ApplicationController

  def show
    @data_versions = DataVersion.order('published_at DESC').all
  end

end