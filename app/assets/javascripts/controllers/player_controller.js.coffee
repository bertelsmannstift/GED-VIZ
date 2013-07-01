define [
  'controllers/base/controller'
  'models/presentation'
  'views/player_view'
], (Controller, Presentation, PlayerView) ->
  'use strict'

  class PlayerController extends Controller

    show: (params) ->
      # Import global params
      presentationData = window.presentation

      # Create presentation and fill it with embedded JSON data
      if presentationData
        @presentation = new Presentation presentationData, parse: true
      else
        @presentation = new Presentation id: params.id
        @presentation.fetch()
      @view = new PlayerView model: @presentation
