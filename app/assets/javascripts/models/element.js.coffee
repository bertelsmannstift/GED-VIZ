define [
  'underscore'
  'models/indicator'
], (_, Indicator) ->
  'use strict'

  # This class is mere data container, it stores the data
  # in a usable format for the display object of the same name

  class Element

    # Property declarations
    # --------------------

    # id: String
    # index: Number
    # name: String
    #   Translated country name or original group name
    # sum: String
    # indicators: Array.<Indicator>
    #
    # From raw data:
    #
    # sum_in: Number
    # sum_out: Number
    # incoming: Object
    # outgoing: Object
    # missing_relations: Object
    # no_incoming: Array
    # no_outgoing: Array

    constructor: (elementData, index, keyframeData) ->
      # Copy properties from raw data
      _.extend this, elementData

      # Create derived properties
      country = keyframeData.countries[index]
      @id    = country.get('iso3')
      @index = index
      # Convert TemplateString to normal string
      @name  = String country.name()
      @sum   = elementData.sum_out + elementData.sum_in

      # Convert indicator objects
      typesWithUnit = keyframeData.indicator_types_with_unit
      @indicators = _(@indicators).map (indicatorData, index) ->
        typeWithUnit = typesWithUnit[index]
        new Indicator typeWithUnit, indicatorData.value,
          indicatorData.tendency, indicatorData.tendency_percent, indicatorData.missing,
