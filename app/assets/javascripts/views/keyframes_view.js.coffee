define [
  'raphael'
  'underscore'
  'models/bubble'
  'views/base/view'
  'views/keyframe_view'
  'views/new_keyframe_view'
  'views/bubble_view'
  'jquery.sortable'
], (Raphael, _, Bubble, View, KeyframeView, NewKeyframeView, BubbleView) ->
  'use strict'

  # This isn’t a CollectionView because we need specific logic.
  # The item views are added to the DOM in the opposite order.

  class KeyframesView extends View

    # Property declarations
    # ---------------------
    #
    # model: Editor (NOT Keyframes)
    # arrowContainer: jQuery

    templateName: 'keyframes'

    className: 'keyframes'

    events:
      'click .capture': 'captureButtonClicked'
      'keypress .new .title': 'newTitleKeypressed'

      'sortupdate' : 'sorted'

      'mouseenter .capture': 'showCaptureRollover'
      'mouseleave .capture': 'hideCaptureRollover'

    initialize: ->
      super

      # Model Bindings
      @listenTo @model, 'change:index', @highlightCurrentKeyframe
      @listenTo @getKeyframes(), 'add remove reset', @renderKeyframeList
      @subscribeEvent 'editor:openEmbedDialog', @hideCaptureNotification

    # Shortcut getter
    # ---------------

    getKeyframes: ->
      @model.getKeyframes()

    # Rendering the list
    # ------------------

    renderKeyframeList: ->
      # Dispose existing subviews
      if @subviews
        for view in @subviews
          view.dispose()

      $list = @$('ul')

      # Render existing keyframes
      @getKeyframes().each (keyframe, index) =>
        view = new KeyframeView
          model: keyframe
          editor: @model
        @subview "keyframe_#{index}", view
        $list.prepend view.el

      # Render new keyframe
      view = new NewKeyframeView {@model}
      @subview 'keyframe_new', view
      $list.prepend view.el

      # Make the list sortable
      $list.sortable items: ':not(.new)'

      @highlightCurrentKeyframe()

      @showCaptureNotification()

    highlightCurrentKeyframe: ->
      index = @model.get 'index'
      index = if index? then -1 - index else 0
      $items = @$('li')
      unless $items.length
        return
      $items.removeClass 'current'
      $item = $items.eq(index).addClass('current')

      # Draw the marker arrow using Raphael
      unless @arrowContainer
        @arrowContainer = @$('.arrow')
        width = 15
        height = 50
        Raphael(@arrowContainer.get(0), width, height)
          .path("M #{width} 0 V #{height} L 0 #{height / 2} z")
          .attr(fill: '#e6e6e6', 'stroke-opacity': 0)
      $item.append @arrowContainer

      return

    # Capture notification
    # --------------------

    showCaptureNotification: ->
      keyframeCount = @getKeyframes().length

      if keyframeCount is 0
        bubble = new Bubble
          type: 'notification'
          text: 'capture_slide_1'
          targetElement: @$('.capture')
          position: 'above'
          positionLeftReference: '.editor .sidebar'
          customClass: 'capture'
          timeout: 2000

      else if keyframeCount is 1
        bubble = new Bubble
          type: 'notification'
          text: 'capture_slide_2'
          targetElement: @$('.capture')
          position: 'above'
          positionLeftReference: '.editor .sidebar'
          customClass: 'capture'
          timeout: 800

      else if keyframeCount is 2
        bubble = new Bubble
          type: 'notification'
          text: 'capture_slide_3'
          targetElement: '.sharing-options .embed'
          position: 'left'
          positionTopReference: '.sharing-options .embed'
          customClass: 'sharing'
          offset: 20
          timeout: 800

      if bubble
        @subview 'captureNotification', new BubbleView(model: bubble)

      return

    hideCaptureNotification: ->
      @removeSubview 'captureNotification'
      return

    # Capture rollover
    # ----------------

    showCaptureRollover: ->
      captureNotificationView = @subview 'captureNotification'
      return if captureNotificationView and not captureNotificationView.disposed

      target = @$('.capture')
      bubble = new Bubble
        type: 'rollover'
        text: 'capture'
        targetElement: target
        position: 'above'
        positionLeftReference: '.editor .sidebar'
        customClass: 'capture'

      @subview 'captureRollover', new BubbleView(model: bubble)
      return

    hideCaptureRollover: ->
      @removeSubview 'captureRollover'
      return

    # Event handlers
    # --------------

    captureButtonClicked: (event) ->
      event.preventDefault()
      @captureKeyframe()
      return

    newTitleKeypressed: (event) ->
      @captureKeyframe() if event.keyCode is 13
      return

    captureKeyframe: ->
      @hideCaptureRollover()
      @hideCaptureNotification()
      @model.captureKeyframe title: @$('.new .title').val()
      return

    # Drag and drop sorting handler
    sorted: (event, params) ->
      length = @$('li').length
      # reverse order because DOM order != keyframe order
      oldIndex = length - 1 - params.oldIndex
      newIndex = length - 1 - params.newIndex
      @model.moveKeyframe oldIndex, newIndex

