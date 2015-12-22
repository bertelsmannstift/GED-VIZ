define (require) ->
  'use strict'
  $ = require 'jquery'
  View = require 'views/base/view'

  class ModalDialogView extends View

    listen:
      addedToDOM: 'addedToDOM'

    events:
      click: 'backgroundClicked'
      'click .close': 'closeButtonClicked'
      'click .close-button': 'closeButtonClicked'

    container: '#page-container'

    autoRender: true

    # Whether to focus to the dialog after showing
    autoFocus: true

    # Whether to center the dialog in the viewport
    centered: true

    initialize: ->
      super
      $(document).keydown @closeOnEscape
      return

    closeButtonClicked: (event) =>
      event.preventDefault()
      @dispose()
      return

    closeOnEscape: (event) =>
      @dispose() if event.keyCode is 27
      return

    backgroundClicked: (event) =>
      @dispose() if event.target is event.currentTarget
      return

    addedToDOM: ->
      @center() if @centered

      # Set focus to the dialog
      if @autoFocus
        @$('.window').attr('tabindex', 0).focus()

      return

    center: ->
      dialogWindow = @$('.window')
      left = ($(window).width() - dialogWindow.outerWidth()) / 2
      top = ($(window).height() - dialogWindow.outerHeight()) / 2
      dialogWindow.css { left, top }
      return

    dispose: ->
      return if @disposed
      $(document).off 'keydown', @closeOnEscape
      super
