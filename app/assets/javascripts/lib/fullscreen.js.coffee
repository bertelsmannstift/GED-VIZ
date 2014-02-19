define ->
  'use strict'

  requestFullscreen: (el) ->
    if el.requestFullscreen
      el.requestFullscreen()
    else if el.mozRequestFullScreen
      el.mozRequestFullScreen()
    else if el.webkitRequestFullScreen
      el.webkitRequestFullScreen()
    else if el.msRequestFullScreen
      el.msRequestFullScreen()
    else
      # Fall back to an old-school popup window
      options = 'fullscreen=yes,menubar=no,location=no,toolbar=no,status=no'
      window.open location.href, '_blank', options
    return

  exitFullscreen: ->
    if document.exitFullscreen
      document.exitFullscreen()
    else if document.mozCancelFullScreen
      document.mozCancelFullScreen()
    else if document.webkitCancelFullScreen
      document.webkitCancelFullScreen()
    else if document.msCancelFullScreen
      document.msCancelFullScreen()
    return

  isFullScreen: ->
    document.fullScreen or document.mozFullScreen or
    document.webkitIsFullScreen or document.msIsFullScreen

  toggleFullscreen: (el) ->
    if @isFullScreen()
      @exitFullscreen()
    else
      @requestFullscreen el
    return

