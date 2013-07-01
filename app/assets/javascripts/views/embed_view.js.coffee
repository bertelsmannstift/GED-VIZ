define [
  'views/modal_dialog_view'
], (ModalDialogView) ->
  'use strict'

  class EmbedView extends ModalDialogView

    templateName: 'embed'

    className: 'modal-dialog embed-dialog'

    container: '#page-container'

    autoRender: true

    previewWindow: null

    events:
      'click .preview' : 'previewClicked'

      'keyup .size input': 'sizeUp'
      'change .size input': 'sizeChanged'
      'change .keyframes': 'optionsChanged'

    render: ->
      super
      @updateCode()

    sizeUp: ->
      width = (Number @$('.size input').val()) or null
      @updateCode() unless width? and width < 300

    previewClicked: (event) ->
      event.preventDefault()
      event.stopImmediatePropagation()
      [width, height] = @getWidthAndHeight()
      width ?= 800
      height ?= 600
      options = "width=#{width},height=#{height},centerscreen"
      @previewWindow?.close()
      @previewWindow = window.open @getPlayerURL(), 'preview', options

    sizeChanged: ->
      width = (Number @$('.size input').val()) or null
      @$('.size input').val('300') if width? and width < 300
      @updateCode()

    optionsChanged: ->
      @updateCode()
      @selectCode()

    getPlayerURL: ->
      options =
        animate: @$('input.animate:checked').val() is '1'
        showTitles: @$('input.show-titles').prop('checked')

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

    selectCode: ->
      @$('textarea').focus().select()

    addedToDOM: ->
      @selectCode()

    dispose: ->
      return if @disposed
      @previewWindow?.close()
      delete @previewWindow
      super
