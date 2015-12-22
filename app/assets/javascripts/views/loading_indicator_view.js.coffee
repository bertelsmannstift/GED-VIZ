define (require) ->
  'use strict'
  View = require 'views/base/view'
  support = require 'lib/support'

  class LoadingIndicatorView extends View
    autoRender: true
    templateName: 'loading_indicator'
    className: 'loading-indicator'

    initialize: ->
      super
      @subscribeEvent 'keyframe:syncing', @handleShowEvent
      @subscribeEvent 'keyframe:synced', @handleHideEvent
      @subscribeEvent 'keyframe:unsynced', @handleHideEvent

    handleShowEvent: ->
      # When in editor, position below the header
      headerHeight = $('.header-and-keyframe-configuration').height()
      if headerHeight?
        chartYPosition = @$el.parent().offset().top
        diff = Math.abs chartYPosition - headerHeight
        @$el.css 'top', diff + 5

      @$el.stop(true, false).fadeIn()

    handleHideEvent: ->
      @$el.stop(true, false).fadeOut()
