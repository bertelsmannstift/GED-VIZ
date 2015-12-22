define (require) ->
  'use strict'
  $ = require 'jquery'
  Chaplin = require 'chaplin'
  routes = require 'routes'
  require 'controllers/editor_controller'
  require 'controllers/player_controller'
  require 'controllers/static_controller'
  require 'lib/dummy_console'

  # The application object
  class GedViz extends Chaplin.Application

    # Set your application name here so the document title is set to
    # “Controller title – Site title” (see Layout#adjustTitle)
    title: 'GED VIZ'

    initialize: ->
      super

      # Register all routes
      @initRouter routes

      # Initialize core components
      @initDispatcher()
      @initLayout()
      @initComposer()
      @initMediator()

      @initAPI()

      # Actually start routing.
      @startRouting()

      # Freeze the application instance to prevent further changes.
      Object.freeze? this

    # Create aditional mediator properties
    # ------------------------------------
    initMediator: ->
      # Seal the mediator
      Chaplin.mediator.seal()

    # Add the authenticity token to all JavaScript requests
    initAPI: ->
      $(document).ajaxSend (event, jqXHR, settings) ->
        return if settings.crossDomain
        jqXHR.setRequestHeader 'X-CSRF-Token',
          $('meta[name="csrf-token"]').attr('content')
      return
