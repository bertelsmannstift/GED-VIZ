define (require) ->
  'use strict'
  _ = require 'underscore'
  $ = require 'jquery'
  CountryFactory = require 'models/country_factory'

  # Send request and return a Promise
  send: (options) ->
    deferred = $.Deferred()

    # We don’t need a server request for alphabetical sorting.
    if options.type is 'alphabetical'
      sortedCountries = _(options.countries).sortBy (c) -> c.name()
      # Resolve deferred immediately and return it.
      return deferred.resolve(sortedCountries).promise()

    successHandler = (data, textStatus, jqXHR) ->
      countries = _(data).map (c) -> CountryFactory.build(c)
      deferred.resolve countries
      return

    options.countries = _(options.countries).map (c) -> c.toJSON()
    $.ajax
      type: 'POST'
      url: '/countries/sort'
      contentType: 'application/json'
      dataType: 'json'
      data: JSON.stringify(options)
      success: successHandler

    deferred.promise()
