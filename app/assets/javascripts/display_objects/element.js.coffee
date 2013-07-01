define [
  'underscore'
  'lib/utils'
  'display_objects/display_object'
  'display_objects/magnet'
  'display_objects/indicators'
], (_, utils, DisplayObject, Magnet, Indicators) ->
  'use strict'

  # Constants
  # ---------

  LEFT = 'left'
  RIGHT = 'right'

  class Element extends DisplayObject

    # Property Declarations
    # ---------------------
    #
    # id: String
    # name: String
    #
    # magnet: Magnet
    # indicators: Indicators
    #
    # relationsOut: Array
    #   Outgoing relations
    # relationsIn: Array
    #   Incoming relations
    #
    # index: Number
    #
    # dataType: String
    # unit: String
    #
    #
    # sum: Number
    #   Total volume of all relations from all countries,
    #   even if they aren’t in the current selection
    # sum_in: Number
    #   Incoming volume
    # sumOut: Number
    #   Outgoing volume
    #
    # noIncoming: Array
    # noOutgoing: Array
    #
    # total: Number
    #   Volume as a sum of the relations to
    #   the countries in the current selection
    # totalIn: Number
    #   Incoming volume
    # totalOut: Number
    #   Outgoing volume
    #
    # Drawing variables which are passed in:
    #
    # paper: Raphael.Paper
    # $container: jQuery
    # animationDuration: Number
    # chartFormat: String
    # chartDrawn: Boolean
    # chartRadius: Number
    # elementCount: Number
    #   Number of elements in the chart
    # elementIdsChanged: Boolean
    # year: Number

    DRAW_OPTIONS:
      ('paper $container animationDuration chartFormat chartDrawn ' +
      'chartRadius elementCount elementIdsChanged year').split(' ')

    constructor: (data, dataTypeWithUnit) ->
      super

      {@id, @name} = data

      # Create relations
      @relationsIn = []
      @relationsOut = []

      # Init/save data
      @resetTotalVolume()
      @update arguments...

      # Create child display objects
      @createMagnet()
      @createIndicators data.indicators

    # Updating
    # --------

    update: (data, dataTypeWithUnit) ->
      [@dataType, @unit] = dataTypeWithUnit

      @name = data.name
      @index = data.index

      @sumIn = data.sum_in
      @sumOut = data.sum_out
      @sum = @sumIn + @sumOut

      @noIncoming = data.no_incoming
      @noOutgoing = data.no_outgoing

      @updateIndicators data.indicators

      return

    # Volume helpers
    # --------------

    # Ratio between outgoing and total volume
    getRate: ->
      if @sum is 0 then return 0
      @sumOut / @sum

    resetTotalVolume: ->
      @totalIn = 0
      @totalOut = 0
      @total = 0
      return

    valueIsMissing: (part) ->
      if part is 'outgoing' and @noOutgoing.length > 0 and @sumOut is 0
        return true

      if part is 'incoming' and @noIncoming.length > 0 and @sumIn is 0
        return true

      false

    # Magnet
    # ------

    createMagnet: ->
      magnet = new Magnet this
      @magnet = magnet
      @addChild magnet
      magnet

    # Indicators
    # ----------

    createIndicators: (indicatorsData) ->
      @indicators = new Indicators this, indicatorsData
      @addChild @indicators
      return

    updateIndicators: (data) ->
      return unless @indicators
      @indicators.update data
      return

    # Relations
    # ---------

    # Returns a new array with all relations
    getAllRelations: ->
      @relationsIn.concat @relationsOut

    # Adding relations
    # ----------------

    addRelationIn: (relation) ->
      @relationsIn.push relation
      # Keep the array sorted
      @relationsIn.sort utils.relationSorter
      @addRelation relation
      return

    addRelationOut: (relation) ->
      @relationsOut.push relation
      # Keep the array sorted
      @relationsOut.sort utils.relationSorter
      @addRelation relation
      return

    # Private method for adding a relation and increasing the volume
    addRelation: (relation) ->
      # Update total volume
      @totalOut += relation.amount
      @total += relation.amount
      return

    # Removing relations
    # ------------------

    removeRelationIn: (relation) ->
      @relationsIn = _(@relationsIn).without relation
      @removeRelation relation
      return

    removeRelationOut: (relation) ->
      @relationsOut = _(@relationsOut).without relation
      @removeRelation relation
      return

    # Private method for removeing a relation and decreasing the volume
    removeRelation: (relation) ->
      # Update total volume
      @totalIn -= relation.amount
      @total -= relation.amount
      return

    # Removes all relations, empties the lists, resets the volumes
    removeRelations: ->
      @relationsOut = []
      @relationsIn = []
      @resetTotalVolume()
      return

    # Drawing
    # -------

    draw: (options) ->
      @saveDrawOptions options

      # Magnet
      @magnet.draw options

      # Relations
      if @elementCount is 2
        @drawOneToOneRelations options
      else
        @drawNormalRelations options

      # Draw Indicators
      options.degDiff = Math.abs(
        @magnet.degdeg - options.previousElement.magnet.degdeg
      )
      @indicators.draw options

      @drawn = true
      return

    # Draw relations
    # --------------

    # Returns the percent position of a relation in all sorted
    # incoming/outgoing relations, measured by the relation amount
    getRelationPosition: (relation) ->
      total = if relation.from is this then @sumOut else @sumIn
      @getRelationSum(relation) / total

    # Returns the sum of the relations before the given relation
    getRelationSum: (relation) ->
      sum = 0
      relations = if relation.from is this then @relationsOut else @relationsIn
      for otherRelation in relations
        if otherRelation is relation
          break
        else
          sum += otherRelation.amount
      sum

    drawNormalRelations: (options) ->
      for relation in @relationsOut when relation.visible and relation.to
        relation.draw options
      return

    drawOneToOneRelations: (options) ->
      side = if @magnet.degdeg is 180 then LEFT else RIGHT
      drawInverseFrom = side is LEFT
      drawInverseTo = side is RIGHT
      for relation in @relationsOut when relation.visible and relation.to
        relation.draw options, drawInverseFrom, drawInverseTo
      return

    # Disposal
    # --------

    dispose: ->
      return if @disposed

      # Magnet and indicators are disposed automatically since they are children
      relation.dispose() for relation in @relationsOut.concat()
      relation.dispose() for relation in @relationsIn.concat()

      super
