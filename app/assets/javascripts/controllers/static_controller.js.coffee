define (require) ->
  'use strict'
  Controller = require 'controllers/base/controller'
  Presentation = require 'models/presentation'
  RenderAgent = require 'lib/render_agent'
  utils = require 'lib/utils'

  class StaticController extends Controller

    render: (params) ->
      # Import global params
      presentationData = window.presentation
      keyframeIndex = window.keyframeIndex

      # Create presentation and fill it with embedded JSON data
      @presentation = new Presentation presentationData, parse: true

      # TODO: Why not use params.show_titles etc.?
      showTitles = /show_titles=1/.test location.href
      showLegend = /show_legend=1/.test location.href
      format = if /size=thumb/.test location.href
        utils.FORMAT_THUMBNAIL
      else
        utils.FORMAT_DEFAULT

      # Hand over to RenderAgent
      renderAgent = new RenderAgent {
        @presentation,
        keyframeIndex,
        showTitles,
        showLegend,
        format
      }
      window.renderAgent = renderAgent
      renderAgent.drawNext()
