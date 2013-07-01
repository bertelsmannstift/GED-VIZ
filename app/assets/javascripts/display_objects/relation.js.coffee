define [
  'jquery'
  'raphael'
  'chaplin/mediator'
  'display_objects/display_object'
  'lib/utils'
  'lib/colors'
  'lib/i18n'
], ($, Raphael, mediator, DisplayObject, utils, Colors, I18n) ->
  'use strict'

  # Shortcuts
  # ---------

  PI = Math.PI
  HALF_PI = PI / 2

  sin = Math.sin
  cos = Math.cos

  EASE_OUT = 'easeOut'

  # Constants
  # ---------

  NORMAL_COLOR = Colors.black
  STROKE_OPACITY = 0.1
  ARROW_SIZE = 10
  PERCENT_LABEL_DISTANCE = 20

  class Relation extends DisplayObject

    # Property declarations
    # ---------------------

    # id: String
    #   from and to ID connected with a “>”, like gbr>deu
    # from: Element
    # fromId: String
    # to: Element
    # toId: String
    # amount: Number
    # stackedAmountFrom: Number
    # stackedAmountTo: Number
    # missingRelations: Object
    # $container: jQuery
    #
    # path: Raphael.Element
    # destinationArrow: Raphael.Element
    # sourceArrow: Raphael.Element
    # labelContainer: jQuery
    # fadeDuration: Number
    # lookAnimation: Raphael.Animation
    #   Current animation of the path look, not the position
    #
    # Drawing variables which are passed in:
    #
    # animationDuration: Number
    # chartDrawn: Boolean

    DRAW_OPTIONS: 'animationDuration chartDrawn'.split(' ')

    constructor: (@fromId, @from, @toId, @to, @amount, @stackedAmountFrom,
      @stackedAmountTo, @missingRelations, @$container) ->
      super

      @id = "#{fromId}>#{toId}"

      @initStates
        states:

          # Locking
          locked: ['on', 'off']

          # Path states
          #   normal: light gray
          #   highlight: highlighted temporarily by hover, dark gray
          #   active: highlighted permanently by click, dark gray
          #   activeIn: red incoming relation, green arrow at source
          #   activeOut: green outgoing relation,
          #              green arrows at source and destination
          path: ['normal', 'highlight', 'active', 'activeIn', 'activeOut'],

          # labels states
          #   on: display labels
          #   off: hide labels
          labels: ['on', 'off']

        initialState:
          locked: 'off'
          path: 'normal'
          labels: 'off'

    # When being hidden, remove all children and return to undrawn state
    hide: ->
      if @drawn
        @animationDeferred?.reject()
        @removeChildren()
        # Remove additional references to DOM elements etc.
        props = 'path destinationArrow sourceArrow' +
          'labelContainer fadeDuration lookAnimation'
        for prop in props.split(' ')
          delete @[prop]
      super

    # Main drawing method
    # -------------------

    draw: (options, drawInverseFrom = false, drawInverseTo = false) ->

      @saveDrawOptions options
      {paper} = options

      @fadeDuration = @animationDuration / 2

      return unless @visible and @from and @to

      fromMagnet = @from.magnet
      toMagnet = @to.magnet

      # Fix for inner-country relations in charts with 1-2 elements
      if @from is @to
        drawInverseTo = drawInverseFrom

      # Helper for getting start and end point of relation line
      relationLinePointFromFace =
        x: (face, totalAmount, stackedAmount) =>
          face.start.x +
          ((face.end.x - face.start.x) / totalAmount * (stackedAmount - (@amount / 2))) +
          offset.x
        y: (face, totalAmount, stackedAmount) =>
          face.start.y +
          ((face.end.y - face.start.y) / totalAmount * (stackedAmount - (@amount / 2))) +
          offset.y

      offset =
        x: paper.width / 2
        y: paper.height / 2

      stackedAmounts =
        from: @from.sumOut - @stackedAmountFrom
        to: @to.sumIn - @stackedAmountTo

      # get faces of start and destination magnets
      startFace =
        start:
          x: unless drawInverseFrom then fromMagnet.x1 else fromMagnet.x2
          y: unless drawInverseFrom then fromMagnet.y1 else fromMagnet.y2
        end:
          x: unless drawInverseFrom then fromMagnet.x2 else fromMagnet.x1
          y: unless drawInverseFrom then fromMagnet.y2 else fromMagnet.y1
      destinationFace =
        start:
          x: unless drawInverseTo then toMagnet.x2 else toMagnet.x3
          y: unless drawInverseTo then toMagnet.y2 else toMagnet.y3
        end:
          x: unless drawInverseTo then toMagnet.x3 else toMagnet.x2
          y: unless drawInverseTo then toMagnet.y3 else toMagnet.y2

      startFace.length = Math.sqrt(
        Math.pow(startFace.end.x - startFace.start.x, 2) +
        Math.pow(startFace.end.y - startFace.start.y, 2)
      )

      # get relation line start and end point
      relationLine =
        start:
          x: relationLinePointFromFace.x(startFace, @from.sumOut, stackedAmounts.from)
          y: relationLinePointFromFace.y(startFace, @from.sumOut, stackedAmounts.from)
        end:
          x: relationLinePointFromFace.x(destinationFace, @to.sumIn, stackedAmounts.to)
          y: relationLinePointFromFace.y(destinationFace, @to.sumIn, stackedAmounts.to)

      # distance from startFace.start <-> destinationFace.start
      distance = Math.sqrt(
        Math.pow(relationLine.end.y - relationLine.start.y, 2) +
        Math.pow(relationLine.end.x - relationLine.start.x, 2)
      )

      controlPointDistance = distance * 0.4

      # some trigonometry for control points
      if drawInverseFrom
        degrees =
          start:
            deg: Math.atan2(startFace.start.y - startFace.end.y, startFace.start.x - startFace.end.x) - HALF_PI
      else
        degrees =
          start:
            deg: Math.atan2(startFace.end.y - startFace.start.y, startFace.end.x - startFace.start.x) - HALF_PI
      degrees.start.cos = Math.cos(degrees.start.deg)
      degrees.start.sin = Math.sin(degrees.start.deg)
      degrees.start.distCos = degrees.start.cos * controlPointDistance
      degrees.start.distSin = degrees.start.sin * controlPointDistance

      if drawInverseTo
        degrees.end =
          deg: Math.atan2(destinationFace.start.y - destinationFace.end.y, destinationFace.start.x - destinationFace.end.x) - HALF_PI
      else
        degrees.end =
          deg: Math.atan2(destinationFace.end.y - destinationFace.start.y, destinationFace.end.x - destinationFace.start.x) - HALF_PI
      degrees.end.cos = Math.cos(degrees.end.deg)
      degrees.end.sin = Math.sin(degrees.end.deg)
      degrees.end.distCos = degrees.end.cos * controlPointDistance
      degrees.end.distSin = degrees.end.sin * controlPointDistance

      # Calculate bézier control points for start and end
      controlPoint =
        start:
          x: relationLine.start.x - degrees.start.distCos
          y: relationLine.start.y - degrees.start.distSin
        end:
          x: relationLine.end.x - degrees.end.distCos
          y: relationLine.end.y - degrees.end.distSin

      relationLine.pathStr =
        # Curve from start through both control points to end
        'M' + relationLine.start.x + ',' + relationLine.start.y +
        'C' + controlPoint.start.x + ',' + controlPoint.start.y +
        ' ' + controlPoint.end.x + ',' + controlPoint.end.y +
        ' ' + relationLine.end.x + ',' + relationLine.end.y

      strokeWidth = (startFace.length / @from.sumOut) * @amount
      strokeWidth = Math.max(strokeWidth, 0.8)

      # Finally draw the paths
      # ----------------------

      # Initialize Deferred which tracks whether all parts have been drawn
      @animationDeferred?.reject()
      @animationDeferred = $.Deferred()

      # Curry the drawArrows function to use it as an animation callback
      drawArrows = _.bind @drawArrows, @,
        paper, startFace, destinationFace, stackedAmounts, degrees, offset

      if @drawn
        # Hide the arrows during the animation
        @hideArrows()

        # Animate existing path, stop all running animations
        @path.stop().animate(
          { path: relationLine.pathStr, 'stroke-width': strokeWidth },
          @animationDuration,
          EASE_OUT,
          # Move arrows after animation
          drawArrows
        )

        @drawn = true
        return

      # Path hasn’t been drawn before, create it from scratch
      @path = paper.path(relationLine.pathStr).attr(
        stroke: NORMAL_COLOR
        'stroke-opacity': if @chartDrawn then 0 else STROKE_OPACITY
        'stroke-width': strokeWidth
        #'stroke-dasharray': '.' # N/A
      )
      @addChild @path

      # If the relation belongs to a country which was added,
      # fade in the path
      afterTransition = if @animationDuration > 0 then @animationDuration + 100 else 0
      if @chartDrawn
        animation = Raphael.animation(
          { 'stroke-opacity': STROKE_OPACITY },
          @fadeDuration,
          EASE_OUT,
          # Draw arrows after animation
          drawArrows
        ).delay(afterTransition)
        @path.animate animation
      else
        # Immediately draw the arrows
        drawArrows()
        @animationDeferred.resolve()

      @registerMouseHandlers()

      @drawn = true
      return

    # Drawing the arrows
    # ------------------

    drawArrows: (paper, startFace, destinationFace, stackedAmounts, degrees, offset) =>
      delta =
        start:
          x: startFace.end.x - startFace.start.x
          y: startFace.end.y - startFace.start.y
        dest:
          x: destinationFace.end.x - destinationFace.start.x
          y: destinationFace.end.y - destinationFace.start.y

      deltaAmountFraction =
        startXFrom: delta.start.x / @from.sumOut
        startYFrom: delta.start.y / @from.sumOut
        destXTo:   delta.dest.x / @to.sumIn
        destYTo:   delta.dest.y / @to.sumIn

      base =
        start:
          one:
            x: startFace.start.x + (deltaAmountFraction.startXFrom * stackedAmounts.from) + offset.x
            y: startFace.start.y + (deltaAmountFraction.startYFrom * stackedAmounts.from) + offset.y
          two:
            x: startFace.start.x + (deltaAmountFraction.startXFrom * (stackedAmounts.from - @amount)) + offset.x
            y: startFace.start.y + (deltaAmountFraction.startYFrom * (stackedAmounts.from - @amount)) + offset.y
        dest:
          one:
            x: destinationFace.start.x + (deltaAmountFraction.destXTo * stackedAmounts.to) + offset.x
            y: destinationFace.start.y + (deltaAmountFraction.destYTo * stackedAmounts.to) + offset.y
          two:
            x: destinationFace.start.x + (deltaAmountFraction.destXTo * (stackedAmounts.to - @amount)) + offset.x
            y: destinationFace.start.y + (deltaAmountFraction.destYTo * (stackedAmounts.to - @amount)) + offset.y

      startArrowPathStr = 'M' + (base.start.one.x + degrees.start.cos) + ',' + (base.start.one.y + degrees.start.sin) +
        'L' + (base.start.two.x + degrees.start.cos) + ',' + (base.start.two.y + degrees.start.sin) +
        'L' + (base.start.one.x + (base.start.two.x - base.start.one.x) / 2 - degrees.start.cos * ARROW_SIZE) + ',' +
              (base.start.one.y + (base.start.two.y - base.start.one.y) / 2 - degrees.start.sin * ARROW_SIZE)

      destinationArrowPathStr = 'M' + (base.dest.one.x - degrees.end.cos) + ',' + (base.dest.one.y - degrees.end.sin) +
        'L' + (base.dest.two.x - degrees.end.cos) + ',' + (base.dest.two.y - degrees.end.sin) +
        'L' + (base.dest.one.x + (base.dest.two.x - base.dest.one.x) / 2 + degrees.end.cos * ARROW_SIZE) + ',' +
              (base.dest.one.y + (base.dest.two.y - base.dest.one.y) / 2 + degrees.end.sin * ARROW_SIZE)

      if @sourceArrow and @destinationArrow
        # Just move the existing arrows
        @sourceArrow.attr path: startArrowPathStr
        @destinationArrow.attr path: destinationArrowPathStr
        @animationDeferred.resolve()
        return

      # Draw arrows from scratch
      color = Colors.magnets[@from.dataType].outgoing
      @sourceArrow = paper.path(startArrowPathStr)
        .hide() # Start hidden
        .attr(fill: color, 'stroke-opacity': 0)
      @addChild @sourceArrow

      @destinationArrow = paper.path(destinationArrowPathStr)
        .hide() # Start hidden
        .attr(fill: Colors.gray, 'stroke-opacity': 0)
      @addChild @destinationArrow

      @animationDeferred.resolve()

      return

    hideArrows: ->
      @sourceArrow?.hide()
      @destinationArrow?.hide()
      return

    # Content box methods
    # -------------------

    showContextBox: ->
      mediator.publish 'contextbox:explainRelation',
        fromName: @from.name
        toName: @to.name
        dataType: @from.dataType
        amount: @amount
        unit: @from.unit
        percentFrom: (100 / @from.sumOut * @amount).toFixed(1) + '%'
        percentTo: (100 / @to.sumIn * @amount).toFixed(1) + '%'
        missingRelations: @missingRelations
        year: @from.year

    hideContextBox: ->
      mediator.publish 'contextbox:hide'

    # Mouse event handling
    # --------------------

    registerMouseHandlers: ->
      $(@path.node)
        .mouseenter(@mouseenterHandler)
        .mouseleave(@mouseleaveHandler)
        .click(@clicked)

    mouseenterHandler: =>
      # Fade in content box
      @showContextBox()

      # Highlight if normal
      if @state('path') is 'normal'
        @transitionTo 'path', 'highlight'

      # Show labels in any case
      @transitionTo 'labels', 'on'
      return

    mouseleaveHandler: (event) =>
      relatedTarget = event.relatedTarget

      # Stop if the target is the relation path
      if _(@displayObjects).some((obj) -> relatedTarget is obj.node) or
        @labelContainer and $.contains(@labelContainer.get(0), relatedTarget)
          return

      # Fade out content box
      @hideContextBox()

      pathState = @state 'path'

      # Reset if highlighted
      if pathState is 'highlight'
        @transitionTo 'path', 'normal'

      # Hide labels if not active
      unless pathState is 'active'
        @transitionTo 'labels', 'off'
      return

    clicked: =>
      # Toggle locking
      if @state('locked') is 'on'
        @transitionTo 'path', 'highlight'
        @transitionTo 'locked', 'off'
      else
        @transitionTo 'path', 'active'
        @transitionTo 'locked', 'on'
      return

    # Transitions
    # -----------

    # Path transition handlers
    # ------------------------

    enterPathNormalState: (oldState) ->
      return unless oldState and @drawn
      @setNormalLook()

    enterPathHighlightState: ->
      @setHighlightLook() if @drawn

    enterPathActiveState: ->
      @setHighlightLook() if @drawn

    enterPathActiveInState: ->
      @setActiveInLook() if @drawn

    enterPathActiveOutState: ->
      @setActiveOutLook() if @drawn

    # Labels transition handlers
    # --------------------------

    enterLabelsOnState: ->
      @createLabels() if @drawn

    enterLabelsOffState: ->
      @removeLabels() if @drawn

    # Transitions helpers
    # -------------------

    # Normal look: Gray translucent path, no arrows
    setNormalLook: ->
      @animatePathLook(
        { stroke: NORMAL_COLOR, 'stroke-opacity': STROKE_OPACITY },
        @fadeDuration
      )
      @hideArrows()
      return

    # Highlighted: Gray opaque path, both arrows visible,
    # gray destination arrow
    setHighlightLook: ->
      # Wait for animation to complete
      @animationDeferred.done =>
        @animatePathLook(
          { stroke: Colors.gray, 'stroke-opacity': 1 },
          @fadeDuration
        )
        @sourceArrow.toFront().show()
        @destinationArrow.stop().toFront().show().animate(
          { fill: Colors.gray, 'fill-opacity': 1 },
          @fadeDuration,
          EASE_OUT
        )
        return
      return

    # Active in: Red translucent path, only show source arrow
    setActiveInLook: ->
      @animationDeferred.done =>
        color = Colors.magnets[@from.dataType].incoming
        @animatePathLook(
          { stroke: color, 'stroke-opacity': 0.85 },
          @fadeDuration
        )
        @sourceArrow.toFront().show()
        @destinationArrow.stop().hide()
        return
      return

    # Active out: Green translucent path, both arrows visible,
    # green destination arrow
    setActiveOutLook: ->
      @animationDeferred.done =>
        color = Colors.magnets[@from.dataType].outgoing
        @animatePathLook(
          { stroke: color, 'stroke-opacity': 0.85 },
          @fadeDuration
        )
        @sourceArrow.toFront().show()
        @destinationArrow.stop().toFront().show().animate(
          { fill: color, 'fill-opacity': 0.85 },
          @fadeDuration,
          EASE_OUT
        )
        return
      return

    # Helper for the path look animation (not the path itself).
    # Ensures that only one look animation is running.
    animatePathLook: (attributes, duration) ->
      return unless @path
      @path.stop @lookAnimation if @lookAnimation
      @lookAnimation = Raphael.animation attributes, duration, EASE_OUT
      @path.animate @lookAnimation
      return

    # Create labels
    # -------------

    createLabels: ->
      # Don’t create the labels twice
      return if @labelContainer

      # Create the container
      @labelContainer = $('<div>')
        .addClass('relation-labels')
        # Check target when the mouse leaves the labels
        .mouseleave(@mouseleaveHandler)
        # Allow activation by clicking on a label
        .click(@clicked)
        # Append to DOM
        .appendTo(@$container)
      @addChild @labelContainer

      # Get a point at the middle of the path to position the labels
      pathLength = @path.getTotalLength()
      middleOfPath = @path.getPointAtLength(pathLength / 2)
      x = middleOfPath.x
      y = middleOfPath.y

      # Create the value label
      # ----------------------

      text = I18n.template(
        ['units', @from.unit, 'with_value_html']
        number: utils.formatValue(@amount, @from.dataType, @from.unit)
      )

      value = $('<div>')
        .addClass('relation-value-label')
        .append(text)
        # Append immediately to get the size
        .appendTo(@labelContainer)

      # Calculate bounding box
      valueBox =
        width: value.outerWidth()
        height: value.outerHeight()
      valueBox.x = x - valueBox.width / 2
      valueBox.y = y - valueBox.height - 1.5
      valueBox.x2 = valueBox.x + valueBox.width
      valueBox.y2 = valueBox.y + valueBox.height

      value.css(left: valueBox.x, top: valueBox.y)

      # Create the description label
      # ----------------------------

      text = I18n.template(
        ['relation', @from.dataType],
        from: @from.name, to: @to.name
      )

      description = $('<div>')
        .addClass('relation-description-label')
        .text(text)
        # Append immediately to get the size
        .appendTo(@labelContainer)

      # Calculate bounding box
      descriptionBox =
        width: description.outerWidth()
        height: description.outerHeight()
      descriptionBox.x = x - descriptionBox.width / 2
      descriptionBox.y = y + 1.5
      descriptionBox.x2 = descriptionBox.x + descriptionBox.width
      descriptionBox.y2 = descriptionBox.y + descriptionBox.height

      description.css(left: descriptionBox.x, top: descriptionBox.y)

      # Create the source percent label
      # -------------------------------

      text = (100 / @from.sumOut * @amount).toFixed(1) + ' %'

      source = $('<div>')
        .addClass('relation-percentage-label')
        .text(text)
        # Append immediately to get the size
        .appendTo(@labelContainer)

      # Calculate bounding box
      point = @path.getPointAtLength PERCENT_LABEL_DISTANCE
      srcBox =
        width: source.outerWidth()
        height: source.outerHeight()
      srcBox.x = point.x - srcBox.width / 2
      srcBox.y = point.y - srcBox.height / 2
      srcBox.x2 = srcBox.x + srcBox.width
      srcBox.y2 = srcBox.y + srcBox.height

      # Create the destination percent label
      # ------------------------------------

      text = (100 / @to.sumIn * @amount).toFixed(1) + ' %'

      destination = $('<div>')
        .addClass('relation-percentage-label')
        .text(text)
        # Append immediately to get the size
        .appendTo(@labelContainer)

      # Calculate bounding box
      point = @path.getPointAtLength pathLength - PERCENT_LABEL_DISTANCE
      destBox =
        width: destination.outerWidth()
        height: destination.outerHeight()
      destBox.x = point.x - destBox.width / 2
      destBox.y = point.y - destBox.height / 2
      destBox.x2 = destBox.x + destBox.width
      destBox.y2 = destBox.y + destBox.height

      # Position the percent labels
      # ---------------------------

      # If one box intersects with value/description,
      # move both over their magnets

      percentLabelsIntersect =
        Raphael.isBBoxIntersect(srcBox, valueBox) or
        Raphael.isBBoxIntersect(srcBox, descriptionBox) or
        Raphael.isBBoxIntersect(destBox, valueBox) or
        Raphael.isBBoxIntersect(destBox, descriptionBox)

      if percentLabelsIntersect

        dist = PERCENT_LABEL_DISTANCE

        # Move source label
        point = @path.getPointAtLength 0
        deg = @from.magnet.deg
        srcBox.x = point.x + cos(deg) * dist - srcBox.width / 2
        srcBox.y = point.y + sin(deg) * dist - srcBox.height / 2

        # Move destination label
        point = @path.getPointAtLength pathLength
        deg = @to.magnet.deg
        destBox.x = point.x + cos(deg) * dist - destBox.width / 2
        destBox.y = point.y + sin(deg) * dist - destBox.height / 2

      # Finally set their position
      source.css(left: srcBox.x, top: srcBox.y)
      destination.css(left: destBox.x, top: destBox.y)

      return

    # Remove labels
    # -------------

    removeLabels: ->
      return unless @labelContainer
      @labelContainer.remove()
      @removeChild @labelContainer
      delete @labelContainer

    # Disposal
    # --------

    dispose: ->
      return if @disposed

      # Remove references from elements
      @from.removeRelationOut this if @from
      @to.removeRelationIn    this if @to

      # Stop the animation Deferred
      @animationDeferred?.reject()

      super
