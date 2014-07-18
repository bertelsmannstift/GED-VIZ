define [
  'underscore'
  'jquery'
  'views/base/view'
  'lib/utils'
  'lib/i18n'
  'lib/support'
], (_, $, View, utils, I18n, support) ->
  'use strict'

  class BubbleView extends View

    # Constants
    # ---------

    ARROW_WIDTH = 10
    ARROW_HALF_WIDTH = ARROW_WIDTH / 2
    ARROW_HEIGHT = 6

    # Properties
    # ----------

    templateName: 'bubble'

    className: 'bubble-container'

    autoRender: true

    container: '#page-container'

    events:
      'click .close': 'close'

    # Property declarations
    # ---------------------
    #
    # showElementHandle: Number

    initialize: ->
      super

      active = true

      type = @model.get 'type'

      # Do not render if it's a notification and was already displayed once
      if type is 'notification' and support.localStorage
        notificationKey = "notification:#{@model.get('text')}"
        if localStorage.getItem(notificationKey)?
          active = false
        localStorage.setItem notificationKey, true

      if type is 'rollover' and not support.mouseover
          active = false

      unless active
        # Do not render at all
        @autoRender = false
        # Dispose after initialize
        utils.after 1, @dispose

      super

    render: ->
      super
      $(window).resize @positionElement

      # Save elements
      @bubble = @$('.bubble')
      @arrow = @$('.bubble-arrow')

      # Add CSS class based on notification type
      className = if @model.get('type') is 'notification'
        'bubble-notification'
      else
        'bubble-rollover'
      @bubble.addClass className

      # Add custom CSS class if set
      customClass = @model.get 'customClass'
      if customClass
        @bubble.addClass "bubble-#{customClass}"

      # Hide element and start timer if timeout is set
      if @model.get('timeout') is 0
        @showElement()
      else
        @resetTimeout()

      this

    getTemplateData: ->
      data = super

      keys = ['bubbles', @model.get('type')]
      key = @model.get 'text'
      if _.isArray(key)
        keys = keys.concat key
      else
        keys.push key

      templateData = @model.get 'templateData'
      data.text = if templateData
        I18n.template keys, templateData
      else
        I18n.t keys...

      data

    # Show the element after the timeout
    resetTimeout: =>
      # Clear and reset timeout
      clearTimeout @showElementHandle
      @showElementHandle = utils.after @model.get('timeout'), @showElement
      return

    showElement: =>
      @positionElement()

      # Show bubble
      @bubble.css 'display', 'block'
      @arrow.css 'display', 'block'

      return

    styleRule: (modelAttribute, cssProperty, func) ->
      reference = @model.get modelAttribute
      return unless reference?
      $reference = $(reference)
      return unless $reference.length
      cssValue = func.call this, $reference
      @bubble.css cssProperty, cssValue if cssValue?
      return

    positionElement: =>

      # Adjust bounds
      @styleRule 'positionLeftReference', 'left', ($reference) ->
        $reference.offset().left

      @styleRule 'positionRightReference', 'right', ($reference) ->
        $(window).width() - $reference.offset().left - $reference.outerWidth()

      @styleRule 'positionTopReference', 'top', ($reference) ->
        $reference.offset().top

      @styleRule 'positionBottomReference', 'bottom', ($reference) ->
        $(window).height() - $reference.offset().top - $reference.outerHeight()

      # Set width and height based on reference element
      # -----------------------------------------------

      @styleRule 'widthReference', 'width', ($reference) ->
        $reference.width()

      @styleRule 'heightReference', 'height', ($reference) ->
        $reference.height()

      # Adjust position
      # ---------------

      offset = @model.get 'offset'
      targetElement = $(@model.get('targetElement'))
      return unless targetElement.length
      targetWidth = targetElement.width()
      targetHalfWidth = targetWidth / 2
      targetHeight = targetElement.height()
      targetHalfHeight = targetHeight / 2

      targetOffset = targetElement.offset()
      arrowOffset = targetOffset

      position = @model.get 'position'

      if position is 'above'
        @bubble.css 'bottom', $(window).height() - targetOffset.top + offset
        arrowOffset.left += targetHalfWidth - ARROW_HALF_WIDTH
        arrowOffset.top -= offset
        pathString = "M 0 0 L #{ARROW_WIDTH / 2} #{ARROW_HEIGHT} L #{ARROW_WIDTH} 0 z"

      else if position is 'below'
        @bubble.css 'top', targetOffset.top + targetHeight + offset
        arrowOffset.left += targetHalfWidth - ARROW_HALF_WIDTH
        arrowOffset.top += targetHeight + offset - ARROW_HEIGHT
        pathString = "M 0 #{ARROW_HEIGHT} L #{ARROW_WIDTH / 2} 0 L #{ARROW_WIDTH} #{ARROW_HEIGHT} z"

      else if position is 'left'
        @bubble.css 'right', $(window).width() - targetOffset.left + offset
        arrowOffset.left -= offset
        arrowOffset.top += targetHalfHeight - ARROW_HALF_WIDTH
        pathString = "M 0 0 L #{ARROW_HEIGHT} #{ARROW_WIDTH / 2} L 0 #{ARROW_WIDTH} z"

      else if position is 'right'
        @bubble.css 'left', targetOffset.left + targetElement.width() + offset
        arrowOffset.left += targetWidth + offset - ARROW_HEIGHT
        arrowOffset.top += targetHalfHeight - ARROW_HALF_WIDTH
        pathString = "M 0 #{ARROW_HEIGHT} L 0 #{ARROW_WIDTH / 2} L #{ARROW_HEIGHT} #{ARROW_WIDTH} z"

      # Draw arrow
      # ----------

      unless @arrowDrawn
        arrowEl = @arrow.get 0
        if position in ['left', 'right']
          # 90° rotation
          paperWidth = ARROW_HEIGHT
          paperHeight = ARROW_WIDTH
        else
          paperWidth = ARROW_WIDTH
          paperHeight = ARROW_HEIGHT
        paper = Raphael arrowEl, paperWidth, paperHeight
        pathAttributes = fill: '#1dbdff', 'stroke-opacity': 0
        paper.path(pathString).attr(pathAttributes)
        @arrowDrawn = true

      @arrow.offset arrowOffset

    close: (event) ->
      event.preventDefault()
      @dispose()

    dispose: =>
      return if @disposed
      clearTimeout @showElementHandle
      $(window).off 'resize', @positionElement
      super
