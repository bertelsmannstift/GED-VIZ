define [
  'underscore'
  'chaplin/lib/sync_machine'
  'models/base/model'
  'models/country_group'
  'models/element'
  'models/country_factory'
  'lib/i18n'
  'lib/type_data'
  'lib/type_text_helper'
], (
  _, SyncMachine, Model, CountryGroup, Element, CountryFactory,
  I18n, TypeData, TypeTextHelper
) ->
  'use strict'

  class Keyframe extends Model

    # Mix in a SyncMachine
    _.extend @prototype, SyncMachine

    # Constants
    # ---------

    QUERY_ATTRIBUTES = [
      'data_type_with_unit', 'indicator_types_with_unit',
      'year', 'currency', 'title', 'locking'
    ]
    DATA_ATTRIBUTES = [
      'elements', 'indicator_bounds', 'yearly_totals', 'max_overall'
    ]

    # Attributes
    # ----------
    #
    # Metadata:
    # data_type_with_unit: Array
    # indicator_types_with_unit: Array
    # year: Number
    # currency: String
    # countries: Array
    # title: String
    # locking: String or Array
    #
    # Data from server:
    # elements: Array
    # indicator_bounds: Array.<Array>
    # yearly_totals: Object
    # max_overall: Number

    # Property declarations
    # ---------------------
    #
    # fetchDeferred: jqXHR

    initialize: (attributes) ->
      super

      @set @parse(attributes) if attributes

    # Keyframe title
    # --------------

    # Returns the title if specified, otherwise the data type and the year
    # e.g. “Trade 2010”
    getDisplayTitle: ->
      title = @get 'title'
      return title if title
      dataType = @getTranslatedDataType()
      year = @get 'year'
      I18n.template(
        ['editor', 'keyframe_subtitle'],
        { data_type: dataType, year: year }
      )

    getSubtitle: ->
      dataType = @getTranslatedDataType()
      year = @get 'year'
      I18n.template(
        ['editor', 'keyframe_subtitle'],
        { data_type: dataType, year: year }
      )

    getTranslatedDataType: ->
      TypeTextHelper.shortType @get('data_type_with_unit')[0]

    # Serialization / Deserialization
    # -------------------------------

    toJSON: ->
      object = @pick QUERY_ATTRIBUTES
      object.countries = _(@get('countries')).map (c) -> c.toJSON()
      object

    parse: (rawData) ->
      data = _.clone rawData

      # Rebuild countries array.
      # Transform raw objects into Country/CountryGroup instances.
      data.countries = _.map rawData.countries, (countryData) ->
        CountryFactory.build countryData

      # Rebuild elements array.
      # Transform raw objects into Element instances.
      indicatorTypesWithUnit = data.indicator_types_with_unit
      data.elements = _.map rawData.elements, (elementData, index) ->
        country = data.countries[index]
        new Element elementData, index, country, indicatorTypesWithUnit

      # Add indicator scaling
      @scaleIndicators data

      data

    # Add the scale to the indicators that have an absolute representation
    scaleIndicators: (data) ->
      # Get absolute units
      absoluteUnits = _.chain(data.indicator_types_with_unit)
        # Create objects we can work with
        .map (typeWithUnit, index) ->
          [type, unit] = typeWithUnit
          {index, type, unit}
        # Filter by representation
        .filter (obj) ->
          TypeData.units[obj.unit].representation is TypeData.UNIT_ABSOLUTE
        .value()

      for {index} in absoluteUnits

        # Aggregate all indicators for this type
        for element in data.elements
          indicator = element.indicators[index]

          # Shared max value
          maxValue = _.max data.indicator_bounds[index], (v) ->
            Math.abs v

          # Add scale
          indicator.scale = Math.abs(indicator.value) / maxValue

      return

    # Fetching
    # --------

    fetch: ->
      @beginSync()
      @publishEvent 'keyframe:syncing', this
      @fetchDeferred?.abort()
      @fetchDeferred = super
        type: 'POST'
        url: '/keyframes/query'
        contentType: 'application/json'
        data: JSON.stringify(@toJSON())
      @fetchDeferred.then @fetchSuccess, @fetchError
      @fetchDeferred

    fetchSuccess: =>
      @finishSync()
      @publishEvent 'keyframe:synced', this
      delete @fetchDeferred
      return

    fetchError: =>
      @abortSync()
      @publishEvent 'keyframe:unsynced', this
      delete @fetchDeferred
      return

    # Cloning
    # -------

    clone: (options = {}) ->
      _.defaults options, withData: true

      # Copy primitives, reference objects.
      attributes = if options.withData
        _.clone @attributes
      else
        # Omit server-provided attributes
        _.omit @attributes, DATA_ATTRIBUTES

      # Create a copy of the objects that are changed and not replaced.
      # (The other objects like the data_type_with_unit array are replaced
      # on write, so we don’t need to copy them.)
      attributes.countries = @attributes.countries.concat()

      newKeyframe = new Keyframe()
      newKeyframe.beginSync()
      newKeyframe.attributes = attributes
      newKeyframe.finishSync()

      newKeyframe

    # Change countries
    # ----------------

    addCountry: (country) ->
      @addCountries [country]

    addCountries: (countries) ->
      oldCountries = @get 'countries'
      # Filter existing countries
      countries = _(countries).reject (country) ->
        _(oldCountries).any (c) ->
          c.get('iso3').indexOf(country.get('iso3')) isnt -1
      return if countries.length is 0
      newCountries = oldCountries.concat countries
      @set countries: newCountries
      @fetch()

    removeCountry: (country) ->
      iso3 = country.get 'iso3'
      countries = _.reject @get('countries'), (c) -> c.get('iso3') is iso3
      @set {countries}
      @fetch()

    moveCountry: (oldIndex, newIndex) ->
      countries = @get('countries').concat()
      country = countries[oldIndex]
      countries.splice oldIndex, 1
      countries.splice newIndex, 0, country
      @set {countries}
      @fetch()

    resetCountries: (countries, options = {}) ->
      @set {countries}, options
      @fetch()

    clearCountries: ->
      @set countries: []
      @fetch()

    isEmpty: ->
      @get('countries').length is 0

    # Country grouping
    # ----------------

    groupCountries: (countries, title) ->
      group = CountryGroup.build {countries, title}
      newCountries = @get('countries').concat()
      newCountries = _(newCountries).difference countries
      newCountries.push group
      @set countries: newCountries
      @fetch()

    ungroupCountries: (group) ->
      return unless group.isGroup
      newCountries = @get('countries').concat()
      index = _(newCountries).indexOf group
      countries = group.get 'countries'
      newCountries.splice index, 1, countries...
      @set countries: newCountries
      @fetch()

    renameGroup: (countryGroup, title) ->
      countryGroup.set {title}
      newCountries = @get('countries').concat()
      @set countries: newCountries
      @fetch()

    # Change indicators
    # -----------------

    # Creates a copy of the existing indicators types with unit,
    # calls the payload, updates the keyframe and fetches new data.
    changeIndicators: (payload) ->
      twus = @get('indicator_types_with_unit').concat()
      payload.call this, twus
      @set indicator_types_with_unit: twus
      @fetch()
      return

    addIndicatorTypeWithUnit: (twu) ->
      @changeIndicators (twus) ->
        twus.push twu
        return
      return

    removeIndicatorAt: (index) ->
      @changeIndicators (twus) ->
        twus.splice index, 1
        return
      return

    moveIndicator: (oldIndex, newIndex) ->
      @changeIndicators (twus) ->
        twu = twus.splice(oldIndex, 1)[0]
        twus.splice newIndex, 0, twu
        return
      return

    # Indicator helpers
    # -----------------

    getIndicatorMaxValue: (twu) ->
      twus = @get 'indicator_types_with_unit'
      index = _(twus).indexOf twu
      return null unless twus.length > index

      bounds = @get('indicator_bounds')[index]
      maxValue = _.max bounds, (v) -> Math.abs(v)

      maxValue
