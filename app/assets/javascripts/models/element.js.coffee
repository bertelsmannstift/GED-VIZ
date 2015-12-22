define (require) ->
  'use strict'
  _ = require 'underscore'
  Indicator = require 'models/indicator'

  # This class is mere data container, it stores the data
  # in a usable format for the display object of the same name

  class Element

    # Property declarations
    # --------------------
    #
    # id: String
    # index: Number
    # name: String
    #   Translated country name or original group name
    # nameWithArticle: String
    #   Translated country name with article
    # nameAdjectivePlural: String
    #   Translated country name as adjective in nominative plural
    # sum: String
    # sumIn: Number
    # sumOut: Number
    # incoming: Object
    # outgoing: Object
    # missingRelations: Object
    # noIncoming: Array
    # noOutgoing: Array
    # indicators: Array.<Indicator>

    constructor: (data, index, country, indicatorTypesWithUnit) ->
      @id = country.get 'iso3'
      @index = index

      @name = country.name()
      @nameWithArticle = country.nameWithArticle()
      @nameWithPrepositionAndArticle = country.nameWithPrepositionAndArticle()
      @nameAdjectivePlural = country.nameAdjectivePlural()
      # Translate underscores to camelCase
      @sumIn = data.sum_in
      @sumOut = data.sum_out
      @sum = data.sum_out + data.sum_in
      {@incoming, @outgoing} = data
      @missingRelations = data.missing_relations
      @noIncoming = data.no_incoming
      @noOutgoing = data.no_outgoing

      # Convert indicator objects to Indicator instances
      @indicators = _(data.indicators).map (indicatorData, index) ->
        typeWithUnit = indicatorTypesWithUnit[index]
        new Indicator(
          typeWithUnit, indicatorData.value, indicatorData.tendency,
          indicatorData.tendency_percent, indicatorData.missing
        )
