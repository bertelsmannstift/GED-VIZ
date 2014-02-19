define [
  'raphael'
  'lib/i18n'
  'lib/scale'
  'lib/utils'
], (Raphael, I18n, scale, utils) ->
  'use strict'

  # Shortcuts
  # ---------

  PI = Math.PI
  TWO_PI = PI * 2
  HALF_PI = PI / 2

  sin = Math.sin
  cos = Math.cos

  OUTGOING = 'outgoing'
  INCOMING = 'incoming'

  # Constants
  # ---------

  SMALLEST_MAGNET = 4
  SMALLEST_SPACE = 4

  # These methods are mixed into Chart
  # ----------------------------------

  # Drawing
  # -------

  draw: (update) ->
    # Stop listening for resizes
    $window = $(window).off 'resize', @resize

    @setRadius()
    @calculatePositions()
    @drawElements()
    @restoreLocking update
    @drawn = true

    # Listen for resizes again
    $window.resize @resize

    return

  setRadius: ->
    scalingMap = if @format is utils.FORMAT_THUMBNAIL
      # Special chart radius for thumbnails
      'chartRadiusThumbnail'
    else if @elements.length is 1
      # Special chart radius for only one elements
      'chartRadiusOneOnly'
    else if @elements.length is 2
      # Special chart radius for two elements
      'chartRadiusOneToOne'
    else
      'chartRadius'

    smallestSide = Math.min @paper.width, @paper.height
    # Charts are typically wider then high
    weightedSmallestSide = Math.min @paper.width * 0.85, @paper.height
    factor = scale scalingMap, weightedSmallestSide
    @radius = weightedSmallestSide * factor

    # Decrease radius by the half of the y offset
    @radius -= @yOffset

    return

  drawElements: ->
    elements = @elements
    elementCount = elements.length

    # In Nine-to-All charts, show the label only for the x biggest countries.
    if elementCount >= 9
      indicatorVisibility = {}
      # Sort elements by sum
      sortedElements = elements.concat().sort utils.elementsSorter
      for element, index in sortedElements
        indicatorVisibility[element.id] = index < 8

    year = @keyframe.get('year')

    for element, index in elements
      previousElement = elements[index - 1] or elements[elementCount - 1]
      nextElement     = elements[index + 1] or elements[0]
      indicatorVisible = if elementCount >= 9
        indicatorVisibility[element.id]
      else
        true

      # Yeah, we need to pass all that stuff.
      element.draw {
        @paper,
        @$container,
        @animationDuration,
        chartFormat: @format,
        @customFont,
        chartDrawn: @drawn,
        chartRadius: @radius,
        elementCount,
        @elementIdsChanged,
        previousElement,
        nextElement,
        indicatorVisible,
        year
      }

    return

  # Restore the locking after drawing
  restoreLocking: (update) ->
    return if @format is utils.FORMAT_THUMBNAIL
    if update
      # Reset states while animating. Don’t publish locking removal.
      @lockingPublisherMuted = true
      @resetStates preserveLocking: false
      @lockingPublisherMuted = false

      # Restore the locking after the animation has finished.
      clearTimeout @initLockingHandle
      @initLockingHandle = utils.after @animationDuration, =>
        @initLocking()
    else
      @initLocking()

    return

  # Reset and Redraw
  # ----------------

  # Clear the paper, make tabula rasa
  clear: ->
    @removeElements()
    @createPaper()
    @drawn = false
    return

  # Clear the paper and redraw the whole chart from scratch
  redraw: ->
    @clear()
    @createElements()
    @createRelations()
    @draw()
    return

  # Element count error message
  # ---------------------------

  showElementCountError: ->
    text = @paper.text(
      @paper.width / 2,
      @paper.height / 2,
      I18n.t('editor', 'element_count_error')
    ).attr(
      'text-anchor': 'middle'
      'font-family': utils.getFont(@customFont)
      'font-weight': 300
      'font-size': 15
      fill: 'black'
    )
    @addChild text
    @elementCountError = text
    return

  hideElementCountError: ->
    if @elementCountError
      @removeChild @elementCountError
      delete @elementCountError
    return

  # The main layouting algorithms
  # -----------------------------

  calculatePositions: ->
    #@paper.circle(@paper.width/2, @paper.height/2, @radius).attr(stroke: 'blue', 'stroke-width': 1, 'stroke-opacity': 1)

    elementCount = @elements.length
    if elementCount is 1
      @calculatePositionForOneMagnet()
    else if elementCount is 2
      @calculatePositionForTwoMagnets()
    else if 2 < elementCount < 9
      @calculatePositionForThreeToEightMagnets()
    else if elementCount > 8
      @calculatePositionsForNineAndMoreMagnets()

    return

  calculatePositionForOneMagnet: ->
    {elements, maxSum} = this
    maxHeight = @radius * 2

    element = elements[0]
    deg = Raphael.rad 180
    height = maxHeight * (element.sum / maxSum)
    # Center the magnet horizontally
    x1 = scale('magnetSizeUpToTwo', @paper.width) / 2
    x2 = x1
    y1 = maxHeight / 2
    y2 = y1 - height

    # Adjust size in case no data is available, so a gray
    # bar can be drawn
    grayHeight = maxHeight * 0.05
    height += grayHeight if element.valueIsMissing(OUTGOING)
    height += grayHeight if element.valueIsMissing(INCOMING)
    grayBarRatio = grayHeight / height

    element.magnet.setPosition deg, x1, y1, x2, y2, grayBarRatio

    return

  calculatePositionForTwoMagnets: ->
    {elements, maxSum} = this
    maxHeight = @radius * 2
    grayHeight = maxHeight * 0.05

    # Left magnet
    # -----------

    element = elements[0]
    deg = Raphael.rad 180
    height = maxHeight * (element.sum / maxSum)

    # Adjust size in case no data is available, so a gray
    # bar can be drawn
    height += grayHeight if element.valueIsMissing(OUTGOING)
    height += grayHeight if element.valueIsMissing(INCOMING)
    grayBarRatio = grayHeight / height

    x1 = - @radius * 0.5
    x2 = x1
    y1 = maxHeight / 2
    y2 = y1 - height
    element.magnet.setPosition deg, x1, y1, x2, y2, grayBarRatio

    # Right magnet
    # ------------

    element = elements[1]
    deg = Raphael.rad 0
    height = maxHeight * (element.sum / maxSum)

    # Adjust size in case no data is available, so a gray
    # bar can be drawn
    height += grayHeight if element.valueIsMissing(OUTGOING)
    height += grayHeight if element.valueIsMissing(INCOMING)
    grayBarRatio = grayHeight / height

    x1 = @radius * 0.5
    x2 = x1
    y2 = maxHeight / 2
    y1 = y2 - height
    element.magnet.setPosition deg, x1, y1, x2, y2, grayBarRatio

    return

  calculatePositionForThreeToEightMagnets: ->
    {elements, maxSum} = this
    elementCount = elements.length

    rotationOffset = - HALF_PI
    rotationStep = TWO_PI / elementCount
    a = 2 * @radius * sin(PI / elementCount)

    deg = rotationOffset
    for element, index in elements
      startX = cos(deg) * @radius
      startY = sin(deg) * @radius

      eSum = element.sum

      # Adjust size in case no data is available, so a gray
      # bar can be drawn
      graySum = maxSum * 0.03
      eSum += graySum if element.valueIsMissing(OUTGOING)
      eSum += graySum if element.valueIsMissing(INCOMING)
      grayBarRatio = graySum / eSum

      weight = eSum / maxSum
      width = weight * (a - 2) + 2

      #width = weight * (a - 22) + 2
      halfWidth = width / 2

      xFactor = sin(PI - deg)
      yFactor = cos(PI - deg)

      x1 = startX + halfWidth * xFactor
      y1 = startY + halfWidth * yFactor

      x2 = startX - halfWidth * xFactor
      y2 = startY - halfWidth * yFactor

      element.magnet.setPosition deg, x1, y1, x2, y2, grayBarRatio

      deg += rotationStep

    return

  calculatePositionsForNineAndMoreMagnets: ->
    {elements, maxSum} = this
    elementCount = elements.length

    # Sort a copy for this algorithm
    sortedElements = elements.concat().sort utils.elementsSorter

    smallestMagnetDeg = @distanceToDeg SMALLEST_MAGNET, @radius
    smallestSpaceDeg  = @distanceToDeg SMALLEST_SPACE, @radius

    deg = -HALF_PI
    minSpaceSum = smallestSpaceDeg * elementCount
    degs = TWO_PI - minSpaceSum
    decInc = TWO_PI / 8

    # -----------------------------------------------------

    while true
      smallestMagnetValue = smallestMagnetDeg / decInc * maxSum
      sumValue = 0
      diffValue = 0

      for element in sortedElements
        magnet = element.magnet
        volume = element.sum
        if volume < smallestMagnetValue
          diffValue += (smallestMagnetValue - volume)
        sumValue += volume

      biggestDeg = degs * maxSum / (sumValue + diffValue)
      if biggestDeg >= decInc
        smallestSpaceDeg = (TWO_PI - ((sumValue + diffValue) / maxSum) * decInc) / elementCount
        break
      else
        decInc = biggestDeg

    # -----------------------------------------------------

    for element in elements
      magnet = element.magnet

      start =
        x: cos(deg) * @radius
        y: sin(deg) * @radius

      stepDeg = element.sum * decInc / maxSum
      if stepDeg < smallestMagnetDeg
        stepDeg = smallestMagnetDeg

      deg2 = deg + stepDeg
      end =
        x: cos(deg2) * @radius
        y: sin(deg2) * @radius

      middleDeg = (deg + deg2) / 2
      magnet.setPosition middleDeg, start.x, start.y, end.x, end.y, 0

      deg = deg2 + smallestSpaceDeg

    return

  distanceToDeg: (distance, circle) ->
    (HALF_PI - Math.atan(circle / distance * 2)) * 2
