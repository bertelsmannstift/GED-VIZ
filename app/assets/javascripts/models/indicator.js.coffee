define (require) ->
  'use strict'
  _ = require 'underscore'
  TypeData = require 'lib/type_data'

  # This class is mere data container, it stores the data
  # in a usable format for the display object of the same name

  class Indicator

    # Property declarations
    # ---------------------

    # type: String
    # value: String
    # tendency: Number
    #   null: no tendency
    #   2: heavily increasing
    #   1: increasing
    #   0: steady
    #   -1: decreasing
    #   -2: heavily decreasing
    # tendencyPercent: Number
    # unit: Number
    # decimals: Number
    # representation: Number
    #   0: ABSOLUTE
    #   1: PROPORTIONAL

    # The percent scale of the value relative to
    # the maximum value in the whole chart
    scale: 1

    constructor: (typeWithUnit, @value, @tendency, @tendencyPercent, @missing) ->
      [@type, @unit] = typeWithUnit
      typeData = TypeData.units[@unit]
      @representation = typeData.representation