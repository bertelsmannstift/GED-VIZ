define [
  'jquery'
  'configuration'
  'views/modal_dialog_view'
], ($, configuration, ModalDialogView) ->
  'use strict'

  class EditorIntroductionView extends ModalDialogView

    templateName: 'editor_introduction'

    className: 'modal-dialog editor-introduction'

    container: '#page-container'

    autoRender: true

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
      return unless window.postMessage and @player
      @player.playVideo()
      return
