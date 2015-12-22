define (require) ->
  'use strict'
  _ = require 'underscore'
  I18n = require 'lib/i18n'
  Model = require 'models/base/model'
  Country = require 'models/country'

  class CountryGroup extends Model

    # Class properties
    # ----------------

    @build: (attributes) ->
      new CountryGroup attributes, parse: true

    # Creates an identifier out of all country iso3 values.
    # For example 'bra-chi-ind-rus'
    # Accepts an array of raw objects or Backbone models.
    @isoFromCountries: (countries) ->
      _(countries).map((c) -> c.iso3 or c.get('iso3')).sort().join('-')

    # Instance properties
    # -------------------

    isGroup: true

    defaults:
      type: 'CountryGroup'

    parse: (attributes) ->
      attributes = _.clone attributes

      attributes.countries or= []

      # Split groups
      attributes.countries = _(attributes.countries).map (c) ->
        if c.isGroup then c.get('countries') else c
      attributes.countries = _(attributes.countries).flatten()

      # Convert countries to Backbone models if necessary
      if _(attributes.countries).any((c) -> c not instanceof Country)
        attributes.countries = _(attributes.countries).map (countryData) ->
          Country.build countryData

      # Create iso3 identifier
      unless attributes.iso3
        attributes.iso3 = CountryGroup.isoFromCountries attributes.countries

      attributes

    toJSON: ->
      {
        type: 'CountryGroup'
        title: @get('title')
        countries: _(@get('countries')).map (c) -> c.toJSON()
      }

    # Return the original group name without translation
    name: ->
      @get 'title'

    nameWithArticle: ->
      @get 'title'

    nameWithPrepositionAndArticle: ->
      @get 'title'

    nameAdjectivePlural: ->
      adjectives = _(@get('countries')).map (country) ->
        I18n.t 'country_names_adjective_plural', country.get('iso3')
      I18n.joinList adjectives
