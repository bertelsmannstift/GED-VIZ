define [
  'models/country'
  'models/country_group'
], (Country, CountryGroup) ->
  'use strict'

  build: (attributes) ->
    if attributes.type is 'Country'
      Country.build attributes
    else if attributes.type is 'CountryGroup'
      CountryGroup.build attributes
