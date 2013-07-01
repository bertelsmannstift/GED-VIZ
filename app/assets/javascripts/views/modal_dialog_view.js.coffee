define [
  'views/base/view'
], (View) ->
  'use strict'

  class ModalDialogView extends View

    listen:
      addedToDOM: 'addedToDOM'

    events:
      click: 'backgroundClicked'
      'click .close': 'closeButtonClicked'
      'click .close-button': 'closeButtonClicked'

    initialize: ->
      super
      $(document).keydown @closeOnEscape

    closeButtonClicked: (event) =>
      event.preventDefault()
      @dispose()

    closeOnEscape: (event) =>
      @dispose() if event.keyCode is 27

    backgroundClicked: (event) =>
      @dispose() if event.target is event.currentTarget

    addedToDOM: ->
      # Set focus to the dialog
      @$('.window').attr(tabindex: 0).focus()

    dispose: ->
      return if @disposed
      $(document).off 'keydown', @closeOnEscape
      super
