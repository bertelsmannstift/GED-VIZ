define (require) ->
  'use strict'
  $ = require 'jquery'
  Raphael = require 'raphael'
  View = require 'views/base/view'
  SaveView = require 'views/save_view'
  EmbedView = require 'views/embed_view'
  ExportView = require 'views/export_view'
  Colors = require 'lib/colors'
  I18n = require 'lib/i18n'

  class SharingView extends View

    # Property declarations
    # ---------------------
    #
    # model: Presentation

    templateName: 'sharing'

    className: 'sharing'

    events:
      'click .get-url .button': 'showSaveView'
      'click .share-via-mail': 'shareViaMail'
      'click .share-via-facebook': 'shareViaFacebook'
      'click .share-via-twitter': 'shareViaTwitter'
      'click .embed .button': 'embed'
      'click .export .button': 'export'

    initialize: ->
      super

      @wrapSaveMethods()

      @model.synced @render

      # Toggle when a keyframe has been captured/removed
      keyframes = @model.get 'keyframes'
      @listenTo keyframes, 'add remove reset', @toggle

    # Wrap handler methods that require the model to be saved
    wrapSaveMethods: ->
      for methodName in ['showSaveView', 'shareViaMail', 'embed', 'export']
        @wrapSaveMethod methodName
      for methodName in ['shareViaFacebook', 'shareViaTwitter']
        @wrapSaveMethod methodName, async: false
      return

    wrapSaveMethod: (methodName, options) ->
        original = this[methodName]
        this[methodName] = (event) ->
          event.preventDefault()
          if options and options.async is false
            @model.syncSaveIfChanged()
            original()
          else
            @model.saveIfChanged().then original
        return

    showSaveView: =>
      @subview 'save', new SaveView {@model}
      return

    shareViaMail: =>
      subject = encodeURIComponent I18n.t('editor', 'sharing_text')
      body = encodeURIComponent @model.getEditorURL()
      url = "mailto:?subject=#{subject}&body=#{body}"
      location.href = url
      return

    shareViaFacebook: =>
      params = u: @model.getEditorURL()
      url = "https://www.facebook.com/sharer.php?#{$.param(params)}"
      window.open url, '_blank'
      return

    shareViaTwitter: =>
      params = text: "#{I18n.t('editor', 'sharing_text')} #{@model.getEditorURL()}"
      url = "https://twitter.com/intent/tweet?#{$.param(params)}"
      window.open url, '_blank'
      return

    embed: =>
      @subview 'embed', new EmbedView {@model}
      @publishEvent 'editor:openEmbedDialog'
      return

    export: =>
      @subview 'export', new ExportView {@model}
      return

    # Show/hide depending on the captured keyframes
    toggle: ->
      direction = if @model.get('keyframes').length
        'slideDown'
      else
        'slideUp'
      @$('.sharing-options')[direction]()
      return

    render: ->
      super

      # Hide options initially if there are no keyframes
      unless @model.get('keyframes').length
        @$('.sharing-options').hide()

      # Append to DOM before drawing the arrow
      $(@container).append @el

      # Draw the top arrow using Raphael
      $arrow = @$('.arrow')
      arrowWidth = $arrow.width()
      arrowHeight = $arrow.height()
      Raphael($arrow.get(0), arrowWidth, arrowHeight)
        .path("M 0 #{arrowHeight} 0 L #{arrowWidth  / 2} 0 L #{arrowWidth} #{arrowHeight} z")
        .attr(fill: Colors.backgroundGray, 'stroke-opacity': 0)

      this
