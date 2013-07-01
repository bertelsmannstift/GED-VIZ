define [
  'views/base/view'
  'lib/support'
], (View, support) ->
  'use strict'

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
      @$el.css 'top', headerHeight + 5 if headerHeight?

      @$el.stop(true, false).fadeIn()

    handleHideEvent: ->
      @$el.stop(true, false).fadeOut()
