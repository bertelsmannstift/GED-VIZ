define [
  'underscore'
  'jquery'
  'models/country_factory'
], (_, $, CountryFactory) ->
  'use strict'

  # Send request and return a Promise
  send: (options) ->
    deferred = $.Deferred()

    successHandler = (data, textStatus, jqXHR) =>
      countries = _(data).map (c) -> CountryFactory.build(c)
      deferred.resolve countries
      return

    $.ajax
      type: 'POST'
      url: '/countries/partners'
      contentType: 'application/json'
      dataType: 'json'
      data: JSON.stringify(options)
      success: successHandler

    deferred.promise()
