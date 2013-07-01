define [
  'raphael'
  'underscore'
  'lib/utils'
  'display_objects/display_object'
  'display_objects/chart_states'
  'display_objects/chart_drawing'
  'display_objects/chart_elements'
  'display_objects/chart_relations'
], (
  Raphael, _, utils,
  DisplayObject,
  # Submodules
  ChartStates, ChartDrawing, ChartElements, ChartRelations
) ->
  'use strict'

  Raphael.easing_formulas.chartEaseOut = (n) -> Math.pow(n, 0.1)

  class Chart extends DisplayObject

    # Support detection (used in the Player)
    @canUse = do ->
      # The browser must support VML or SVG
      Raphael.type isnt '' and
      # But exclude IE 6 and 7 so they get the static chart
      not /MSIE [67]\.0/.test(navigator.userAgent)

    # Mixin the submodules
    # --------------------

    _.extend @prototype,
      ChartStates, ChartDrawing, ChartElements, ChartRelations

    # Property declarations
    # ---------------------

    # $container: jQuery
    # animationDuration: Number
    # keyframe: Keyframe
    #   The main data source
    # dataTypeWithUnit: Array.<String>
    # elements: Array.<Element>
    #   The main element list
    # elementsById: Object.<Element>
    #   Current elements by ID
    # elementIdsChanged: Boolean
    #   Flag that indicates whether element IDs changed since the last update
    #   (i.e. elements were added, removed or moved)
    # format: utils.FORMAT_DEFAULT or utils.FORMAT_THUMBNAIL
    #   Normal or compact rendering (used for static images)
    # customFont: Boolean
    #   Whether to use a custom font (used for static images)
    # radius: Number
    #   The chart radius
    # yOffset: Number
    #   Move the chart center using this y offset
    # maxSum: Number
    #   Maximum data value that is used for magnet scaling
    # initLockingHandle: Number
    #   setTimeout handle for restoring the locking after chart transition
    # updateDisabled: Boolean
    #   Flag that is enabled while setting locks to prevent recursion
    # lockingPublisherMuted: Boolean
    #   Flag that is enabled while resetting states to prevent recursion
    # elementCountError: Raphael.Element
    #   When no elements are present, this is the error message

    constructor: (options) ->
      super
      @initChartStates()

      # Wrap the container in a jQuery object
      $container = $(options.container)
      @$container = $container

      @customFont = options.customFont ? true
      @$container.toggleClass 'custom-font', @customFont

      # Set up animation duration
      @animationDuration = options.animationDuration ? 1000

      # Determine the format
      @format = options.format ? utils.FORMAT_DEFAULT

      @createPaper()

    # (Re-)Create the main drawing paper
    createPaper: ->
      # Remove existing paper
      @removeChild @paper if @paper

      # Create the new paper
      @paper = Raphael @$container.get(0), @$container.width(), @$container.height()
      @addChild @paper

      # Listen for clicks on the canvas
      $(@paper.canvas).click _.bind(@canvasClicked, @)

      return

    # On window resize, redraw the whole chart
    resize: =>
      @redraw() if @drawn
      return

    # Limit calls to resize
    resize: _.debounce(@prototype.resize, 600)

    # Update the chart to represent a keyframe
    update: (options) ->
      return if @updateDisabled

      keyframe = options.keyframe
      @keyframe = keyframe

      @yOffset = options.yOffset ? 0

      # Get max sum from model
      @maxSum = keyframe.get 'max_overall'

      oldDataTypeWithUnit = @dataTypeWithUnit
      @dataTypeWithUnit = keyframe.get 'data_type_with_unit'

      # Just show an error message if no elements
      if @getElementCount() is 0
        @clear()
        @showElementCountError()
        return
      else
        @hideElementCountError()

      # Draw chart from scratch if the data type changed
      if @elements and not _(@dataTypeWithUnit).isEqual(oldDataTypeWithUnit)
        @clear()

      # Set up or update display objects
      unless @elements
        update = false
        @createElements()
        @createRelations()
      else
        update = true
        @updateElements()
        @updateRelations()

      # (Re-)draw
      @draw update

      return

    # Disposal
    # --------

    disposed: false

    dispose: ->
      return if @disposed
      clearTimeout @initLockingHandle
      $(window).off 'resize', @resize
      @removeElements()
      @paper.clear()
      delete @keyframe
      delete @dataTypeWithUnit
      super
