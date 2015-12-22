define (require) ->
  'use strict'
  Controller = require 'controllers/base/controller'
  Presentation = require 'models/presentation'
  PlayerView = require 'views/player_view'

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
