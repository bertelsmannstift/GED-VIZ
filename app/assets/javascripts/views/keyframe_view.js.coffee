define (require) ->
  'use strict'
  _ = require 'underscore'
  I18n = require 'lib/i18n'
  Bubble = require 'models/bubble'
  View = require 'views/base/view'
  BubbleView = require 'views/bubble_view'

  class KeyframeView extends View

    # Property declarations
    # ---------------------
    #
    # editor: Editor

    tagName: 'li'
    className: 'existing'

    templateName: 'keyframe'

    autoRender: true

    events:
      click: 'select'
      'click .remove': 'removeKeyframe'

      'mouseenter .title': 'showRollover'
      'mouseleave .title': 'hideRollover'
      'focus .title' : 'titleFocussed'

      'keypress .title': 'saveTitleOnEnter'
      'blur .title': 'titleBlurred'

    initialize: (options) ->
      super
      @editor = options.editor

    # Rendering
    # ---------

    getTemplateData: ->
      data = super
      data.visibleIndex = @editor.getKeyframes().indexOf(@model) + 1
      data.subtitle = @model.getSubtitle()
      data

    # Event handlers
    # --------------

    select: (event) ->
      event.preventDefault()
      @hideRollover()
      @editor.selectKeyframe @model
      # Save the index change
      @editor.saveDraft()
      return

    removeKeyframe: (event) ->
      event.preventDefault()
      event.stopPropagation() # Prevent selecting
      @editor.getKeyframes().remove @model
      return

    titleFocussed: ->
      # Disable drag and drop while input is focussed
      @$el.attr 'draggable', false
      @hideRollover()
      return

    titleBlurred: (event) ->
      # Re-enable drag and drop
      @$el.attr 'draggable', true
      @saveTitle event.target.value
      return

    saveTitleOnEnter: (event) ->
      if event.keyCode is 13
        input = event.target
        @saveTitle input.value
        input.blur()
      return

    saveTitle: (title) ->
      @model.set {title}
      return

    # Rename rollover
    # ---------------

    showRollover: (event) ->
      target = $(event.target)
      return if target.is(':focus')
      bubble = new Bubble
        type: 'rollover'
        text: 'rename_slide'
        targetElement: target
        position: 'left'
        positionTopReference: target
        offset: 12
        timeout: 800

      @subview 'rollover', new BubbleView(model: bubble)
      return

    hideRollover: ->
      @removeSubview 'rollover'
      return

    # Disposal
    # --------

    dispose: ->
      return if @disposed
      delete @editor
      super
