class PresentationsController < ApplicationController

  unless Rails.env.development?
    after_filter :cache_page_with_locale, only: [:show, :edit]
  end

  def new
    render_presentation(ExamplePresentation.cached_instance)
  end

  def create
    presentation = Presentation.from_json(params)
    presentation.save!
    render json: presentation
  end

  def show
    render_presentation(Presentation.find(params[:id]))
  end

  def edit
    render_presentation(Presentation.find(params[:id]))
  end

  def export
    presentation = Presentation.find(params[:id])
    exporter = PresentationExporter.new(presentation, params[:keyframes])

    if params[:file_format] == 'csv'
      zip_string = exporter.export_csv_zip
      filename = exporter.public_filename(:data)
      send_data zip_string, filename: filename, type: 'application/zip'

    elsif params[:file_format] == 'image'
      options = {
        base_url: request.protocol + request.host_with_port,
        locale: I18n.locale,
        size: 'large',
        show_titles: !!params[:show_titles],
        show_legend: !!params[:show_legend]
      }
      zip_file = exporter.export_images_zip(options)
      if zip_file
        filename = exporter.public_filename(:image)
        send_file zip_file, filename: filename, type: 'application/zip'
      else
        render text: 'An error occurred while generating the export ZIP.',
          status: 500
      end
    end

  end

  def compare
    presentation = Presentation.find(params[:id])
    old_json = presentation.instance_variable_get :@keyframes_json
    new_json = presentation.send(:duplicate_keyframes).to_json
    @diff = Diffy::Diff.new(old_json, new_json).to_s(:html)
  end

  private

  def render_presentation(presentation, options = {})
    json = presentation.to_json(options)
    respond_to do |format|
      format.html do
        @presentation = presentation
        @presentation_json = json
        render :embedded
      end
      format.json { render json: json }
    end
  end

  def cache_page_with_locale
    cache_page nil, "/#{controller_name}_#{action_name}_#{params[:id]}_#{I18n.locale}"
  end

end