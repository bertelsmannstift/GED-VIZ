define [
  'jquery'
  'views/modal_dialog_view'
  'lib/utils'
  'lib/support'
], ($, ModalDialogView, utils, support) ->
  'use strict'

  class EditorIntroductionView extends ModalDialogView

    templateName: 'editor_introduction'

    className: 'modal-dialog editor-introduction'

    events:
      'click .tutorial': 'play'
      'click .start': 'closeButtonClicked'

    # Property declarations
    # ---------------------

    # YouTube player
    player: null

    render: ->
      super
      @loadPlayerAPI()

    loadPlayerAPI: ->
      # Load the YouTube player API
      # (See https://developers.google.com/youtube/iframe_api_reference
      # and https://developers.google.com/youtube/youtube_player_demo)
      window.onYouTubeIframeAPIReady = @playerAPILoaded
      $.ajax
        url: 'http://www.youtube.com/player_api'
        cache: true
        dataType: 'script'
      return

    playerAPILoaded: =>
      # Cleanup
      try
        delete window.onYouTubeIframeAPIReady
      catch error
        window.onYouTubeIframeAPIReady = null
      # Create the player for existing iframe
      return unless window.YT and YT.Player
      @player = new YT.Player 'tutorial-video'
      return

    play: (event) ->
      event.preventDefault()
      if window.postMessage and @player and @player.playVideo
        @player.playVideo()
      return

    minimize: (event) ->
      event.preventDefault() if event and event.type is 'click'
      if support.cssTransitionProperty and support.cssTransformProperty
        @player.stopVideo() if @player and @player.stopVideo
        @$('.window').addClass 'minimized'
        utils.after 1200, => @dispose()
      else
        @dispose()
      return

    closeOnEscape: @prototype.minimize
    closeButtonClicked: @prototype.minimize

    backgroundClicked: =>
      if event.target is event.currentTarget
        @prototype.minimize()
      return
