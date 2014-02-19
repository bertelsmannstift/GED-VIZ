define [
  'jquery'
  'chaplin'
  'routes'
  # Require base controllers manually because
  # they aren’t compiled individually
  'controllers/editor_controller'
  'controllers/player_controller'
  'controllers/static_controller'
  # Require dummy console
  'lib/dummy_console'
], ($, Chaplin, routes) ->
  'use strict'

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
