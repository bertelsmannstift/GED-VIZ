define (require) ->
  'use strict'
  Country = require 'models/country'
  CountryGroup = require 'models/country_group'

  build: (attributes) ->
    if attributes.type is 'Country'
      Country.build attributes
    else if attributes.type is 'CountryGroup'
      CountryGroup.build attributes
