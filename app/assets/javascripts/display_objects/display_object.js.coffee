define [
  'backbone'
  'lib/states'
], (Backbone, States) ->
  'use strict'

  # Constants
  # ---------

  FUNCTION = 'function'

  class DisplayObject

    # Mix in on, off, trigger etc.
    _(@prototype).extend Backbone.Events

    # Mix in the state handling
    _(@prototype).extend States

    # Property declarations
    # ---------------------
    #
    # displayObjects: Array
    #   Child display objects stored for disposal

    # Whether the element is visible in the chart
    visible: true

    # Whether the element was drawn
    drawn: false

    constructor: ->
      @displayObjects = []

    # Drawing
    # -------

    saveDrawOptions: (options) ->
      for prop in @DRAW_OPTIONS
        @[prop] = options[prop]
      return

    # Visibility
    # ----------

    show: ->
      @visible = true
      return

    hide: ->
      @visible = false
      return

    # Adding and removing of child display objects
    # --------------------------------------------

    addChild: (child) ->
      @displayObjects.push child
      return

    removeChild: (child) ->
      @disposeChild child
      @displayObjects = _.without @displayObjects, child
      return

    disposeChild: (child) ->
      if typeof child.remove is FUNCTION
        child.remove()
      else if typeof child.dispose is FUNCTION
        child.dispose()
      return

    removeChildren: ->
      @disposeChild child for child in @displayObjects
      @displayObjects = []
      @drawn = false
      return

    # Debugging
    # ---------

    debugPoint: (x, y, color = 'red', r = 2) ->
      return unless @paper
      @addChild @paper.circle(x, y, r).attr(fill: color, 'stroke-opacity': 0)
      return

    # Disposal
    # --------

    disposed: false

    dispose: ->
      return if @disposed

      # Remove all event handlers
      @off()

      @removeChildren()

      @disposeStates()

      # Remove all properties except `id`
      delete @[prop] for own prop of this when prop isnt 'id'

      @disposed = true
      Object.freeze? this
