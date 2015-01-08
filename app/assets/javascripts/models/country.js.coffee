define [
  'underscore'
  'models/base/model'
  'lib/i18n'
], (_, Model, I18n) ->
  'use strict'

  class Country extends Model

    # Class properties
    # ----------------

    # Identity map

    @byIso3: {}

    @build: (attributes) ->
      iso3 = attributes.iso3
      country = Country.byIso3[iso3]
      unless country
        country = new Country attributes
        Country.byIso3[iso3] = country
      country

    # Instance properties
    # -------------------

    defaults:
      type: 'Country'

    isGroup: false

    name: ->
      I18n.t 'country_names', @get('iso3')

    nameWithArticle: ->
      I18n.t 'country_names_with_articles', @get('iso3')

    nameWithPrepositionAndArticle: ->
      I18n.translateWithFallback(
        'country_names_with_preposition_and_article', @get('iso3'),
        ''
      )

    nameAdjectivePlural: ->
      I18n.t 'country_names_adjective_plural', @get('iso3')

    toJSON: ->
      {
        type: 'Country',
        iso3: @get('iso3')
      }
