define (require) ->
  'use strict'
  $ = require 'jquery'
  Raphael = require 'raphael'
  DisplayObject = require 'display_objects/display_object'
  Indicator = require 'display_objects/indicator'
  IndicatorVisualization = require 'display_objects/indicator_visualization'
  scale = require 'lib/scale'
  utils = require 'lib/utils'

  # Shortcuts
  # ---------

  PI = Math.PI
  HALF_PI = PI / 2

  sin = Math.sin
  cos = Math.cos

  TOP = 'top'
  LEFT = 'left'
  BOTTOM = 'bottom'
  RIGHT = 'right'

  NORMAL = 'normal'
  INVISIBLE = 'invisible'
  HIGHLIGHT = 'highlight'

  class Indicators extends DisplayObject

    # Property declarations
    # ---------------------
    #
    # element: Element
    # data: Array.<Object>
    # animateExisting: Boolean
    #
    # indicatorHeight: Number
    # distanceToMagnet: Number
    #
    # indicatorLimit: Number
    #   Maximum number of visible indicators
    #   determined by the number of elements in the chart
    # visibleCount: Number
    #   The number of visible Indicators
    #
    # side: TOP, RIGHT, BOTTOM or LEFT
    # labelBesideIndicators: Boolean
    #
    # tanYFactor: Number
    # startX: Number
    # startY: Number
    #
    # countryLabel: Raphael.Element
    # countryLabelX: Number
    # countryLabelY: Number
    #
    # indicators: Array.<Indicator>
    #   The actual list which holds the Indicator instances
    #
    # labelBesideIndicators: Boolean
    #   Whether the country label is positioned next to the indicators
    #   (top/bottom placement)
    #
    # afterTransitionHandle: Number
    #   setTimeout handle for the deferred drawing
    #
    # Drawing variables which are passed in:
    #
    # paper: Raphael.Paper
    # $container: jQuery
    # animationDuration: Number
    # chartFormat: String
    # customFont: Boolean
    # chartRadius: Number
    # elementCount: Number
    # elementIdsChanged: Boolean
    # indicatorVisible: Boolean
    #   Whether label/indicator is visible per default in Nine-To-All charts
    # degDiff: Number

    DRAW_OPTIONS: ('paper $container animationDuration chartFormat ' +
      'customFont chartRadius elementCount elementIdsChanged ' +
      'indicatorVisible degDiff').split(' ')

    constructor: (@element, @data) ->
      super

      # States:
      #
      # normal
      #   Country label and indicators are permanently visible
      # invisible
      #   Nothing is visible
      # highlight
      #   Label and indicators temporarily visible
      #
      @initStates
        states: [NORMAL, INVISIBLE, HIGHLIGHT]
        initialState: NORMAL

      @indicators = []

    # Updating the data
    # -----------------

    update: (@data) ->
      # Just save the data, the indicators are created/updated on draw.

    # Creating and updating indicators
    # --------------------------------

    # Create indicator objects from @data
    createIndicators: ->
      @indicators = []
      for indicatorData in @data
        indicator = new Indicator @element, indicatorData
        @indicators.push indicator
        @addChild indicator
      return

    # Dispose all indicators
    removeIndicators: ->
      @removeChild indicator for indicator in @indicators
      @indicators = []
      return

    # Update existing indicators from @data
    updateIndicators: ->
      for indicator, index in @indicators
        indicator.update @data[index]
      return

    # Drawing
    # -------

    draw: (options) =>
      @saveDrawOptions options

      @animateExisting = @elementCount < 9 and not @elementIdsChanged and
        @sameIndicatorTypes()

      if @indicators.length and @animateExisting
        # Update (and later animate) existing indicators
        @updateIndicators()
      else
        # Create (and later draw) indicators from scratch
        @removeIndicators()
        @createIndicators()

      # Initialize visibility
      @toggle()

      # Preparations
      @calculateLimit()
      @calculateHeightAndDistance()
      @calculateSide()
      @calculateStart()

      # Draw the indicator(s)
      if @elementCount < 9
        @drawOneToEight()
      else
        @drawNineToAll()

      @drawn = true
      return

    # Returns whether the indicator types and units in @data
    # matches the existing @indicators
    sameIndicatorTypes: ->
      @indicators and (@data.length is @indicators.length) and
      _(@indicators).every (oldIndicator, index) =>
        newModel = @data[index]
        oldModel = oldIndicator.data
        newModel.type is oldModel.type and newModel.unit is oldModel.unit

    # Decide how many indicators are visible depending on
    # the amount of elements in the chart.
    # Sets `indicatorLimit` and `visibleCount`.
    calculateLimit: ->
      @indicatorLimit = if @paper.width <= 300
        0
      else if @elementCount >= 9
        1
      else if @elementCount >= 6
        2
      else if @elementCount >= 3
        3
      else
        5
      @visibleCount = Math.min @indicatorLimit, @indicators.length
      return

    # Initialize the state (visible or hidden)
    toggle: ->
      # Hide if indicators would overlap with previous
      state = if @elementCount < 9 and @degDiff >= 18 or
      @elementCount >= 9 and @indicatorVisible or
      @elementCount is 1
        NORMAL
      else
        INVISIBLE
      @transitionTo state
      return

    # Calculate `indicatorHeight` and `distanceToMagnet`
    calculateHeightAndDistance: ->
      smallestSide = Math.min @paper.width, @paper.height
      @indicatorHeight  = scale 'indicatorHeight', smallestSide
      @distanceToMagnet = scale 'indicatorDistance', smallestSide
      return

    # Calculate `side` and `labelBesideIndicators`
    calculateSide: ->
      degdeg = @element.magnet.degdeg

      @side =
        # One-To-Eight
        if -65 < degdeg <= 65
          RIGHT
        else if 65 < degdeg <= 115
          BOTTOM
        else if 115 < degdeg <= 245
          LEFT
        else if 245 < degdeg or -90 <= degdeg <= -65
          TOP

      # Whether to position the indicators next to the label
      # and stack them vertically without indentation
      @labelBesideIndicators = @side in [TOP, BOTTOM] and @indicatorLimit > 2

      return

    # Calculate the start position of the country label
    # Sets `startX`, `startY`, `tanYFactor`
    calculateStart: ->
      magnet = @element.magnet
      deg = magnet.deg

      # Offset factors
      @tanYFactor = 1 / Math.tan(if @side is LEFT then HALF_PI - deg else deg - HALF_PI)

      # Get the magnet outer points
      x4 = magnet.absx4; y4 = magnet.absy4
      x6 = magnet.absx6; y6 = magnet.absy6

      # Get the point in the middle of them
      x = x4 + (x6 - x4) / 2
      y = y4 + (y6 - y4) / 2

      # Special behavior for less than 3 elements
      if @elementCount < 3
        @startX =
          # Magnet reference point
          (if @side is LEFT then x6 else x4) +
          # Move away from magnet
          @distanceToMagnet * (if @side is LEFT then -1 else 1)
        # Don’t use the magnet points for y point
        @startY =
          # Start at origin
          (@paper.height / 2) +
          # Move from center to the top
          (@chartRadius * -0.4)
        return

      # Move point away from magnet
      x += cos(deg) * @distanceToMagnet
      y += sin(deg) * @distanceToMagnet

      if @elementCount < 9
        # Regular polygon

        # Top position: Start at the topmost, draw from top to bottom
        if @side is TOP and @visibleCount
          y -= (@visibleCount - (if @labelBesideIndicators then 1 else 0)) * @indicatorHeight

        # Left and right position: Center the label and the indicators vertically
        # Calculate total height, then move the start point accordingly
        if @side in [LEFT, RIGHT]
          direction = if @side is RIGHT then -1 else 1
          # Total height of all indicators
          totalHeight = @visibleCount * @indicatorHeight
          offset = totalHeight / 2
          x += direction * offset * @tanYFactor
          y -= offset

      # Save calculated properties
      @startX = x
      @startY = y

      return

    # Drawing helper
    # --------------

    afterTransition: (handler) ->
      # Don’t wait if the existing indicators can be animated
      if @animateExisting
        handler()
        return

      timeout = if @drawn
        if @animationDuration > 0 then @animationDuration + 100 else 0
      else
        0
      clearTimeout @afterTransitionHandle
      @afterTransitionHandle = utils.after timeout, handler
      return

    # Draw indicators given there are max. 8 elements in the chart
    # ------------------------------------------------------------

    drawOneToEight: ->
      isDefaultFormat = @chartFormat is utils.FORMAT_DEFAULT

      @removeNineToAllVisualization()

      if @state() is NORMAL
        @drawCountryLabel() if isDefaultFormat
        # Draw indicators off-thread after chart update
        @afterTransition @drawOneToEightIndicators

      else # invisible
        # Clean up if (re-)drawn invisible
        @removeCountryLabel()
        @hideIndicators()

      return

    # Country label
    # -------------

    drawCountryLabel: ->
      {magnet} = @element
      {deg} = magnet

      x = @startX
      y = @startY - 2

      isNineToAll = @elementCount >= 9

      # Adjust the position
      if isNineToAll
        # 9+ elements
        # -----------

        # Move point away from magnet
        distance = @distanceToMagnet # Take the same value again
        x += cos(deg) * distance
        y += sin(deg) * distance

        # Top position: Start at the topmost, draw from top to bottom
        if @side is TOP and @visibleCount
          y -= (@visibleCount - (if @labelBesideIndicators then 1 else 0)) * @indicatorHeight

      else
        # 1-8 elements
        # ------------

        # Left and right position: Move x so the label is in a line with
        # the indicator visualizations’ center point
        if @side in [LEFT, RIGHT] and @visibleCount
          visualizationSize = scale 'visualizationSize', @paper.width
          x += (visualizationSize / 4) * (if @side is LEFT then -1 else 1)

        # Top and bottom position: When showing the text next to indicators,
        # add a gap between the text and the indicators
        if @labelBesideIndicators and @visibleCount
          x -= 20

      # Finally, the label.
      labelText = @element.name

      newLabel = not @countryLabel
      if newLabel
        # Create the a fresh label
        @countryLabel = @paper.text(x, y, labelText)
          .attr(
            'font-family': utils.getFont(@customFont)
            'font-weight': 600
            fill: 'rgb(45, 45, 45)'
          )

      # Text alignment
      textAnchor =
        if @labelBesideIndicators # This implies top or bottom
          'end'
        else if @side in [TOP, BOTTOM]
          'middle'
        else if @side is LEFT
          'end'
        else # right
          'start'

      # Set the font size and other properties
      # which might have changed since the creation.
      fontSize = scale 'countryLabelSize', @paper.width
      @countryLabel.attr
        text: labelText
        'text-anchor': textAnchor
        'font-size': fontSize
        opacity: 1

      if newLabel
        @addChild @countryLabel
      else
        # Animate existing country label
        @countryLabel
          .stop()
          .animate({x, y}, @animationDuration, 'easeOut')

      # Save the position
      @countryLabelX = x
      @countryLabelY = y

      return

    removeCountryLabel: ->
      return unless @countryLabel
      @removeChild @countryLabel
      delete @countryLabel
      delete @countryLabelX
      delete @countryLabelY
      return

    # Draw indicators (less than 9 elements)
    # --------------------------------------

    drawOneToEightIndicators: =>
      return if @visibleCount is 0

      x = @startX
      y = @startY

      # Top and bottom position: When showing the indicators below the text,
      # move x in order to center the indicators horizontally
      if @side in [TOP, BOTTOM] and not @labelBesideIndicators
        x += scale 'indicatorIndent', @paper.width

      for indicator, index in @indicators[0...@visibleCount]

        # Calculate the indicator’s position
        if @side in [LEFT, RIGHT]
          # Assure the actual vertical distance
          direction = if @side is LEFT then -1 else 1
          x += direction * @indicatorHeight * @tanYFactor
          y += @indicatorHeight
        else
          # Top and bottom: Skip the first increment when
          # the label is positioned next to the indicators
          if not @labelBesideIndicators or index > 0
            y += @indicatorHeight

        # Draw the indicator
        indicator.draw {@paper, @$container, @side}

        # Position the indicator’s element
        indicatorEl = indicator.el
        smallestSide = Math.min @paper.width, @paper.height
        eventualY = y - scale('visualizationSize', smallestSide) / 2
        if @side is LEFT
          eventualX = @paper.width - x
          indicatorEl.css right: eventualX, top: eventualY
        else
          eventualX = x
          indicatorEl.css left: eventualX, top: eventualY

      return

    # Draw visualization and indicator for Nine-To-All charts
    # -------------------------------------------------------

    drawNineToAll: ->
      isNormalState = @state() is NORMAL
      isDefaultFormat = @chartFormat is utils.FORMAT_DEFAULT

      @removeNineToAllVisualization()

      if isNormalState
        # Animate existing country label
        if @countryLabel and isDefaultFormat
          @drawCountryLabel()

      else # invisible
        # Clean up if (re-)drawn invisible
        @removeCountryLabel()
        @hideIndicators()

      @afterTransition @drawNineToAllAfterTransition

      return

    drawNineToAllAfterTransition: =>
      isNormalState = @state() is NORMAL
      isDefaultFormat = @chartFormat is utils.FORMAT_DEFAULT

      # Draw new country label
      if not @countryLabel and isNormalState and isDefaultFormat
        @drawCountryLabel()

      @drawNineToAllVisualization()

      if isNormalState
        @drawNineToAllIndicator()

      return

    # Nine-To-All visualization
    # -------------------------

    # Draw a visualization directly and position it on the start point
    drawNineToAllVisualization: ->
      indicator = @indicators[0]
      return unless indicator

      unless @visualization
        @visualization = new IndicatorVisualization()
        @listenTo @visualization, 'mouseenter', @visualizationMouseenter
        @listenTo @visualization, 'mouseleave', @visualizationMouseleave
        @addChild @visualization

      width = scale 'visualizationSizeNineToAll', @paper.width
      height = width
      x = @startX - width / 2
      y = @startY - height / 2
      @visualization.draw {@paper, x, y, width, height, data: indicator.data}

      return

    visualizationMouseenter: ->
      if @state() is INVISIBLE
        @transitionTo HIGHLIGHT
      @element.magnet.transitionTo 'mode', 'highlight'
      return

    visualizationMouseleave: ->
      if @state() is HIGHLIGHT
        @transitionTo INVISIBLE
      @element.magnet.transitionTo 'mode', 'normal'
      return

    removeNineToAllVisualization: ->
      if @visualization
        @removeChild @visualization
        delete @visualization
      return

    # Nine-To-All indicator
    # ---------------------

    # Draw one indicator just below the label
    drawNineToAllIndicator: ->
      indicator = @indicators[0]
      return unless indicator

      # Draw an indicator without visualization
      indicator.draw {@paper, @$container, @side, drawVisualization: false}

      # Calculate position
      x = @countryLabelX - 4
      y = @countryLabelY + scale('magnetLabelSize', @paper.width) * 0.75

      # Top and bottom position: When showing the indicators below the text,
      # move x in order to center the indicators horizontally
      if @side in [TOP, BOTTOM] and not @labelBesideIndicators
        x += scale 'indicatorIndent', @paper.width

      # Ensure a minimum distance to visualization
      # diffX = Math.abs x - @startX
      # diffY = Math.abs y - @startY
      # if diffX < 5
      #   x += 5 * (if @side is LEFT then -1 else 1)
      # if diffY < 5
      #   y += 5

      # Position the indicator
      indicatorEl = indicator.el
      if @side is LEFT
        x = @paper.width - x
        indicatorEl.css right: x, top: y
      else
        indicatorEl.css left: x, top: y

      return

    # Indicator visibility
    # --------------------

    hideIndicators: ->
      for indicator in @indicators when indicator.el
        indicator.el.hide()
      return

    fade: (visible, duration, callback) ->
      unless @drawn
        callback?()
        return

      endOpacity = if visible then 1 else 0

      # Country label
      @countryLabel # Raphael.Element
        .stop()
        .show()
        .animate(opacity: endOpacity, duration, 'linear', callback)

      # Indicators
      for indicator in @indicators when indicator.el
        indicator.el # jQuery-wrapped element
          .stop(true, false)
          .css(display: 'block')
          .animate(opacity: endOpacity, duration, 'linear')

      return

    fadeIn: (callback) ->
      @fade true, @animationDuration / 2, callback
      return

    fadeOut: (callback) ->
      @fade false, @animationDuration / 2, callback
      return

    # State changes
    # -------------

    enterInvisibleState: (oldState) ->
      # Only handle the case highlight > invisible
      return unless oldState is HIGHLIGHT
      @fadeOut()
      return

    enterHighlightState: (oldState) ->
      # Only handle the case invisible > highlight
      return unless oldState is INVISIBLE

      @drawCountryLabel()

      if @elementCount < 9
        @drawOneToEightIndicators()
      else
        @drawNineToAllIndicator()

      @fadeIn()
      return

    # Disposal
    # --------

    dispose: ->
      return if @disposed
      clearTimeout @afterTransitionHandle
      super
