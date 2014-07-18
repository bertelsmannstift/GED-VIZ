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

      # Create presentation
      if presentationData and presentationData.id
        # Fill it with embedded JSON data
        @presentation = new Presentation presentationData, parse: true
      else if params.id
        # Fetch it from remote
        @presentation = new Presentation id: params.id
        @presentation.fetch()
      @view = new PlayerView model: @presentation if @presentation
