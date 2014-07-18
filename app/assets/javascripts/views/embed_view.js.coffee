define [
  'views/modal_dialog_view'
], (ModalDialogView) ->
  'use strict'

  class EmbedView extends ModalDialogView

    templateName: 'embed'

    className: 'modal-dialog embed-dialog'

    # Reference to the popup window object
    previewWindow: null

    events:
      'click .preview' : 'previewClicked'

      'keyup .size input': 'sizeUp'
      'change .size input': 'sizeChanged'
      'change .keyframes': 'optionsChanged'

    render: ->
      super
      @updateCode()
      this

    sizeUp: ->
      width = Number @$('.size input').val()
      @updateCode() if not isNaN(width) and width >= 300
      return

    previewClicked: (event) ->
      event.preventDefault()
      event.stopImmediatePropagation()
      [width, height] = @getWidthAndHeight()
      width ?= 800
      height ?= 600
      options = "width=#{width},height=#{height},centerscreen"
      @previewWindow.close() if @previewWindow
      @previewWindow = window.open @getPlayerURL(), 'preview', options
      @previewWindow.focus()
      return

    sizeChanged: ->
      width = Number @$('.size input').val()
      @$('.size input').val('300') if isNaN(width) or width < 300
      @updateCode()
      return

    optionsChanged: ->
      @updateCode()
      @selectCode()
      return

    getPlayerURL: ->
      options =
        animate: @$('input.animate:checked').val() is '1'
        showTitles: @$('input.show-titles').prop('checked')
        includeProtocol: false

      @model.getPlayerURL options

    getWidthAndHeight: ->
      width = (Number @$('.size input').val()) or null
      if width
        height = Math.round(width / 4 * 3)
        [width, height]
      else
        [null, null]

    updateCode: ->
      url = @getPlayerURL()

      @$('.preview').attr href: url

      [width, height] = @getWidthAndHeight()
      widthString = if width?
        " width=\"#{width}\" height=\"#{height}\""
      else
        ""
      @$('textarea').text """<iframe src="#{url}"#{widthString} style="border: 1px solid #eee" mozallowfullscreen="true" webkitallowfullscreen="true" allowfullscreen="true"><a href="#{url}" target="_blank">GED VIZ Slideshow</a></iframe>"""

      return

    selectCode: ->
      @$('textarea').focus().select()
      return

    addedToDOM: ->
      super
      @selectCode()
      return

    dispose: ->
      return if @disposed
      @previewWindow.close() if @previewWindow
      delete @previewWindow
      super
