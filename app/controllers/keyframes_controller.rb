# encoding: utf-8

class KeyframesController < ApplicationController

  layout :nil

  def query
    keyframe = Keyframe.from_json(params)
    render json: keyframe.as_json
  end

  def render_chart
    @presentation_json = Presentation.cached_json(params[:presentation_id])
    @keyframe_index    = params[:keyframe] ? params[:keyframe].to_i : nil
    render layout: 'application'
  end

  def static
    presentation = Presentation.find(params[:id])
    keyframe_index = params[:keyframe].to_i

    if presentation.keyframes.length <= keyframe_index
      render text: 'Invalid Keyframe index', status: 404
      return
    end

    file = render_keyframe(presentation, keyframe_index)
    if file.exist?
      expires_in 10.years, public: true
      send_file file, type: 'image/png', disposition: 'inline'
    else
      render text: 'Rendering failed', status: 500
    end
  end

  private

  # Renders the keyframe to a file
  def render_keyframe(presentation, keyframe_index)
    locale = params[:lang] || I18n.locale
    # No different languages for thumbnails. There is no text on them.
    locale = 'en' if params[:size] == 'thumb'
    options = {
      base_url: request.protocol + request.host_with_port,
      locale: locale,
      size: params[:size],
      show_titles: false,
      show_legend: false
    }
    renderer = PresentationRenderer.new(presentation)
    file = renderer.image_path(keyframe_index, options)
    renderer.render(options) unless file.exist?
    file
  end


end